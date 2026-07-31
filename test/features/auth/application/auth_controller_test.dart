import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_failure.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository repository;
  late _FakeCallbackSource callbackSource;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeAuthRepository();
    callbackSource = _FakeCallbackSource();
    container = _container(repository, callbackSource);
  });

  tearDown(() async {
    container.dispose();
    await callbackSource.dispose();
    await repository.dispose();
  });

  test('development resta guest e non inizializza Auth remoto', () async {
    var factoryCalls = 0;
    final developmentContainer = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromValues()),
        authRepositoryFactoryProvider.overrideWithValue((config) async {
          factoryCalls++;
          return repository;
        }),
        authCallbackSourceProvider.overrideWithValue(callbackSource),
      ],
    );
    addTearDown(developmentContainer.dispose);

    final state = developmentContainer.read(authControllerProvider);
    await _settle();

    expect(state, isA<AuthGuest>());
    expect((state as AuthGuest).canAuthenticate, isFalse);
    expect(factoryCalls, 0);
    expect(callbackSource.hasListener, isFalse);
  });

  test('restore iniziale autentica senza origine callback', () async {
    repository.currentCustomer = _customer('restored');

    container.read(authControllerProvider);
    await _settle();

    expect(
      container.read(authControllerProvider),
      isA<AuthAuthenticated>()
          .having((state) => state.customer.subjectId, 'subject', 'restored')
          .having(
            (state) => state.origin,
            'origin',
            AuthSessionOrigin.restored,
          ),
    );
  });

  test(
    'doppio tap condivide un solo launch e callback autentica una volta',
    () async {
      final launch = Completer<bool>();
      repository.launchCompleter = launch;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);

      final first = controller.startGoogleSignIn();
      final second = controller.startGoogleSignIn();
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(repository.launchCalls, 1);

      launch.complete(true);
      await first;
      expect(container.read(authControllerProvider), isA<AuthAuthenticating>());

      callbackSource.emit(_validCallback('single-code'));
      callbackSource.emit(_validCallback('single-code'));
      await _settle();

      expect(repository.exchangeCalls, 1);
      expect(repository.exchangedCodes, ['single-code']);
      expect(
        container.read(authControllerProvider),
        isA<AuthAuthenticated>().having(
          (state) => state.origin,
          'origin',
          AuthSessionOrigin.callback,
        ),
      );
    },
  );

  test('cold callback resta queued finché il repository è pronto', () async {
    final repositoryReady = Completer<AuthRepository>();
    container.dispose();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_enabledConfig()),
        authRepositoryFactoryProvider.overrideWithValue(
          (config) => repositoryReady.future,
        ),
        authCallbackSourceProvider.overrideWithValue(callbackSource),
      ],
    );

    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    callbackSource.emit(_validCallback('cold-code'));
    await Future<void>.delayed(Duration.zero);
    expect(repository.exchangeCalls, 0);

    repositoryReady.complete(repository);
    await _settle();

    expect(repository.exchangedCodes, ['cold-code']);
    expect(
      container.read(authControllerProvider),
      isA<AuthAuthenticated>().having(
        (state) => state.origin,
        'origin',
        AuthSessionOrigin.callback,
      ),
    );
  });

  test('callback invalido non invoca repository e non causa crash', () async {
    container.read(authControllerProvider);
    await _settle();

    callbackSource.emit(
      Uri.parse('evil.scheme://auth-callback/?code=should-not-be-exchanged'),
    );
    await _settle();

    expect(repository.exchangeCalls, 0);
    expect(repository.clearPendingCalls, 0);
    expect(
      container.read(authControllerProvider),
      isA<AuthRecoverableError>().having(
        (state) => state.failure.kind,
        'failure',
        AuthFailureKind.invalidCallback,
      ),
    );
  });

  test('cancellazione pulisce verifier e ignora callback tardivo', () async {
    container.read(authControllerProvider);
    await _settle();
    final controller = container.read(authControllerProvider.notifier);

    await controller.startGoogleSignIn();
    await controller.cancelGoogleSignIn();
    callbackSource.emit(_validCallback('late-code'));
    await _settle();

    expect(repository.clearPendingCalls, 1);
    expect(repository.exchangeCalls, 0);
    expect(container.read(authControllerProvider), isA<AuthCancelled>());
  });

  test('errore provider cancellato non effettua exchange', () async {
    container.read(authControllerProvider);
    await _settle();
    await container.read(authControllerProvider.notifier).startGoogleSignIn();

    callbackSource.emit(
      Uri.parse('${AppConfig.allowedAuthRedirectUri}?error=access_denied'),
    );
    await _settle();

    expect(repository.exchangeCalls, 0);
    expect(repository.clearPendingCalls, 1);
    expect(container.read(authControllerProvider), isA<AuthCancelled>());
  });

  test(
    'browser non lanciato produce errore recuperabile e consente retry',
    () async {
      repository.launchResult = false;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);

      await controller.startGoogleSignIn();

      expect(
        container.read(authControllerProvider),
        isA<AuthRecoverableError>().having(
          (state) => state.failure.kind,
          'failure',
          AuthFailureKind.browserLaunchFailed,
        ),
      );

      repository.launchResult = true;
      await controller.retry();
      expect(repository.launchCalls, 2);
      expect(container.read(authControllerProvider), isA<AuthAuthenticating>());
    },
  );

  test(
    'session expiry rimuove authenticated e offre recovery sicura',
    () async {
      repository.currentCustomer = _customer('session');
      container.read(authControllerProvider);
      await _settle();

      repository.emit(
        const AuthSessionEvent(
          type: AuthSessionEventType.signedOut,
          customer: null,
          signOutReason: AuthSignOutReason.sessionExpired,
        ),
      );
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthGuest>()
            .having(
              (state) => state.notice?.kind,
              'notice',
              AuthFailureKind.sessionExpired,
            )
            .having(
              (state) => state.canAuthenticate,
              'canAuthenticate',
              isTrue,
            ),
      );
    },
  );

  test('logout offline resta guest e non ripristina la sessione', () async {
    repository.currentCustomer = _customer('logout');
    repository.signOutError = const SocketException('private network detail');
    container.read(authControllerProvider);
    await _settle();
    final controller = container.read(authControllerProvider.notifier);

    await controller.signOut();

    expect(repository.signOutCalls, 1);
    expect(
      container.read(authControllerProvider),
      isA<AuthGuest>().having(
        (state) => state.notice?.kind,
        'notice',
        AuthFailureKind.offline,
      ),
    );

    repository.emit(
      AuthSessionEvent(
        type: AuthSessionEventType.signedIn,
        customer: _customer('late'),
      ),
    );
    await _settle();
    expect(container.read(authControllerProvider), isA<AuthGuest>());
  });

  test(
    'logout prevale su exchange tardivo e completamento fuori ordine',
    () async {
      final exchange = Completer<AuthenticatedCustomer>();
      repository.exchangeCompleter = exchange;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      await controller.startGoogleSignIn();

      callbackSource.emit(_validCallback('pending-code'));
      await Future<void>.delayed(Duration.zero);
      repository.emit(
        AuthSessionEvent(
          type: AuthSessionEventType.signedIn,
          customer: _customer('stream-session'),
        ),
      );
      await _settle();
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      await controller.signOut();
      exchange.complete(_customer('late-exchange'));
      await _settle();

      expect(container.read(authControllerProvider), isA<AuthGuest>());
    },
  );

  test('dispose chiude subscription e ignora future tardive', () async {
    final exchange = Completer<AuthenticatedCustomer>();
    repository.exchangeCompleter = exchange;
    container.read(authControllerProvider);
    await _settle();
    await container.read(authControllerProvider.notifier).startGoogleSignIn();
    callbackSource.emit(_validCallback('dispose-code'));
    await Future<void>.delayed(Duration.zero);

    container.dispose();
    exchange.complete(_customer('late'));
    await _settle();

    expect(callbackSource.hasListener, isFalse);
    expect(repository.hasSessionListener, isFalse);
  });

  test('errore inizializzazione storage diventa configurationError', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_enabledConfig()),
        authRepositoryFactoryProvider.overrideWithValue((config) async {
          throw const AuthStorageException(
            'secure_storage_initialization_failed',
          );
        }),
        authCallbackSourceProvider.overrideWithValue(callbackSource),
      ],
    );

    container.read(authControllerProvider);
    await _settle();

    expect(
      container.read(authControllerProvider),
      isA<AuthConfigurationError>().having(
        (state) => state.failure.kind,
        'failure',
        AuthFailureKind.secureStorageUnavailable,
      ),
    );
  });
}

