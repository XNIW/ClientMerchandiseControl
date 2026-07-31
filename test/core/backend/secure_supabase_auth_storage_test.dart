import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'primo avvio cancella soltanto sessione e PKCE e marca installazione',
    () async {
      final secureStore = _MemorySecureStore({
        SecureSupabaseAuthStorage.sessionStorageKey: 'old-session',
        SecureSupabaseAuthStorage.pkceStorageKey: 'old-verifier',
        'unrelated': 'preserve-me',
      });
      final marker = _MemoryMarkerStore();
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );

      await storage.initialize();
      await storage.initialize();

      expect(secureStore.deleted, [
        SecureSupabaseAuthStorage.sessionStorageKey,
        SecureSupabaseAuthStorage.pkceStorageKey,
        SecureSupabaseAuthStorage.sessionCleanupMarkerStorageKey,
        SecureSupabaseAuthStorage.pkceCleanupMarkerStorageKey,
      ]);
      expect(secureStore.values['unrelated'], 'preserve-me');
      expect(marker.marked, isTrue);
      expect(marker.readCalls, 1);
      expect(marker.markCalls, 1);
    },
  );

  test('installazione già marcata preserva la sessione sicura', () async {
    final secureStore = _MemorySecureStore({
      SecureSupabaseAuthStorage.sessionStorageKey: 'persisted-session',
    });
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );

    await storage.initialize();

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'persisted-session');
    expect(secureStore.deleted, isEmpty);
  });

  test('sessione e verifier usano chiavi distinte con CRUD completo', () async {
    final secureStore = _MemorySecureStore();
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );

    await storage.persistSession('session-json');
    await storage.setItem(
      key: SecureSupabaseAuthStorage.sdkPkceStorageKey,
      value: 'pkce-verifier',
    );

    expect(await storage.accessToken(), 'session-json');
    expect(
      await storage.getItem(key: SecureSupabaseAuthStorage.sdkPkceStorageKey),
      'pkce-verifier',
    );
    expect(
      secureStore.values[SecureSupabaseAuthStorage.sessionStorageKey],
      'session-json',
    );
    expect(
      secureStore.values[SecureSupabaseAuthStorage.pkceStorageKey],
      'pkce-verifier',
    );

    await storage.removePersistedSession();
    await storage.clearPendingOAuth();
    expect(await storage.hasAccessToken(), isFalse);
    expect(secureStore.values, isEmpty);
  });

  test('rifiuta chiavi SDK inattese senza leggere o scrivere', () async {
    final secureStore = _MemorySecureStore();
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );

    await expectLater(
      storage.setItem(key: 'unexpected', value: 'secret'),
      throwsA(
        isA<AuthStorageException>().having(
          (error) => error.code,
          'code',
          'unsupported_secure_storage_key',
        ),
      ),
    );
    expect(secureStore.values, isEmpty);
  });

  test('errori driver falliscono chiuso senza riportare il valore', () async {
    const sentinel = 'SENSITIVE_SESSION_SENTINEL';
    final secureStore = _MemorySecureStore()..writeError = StateError(sentinel);
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );

    Object? captured;
    try {
      await storage.persistSession(sentinel);
    } on Object catch (error) {
      captured = error;
    }

    expect(captured, isA<AuthStorageException>());
    expect(captured.toString(), isNot(contains(sentinel)));
    expect(secureStore.values, isEmpty);
  });

  test('valori vuoti o eccessivi non raggiungono il driver', () async {
    final secureStore = _MemorySecureStore();
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );

    await expectLater(
      storage.persistSession(''),
      throwsA(isA<AuthStorageException>()),
    );
    await expectLater(
      storage.setItem(
        key: SecureSupabaseAuthStorage.sdkPkceStorageKey,
        value: List.filled(4097, 'x').join(),
      ),
      throwsA(isA<AuthStorageException>()),
    );
    expect(secureStore.values, isEmpty);
  });

  test('errore marker impedisce ogni uso senza fallback plaintext', () async {
    final marker = _MemoryMarkerStore(
      readError: StateError('private marker detail'),
    );
    final storage = SecureSupabaseAuthStorage(
      secureStore: _MemorySecureStore(),
      installationMarkerStore: marker,
    );

    await expectLater(
      storage.initialize(),
      throwsA(
        isA<AuthStorageException>().having(
          (error) => error.code,
          'code',
          'secure_storage_initialization_failed',
        ),
      ),
    );

    marker.readError = null;
    await storage.initialize();
    expect(marker.readCalls, 2);
  });

  test('cleanup pendente viene ritentato prima di qualunque restore', () async {
    final secureStore = _MemorySecureStore({
      SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
      SecureSupabaseAuthStorage.pkceStorageKey: 'stale-verifier',
    });
    final marker = _MemoryMarkerStore(marked: true)
      ..pendingCleanup.addAll(AuthCleanupTarget.values);
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: marker,
    );

    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(secureStore.values, isEmpty);
    expect(marker.pendingCleanup, isEmpty);
  });

  test(
    'bootstrap tenta PKCE anche quando il cleanup sessione fallisce',
    () async {
      final secureStore =
          _MemorySecureStore({
              SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
              SecureSupabaseAuthStorage.pkceStorageKey: 'stale-verifier',
            })
            ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
                StateError('private session delete detail');
      final marker = _MemoryMarkerStore(marked: true)
        ..pendingCleanup.addAll(AuthCleanupTarget.values);
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );

      await expectLater(
        storage.initialize(),
        throwsA(isA<AuthStorageException>()),
      );

      expect(
        secureStore.deleted,
        containsAll([
          SecureSupabaseAuthStorage.sessionStorageKey,
          SecureSupabaseAuthStorage.pkceStorageKey,
        ]),
      );
      expect(marker.pendingCleanup, contains(AuthCleanupTarget.session));
      expect(marker.pendingCleanup, isNot(contains(AuthCleanupTarget.pkce)));
    },
  );

  test(
    'delete fallito mantiene tombstone e bootstrap successivo ritenta',
    () async {
      final secureStore =
          _MemorySecureStore({
              SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
            })
            ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
                StateError('private driver detail');
      final marker = _MemoryMarkerStore(marked: true);
      final first = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );

      await expectLater(
        first.removePersistedSession(),
        throwsA(isA<AuthStorageException>()),
      );
      expect(marker.pendingCleanup, contains(AuthCleanupTarget.session));

      secureStore.deleteErrors.clear();
      final restarted = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );
      await restarted.initialize();

      expect(await restarted.hasAccessToken(), isFalse);
      expect(marker.pendingCleanup, isNot(contains(AuthCleanupTarget.session)));
    },
  );

  test(
    'delete fallito ritenta il tombstone dopo failure marker transitoria',
    () async {
      final secureStore =
          _MemorySecureStore({
              SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
            })
            ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
                StateError('private driver detail');
      final marker = _MemoryMarkerStore(
        marked: true,
        markCleanupErrorsRemaining: 1,
      );
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );

      await expectLater(
        storage.removePersistedSession(),
        throwsA(isA<AuthStorageException>()),
      );

      expect(marker.markCleanupCalls[AuthCleanupTarget.session], 2);
      expect(marker.pendingCleanup, contains(AuthCleanupTarget.session));
    },
  );

  test(
    'tombstone sicuro recupera due failure marker e delete al riavvio',
    () async {
      final secureStore =
          _MemorySecureStore({
              SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
            })
            ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
                StateError('private driver detail');
      final marker = _MemoryMarkerStore(
        marked: true,
        markCleanupErrorsRemaining: 2,
      );
      final first = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );

      await expectLater(
        first.removePersistedSession(),
        throwsA(isA<AuthStorageException>()),
      );
      expect(marker.pendingCleanup, isEmpty);
      expect(
        secureStore.values.containsKey(
          SecureSupabaseAuthStorage.sessionCleanupMarkerStorageKey,
        ),
        isTrue,
      );

      secureStore.deleteErrors.clear();
      final restarted = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
      );
      await restarted.initialize();

      expect(await restarted.hasAccessToken(), isFalse);
      expect(
        secureStore.values.containsKey(
          SecureSupabaseAuthStorage.sessionCleanupMarkerStorageKey,
        ),
        isFalse,
      );
    },
  );

  test('failure di persistenza è osservabile con codice sanitizzato', () async {
    final secureStore = _MemorySecureStore()
      ..writeError = StateError('SENSITIVE_DRIVER_DETAIL');
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
    );
    final failure = storage.failures.first;

    await expectLater(
      storage.persistSession('bounded-session'),
      throwsA(isA<AuthStorageException>()),
    );

    expect(
      await failure,
      isA<AuthStorageException>()
          .having((error) => error.code, 'code', 'secure_storage_write_failed')
          .having(
            (error) => error.toString(),
            'sanitized',
            isNot(contains('SENSITIVE_DRIVER_DETAIL')),
          ),
    );
  });
}

