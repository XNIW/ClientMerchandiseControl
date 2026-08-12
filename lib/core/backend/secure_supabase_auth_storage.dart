import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errore chiuso e privo di dettagli sensibili del confine di persistenza Auth.
final class AuthStorageException implements Exception {
  const AuthStorageException(this.code);

  final String code;

  @override
  String toString() => 'AuthStorageException($code)';
}

final class AuthPendingRemoteRevocation {
  const AuthPendingRemoteRevocation({
    required this.slot,
    required this.session,
  });

  final int slot;
  final String session;
}

abstract interface class SecureAuthKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class AuthInstallationMarkerStore {
  Future<bool> isCurrentInstallMarked();

  Future<void> markCurrentInstall();

  Future<bool> isCleanupPending(AuthCleanupTarget target);

  Future<void> markCleanupPending(AuthCleanupTarget target);

  Future<void> clearCleanupPending(AuthCleanupTarget target);
}

abstract interface class AuthCleanupJournalStore {
  Future<bool> isCleanupPending(AuthCleanupTarget target);

  Future<void> markCleanupPending(AuthCleanupTarget target);

  Future<void> clearCleanupPending(AuthCleanupTarget target);
}

enum AuthCleanupTarget { session, pkce, logout }

final class FlutterSecureAuthKeyValueStore implements SecureAuthKeyValueStore {
  FlutterSecureAuthKeyValueStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: false,
              migrateOnAlgorithmChange: true,
              migrateWithBackup: false,
              keyCipherAlgorithm:
                  KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
              storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
              storageNamespace: 'cmc_customer_auth_v1',
            ),
            iOptions: IOSOptions(
              accountName: 'com.xniw.clientmerchandisecontrol.auth.v1',
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final class SharedPreferencesAuthInstallationMarkerStore
    implements AuthInstallationMarkerStore {
  SharedPreferencesAuthInstallationMarkerStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _markerKey = 'cmc.auth.installation-marker.v1';
  static const _sessionCleanupKey = 'cmc.auth.cleanup-session.v1';
  static const _pkceCleanupKey = 'cmc.auth.cleanup-pkce.v1';
  static const _logoutIntentKey = 'cmc.auth.logout-intent.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCurrentInstallMarked() async {
    return await _preferences.getBool(_markerKey) ?? false;
  }

  @override
  Future<void> markCurrentInstall() {
    return _preferences.setBool(_markerKey, true);
  }

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async {
    return await _preferences.getBool(_cleanupKey(target)) ?? false;
  }

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) {
    return _preferences.setBool(_cleanupKey(target), true);
  }

  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) {
    return _preferences.remove(_cleanupKey(target));
  }

  static String _cleanupKey(AuthCleanupTarget target) {
    return switch (target) {
      AuthCleanupTarget.session => _sessionCleanupKey,
      AuthCleanupTarget.pkce => _pkceCleanupKey,
      AuthCleanupTarget.logout => _logoutIntentKey,
    };
  }
}

