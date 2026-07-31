import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errore chiuso e privo di dettagli sensibili del confine di persistenza Auth.
final class AuthStorageException implements Exception {
  const AuthStorageException(this.code);

  final String code;

  @override
  String toString() => 'AuthStorageException($code)';
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

enum AuthCleanupTarget { session, pkce }

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
    };
  }
}

/// Unico adapter per sessione Supabase e verifier PKCE.
///
/// La sessione e il verifier vengono mappati su due sole chiavi del namespace
/// sicuro. SharedPreferences contiene esclusivamente marker booleani non sensibili,
/// usati per first-install cleanup e per ritentare purge interrotti prima del restore.
final class SecureSupabaseAuthStorage extends LocalStorage
    implements GotrueAsyncStorage {
  factory SecureSupabaseAuthStorage({
    required SecureAuthKeyValueStore secureStore,
    required AuthInstallationMarkerStore installationMarkerStore,
  }) {
    return SecureSupabaseAuthStorage._(secureStore, installationMarkerStore);
  }

  SecureSupabaseAuthStorage._(this._secureStore, this._installationMarkerStore);

  factory SecureSupabaseAuthStorage.standard() {
    return SecureSupabaseAuthStorage(
      secureStore: FlutterSecureAuthKeyValueStore(),
      installationMarkerStore: SharedPreferencesAuthInstallationMarkerStore(),
    );
  }

  static final SecureSupabaseAuthStorage standardInstance =
      SecureSupabaseAuthStorage.standard();

  static const sessionStorageKey = 'cmc.auth.session.v1';
  static const pkceStorageKey = 'cmc.auth.pkce.v1';
  static const sdkPkceStorageKey = 'supabase.auth.token-code-verifier';

  static const _maxSessionLength = 128 * 1024;
  static const _maxPkceLength = 4096;

  final SecureAuthKeyValueStore _secureStore;
  final AuthInstallationMarkerStore _installationMarkerStore;
  final StreamController<AuthStorageException> _failures =
      StreamController<AuthStorageException>.broadcast(sync: true);

  Future<void>? _initialization;
  Future<void> _mutationTail = Future<void>.value();

  Stream<AuthStorageException> get failures => _failures.stream;

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
        await _runIndependently([
          () => _retryPendingCleanup(AuthCleanupTarget.session),
          () => _retryPendingCleanup(AuthCleanupTarget.pkce),
        ]);
        return;
      }

      await _runIndependently([
        () => _secureStore.delete(sessionStorageKey),
        () => _secureStore.delete(pkceStorageKey),
      ]);
      await _installationMarkerStore.markCurrentInstall();
      await _runIndependently([
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.session,
        ),
        () => _installationMarkerStore.clearCleanupPending(
          AuthCleanupTarget.pkce,
        ),
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
    return await _read(sessionStorageKey) != null;
  }

  @override
  Future<String?> accessToken() async {
    await _ensureInitialized();
    return _read(sessionStorageKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _ensureInitialized();
    await _enqueueMutation(
      () => _writeBounded(
        key: sessionStorageKey,
        value: persistSessionString,
        maxLength: _maxSessionLength,
      ),
    );
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
    final isPending = await _installationMarkerStore.isCleanupPending(target);
    if (!isPending) {
      return;
    }
    await _secureStore.delete(_storageKey(target));
    await _installationMarkerStore.clearCleanupPending(target);
  }

  Future<void> _deleteWithTombstone({
    required String key,
    required AuthCleanupTarget target,
  }) async {
    AuthStorageException? firstFailure;
    StackTrace? firstStackTrace;
    var markerWritten = false;
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
      await _installationMarkerStore.markCleanupPending(target);
      markerWritten = true;
    }, 'cleanup_marker_write_failed');
    await capture(() async {
      await _delete(key);
      deleteSucceeded = true;
    }, 'secure_storage_delete_failed');

    if (!deleteSucceeded && !markerWritten) {
      await capture(() async {
        await _installationMarkerStore.markCleanupPending(target);
        markerWritten = true;
      }, 'cleanup_marker_write_failed');
    }

    if (firstFailure == null) {
      await capture(
        () => _installationMarkerStore.clearCleanupPending(target),
        'cleanup_marker_clear_failed',
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
    };
  }
}
