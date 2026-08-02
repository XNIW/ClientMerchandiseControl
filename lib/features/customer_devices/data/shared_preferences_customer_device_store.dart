import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/customer_device_models.dart';
import '../domain/customer_device_repository.dart';

typedef CustomerDeviceUuidFactory = String Function();

abstract interface class CustomerDevicePreferences {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

final class PlatformCustomerDevicePreferences
    implements CustomerDevicePreferences {
  PlatformCustomerDevicePreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

final class SharedPreferencesCustomerDeviceStore
    implements CustomerDeviceLocalStore {
  factory SharedPreferencesCustomerDeviceStore({
    required CustomerDeviceUuidFactory uuidFactory,
    CustomerDevicePreferences? preferences,
  }) {
    return SharedPreferencesCustomerDeviceStore._(
      uuidFactory,
      preferences ?? PlatformCustomerDevicePreferences(),
    );
  }

  SharedPreferencesCustomerDeviceStore._(this._uuidFactory, this._preferences);

  static const storageKey = 'cmc.customer-device.v1';

  final CustomerDeviceUuidFactory _uuidFactory;
  final CustomerDevicePreferences _preferences;
  Future<void> _tail = Future<void>.value();

  @override
  Future<CustomerDeviceLocalRecord> loadOrCreate() {
    return _serialized(() async {
      final encoded = await _preferences.getString(storageKey);
      if (encoded != null) {
        try {
          return _decode(encoded);
        } on Object {
          // Un record locale corrotto non deve riusare identificatori o consenso.
        }
      }
      final record = _freshRecord();
      await _preferences.setString(storageKey, _encode(record));
      return record;
    });
  }

  @override
  Future<void> save(CustomerDeviceLocalRecord record) {
    return _serialized(() async {
      _validateRecord(record);
      await _preferences.setString(storageKey, _encode(record));
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = _tail.then((_) => action());
    _tail = completer.then<void>((_) {}, onError: (_, _) {});
    return completer;
  }

  CustomerDeviceLocalRecord _freshRecord() {
    final installationId = _uuidFactory();
    if (!isCustomerDeviceUuid(installationId)) {
      throw const FormatException('Invalid generated installation UUID.');
    }
    return CustomerDeviceLocalRecord(
      installationId: installationId,
      decisionOwnerSubjectId: null,
      consentStatus: CustomerDeviceConsentStatus.notRequested,
      pendingOperation: null,
    );
  }
}

String _encode(CustomerDeviceLocalRecord record) {
  _validateRecord(record);
  final pending = record.pendingOperation;
  return jsonEncode(<String, Object?>{
    'version': 1,
    'installationId': record.installationId,
    'decisionOwnerSubjectId': record.decisionOwnerSubjectId,
    'consentStatus': record.consentStatus.wireValue,
    'pendingOperation': pending == null
        ? null
        : <String, Object?>{
            'kind': pending.kind.name,
            'ownerSubjectId': pending.ownerSubjectId,
            'idempotencyKey': pending.idempotencyKey,
          },
  });
}

CustomerDeviceLocalRecord _decode(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! Map) {
    throw const FormatException('Invalid customer device local record.');
  }
  final map = decoded.map((key, value) => MapEntry(key.toString(), value));
  const keys = {
    'version',
    'installationId',
    'decisionOwnerSubjectId',
    'consentStatus',
    'pendingOperation',
  };
  if (map['version'] != 1 ||
      map.keys.length != keys.length ||
      map.keys.any((key) => !keys.contains(key)) ||
      map['installationId'] is! String ||
      (map['decisionOwnerSubjectId'] != null &&
          map['decisionOwnerSubjectId'] is! String) ||
      map['consentStatus'] is! String) {
    throw const FormatException('Invalid customer device local record.');
  }
  final pending = _decodePending(map['pendingOperation']);
  final record = CustomerDeviceLocalRecord(
    installationId: map['installationId']! as String,
    decisionOwnerSubjectId: map['decisionOwnerSubjectId'] as String?,
    consentStatus: customerDeviceConsentFromWire(
      map['consentStatus']! as String,
    ),
    pendingOperation: pending,
  );
  _validateRecord(record);
  return record;
}

CustomerDevicePendingOperation? _decodePending(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw const FormatException('Invalid pending device operation.');
  }
  final map = value.map((key, item) => MapEntry(key.toString(), item));
  const keys = {'kind', 'ownerSubjectId', 'idempotencyKey'};
  if (map.keys.length != keys.length ||
      map.keys.any((key) => !keys.contains(key)) ||
      map.values.any((item) => item is! String)) {
    throw const FormatException('Invalid pending device operation.');
  }
  final kind = switch (map['kind']) {
    'register' => CustomerDevicePendingOperationKind.register,
    'revoke' => CustomerDevicePendingOperationKind.revoke,
    _ => throw const FormatException('Invalid pending operation kind.'),
  };
  return CustomerDevicePendingOperation(
    kind: kind,
    ownerSubjectId: map['ownerSubjectId']! as String,
    idempotencyKey: map['idempotencyKey']! as String,
  );
}

void _validateRecord(CustomerDeviceLocalRecord record) {
  final owner = record.decisionOwnerSubjectId;
  final pending = record.pendingOperation;
  if (!isCustomerDeviceUuid(record.installationId) ||
      (owner != null && !isCustomerDeviceUuid(owner)) ||
      (pending != null &&
          (!isCustomerDeviceUuid(pending.ownerSubjectId) ||
              !isCustomerDeviceUuid(pending.idempotencyKey)))) {
    throw const FormatException('Invalid local customer device UUID.');
  }
}