/// Terzo canale persistente non sensibile, indipendente da SharedPreferences e
/// Keychain/Keystore.
///
/// Il journal contiene soltanto file marker di un byte nel container privato
/// Application Support. L'esistenza del file è sufficiente: anche un'interruzione
/// successiva alla creazione mantiene il bootstrap in modalità cleanup.
final class FileAuthCleanupJournalStore implements AuthCleanupJournalStore {
  FileAuthCleanupJournalStore({
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const _directoryName = 'cmc_auth_cleanup_journal_v1';

  final Future<Directory> Function() _supportDirectoryProvider;

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async {
    return (await _markerFile(target)).exists();
  }

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {
    final marker = await _markerFile(target);
    if (await marker.exists()) {
      return;
    }
    await marker.create(recursive: true);
    final file = await marker.open(mode: FileMode.writeOnlyAppend);
    try {
      await file.writeByte(1);
      await file.flush();
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {
    final marker = await _markerFile(target);
    if (await marker.exists()) {
      await marker.delete();
    }
  }

  Future<File> _markerFile(AuthCleanupTarget target) async {
    final supportDirectory = await _supportDirectoryProvider();
    final journalDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}$_directoryName',
    );
    return File(
      '${journalDirectory.path}${Platform.pathSeparator}${target.name}.pending',
    );
  }
}

/// Unico adapter per sessione Supabase e verifier PKCE.
///
/// La sessione e il verifier vengono mappati su due sole chiavi del namespace
/// sicuro. SharedPreferences e il journal Application Support contengono
/// esclusivamente marker non sensibili, usati per first-install cleanup e per
/// ritentare purge interrotti prima del restore.
final class SecureSupabaseAuthStorage extends LocalStorage
    implements GotrueAsyncStorage {
  factory SecureSupabaseAuthStorage({
    required SecureAuthKeyValueStore secureStore,
    required AuthInstallationMarkerStore installationMarkerStore,
    required AuthCleanupJournalStore cleanupJournalStore,
  }) {
    return SecureSupabaseAuthStorage._(
      secureStore,
      installationMarkerStore,
      cleanupJournalStore,
    );
  }

  SecureSupabaseAuthStorage._(
    this._secureStore,
    this._installationMarkerStore,
    this._cleanupJournalStore,
  );

  factory SecureSupabaseAuthStorage.standard() {
    return SecureSupabaseAuthStorage(
      secureStore: FlutterSecureAuthKeyValueStore(),
      installationMarkerStore: SharedPreferencesAuthInstallationMarkerStore(),
      cleanupJournalStore: FileAuthCleanupJournalStore(),
    );
  }

  static final SecureSupabaseAuthStorage standardInstance =
      SecureSupabaseAuthStorage.standard();

  static const sessionStorageKey = 'cmc.auth.session.v1';
  static const pkceStorageKey = 'cmc.auth.pkce.v1';
  static const sdkPkceStorageKey = 'supabase.auth.token-code-verifier';
  static const sessionCleanupMarkerStorageKey =
      'cmc.auth.cleanup-session.secure.v1';
  static const pkceCleanupMarkerStorageKey = 'cmc.auth.cleanup-pkce.secure.v1';
  static const logoutIntentStorageKey = 'cmc.auth.logout-intent.secure.v1';
  static const remoteRevocationStorageKeyPrefix =
      'cmc.auth.remote-revocation.secure.v1';

  static const _maxSessionLength = 128 * 1024;
  static const _maxPkceLength = 4096;
  static const _maximumPendingRemoteRevocations = 4;

  final SecureAuthKeyValueStore _secureStore;
  final AuthInstallationMarkerStore _installationMarkerStore;
  final AuthCleanupJournalStore _cleanupJournalStore;
  final StreamController<AuthStorageException> _failures =
      StreamController<AuthStorageException>.broadcast(sync: true);

  Future<void>? _initialization;
  Future<void> _mutationTail = Future<void>.value();
  var _logoutRequested = false;

  Stream<AuthStorageException> get failures => _failures.stream;

  bool get logoutRequested => _logoutRequested;

  @override
  Future<void> initialize() {
    final inFlight = _initialization;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> operation;
    operation = _initializeOnce().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (identical(_initialization, operation)) {
        _initialization = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _initialization = operation;
    return operation;
  }

  Future<void> _initializeOnce() async {
    try {
      final isMarked = await _installationMarkerStore.isCurrentInstallMarked();
      if (isMarked) {
        _logoutRequested = await _isLogoutIntentPending();
        if (_logoutRequested) {
          await _runIndependently([
            () => _delete(sessionStorageKey),
            () => _delete(pkceStorageKey),
          ]);
        }
        await _runIndependently([
          () => _retryPendingCleanup(AuthCleanupTarget.session),
          () => _retryPendingCleanup(AuthCleanupTarget.pkce),
        ]);
        return;
      }

      await _runIndependently([
        () => _secureStore.delete(sessionStorageKey),
        () => _secureStore.delete(pkceStorageKey),
        () => _secureStore.delete(sessionCleanupMarkerStorageKey),
        () => _secureStore.delete(pkceCleanupMarkerStorageKey),
        () => _secureStore.delete(logoutIntentStorageKey),
        for (var slot = 0; slot < _maximumPendingRemoteRevocations; slot++)
          () => _secureStore.delete(_remoteRevocationStorageKey(slot)),
      ]);
      await _installationMarkerStore.markCurrentInstall();
      await _runIndependently([
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.session,
        ),
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.pkce,
        ),
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.logout,
        ),
        () =>
            _cleanupJournalStore.clearCleanupPending(AuthCleanupTarget.session),
        () => _cleanupJournalStore.clearCleanupPending(AuthCleanupTarget.pkce),
        () =>
            _cleanupJournalStore.clearCleanupPending(AuthCleanupTarget.logout),
      ]);
    } on Object {
      throw _reportFailure(
        const AuthStorageException('secure_storage_initialization_failed'),
      );
    }
  }

  Future<void> _ensureInitialized() => initialize();

