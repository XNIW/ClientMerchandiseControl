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
}

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

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isCurrentInstallMarked() async {
    return await _preferences.getBool(_markerKey) ?? false;
  }

  @override
  Future<void> markCurrentInstall() {
    return _preferences.setBool(_markerKey, true);
  }
}

/// Unico adapter per sessione Supabase e verifier PKCE.
///
/// La sessione e il verifier vengono mappati su due sole chiavi del namespace
/// sicuro. SharedPreferences contiene esclusivamente un marker booleano
/// non sensibile, usato per eliminare residui Keychain dopo una reinstallazione.
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

  Future<void>? _initialization;

  @override
  Future<void> initialize() {
    return _initialization ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      final isMarked = await _installationMarkerStore.isCurrentInstallMarked();
      if (isMarked) {
        return;
      }

      await _secureStore.delete(sessionStorageKey);
      await _secureStore.delete(pkceStorageKey);
      await _installationMarkerStore.markCurrentInstall();
    } on Object {
      throw const AuthStorageException('secure_storage_initialization_failed');
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
    await _writeBounded(
      key: sessionStorageKey,
      value: persistSessionString,
      maxLength: _maxSessionLength,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _ensureInitialized();
    await _delete(sessionStorageKey);
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
    await _writeBounded(
      key: pkceStorageKey,
      value: value,
      maxLength: _maxPkceLength,
    );
  }

  @override
  Future<void> removeItem({required String key}) async {
    _requireSdkPkceKey(key);
    await clearPendingOAuth();
  }

  Future<void> clearPendingOAuth() async {
    await _ensureInitialized();
    await _delete(pkceStorageKey);
  }

  void _requireSdkPkceKey(String key) {
    if (key != sdkPkceStorageKey) {
      throw const AuthStorageException('unsupported_secure_storage_key');
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _secureStore.read(key);
    } on Object {
      throw const AuthStorageException('secure_storage_read_failed');
    }
  }

  Future<void> _writeBounded({
    required String key,
    required String value,
    required int maxLength,
  }) async {
    if (value.isEmpty || value.length > maxLength) {
      throw const AuthStorageException('secure_storage_value_rejected');
    }
    try {
      await _secureStore.write(key, value);
    } on Object {
      throw const AuthStorageException('secure_storage_write_failed');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _secureStore.delete(key);
    } on Object {
      throw const AuthStorageException('secure_storage_delete_failed');
    }
  }
}