final class _MemorySecureStore implements SecureAuthKeyValueStore {
  _MemorySecureStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;
  final List<String> deleted = [];
  Object? readError;
  Object? writeError;
  Object? deleteError;
  final Map<String, Object> deleteErrors = {};

  @override
  Future<String?> read(String key) async {
    if (readError case final error?) {
      throw error;
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeError case final error?) {
      throw error;
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleted.add(key);
    if (deleteErrors[key] case final error?) {
      throw error;
    }
    if (deleteError case final error?) {
      throw error;
    }
    values.remove(key);
  }
}

final class _MemoryMarkerStore implements AuthInstallationMarkerStore {
  _MemoryMarkerStore({
    this.marked = false,
    this.readError,
    this.markCleanupErrorsRemaining = 0,
  });

  bool marked;
  Object? readError;
  int readCalls = 0;
  int markCalls = 0;
  int markCleanupErrorsRemaining;
  final Map<AuthCleanupTarget, int> markCleanupCalls = {};
  final Set<AuthCleanupTarget> pendingCleanup = {};

  @override
  Future<bool> isCurrentInstallMarked() async {
    readCalls++;
    if (readError case final error?) {
      throw error;
    }
    return marked;
  }

  @override
  Future<void> markCurrentInstall() async {
    markCalls++;
    marked = true;
  }

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async {
    return pendingCleanup.contains(target);
  }

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {
    markCleanupCalls[target] = (markCleanupCalls[target] ?? 0) + 1;
    if (markCleanupErrorsRemaining > 0) {
      markCleanupErrorsRemaining--;
      throw StateError('private marker write detail');
    }
    pendingCleanup.add(target);
  }

  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {
    pendingCleanup.remove(target);
  }
}