  @override
  Future<bool> hasAccessToken() async {
    await _ensureInitialized();
    if (_logoutRequested) return false;
    return await _read(sessionStorageKey) != null;
  }

  @override
  Future<String?> accessToken() async {
    await _ensureInitialized();
    if (_logoutRequested) return null;
    return _read(sessionStorageKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _ensureInitialized();
    if (_logoutRequested) return;
    await _enqueueMutation(
      () => _writeBounded(
        key: sessionStorageKey,
        value: persistSessionString,
        maxLength: _maxSessionLength,
      ),
    );
  }

  /// Rende persistente l'intento prima di qualsiasi cleanup feature-specific.
  /// Il record sicuro include la sessione corrente esclusivamente per consentire
  /// una revoca server-side ritentabile; i due marker non sensibili non la copiano.
  Future<void> beginLogoutIntent(String? serializedSession) async {
    await _ensureInitialized();
    await _enqueueMutation(() async {
      // Il processo corrente deve diventare fail-closed anche quando nessuno
      // dei tre backend riesce a rendere durevole il marker.
      _logoutRequested = true;
      AuthStorageException? firstFailure;
      StackTrace? firstStackTrace;
      var markerWritten = false;

      Future<void> capture(
        Future<void> Function() operation,
        String failureCode,
      ) async {
        try {
          await operation();
          markerWritten = true;
        } on Object catch (error, stackTrace) {
          firstFailure ??= error is AuthStorageException
              ? error
              : _reportFailure(AuthStorageException(failureCode));
          firstStackTrace ??= stackTrace;
        }
      }

      await capture(
        () => _writeBounded(
          key: logoutIntentStorageKey,
          value: serializedSession ?? 'pending',
          maxLength: _maxSessionLength,
        ),
        'logout_intent_secure_write_failed',
      );
      await capture(
        () => _cleanupJournalStore.markCleanupPending(AuthCleanupTarget.logout),
        'logout_intent_journal_write_failed',
      );
      await capture(
        () => _installationMarkerStore.markCleanupPending(
          AuthCleanupTarget.logout,
        ),
        'logout_intent_marker_write_failed',
      );
      try {
        await _deleteWithTombstone(
          key: sessionStorageKey,
          target: AuthCleanupTarget.session,
        );
      } on Object catch (error, stackTrace) {
        firstFailure ??= error is AuthStorageException
            ? error
            : _reportFailure(
                const AuthStorageException('logout_session_purge_failed'),
              );
        firstStackTrace ??= stackTrace;
      }
      try {
        await _deleteWithTombstone(
          key: pkceStorageKey,
          target: AuthCleanupTarget.pkce,
        );
      } on Object catch (error, stackTrace) {
        firstFailure ??= error is AuthStorageException
            ? error
            : _reportFailure(
                const AuthStorageException('logout_pkce_purge_failed'),
              );
        firstStackTrace ??= stackTrace;
      }
      if (!markerWritten) {
        firstFailure = _reportFailure(
          const AuthStorageException('logout_intent_not_durable'),
        );
        firstStackTrace = StackTrace.current;
      }
      if (firstFailure case final failure?) {
        Error.throwWithStackTrace(failure, firstStackTrace!);
      }
    });
  }

  Future<void> finishLogout({required bool remoteRevoked}) async {
    await _ensureInitialized();
    await _enqueueMutation(() async {
      if (!remoteRevoked) {
        final serializedSession = await _read(logoutIntentStorageKey);
        if (serializedSession != null && serializedSession != 'pending') {
          await _enqueueRemoteRevocation(serializedSession);
        }
      }
      _logoutRequested = true;
      await _runIndependently([
        () => _delete(sessionStorageKey),
        () => _delete(pkceStorageKey),
        // Il marker resta intenzionalmente attivo fino al prossimo login
        // esplicito riuscito. Dopo avere trasferito l'eventuale sessione nella
        // coda di revoca, il payload viene ridotto a un valore non sensibile.
        () => _writeBounded(
          key: logoutIntentStorageKey,
          value: 'pending',
          maxLength: _maxSessionLength,
        ),
      ]);
    });
  }

  Future<void> persistExplicitLoginSession(String serializedSession) async {
    await _ensureInitialized();
    await _enqueueMutation(() async {
      await _writeBounded(
        key: sessionStorageKey,
        value: serializedSession,
        maxLength: _maxSessionLength,
      );
      await _runIndependently([
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.logout,
        ),
        () =>
            _cleanupJournalStore.clearCleanupPending(AuthCleanupTarget.logout),
        () => _delete(logoutIntentStorageKey),
      ]);
      _logoutRequested = false;
    });
  }

