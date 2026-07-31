import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_callback_validator.dart';
import '../data/auth_error_mapper.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
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

    try {
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

  Future<void> cancelGoogleSignIn() async {
    if (_disposed || (!_oauthFlowActive && state is! AuthAuthenticating)) {
      return;
    }

    ++_generation;
    _oauthFlowActive = false;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = true;
    _setState(const AuthCancelling());

    try {
      await _repository?.clearPendingOAuth();
      if (!_disposed) {
        _setState(const AuthCancelled());
      }
    } on Object catch (error) {
      if (!_disposed) {
        _publishMappedFailure(error);
      }
    }
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
    _oauthFlowActive = false;
    _ignoreCallbacksUntilNextLogin = true;
    _suppressSessionAuthentication = true;
    _pendingCallbacks.clear();
    _setState(AuthSigningOut(authenticated.customer));

    AuthFailure? notice;
    try {
      await _repository?.signOutLocal();
    } on Object catch (error) {
      notice = _errorMapper!.map(error);
    }

    if (!_isCurrent(generation)) {
      return;
    }
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
    if (!_disposed) {
      _publishMappedFailure(error);
    }
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
    final fingerprint = _fingerprint(callback);
    if (!_rememberFingerprint(fingerprint)) {
      return;
    }

    final validation = _validator!.validate(callback);
    switch (validation) {
      case AuthCallbackRejected(:final failure):
        _oauthFlowActive = false;
        _publishFailurePreservingAuthenticated(failure);
        return;
      case AuthCallbackProviderFailure(:final wasCancelled):
        _oauthFlowActive = false;
        try {
          await _repository?.clearPendingOAuth();
        } on Object catch (error) {
          _publishMappedFailure(error);
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
        if (state is AuthAuthenticated ||
            _ignoreCallbacksUntilNextLogin ||
            _suppressSessionAuthentication) {
          return;
        }
        final generation = ++_generation;
        _setState(const AuthAuthenticating());
        try {
          final customer = await _repository!.exchangeCodeForSession(code);
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
          try {
            await _repository?.clearPendingOAuth();
          } on Object {
            if (_isCurrent(generation)) {
              _setState(
                const AuthConfigurationError(
                  AuthFailure(AuthFailureKind.secureStorageUnavailable),
                ),
              );
            }
            return;
          }
          if (_isCurrent(generation)) {
            _oauthFlowActive = false;
            _publishMappedFailure(error);
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
      if (state is AuthSigningOut) {
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
    if (_disposed || state is AuthAuthenticated) {
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
    unawaited(_callbackSubscription?.cancel());
    unawaited(_sessionSubscription?.cancel());
  }
}
