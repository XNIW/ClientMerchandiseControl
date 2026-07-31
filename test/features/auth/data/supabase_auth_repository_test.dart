import 'dart:async';

import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/data/supabase_auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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
      port.exchangeIdentity = const SupabaseIdentitySnapshot(
        subjectId: 'subject',
        email: null,
        metadata: {'name': 'Safe Customer'},
      );

      final customer = await repository.exchangeCodeForSession('fake-code');

      expect(port.exchangedCodes, ['fake-code']);
      expect(customer.displayName, 'Safe Customer');

      port.exchangeIdentity = null;
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
}

final class _FakeSupabaseAuthPort implements SupabaseAuthPort {
  final StreamController<SupabaseAuthChange> _changes =
      StreamController<SupabaseAuthChange>.broadcast();

  @override
  SupabaseIdentitySnapshot? currentIdentity;
  SupabaseIdentitySnapshot? exchangeIdentity;
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
  Future<SupabaseIdentitySnapshot?> exchangeCode(String code) async {
    exchangedCodes.add(code);
    if (exchangeError case final error?) {
      throw error;
    }
    return exchangeIdentity;
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

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

final class _MarkedInstall implements AuthInstallationMarkerStore {
  @override
  Future<bool> isCurrentInstallMarked() async => true;

  @override
  Future<void> markCurrentInstall() async {}
}
