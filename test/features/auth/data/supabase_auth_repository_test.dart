import 'dart:async';
import 'dart:convert';

import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/data/supabase_auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late _FakeSupabaseAuthPort port;
  late _MemorySecureStore secureStore;
  late SecureSupabaseAuthStorage storage;
  late SupabaseAuthRepository repository;

  setUp(() {
    port = _FakeSupabaseAuthPort();
    secureStore = _MemorySecureStore();
    storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MarkedInstall(),
    );
    repository = SupabaseAuthRepository(
      authPort: port,
      secureStorage: storage,
      redirectUri: AppConfig.allowedAuthRedirectUri,
    );
  });

  tearDown(() => port.dispose());

  test(
    'lancia soltanto Google con redirect canonico tramite il port',
    () async {
      port.launchResult = true;

      final launched = await repository.launchGoogleSignIn();

      expect(launched, isTrue);
      expect(port.launchCalls, 1);
      expect(port.redirects, [AppConfig.allowedAuthRedirectUri]);
    },
  );

  test('mappa identità corrente senza avatar o metadata autorizzativi', () {
    port.currentIdentity = const SupabaseIdentitySnapshot(
      subjectId: 'subject',
      email: 'customer@example.test',
      metadata: {
        'full_name': 'Customer',
        'avatar_url': 'https://untrusted.example/avatar.png',
        'role': 'admin',
        'shop_id': 'not-an-authorization',
      },
    );

    final customer = repository.currentCustomer;

    expect(customer?.subjectId, 'subject');
    expect(customer?.displayName, 'Customer');
    expect(customer?.email, 'customer@example.test');
    expect(customer.toString(), isNot(contains('avatar')));
    expect(customer.toString(), isNot(contains('admin')));
  });

  test(
    'exchange usa soltanto il code e richiede una sessione customer',
    () async {
      port.exchangeResult = const SupabaseAuthExchange(
        identity: SupabaseIdentitySnapshot(
          subjectId: 'subject',
          email: null,
          metadata: {'name': 'Safe Customer'},
        ),
        serializedSession: '{"session":"bounded"}',
      );

      final customer = await repository.exchangeCodeForSession('fake-code');

      expect(port.exchangedCodes, ['fake-code']);
      expect(customer.displayName, 'Safe Customer');
      expect(await storage.accessToken(), '{"session":"bounded"}');

      port.exchangeResult = const SupabaseAuthExchange(
        identity: null,
        serializedSession: '{"session":"missing-customer"}',
      );
      await expectLater(
        repository.exchangeCodeForSession('second-fake-code'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (error) => error.code,
            'code',
            'missing_customer_session',
          ),
        ),
      );
      expect(await storage.accessToken(), isNull);
    },
  );

  test(
    'traduce stream sessione, refresh e scadenza senza oggetti SDK',
    () async {
      final events = <AuthSessionEvent>[];
      final subscription = repository.sessionChanges.listen(events.add);
      const identity = SupabaseIdentitySnapshot(
        subjectId: 'subject',
        email: null,
        metadata: {},
      );

      port.emit(
        const SupabaseAuthChange(
          kind: SupabaseAuthChangeKind.initialSession,
          identity: identity,
        ),
      );
      port.emit(
        const SupabaseAuthChange(
          kind: SupabaseAuthChangeKind.tokenRefreshed,
          identity: identity,
        ),
      );
      port.emit(
        const SupabaseAuthChange(
          kind: SupabaseAuthChangeKind.signedOut,
          identity: null,
          signOutKind: SupabaseSignOutKind.sessionExpired,
          shouldRemovePersistedSession: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.map((event) => event.type), [
        AuthSessionEventType.initialSession,
        AuthSessionEventType.tokenRefreshed,
        AuthSessionEventType.signedOut,
      ]);
      expect(events.last.signOutReason, AuthSignOutReason.sessionExpired);
      await subscription.cancel();
    },
  );

  test(
    'logout pulisce sessione e verifier anche se il remoto fallisce',
    () async {
      const sentinel = 'REMOTE_ERROR_WITH_SECRET_SENTINEL';
      await storage.persistSession('local-session');
      await storage.setItem(
        key: SecureSupabaseAuthStorage.sdkPkceStorageKey,
        value: 'local-verifier',
      );
      port.signOutError = StateError(sentinel);

      Object? captured;
      try {
        await repository.signOutLocal();
      } on Object catch (error) {
        captured = error;
      }

      expect(captured, isA<StateError>());
      expect(await storage.hasAccessToken(), isFalse);
      expect(
        await storage.getItem(key: SecureSupabaseAuthStorage.sdkPkceStorageKey),
        isNull,
      );
      expect(port.signOutCalls, 1);
    },
  );

  test('exchange fallisce chiuso se la sessione non è persistibile', () async {
    port.exchangeResult = const SupabaseAuthExchange(
      identity: SupabaseIdentitySnapshot(
        subjectId: 'subject',
        email: null,
        metadata: {},
      ),
      serializedSession: '{"session":"must-not-leak"}',
    );
    secureStore.writeError = StateError('private driver detail');

    await expectLater(
      repository.exchangeCodeForSession('storage-failure-code'),
      throwsA(isA<AuthStorageException>()),
    );

    expect(port.signOutCalls, 1);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('failure di persistenza refresh raggiunge il boundary Auth', () async {
    secureStore.writeError = StateError('private refresh detail');
    final streamError = Completer<Object>();
    final subscription = repository.sessionChanges.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (!streamError.isCompleted) {
          streamError.complete(error);
        }
      },
    );

    port.emit(
      const SupabaseAuthChange(
        kind: SupabaseAuthChangeKind.tokenRefreshed,
        identity: SupabaseIdentitySnapshot(
          subjectId: 'subject',
          email: null,
          metadata: {},
        ),
        serializedSession: '{"session":"rotated"}',
      ),
    );

    expect(await streamError.future, isA<AuthStorageException>());
    await subscription.cancel();
  });

  test(
    'expiry sintetica non elimina il refresh token prima del retry SDK',
    () async {
      await storage.persistSession('expired-session-with-refresh-token');
      final eventReady = Completer<AuthSessionEvent>();
      final subscription = repository.sessionChanges.listen((event) {
        if (!eventReady.isCompleted) {
          eventReady.complete(event);
        }
      });

      port.emit(
        const SupabaseAuthChange(
          kind: SupabaseAuthChangeKind.signedOut,
          identity: null,
          signOutKind: SupabaseSignOutKind.sessionExpired,
          shouldRemovePersistedSession: false,
        ),
      );

      final event = await eventReady.future;
      expect(event.signOutReason, AuthSignOutReason.sessionExpired);
      expect(await storage.accessToken(), 'expired-session-with-refresh-token');
      await subscription.cancel();
    },
  );

  test(
    'logout tenta verifier anche quando il delete sessione fallisce',
    () async {
      await storage.persistSession('local-session');
      await storage.setItem(
        key: SecureSupabaseAuthStorage.sdkPkceStorageKey,
        value: 'local-verifier',
      );
      secureStore.deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
          StateError('private session delete detail');

      await expectLater(
        repository.signOutLocal(),
        throwsA(isA<AuthStorageException>()),
      );

      expect(
        secureStore.deleted,
        containsAll([
          SecureSupabaseAuthStorage.sessionStorageKey,
          SecureSupabaseAuthStorage.pkceStorageKey,
        ]),
      );
      expect(
        secureStore.values[SecureSupabaseAuthStorage.pkceStorageKey],
        isNull,
      );
    },
  );

  test('sessioni scadute o senza expiry non espongono identità', () {
    final expired = _session(expiresAt: 1, refreshToken: 'refreshable');
    final valid = _session(
      expiresAt:
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    );
    final missingExpiry = Session(
      accessToken: 'not-a-jwt',
      tokenType: 'bearer',
      user: _sdkUser(),
    );

    expect(PlatformSupabaseAuthPort.identityFromSession(expired), isNull);
    expect(PlatformSupabaseAuthPort.identityFromSession(missingExpiry), isNull);
    expect(
      PlatformSupabaseAuthPort.shouldPreserveForSdkRecovery(expired),
      isTrue,
    );
    expect(
      PlatformSupabaseAuthPort.shouldPreserveForSdkRecovery(missingExpiry),
      isFalse,
    );
    expect(
      PlatformSupabaseAuthPort.shouldPreserveForSdkRecovery(
        _session(expiresAt: 1),
      ),
      isFalse,
    );
    expect(
      PlatformSupabaseAuthPort.identityFromSession(valid)?.subjectId,
      'sdk-subject',
    );
  });

  test('mapping SDK preserva solo sessione scaduta realmente refreshable', () {
    final refreshableExpired = _session(
      expiresAt: 1,
      refreshToken: 'refreshable',
    );
    final missingExpiry = Session(
      accessToken: 'not-a-jwt',
      tokenType: 'bearer',
      refreshToken: 'must-not-loop',
      user: _sdkUser(),
    );

    final refreshableChange = PlatformSupabaseAuthPort.mapSdkAuthChange(
      AuthState(AuthChangeEvent.initialSession, refreshableExpired),
    );
    final malformedChange = PlatformSupabaseAuthPort.mapSdkAuthChange(
      AuthState(AuthChangeEvent.initialSession, missingExpiry),
    );
    final terminatedChange = PlatformSupabaseAuthPort.mapSdkAuthChange(
      AuthState(
        AuthChangeEvent.signedOut,
        refreshableExpired,
        signOutReason: SignOutReason.sessionExpired,
      ),
    );

    expect(refreshableChange.kind, SupabaseAuthChangeKind.signedOut);
    expect(refreshableChange.shouldRemovePersistedSession, isFalse);
    expect(malformedChange.shouldRemovePersistedSession, isTrue);
    expect(terminatedChange.shouldRemovePersistedSession, isTrue);
  });
}

