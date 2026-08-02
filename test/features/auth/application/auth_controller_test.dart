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

  test(
    'errore provider cancellato termina il flow e ignora callback tardivo',
    () async {
      container.read(authControllerProvider);
      await _settle();
      await container.read(authControllerProvider.notifier).startGoogleSignIn();

      callbackSource.emit(
        Uri.parse('${AppConfig.allowedAuthRedirectUri}?error=access_denied'),
      );
      await _settle();
      callbackSource.emit(_validCallback('late-after-provider-cancel'));
      await _settle();

      expect(repository.exchangeCalls, 0);
      expect(repository.clearPendingCalls, 1);
      expect(repository.signOutCalls, 1);
      expect(container.read(authControllerProvider), isA<AuthCancelled>());
    },
  );

  test(
    'callback provider cancellato identico termina anche il flow di retry',
    () async {
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      final callback = Uri.parse(
        '${AppConfig.allowedAuthRedirectUri}?error=access_denied',
      );

      await controller.startGoogleSignIn();
      callbackSource.emit(callback);
      await _settle();
      expect(container.read(authControllerProvider), isA<AuthCancelled>());

      await controller.retry();
      callbackSource.emit(callback);
      await _settle();

      expect(repository.launchCalls, 2);
      expect(repository.signOutCalls, 2);
      expect(container.read(authControllerProvider), isA<AuthCancelled>());
    },
  );

  test(
    'callback provider fallito identico termina anche il flow di retry',
    () async {
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      final callback = Uri.parse(
        '${AppConfig.allowedAuthRedirectUri}?error=server_error',
      );

      await controller.startGoogleSignIn();
      callbackSource.emit(callback);
      await _settle();
      expect(
        container.read(authControllerProvider),
        isA<AuthRecoverableError>(),
      );

      await controller.retry();
      callbackSource.emit(callback);
      await _settle();

      expect(repository.launchCalls, 2);
      expect(repository.signOutCalls, 2);
      expect(
        container.read(authControllerProvider),
        isA<AuthRecoverableError>().having(
          (state) => state.failure.kind,
          'failure',
          AuthFailureKind.providerUnavailable,
        ),
      );
    },
  );

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
    'logout attende cleanup autenticato prima di eliminare la sessione',
    () async {
      final cleanup = Completer<void>();
      final cleanupCustomers = <AuthenticatedCustomer>[];
      repository.currentCustomer = _customer('logout-cleanup');
      container.dispose();
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(_enabledConfig()),
          authRepositoryFactoryProvider.overrideWithValue(
            (config) async => repository,
          ),
          authCallbackSourceProvider.overrideWithValue(callbackSource),
          authenticatedSignOutCleanupProvider.overrideWithValue((customer) {
            cleanupCustomers.add(customer);
            return cleanup.future;
          }),
        ],
      );
      container.read(authControllerProvider);
      await _settle();

      final logout = container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider), isA<AuthSigningOut>());
      expect(cleanupCustomers.single.subjectId, 'logout-cleanup');
      expect(repository.signOutCalls, 0);

      cleanup.complete();
      await logout;
      expect(repository.signOutCalls, 1);
      expect(container.read(authControllerProvider), isA<AuthGuest>());
    },
  );

  test('failure cleanup feature-specific non trattiene il logout', () async {
    repository.currentCustomer = _customer('logout-cleanup-failure');
    container.dispose();
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_enabledConfig()),
        authRepositoryFactoryProvider.overrideWithValue(
          (config) async => repository,
        ),
        authCallbackSourceProvider.overrideWithValue(callbackSource),
        authenticatedSignOutCleanupProvider.overrideWithValue((customer) {
          throw StateError('private-device-cleanup-detail');
        }),
      ],
    );
    container.read(authControllerProvider);
    await _settle();

    await expectLater(
      container.read(authControllerProvider.notifier).signOut(),
      completes,
    );

    expect(repository.signOutCalls, 1);
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

      repository.exchangeCreatesSession = true;
      final logout = controller.signOut();
      expect(container.read(authControllerProvider), isA<AuthSigningOut>());
      exchange.complete(_customer('late-exchange'));
      await logout;
      await _settle();

      expect(repository.signOutCalls, 2);
      expect(repository.currentCustomer, isNull);
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

  test(
    'cancel attende exchange, compensa la sessione e blocca retry prematuro',
    () async {
      final exchange = Completer<AuthenticatedCustomer>();
      repository.exchangeCompleter = exchange;
      repository.exchangeCreatesSession = true;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      await controller.startGoogleSignIn();
      callbackSource.emit(_validCallback('cancel-in-flight'));
      await Future<void>.delayed(Duration.zero);

      final cancellation = controller.cancelGoogleSignIn();
      final prematureRetry = controller.retry();
      expect(container.read(authControllerProvider), isA<AuthCancelling>());
      expect(repository.launchCalls, 1);

      exchange.complete(_customer('stale-session'));
      await cancellation;
      await prematureRetry;
      await _settle();

      expect(repository.signOutCalls, 1);
      expect(repository.currentCustomer, isNull);
      expect(container.read(authControllerProvider), isA<AuthCancelled>());

      await controller.retry();
      expect(repository.launchCalls, 2);
    },
  );

  test(
    'cancel non sovrascrive configurationError emesso durante exchange',
    () async {
      final exchange = Completer<AuthenticatedCustomer>();
      repository.exchangeCompleter = exchange;
      repository.exchangeCreatesSession = true;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      await controller.startGoogleSignIn();
      callbackSource.emit(_validCallback('cancel-storage-failure'));
      await Future<void>.delayed(Duration.zero);

      final cancellation = controller.cancelGoogleSignIn();
      repository.emitError(
        const AuthStorageException('secure_storage_write_failed'),
      );
      await _settle();
      exchange.complete(_customer('must-be-purged'));
      await cancellation;
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthConfigurationError>().having(
          (state) => state.failure.kind,
          'failure',
          AuthFailureKind.secureStorageUnavailable,
        ),
      );
      expect(repository.currentCustomer, isNull);
    },
  );

  test('restore valido termina il login senza aprire il browser', () async {
    final repositoryReady = Completer<AuthRepository>();
    repository.currentCustomer = _customer('restored-before-launch');
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
    final controller = container.read(authControllerProvider.notifier);

    final login = controller.startGoogleSignIn();
    await Future<void>.delayed(Duration.zero);
    repositoryReady.complete(repository);
    await login;
    await _settle();

    expect(repository.launchCalls, 0);
    expect(
      container.read(authControllerProvider),
      isA<AuthAuthenticated>().having(
        (state) => state.origin,
        'origin',
        AuthSessionOrigin.restored,
      ),
    );
  });

  test(
    'restore apparso dopo initialization non lascia UI authenticating',
    () async {
      final restored = _customer('restored-after-initial-read');
      repository.currentCustomerOnRead = (read) => read == 1 ? null : restored;
      container.read(authControllerProvider);
      final controller = container.read(authControllerProvider.notifier);

      await controller.startGoogleSignIn();
      await _settle();

      expect(repository.launchCalls, 0);
      expect(
        container.read(authControllerProvider),
        isA<AuthAuthenticated>()
            .having(
              (state) => state.origin,
              'origin',
              AuthSessionOrigin.restored,
            )
            .having(
              (state) => state.customer.subjectId,
              'customer',
              restored.subjectId,
            ),
      );
    },
  );

  test(
    'restore durante cleanup pre-login impedisce il launch browser',
    () async {
      final cleanup = Completer<void>();
      repository.clearPendingCompleter = cleanup;
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);

      final login = controller.startGoogleSignIn();
      await Future<void>.delayed(Duration.zero);
      final restored = _customer('restored-during-cleanup');
      repository.currentCustomer = restored;
      repository.emit(
        AuthSessionEvent(
          type: AuthSessionEventType.tokenRefreshed,
          customer: restored,
        ),
      );
      await _settle();
      cleanup.complete();
      await login;
      await _settle();

      expect(repository.launchCalls, 0);
      expect(
        container.read(authControllerProvider),
        isA<AuthAuthenticated>().having(
          (state) => state.customer.subjectId,
          'customer',
          restored.subjectId,
        ),
      );
    },
  );

  test('cancel prima della factory attende e pulisce lo stato Auth', () async {
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
    final controller = container.read(authControllerProvider.notifier);

    final login = controller.startGoogleSignIn();
    await Future<void>.delayed(Duration.zero);
    final cancellation = controller.cancelGoogleSignIn();
    repositoryReady.complete(repository);
    await Future.wait([login, cancellation]);
    await _settle();

    expect(repository.launchCalls, 0);
    expect(repository.signOutCalls, 1);
    expect(container.read(authControllerProvider), isA<AuthCancelled>());
  });

  test(
    'errore callback durante OAuth termina il flow e Retry rilancia',
    () async {
      container.read(authControllerProvider);
      await _settle();
      final controller = container.read(authControllerProvider.notifier);
      await controller.startGoogleSignIn();

      callbackSource.emitError(
        const SocketException('private callback detail'),
      );
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthRecoverableError>(),
      );
      await controller.retry();
      expect(repository.launchCalls, 2);
    },
  );

  test(
    'refresh retryable scaduto degrada a guest e consente recovery SDK',
    () async {
      repository.currentCustomer = _customer('expires-offline');
      container.read(authControllerProvider);
      await _settle();
      repository.currentCustomer = null;

      repository.emitError(const SocketException('private refresh detail'));
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthGuest>().having(
          (state) => state.notice?.kind,
          'notice',
          AuthFailureKind.sessionExpired,
        ),
      );
      expect(repository.signOutCalls, 0);

      final refreshed = _customer('refreshed-after-offline');
      repository.currentCustomer = refreshed;
      repository.emit(
        AuthSessionEvent(
          type: AuthSessionEventType.tokenRefreshed,
          customer: refreshed,
        ),
      );
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthAuthenticated>().having(
          (state) => state.customer.subjectId,
          'customer',
          refreshed.subjectId,
        ),
      );
    },
  );

  test(
    'failure storage post-auth produce configurationError e purge',
    () async {
      repository.currentCustomer = _customer('storage-failure');
      container.read(authControllerProvider);
      await _settle();

      repository.emitError(
        const AuthStorageException('secure_storage_write_failed'),
      );
      await _settle();

      expect(
        container.read(authControllerProvider),
        isA<AuthConfigurationError>().having(
          (state) => state.failure.kind,
          'failure',
          AuthFailureKind.secureStorageUnavailable,
        ),
      );
      expect(repository.signOutCalls, 1);
      expect(repository.currentCustomer, isNull);
    },
  );

  test('callback vecchio non elimina il verifier del flow nuovo', () async {
    container.read(authControllerProvider);
    await _settle();
    final controller = container.read(authControllerProvider.notifier);
    await controller.startGoogleSignIn();
    await controller.cancelGoogleSignIn();
    await controller.retry();
    expect(repository.clearPendingCalls, 2);

    repository.exchangeError = StateError('old callback rejected');
    callbackSource.emit(_validCallback('old-code'));
    await _settle();
    expect(repository.clearPendingCalls, 2);
    expect(container.read(authControllerProvider), isA<AuthRecoverableError>());

    repository.exchangeError = null;
    callbackSource.emit(_validCallback('new-code'));
    await _settle();
    expect(repository.clearPendingCalls, 2);
    expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
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
    storefrontShopSlug: 'storefront-test',
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

  void emitError(Object error) => _callbacks.addError(error);

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

  AuthenticatedCustomer? _currentCustomer;
  int _currentCustomerReads = 0;
  AuthenticatedCustomer? Function(int read)? currentCustomerOnRead;

  @override
  AuthenticatedCustomer? get currentCustomer {
    _currentCustomerReads++;
    return currentCustomerOnRead?.call(_currentCustomerReads) ??
        _currentCustomer;
  }

  set currentCustomer(AuthenticatedCustomer? customer) {
    _currentCustomer = customer;
  }

  bool launchResult = true;
  Completer<bool>? launchCompleter;
  Completer<AuthenticatedCustomer>? exchangeCompleter;
  Completer<void>? clearPendingCompleter;
  Object? launchError;
  Object? exchangeError;
  Object? clearPendingError;
  Object? signOutError;
  bool exchangeCreatesSession = false;

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
    final customer = completer == null
        ? _customer('callback-customer')
        : await completer.future;
    if (exchangeCreatesSession) {
      currentCustomer = customer;
      emit(
        AuthSessionEvent(
          type: AuthSessionEventType.signedIn,
          customer: customer,
        ),
      );
    }
    return customer;
  }

  @override
  Future<void> clearPendingOAuth() async {
    clearPendingCalls++;
    if (clearPendingError case final error?) {
      throw error;
    }
    await clearPendingCompleter?.future;
  }

  @override
  Future<void> signOutLocal() async {
    signOutCalls++;
    currentCustomer = null;
    emit(
      const AuthSessionEvent(
        type: AuthSessionEventType.signedOut,
        customer: null,
        signOutReason: AuthSignOutReason.userInitiated,
      ),
    );
    if (signOutError case final error?) {
      throw error;
    }
  }

  void emit(AuthSessionEvent event) => _events.add(event);

  void emitError(Object error) => _events.addError(error);

  Future<void> dispose() async {
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
