import 'dart:io';

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
      final journal = _MemoryCleanupJournalStore()
        ..pendingCleanup.addAll(const {
          AuthCleanupTarget.session,
          AuthCleanupTarget.pkce,
        });
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: journal,
      );

      await storage.initialize();
      await storage.initialize();

      expect(secureStore.deleted, [
        SecureSupabaseAuthStorage.sessionStorageKey,
        SecureSupabaseAuthStorage.pkceStorageKey,
        SecureSupabaseAuthStorage.sessionCleanupMarkerStorageKey,
        SecureSupabaseAuthStorage.pkceCleanupMarkerStorageKey,
        SecureSupabaseAuthStorage.logoutIntentStorageKey,
        '${SecureSupabaseAuthStorage.remoteRevocationStorageKeyPrefix}.0',
        '${SecureSupabaseAuthStorage.remoteRevocationStorageKeyPrefix}.1',
        '${SecureSupabaseAuthStorage.remoteRevocationStorageKeyPrefix}.2',
        '${SecureSupabaseAuthStorage.remoteRevocationStorageKeyPrefix}.3',
      ]);
      expect(secureStore.values['unrelated'], 'preserve-me');
      expect(marker.marked, isTrue);
      expect(marker.readCalls, 1);
      expect(marker.markCalls, 1);
      expect(journal.pendingCleanup, isEmpty);
    },
  );

  test('installazione già marcata preserva la sessione sicura', () async {
    final secureStore = _MemorySecureStore({
      SecureSupabaseAuthStorage.sessionStorageKey: 'persisted-session',
    });
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
      cleanupJournalStore: _MemoryCleanupJournalStore(),
    );

    await storage.initialize();

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'persisted-session');
    expect(secureStore.deleted, isEmpty);
  });

  test(
    'logout resta fail-closed dopo restart fino a un nuovo login esplicito',
    () async {
      final secureStore = _MemorySecureStore();
      final marker = _MemoryMarkerStore(marked: true);
      final journal = _MemoryCleanupJournalStore();
      final first = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: journal,
      );

      await first.persistSession('session-before-logout');
      await first.setItem(
        key: SecureSupabaseAuthStorage.sdkPkceStorageKey,
        value: 'verifier-before-logout',
      );
      await first.beginLogoutIntent('serialized-session');
      await first.finishLogout(remoteRevoked: true);

      expect(first.logoutRequested, isTrue);
      expect(await first.accessToken(), isNull);
      expect(
        secureStore.values[SecureSupabaseAuthStorage.logoutIntentStorageKey],
        'pending',
      );

      final restarted = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: journal,
      );
      await restarted.initialize();

      expect(restarted.logoutRequested, isTrue);
      expect(await restarted.hasAccessToken(), isFalse);
      await restarted.persistSession('late-sdk-session');
      expect(await restarted.accessToken(), isNull);

      await restarted.persistExplicitLoginSession('new-explicit-session');

      expect(restarted.logoutRequested, isFalse);
      expect(await restarted.accessToken(), 'new-explicit-session');
      expect(marker.pendingCleanup, isNot(contains(AuthCleanupTarget.logout)));
      expect(journal.pendingCleanup, isNot(contains(AuthCleanupTarget.logout)));
    },
  );

  test(
    'logout fallisce chiuso in memoria se marker e delete sessione falliscono',
    () async {
      final secureStore = _MemorySecureStore();
      final marker = _MemoryMarkerStore(
        marked: true,
        markCleanupErrorsRemaining: 8,
      );
      final journal = _MemoryCleanupJournalStore();
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: journal,
      );
      await storage.persistSession('session-that-must-not-be-restored');
      secureStore
        ..writeError = StateError('private secure write failure')
        ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
            StateError('private secure delete failure');
      journal.markError = StateError('private journal write failure');

      await expectLater(
        storage.beginLogoutIntent('serialized-session'),
        throwsA(
          isA<AuthStorageException>().having(
            (failure) => failure.code,
            'code',
            'logout_intent_not_durable',
          ),
        ),
      );

      expect(storage.logoutRequested, isTrue);
      expect(await storage.accessToken(), isNull);
      expect(
        secureStore.values[SecureSupabaseAuthStorage.sessionStorageKey],
        'session-that-must-not-be-restored',
      );
    },
  );

  test('sessione e verifier usano chiavi distinte con CRUD completo', () async {
    final secureStore = _MemorySecureStore();
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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

  test(
    'errore lettura journal impedisce il restore e resta retryable',
    () async {
      final journal = _MemoryCleanupJournalStore(
        readError: StateError('private journal detail'),
      );
      final storage = SecureSupabaseAuthStorage(
        secureStore: _MemorySecureStore({
          SecureSupabaseAuthStorage.sessionStorageKey: 'persisted-session',
        }),
        installationMarkerStore: _MemoryMarkerStore(marked: true),
        cleanupJournalStore: journal,
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

      journal.readError = null;
      await storage.initialize();
      expect(await storage.accessToken(), 'persisted-session');
    },
  );

  test('cleanup pendente viene ritentato prima di qualunque restore', () async {
    final secureStore = _MemorySecureStore({
      SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
      SecureSupabaseAuthStorage.pkceStorageKey: 'stale-verifier',
    });
    final marker = _MemoryMarkerStore(marked: true)
      ..pendingCleanup.addAll(const {
        AuthCleanupTarget.session,
        AuthCleanupTarget.pkce,
      });
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: marker,
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        ..pendingCleanup.addAll(const {
          AuthCleanupTarget.session,
          AuthCleanupTarget.pkce,
        });
      final storage = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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
        cleanupJournalStore: _MemoryCleanupJournalStore(),
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

  test(
    'journal file blocca restore se marker, tombstone sicuro e delete falliscono',
    () async {
      final supportDirectory = await Directory.systemTemp.createTemp(
        'cmc-auth-cleanup-journal-test.',
      );
      addTearDown(() async {
        if (await supportDirectory.exists()) {
          await supportDirectory.delete(recursive: true);
        }
      });
      final secureStore =
          _MemorySecureStore({
              SecureSupabaseAuthStorage.sessionStorageKey: 'stale-session',
            })
            ..writeError = StateError('private secure marker detail')
            ..deleteErrors[SecureSupabaseAuthStorage.sessionStorageKey] =
                StateError('private delete detail');
      final marker = _MemoryMarkerStore(
        marked: true,
        markCleanupErrorsRemaining: 2,
      );
      final firstJournal = FileAuthCleanupJournalStore(
        supportDirectoryProvider: () async => supportDirectory,
      );
      final first = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: firstJournal,
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
        isFalse,
      );
      expect(
        await firstJournal.isCleanupPending(AuthCleanupTarget.session),
        isTrue,
      );
      expect(
        secureStore.values[SecureSupabaseAuthStorage.sessionStorageKey],
        'stale-session',
      );

      secureStore
        ..writeError = null
        ..deleteErrors.clear();
      final restartedJournal = FileAuthCleanupJournalStore(
        supportDirectoryProvider: () async => supportDirectory,
      );
      final restarted = SecureSupabaseAuthStorage(
        secureStore: secureStore,
        installationMarkerStore: marker,
        cleanupJournalStore: restartedJournal,
      );

      await restarted.initialize();

      expect(await restarted.hasAccessToken(), isFalse);
      expect(
        await restartedJournal.isCleanupPending(AuthCleanupTarget.session),
        isFalse,
      );
    },
  );

  test('journal file separa i target e rende il marker idempotente', () async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'cmc-auth-cleanup-journal-targets.',
    );
    addTearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });
    final journal = FileAuthCleanupJournalStore(
      supportDirectoryProvider: () async => supportDirectory,
    );

    await journal.markCleanupPending(AuthCleanupTarget.session);
    await journal.markCleanupPending(AuthCleanupTarget.session);

    expect(await journal.isCleanupPending(AuthCleanupTarget.session), isTrue);
    expect(await journal.isCleanupPending(AuthCleanupTarget.pkce), isFalse);

    await journal.markCleanupPending(AuthCleanupTarget.pkce);
    await journal.clearCleanupPending(AuthCleanupTarget.session);

    expect(await journal.isCleanupPending(AuthCleanupTarget.session), isFalse);
    expect(await journal.isCleanupPending(AuthCleanupTarget.pkce), isTrue);
  });

  test('failure di persistenza è osservabile con codice sanitizzato', () async {
    final secureStore = _MemorySecureStore()
      ..writeError = StateError('SENSITIVE_DRIVER_DETAIL');
    final storage = SecureSupabaseAuthStorage(
      secureStore: secureStore,
      installationMarkerStore: _MemoryMarkerStore(marked: true),
      cleanupJournalStore: _MemoryCleanupJournalStore(),
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

final class _MemoryCleanupJournalStore implements AuthCleanupJournalStore {
  _MemoryCleanupJournalStore({this.readError});

  Object? readError;
  Object? markError;
  final Set<AuthCleanupTarget> pendingCleanup = {};

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async {
    if (readError case final error?) {
      throw error;
    }
    return pendingCleanup.contains(target);
  }

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {
    if (markError case final error?) {
      throw error;
    }
    pendingCleanup.add(target);
  }

  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {
    pendingCleanup.remove(target);
  }
}