Session _session({required int expiresAt, String? refreshToken}) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"none"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"exp":$expiresAt}'))
      .replaceAll('=', '');
  return Session(
    accessToken: '$header.$payload.signature',
    tokenType: 'bearer',
    refreshToken: refreshToken,
    user: _sdkUser(),
  );
}

User _sdkUser() {
  return const User(
    id: 'sdk-subject',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

final class _FakeSupabaseAuthPort implements SupabaseAuthPort {
  final StreamController<SupabaseAuthChange> _changes =
      StreamController<SupabaseAuthChange>.broadcast();

  @override
  SupabaseIdentitySnapshot? currentIdentity;
  SupabaseAuthExchange exchangeResult = const SupabaseAuthExchange(
    identity: null,
    serializedSession: '{"session":"fake"}',
  );
  bool launchResult = false;
  Object? launchError;
  Object? exchangeError;
  Object? signOutError;
  int launchCalls = 0;
  int signOutCalls = 0;
  final List<String> redirects = [];
  final List<String> exchangedCodes = [];

  @override
  Stream<SupabaseAuthChange> get changes => _changes.stream;

  @override
  Future<bool> launchGoogleOAuth(String redirectUri) async {
    launchCalls++;
    redirects.add(redirectUri);
    if (launchError case final error?) {
      throw error;
    }
    return launchResult;
  }

  @override
  Future<SupabaseAuthExchange> exchangeCode(String code) async {
    exchangedCodes.add(code);
    if (exchangeError case final error?) {
      throw error;
    }
    return exchangeResult;
  }

  @override
  Future<void> signOutLocal() async {
    signOutCalls++;
    if (signOutError case final error?) {
      throw error;
    }
  }

  void emit(SupabaseAuthChange change) => _changes.add(change);

  Future<void> dispose() => _changes.close();
}

final class _MemorySecureStore implements SecureAuthKeyValueStore {
  final Map<String, String> values = {};
  final List<String> deleted = [];
  final Map<String, Object> deleteErrors = {};
  Object? writeError;

  @override
  Future<void> delete(String key) async {
    deleted.add(key);
    if (deleteErrors[key] case final error?) {
      throw error;
    }
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (writeError case final error?) {
      throw error;
    }
    values[key] = value;
  }
}

final class _MarkedInstall implements AuthInstallationMarkerStore {
  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {}

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async => false;

  @override
  Future<bool> isCurrentInstallMarked() async => true;

  @override
  Future<void> markCurrentInstall() async {}

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {}
}