  Future<List<AuthPendingRemoteRevocation>> pendingRemoteRevocations() async {
    await _ensureInitialized();
    final pending = <AuthPendingRemoteRevocation>[];
    for (var slot = 0; slot < _maximumPendingRemoteRevocations; slot++) {
      final session = await _read(_remoteRevocationStorageKey(slot));
      if (session != null) {
        pending.add(AuthPendingRemoteRevocation(slot: slot, session: session));
      }
    }
    return pending;
  }

  /// Restituisce la sessione cifrata di un logout interrotto, senza renderla
  /// nuovamente disponibile al restore locale.
  Future<String?> pendingLogoutSession() async {
    await _ensureInitialized();
    if (!_logoutRequested) return null;
    final serializedSession = await _read(logoutIntentStorageKey);
    return serializedSession == null || serializedSession == 'pending'
        ? null
        : serializedSession;
  }

  Future<void> clearPendingRemoteRevocation(int slot) async {
    if (slot < 0 || slot >= _maximumPendingRemoteRevocations) {
      throw _reportFailure(
        const AuthStorageException('remote_revocation_slot_invalid'),
      );
    }
    await _ensureInitialized();
    await _enqueueMutation(() => _delete(_remoteRevocationStorageKey(slot)));
  }

  @override
  Future<void> removePersistedSession() async {
    await _ensureInitialized();
    await _enqueueMutation(
      () => _deleteWithTombstone(
        key: sessionStorageKey,
        target: AuthCleanupTarget.session,
      ),
    );
  }

  @override
  Future<String?> getItem({required String key}) async {
    _requireSdkPkceKey(key);
    await _ensureInitialized();
    return _read(pkceStorageKey);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _requireSdkPkceKey(key);
    await _ensureInitialized();
    await _enqueueMutation(
      () => _writeBounded(
        key: pkceStorageKey,
        value: value,
        maxLength: _maxPkceLength,
      ),
    );
  }

  @override
  Future<void> removeItem({required String key}) async {
    _requireSdkPkceKey(key);
    await clearPendingOAuth();
  }

  Future<void> clearPendingOAuth() async {
    await _ensureInitialized();
    await _enqueueMutation(
      () => _deleteWithTombstone(
        key: pkceStorageKey,
        target: AuthCleanupTarget.pkce,
      ),
    );
  }

  void _requireSdkPkceKey(String key) {
    if (key != sdkPkceStorageKey) {
      throw _reportFailure(
        const AuthStorageException('unsupported_secure_storage_key'),
      );
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _secureStore.read(key);
    } on Object {
      throw _reportFailure(
        const AuthStorageException('secure_storage_read_failed'),
      );
    }
  }

  Future<void> _writeBounded({
    required String key,
    required String value,
    required int maxLength,
  }) async {
    if (value.isEmpty || value.length > maxLength) {
      throw _reportFailure(
        const AuthStorageException('secure_storage_value_rejected'),
      );
    }
    try {
      await _secureStore.write(key, value);
    } on Object {
      throw _reportFailure(
        const AuthStorageException('secure_storage_write_failed'),
      );
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _secureStore.delete(key);
    } on Object {
      throw _reportFailure(
        const AuthStorageException('secure_storage_delete_failed'),
      );
    }
  }

  Future<void> _retryPendingCleanup(AuthCleanupTarget target) async {
    final sharedMarkerPending = await _installationMarkerStore.isCleanupPending(
      target,
    );
    final secureMarkerPending =
        await _read(_secureCleanupMarkerKey(target)) != null;
    final journalMarkerPending = await _cleanupJournalStore.isCleanupPending(
      target,
    );
    if (!sharedMarkerPending && !secureMarkerPending && !journalMarkerPending) {
      return;
    }
    await _delete(_storageKey(target));
    await _runIndependently([
      () => _installationMarkerStore.clearCleanupPending(target),
      () => _delete(_secureCleanupMarkerKey(target)),
      () => _cleanupJournalStore.clearCleanupPending(target),
    ]);
  }

  Future<bool> _isLogoutIntentPending() async {
    final secure = await _read(logoutIntentStorageKey) != null;
    final shared = await _installationMarkerStore.isCleanupPending(
      AuthCleanupTarget.logout,
    );
    final journal = await _cleanupJournalStore.isCleanupPending(
      AuthCleanupTarget.logout,
    );
    return secure || shared || journal;
  }