ProviderContainer _container(
  _FakeAuthRepository repository,
  _FakeCallbackSource source,
) {
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_enabledConfig()),
      authRepositoryFactoryProvider.overrideWithValue(
        (config) async => repository,
      ),
      authCallbackSourceProvider.overrideWithValue(source),
    ],
  );
}

AppConfig _enabledConfig() {
  return AppConfig.fromValues(
    appEnvironment: 'staging',
    supabaseUrl: 'https://project.example.invalid',
    supabasePublishableKey: 'sb_publishable_test_key',
    authRedirectUri: AppConfig.allowedAuthRedirectUri,
    googleAuthEnabled: 'true',
  );
}

AuthenticatedCustomer _customer(String subject) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: subject,
    email: null,
    metadata: const {'name': 'Customer'},
  );
}

Uri _validCallback(String code) {
  return Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=$code');
}

Future<void> _settle() async {
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _FakeCallbackSource implements AuthCallbackSource {
  final StreamController<Uri> _callbacks = StreamController<Uri>.broadcast();

  bool get hasListener => _callbacks.hasListener;

  @override
  Stream<Uri> get callbacks => _callbacks.stream;

  void emit(Uri callback) => _callbacks.add(callback);

  @override
  Future<void> dispose() async {
    if (!_callbacks.isClosed) {
      await _callbacks.close();
    }
  }
}

final class _FakeAuthRepository implements AuthRepository {
  final StreamController<AuthSessionEvent> _events =
      StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer;
  bool launchResult = true;
  Completer<bool>? launchCompleter;
  Completer<AuthenticatedCustomer>? exchangeCompleter;
  Object? launchError;
  Object? exchangeError;
  Object? clearPendingError;
  Object? signOutError;

  int launchCalls = 0;
  int exchangeCalls = 0;
  int clearPendingCalls = 0;
  int signOutCalls = 0;
  final List<String> exchangedCodes = [];

  bool get hasSessionListener => _events.hasListener;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  @override
  Future<bool> launchGoogleSignIn() async {
    launchCalls++;
    if (launchError case final error?) {
      throw error;
    }
    final completer = launchCompleter;
    return completer == null ? launchResult : completer.future;
  }

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    exchangeCalls++;
    exchangedCodes.add(code);
    if (exchangeError case final error?) {
      throw error;
    }
    final completer = exchangeCompleter;
    return completer == null
        ? _customer('callback-customer')
        : completer.future;
  }

  @override
  Future<void> clearPendingOAuth() async {
    clearPendingCalls++;
    if (clearPendingError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> signOutLocal() async {
    signOutCalls++;
    if (signOutError case final error?) {
      throw error;
    }
  }

  void emit(AuthSessionEvent event) => _events.add(event);

  Future<void> dispose() async {
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
