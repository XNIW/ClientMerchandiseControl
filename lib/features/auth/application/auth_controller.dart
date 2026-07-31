import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/secure_supabase_auth_storage.dart';
import '../../../core/config/app_config.dart';
import '../data/auth_callback_validator.dart';
import '../data/auth_error_mapper.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/authenticated_customer.dart';
import 'auth_providers.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final class AuthController extends Notifier<AuthState> {
  static const _maxPendingCallbacks = 4;
  static const _maxConsumedFingerprints = 64;

  AppConfig? _config;
  AuthRepository? _repository;
  AuthCallbackValidator? _validator;
  AuthErrorMapper? _errorMapper;

  StreamSubscription<Uri>? _callbackSubscription;
  StreamSubscription<AuthSessionEvent>? _sessionSubscription;
  Future<void>? _initialization;
  Future<void>? _loginOperation;
  Future<void>? _callbackDrain;
  Future<void>? _logoutOperation;
  Future<AuthenticatedCustomer>? _exchangeOperation;
  Future<void>? _flowTermination;

  final ListQueue<Uri> _pendingCallbacks = ListQueue();
  final Set<int> _consumedFingerprints = <int>{};
  final ListQueue<int> _fingerprintOrder = ListQueue();

  var _generation = 0;
  var _disposed = false;
  var _oauthFlowActive = false;
  var _ignoreCallbacksUntilNextLogin = false;
  var _suppressSessionAuthentication = false;

  @override
  AuthState build() {
    final config = ref.watch(appConfigProvider);
    _config = config;
    _validator = ref.read(authCallbackValidatorProvider);
    _errorMapper = ref.read(authErrorMapperProvider);
    ref.onDispose(_dispose);

    if (!config.googleAuthEnabled) {
      return const AuthGuest(canAuthenticate: false);
    }

    scheduleMicrotask(() {
      if (!_disposed) {
        _initialization ??= _initialize(config);
      }
    });
    return const AuthGuest(canAuthenticate: true);
  }

  Future<void> startGoogleSignIn() {
    final termination = _flowTermination;
    if (termination != null) {
      return termination;
    }
    final logout = _logoutOperation;
    if (logout != null || state is AuthSigningOut) {
      return logout ?? Future<void>.value();
    }
    final active = _loginOperation;
    if (active != null || _oauthFlowActive) {
      return active ?? Future<void>.value();
    }
    if (_disposed || !(_config?.googleAuthEnabled ?? false)) {
      return Future<void>.value();
    }

    late final Future<void> operation;
    operation = _runGoogleSignIn().whenComplete(() {
      if (identical(_loginOperation, operation)) {
        _loginOperation = null;
      }
    });
    _loginOperation = operation;
    return operation;
  }

  Future<void> _runGoogleSignIn() async {
    final generation = ++_generation;
    _ignoreCallbacksUntilNextLogin = false;
    _suppressSessionAuthentication = false;
    _oauthFlowActive = true;
    _setState(const AuthAuthenticating());

    await (_initialization ??= _initialize(_config!));
    final repository = _repository;
    if (!_isCurrent(generation) || repository == null) {
      _oauthFlowActive = false;
      return;
    }
    if (state is AuthAuthenticated) {
      _oauthFlowActive = false;
      return;
    }
    final restoredCustomer = repository.currentCustomer;
    if (restoredCustomer != null) {
      _oauthFlowActive = false;
      _setState(
        AuthAuthenticated(
          customer: restoredCustomer,
          origin: AuthSessionOrigin.restored,
        ),
      );
      return;
    }

    try {
      await repository.clearPendingOAuth();
      if (!_isCurrent(generation)) {
        return;
      }
      if (state is AuthAuthenticated) {
        _oauthFlowActive = false;
        return;
      }
      final restoredAfterCleanup = repository.currentCustomer;
      if (restoredAfterCleanup != null) {
        _oauthFlowActive = false;
        _setState(
          AuthAuthenticated(
            customer: restoredAfterCleanup,
            origin: AuthSessionOrigin.restored,
          ),
        );
        return;
      }
      final launched = await repository.launchGoogleSignIn();
      if (!_isCurrent(generation)) {
        return;
      }
      if (!launched) {
        _oauthFlowActive = false;
        _setState(
          const AuthRecoverableError(
            AuthFailure(AuthFailureKind.browserLaunchFailed),
          ),
        );
      }
    } on Object catch (error) {
      if (_isCurrent(generation)) {
        _oauthFlowActive = false;
        _publishMappedFailure(error);
      }
    }
  }

  Future<void> cancelGoogleSignIn() {
    final termination = _flowTermination;
    if (termination != null) {
      return termination;
    }
    if (_disposed || (!_oauthFlowActive && state is! AuthAuthenticating)) {
      return Future<void>.value();
    }

    return _startFlowTermination(cancelled: true);
  }

  Future<void> _startFlowTermination({
    required bool cancelled,
    AuthFailure? failure,
  }) {
    final active = _flowTermination;
    if (active != null) {
      return active;
    }

    late final Future<void> operation;
    operation = _runFlowTermination(cancelled: cancelled, failure: failure)
        .whenComplete(() {
          if (identical(_flowTermination, operation)) {
            _flowTermination = null;
          }
        });
    _flowTermination = operation;
    return operation;
  }

  Future<void> _runFlowTermination({
    required bool cancelled,
    AuthFailure? failure,
  }) async {
    ++_generation;
    _oauthFlowActive = true;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = true;
    _pendingCallbacks.clear();
    _setState(const AuthCancelling());

    Object? cleanupError;
    try {
      final initialization = _initialization;
      if (_repository == null && initialization != null) {
        await initialization;
      }

      final exchange = _exchangeOperation;
      if (exchange != null) {
        try {
          await exchange;
        } on Object {
          // La compensazione è identica per successo o errore dell'exchange.
        }
      }
      await _repository?.signOutLocal();
    } on Object catch (error) {
      cleanupError = error;
    }

    _oauthFlowActive = false;
    if (_disposed) {
      return;
    }
    if (state is AuthConfigurationError) {
      return;
    }
    if (cleanupError != null) {
      _publishMappedFailure(cleanupError);
      return;
    }
    if (failure != null) {
      _publishFailurePreservingAuthenticated(failure);
      return;
    }
    if (cancelled) {
      _setState(const AuthCancelled());
    } else {
      _setState(
        const AuthRecoverableError(AuthFailure(AuthFailureKind.unexpected)),
      );
    }
  }

  Future<void> _failClosedStorage(Object _) async {
    if (_disposed || state is AuthConfigurationError) {
      return;
    }
    ++_generation;
    _oauthFlowActive = false;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = true;
    _pendingCallbacks.clear();
    _setState(
      const AuthConfigurationError(
        AuthFailure(AuthFailureKind.secureStorageUnavailable),
      ),
    );
    try {
      await _repository?.signOutLocal();
    } on Object {
      // Il configuration error resta il risultato fail-closed anche se il purge
      // dovrà essere ritentato al bootstrap tramite i cleanup marker.
    }
  }

  void _suspendExpiredSession() {
    if (_disposed) {
      return;
    }
    ++_generation;
    _oauthFlowActive = false;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = false;
    _pendingCallbacks.clear();
    _setState(
      AuthGuest(
        canAuthenticate: _config?.googleAuthEnabled ?? false,
        notice: const AuthFailure(AuthFailureKind.sessionExpired),
      ),
    );
  }

  Future<void> retry() => startGoogleSignIn();

  Future<void> signOut() {
    final active = _logoutOperation;
    if (active != null) {
      return active;
    }
    final currentState = state;
    if (_disposed || currentState is! AuthAuthenticated) {
      return Future<void>.value();
    }

    late final Future<void> operation;
    operation = _runSignOut(currentState).whenComplete(() {
      if (identical(_logoutOperation, operation)) {
        _logoutOperation = null;
      }
    });
    _logoutOperation = operation;
    return operation;
  }

  Future<void> _runSignOut(AuthAuthenticated authenticated) async {
    final generation = ++_generation;
    final exchange = _exchangeOperation;
    _oauthFlowActive = false;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = true;
    _pendingCallbacks.clear();
    _setState(AuthSigningOut(authenticated.customer));

    Object? firstCleanupError;

    Future<void> purge() async {
      try {
        await _repository?.signOutLocal();
      } on Object catch (error) {
        firstCleanupError ??= error;
      }
    }

    await purge();
    if (exchange != null) {
      try {
        await exchange;
      } on Object {
        // Anche un exchange fallito può avere prodotto side effect parziali.
      }
      await purge();
    }

    if (!_isCurrent(generation)) {
      return;
    }
    final notice = firstCleanupError == null
        ? null
        : _errorMapper!.map(firstCleanupError!);
    if (notice?.kind == AuthFailureKind.secureStorageUnavailable) {
      _setState(AuthConfigurationError(notice!));
      return;
    }
    _setState(AuthGuest(canAuthenticate: true, notice: notice));
  }

  Future<void> _initialize(AppConfig config) async {
    try {
      final source = ref.read(authCallbackSourceProvider);
      _callbackSubscription ??= source.callbacks.listen(
        _receiveCallback,
        onError: _receiveCallbackError,
      );

      final factory = ref.read(authRepositoryFactoryProvider);
      final repository = await factory(config);
      if (_disposed) {
        return;
      }

      _repository = repository;
      _sessionSubscription ??= repository.sessionChanges.listen(
        _receiveSessionEvent,
        onError: _receiveSessionError,
      );

      final restoredCustomer = repository.currentCustomer;
      if (restoredCustomer != null &&
          !_suppressSessionAuthentication &&
          state is! AuthSigningOut) {
        _setState(
          AuthAuthenticated(
            customer: restoredCustomer,
            origin: AuthSessionOrigin.restored,
          ),
        );
      }
      _scheduleCallbackDrain();
    } on Object catch (error) {
      if (_disposed) {
        return;
      }
      _initialization = null;
      _oauthFlowActive = false;
      _publishMappedFailure(error);
    }
  }

  void _receiveCallback(Uri callback) {
    if (_disposed || _ignoreCallbacksUntilNextLogin) {
      return;
    }
    if (_pendingCallbacks.length >= _maxPendingCallbacks) {
      _publishFailurePreservingAuthenticated(
        const AuthFailure(AuthFailureKind.invalidCallback),
      );
      return;
    }
    _pendingCallbacks.addLast(callback);
    _scheduleCallbackDrain();
  }

  void _receiveCallbackError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    if (_oauthFlowActive || state is AuthAuthenticating) {
      unawaited(
        _startFlowTermination(
          cancelled: false,
          failure: _errorMapper!.map(error),
        ),
      );
      return;
    }
    _publishMappedFailure(error);
  }

  void _scheduleCallbackDrain() {
    if (_repository == null || _callbackDrain != null || _disposed) {
      return;
    }
    late final Future<void> drain;
    drain = _drainCallbacks().whenComplete(() {
      if (identical(_callbackDrain, drain)) {
        _callbackDrain = null;
        if (_pendingCallbacks.isNotEmpty) {
          _scheduleCallbackDrain();
        }
      }
    });
    _callbackDrain = drain;
  }

  Future<void> _drainCallbacks() async {
    while (_pendingCallbacks.isNotEmpty && !_disposed) {
      final callback = _pendingCallbacks.removeFirst();
      await _handleCallback(callback);
    }
  }

  Future<void> _handleCallback(Uri callback) async {
    final validation = _validator!.validate(callback);
    switch (validation) {
      case AuthCallbackRejected(:final failure):
        _oauthFlowActive = false;
        _publishFailurePreservingAuthenticated(failure);
        return;
      case AuthCallbackProviderFailure(:final wasCancelled):
        if (_oauthFlowActive || state is AuthAuthenticating) {
          await _startFlowTermination(
            cancelled: wasCancelled,
            failure: wasCancelled
                ? null
                : const AuthFailure(AuthFailureKind.providerUnavailable),
          );
          return;
        }
        if (!_disposed && state is! AuthAuthenticated) {
          _setState(
            wasCancelled
                ? const AuthCancelled()
                : const AuthRecoverableError(
                    AuthFailure(AuthFailureKind.providerUnavailable),
                  ),
          );
        }
        return;
      case AuthCallbackAccepted(:final code):
        final fingerprint = _fingerprint(callback);
        if (!_rememberFingerprint(fingerprint)) {
          return;
        }
        if (state is AuthAuthenticated ||
            _ignoreCallbacksUntilNextLogin ||
            _suppressSessionAuthentication) {
          return;
        }
        final generation = ++_generation;
        _setState(const AuthAuthenticating());
        late final Future<AuthenticatedCustomer> exchange;
        exchange = _repository!.exchangeCodeForSession(code);
        _exchangeOperation = exchange;
        try {
          final customer = await exchange;
          if (_isCurrent(generation) &&
              !_ignoreCallbacksUntilNextLogin &&
              !_suppressSessionAuthentication) {
            _oauthFlowActive = false;
            _setState(
              AuthAuthenticated(
                customer: customer,
                origin: AuthSessionOrigin.callback,
              ),
            );
          }
        } on Object catch (error) {
          if (!_isCurrent(generation)) {
            return;
          }
          _oauthFlowActive = false;
          if (error is AuthStorageException) {
            await _failClosedStorage(error);
          } else {
            _publishMappedFailure(error);
          }
        } finally {
          if (identical(_exchangeOperation, exchange)) {
            _exchangeOperation = null;
          }
        }
    }
  }

  void _receiveSessionEvent(AuthSessionEvent event) {
    if (_disposed) {
      return;
    }
    final customer = event.customer;
    if (customer != null &&
        event.type != AuthSessionEventType.signedOut &&
        !_suppressSessionAuthentication &&
        state is! AuthSigningOut) {
      final origin = event.type == AuthSessionEventType.initialSession
          ? AuthSessionOrigin.restored
          : AuthSessionOrigin.stateChange;
      _setState(AuthAuthenticated(customer: customer, origin: origin));
      return;
    }

    if (event.type == AuthSessionEventType.signedOut) {
      _oauthFlowActive = false;
      if (state is AuthSigningOut ||
          state is AuthCancelling ||
          _suppressSessionAuthentication ||
          _flowTermination != null) {
        return;
      }
      final notice = event.signOutReason == AuthSignOutReason.sessionExpired
          ? const AuthFailure(AuthFailureKind.sessionExpired)
          : null;
      _setState(
        AuthGuest(
          canAuthenticate: _config?.googleAuthEnabled ?? false,
          notice: notice,
        ),
      );
    }
  }

  void _receiveSessionError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    if (error is AuthStorageException) {
      unawaited(_failClosedStorage(error));
      return;
    }
    if (state is AuthAuthenticated) {
      if (_repository?.currentCustomer != null) {
        return;
      }
      _suspendExpiredSession();
      return;
    }
    if (_oauthFlowActive || state is AuthAuthenticating) {
      unawaited(
        _startFlowTermination(
          cancelled: false,
          failure: _errorMapper!.map(error),
        ),
      );
      return;
    }
    _publishMappedFailure(error);
  }

  bool _rememberFingerprint(int fingerprint) {
    if (!_consumedFingerprints.add(fingerprint)) {
      return false;
    }
    _fingerprintOrder.addLast(fingerprint);
    if (_fingerprintOrder.length > _maxConsumedFingerprints) {
      _consumedFingerprints.remove(_fingerprintOrder.removeFirst());
    }
    return true;
  }

  static int _fingerprint(Uri callback) {
    var hash = 0xcbf29ce484222325;
    for (final rune in callback.toString().runes) {
      hash ^= rune;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return Object.hash(hash, callback.toString().length);
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  void _publishMappedFailure(Object error) {
    final failure = _errorMapper!.map(error);
    if (failure.kind == AuthFailureKind.configuration ||
        failure.kind == AuthFailureKind.secureStorageUnavailable) {
      _setState(AuthConfigurationError(failure));
    } else {
      _publishFailurePreservingAuthenticated(failure);
    }
  }

  void _publishFailurePreservingAuthenticated(AuthFailure failure) {
    if (state is! AuthAuthenticated) {
      _setState(AuthRecoverableError(failure));
    }
  }

  void _setState(AuthState nextState) {
    if (!_disposed) {
      state = nextState;
    }
  }

  void _dispose() {
    _disposed = true;
    ++_generation;
    _oauthFlowActive = false;
    _pendingCallbacks.clear();
    final exchange = _exchangeOperation;
    final repository = _repository;
    if (exchange != null && repository != null) {
      unawaited(_compensateDisposedExchange(exchange, repository));
    }
    unawaited(_callbackSubscription?.cancel());
    unawaited(_sessionSubscription?.cancel());
  }

  static Future<void> _compensateDisposedExchange(
    Future<AuthenticatedCustomer> exchange,
    AuthRepository repository,
  ) async {
    try {
      await exchange;
    } on Object {
      // Anche un exchange fallito può aver prodotto side effect parziali SDK.
    }
    try {
      await repository.signOutLocal();
    } on Object {
      // Nessun errore o dettaglio sensibile deve uscire dal dispose.
    }
  }
}