  Future<void> _enqueueRemoteRevocation(String serializedSession) async {
    for (var slot = 0; slot < _maximumPendingRemoteRevocations; slot++) {
      final key = _remoteRevocationStorageKey(slot);
      if (await _read(key) == null) {
        await _writeBounded(
          key: key,
          value: serializedSession,
          maxLength: _maxSessionLength,
        );
        return;
      }
    }
    throw _reportFailure(
      const AuthStorageException('remote_revocation_queue_full'),
    );
  }

  Future<void> _deleteWithTombstone({
    required String key,
    required AuthCleanupTarget target,
  }) async {
    AuthStorageException? firstFailure;
    StackTrace? firstStackTrace;
    var sharedMarkerWritten = false;
    var secureMarkerWritten = false;
    var journalMarkerWritten = false;
    var deleteSucceeded = false;

    Future<void> capture(
      Future<void> Function() operation,
      String failureCode,
    ) async {
      try {
        await operation();
      } on Object catch (error, stackTrace) {
        firstFailure ??= error is AuthStorageException
            ? error
            : _reportFailure(AuthStorageException(failureCode));
        firstStackTrace ??= stackTrace;
      }
    }

    await capture(() async {
      await _cleanupJournalStore.markCleanupPending(target);
      journalMarkerWritten = true;
    }, 'cleanup_journal_write_failed');
    await capture(() async {
      await _installationMarkerStore.markCleanupPending(target);
      sharedMarkerWritten = true;
    }, 'cleanup_marker_write_failed');
    await capture(() async {
      await _writeSecureCleanupMarker(target);
      secureMarkerWritten = true;
    }, 'cleanup_secure_marker_write_failed');
    await capture(() async {
      await _delete(key);
      deleteSucceeded = true;
    }, 'secure_storage_delete_failed');

    if (!deleteSucceeded && !sharedMarkerWritten) {
      await capture(() async {
        await _installationMarkerStore.markCleanupPending(target);
        sharedMarkerWritten = true;
      }, 'cleanup_marker_write_failed');
    }
    if (!deleteSucceeded && !secureMarkerWritten) {
      await capture(() async {
        await _writeSecureCleanupMarker(target);
        secureMarkerWritten = true;
      }, 'cleanup_secure_marker_write_failed');
    }
    if (!deleteSucceeded && !journalMarkerWritten) {
      await capture(() async {
        await _cleanupJournalStore.markCleanupPending(target);
        journalMarkerWritten = true;
      }, 'cleanup_journal_write_failed');
    }

    if (deleteSucceeded) {
      await capture(
        () => _installationMarkerStore.clearCleanupPending(target),
        'cleanup_marker_clear_failed',
      );
      await capture(
        () => _delete(_secureCleanupMarkerKey(target)),
        'cleanup_secure_marker_clear_failed',
      );
      await capture(
        () => _cleanupJournalStore.clearCleanupPending(target),
        'cleanup_journal_clear_failed',
      );
    }

    if (firstFailure case final failure?) {
      Error.throwWithStackTrace(failure, firstStackTrace!);
    }
  }

  static Future<void> _runIndependently(
    Iterable<Future<void> Function()> operations,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final operation in operations) {
      try {
        await operation();
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (firstError case final error?) {
      Error.throwWithStackTrace(error, firstStackTrace!);
    }
  }

  Future<void> _enqueueMutation(Future<void> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  AuthStorageException _reportFailure(AuthStorageException failure) {
    if (!_failures.isClosed) {
      _failures.add(failure);
    }
    return failure;
  }

  static String _storageKey(AuthCleanupTarget target) {
    return switch (target) {
      AuthCleanupTarget.session => sessionStorageKey,
      AuthCleanupTarget.pkce => pkceStorageKey,
      AuthCleanupTarget.logout => sessionStorageKey,
    };
  }

  Future<void> _writeSecureCleanupMarker(AuthCleanupTarget target) async {
    try {
      await _secureStore.write(_secureCleanupMarkerKey(target), 'pending');
    } on Object {
      throw _reportFailure(
        const AuthStorageException('cleanup_secure_marker_write_failed'),
      );
    }
  }

  static String _secureCleanupMarkerKey(AuthCleanupTarget target) {
    return switch (target) {
      AuthCleanupTarget.session => sessionCleanupMarkerStorageKey,
      AuthCleanupTarget.pkce => pkceCleanupMarkerStorageKey,
      AuthCleanupTarget.logout => logoutIntentStorageKey,
    };
  }

  static String _remoteRevocationStorageKey(int slot) {
    return '$remoteRevocationStorageKeyPrefix.$slot';
  }
}
