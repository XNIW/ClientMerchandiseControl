import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_device_failure.dart';
import '../domain/customer_device_models.dart';
import '../domain/customer_device_repository.dart';

abstract interface class CustomerDevicePort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerDevicePort implements CustomerDevicePort {
  PlatformCustomerDevicePort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerDeviceRepository
    implements CustomerDeviceRepository {
  factory SupabaseCustomerDeviceRepository({
    required CustomerDevicePort port,
    Duration requestTimeout = const Duration(seconds: 12),
  }) {
    return SupabaseCustomerDeviceRepository._(port, requestTimeout);
  }

  SupabaseCustomerDeviceRepository._(this._port, this.requestTimeout);

  final CustomerDevicePort _port;
  final Duration requestTimeout;

  @override
  Future<CustomerDeviceSnapshot?> status(String installationId) {
    return _guard(() async {
      _requireUuidInput(installationId);
      final payload = _map(
        await _port.invoke('customer_device_status_v1', {
          'p_installation_id': installationId,
        }),
      );
      if (_isMinimalStatus(payload, 'not_found')) {
        return null;
      }
      return _parseSnapshot(payload, installationId, const {'ok'});
    });
  }

  @override
  Future<CustomerDeviceSnapshot> register(
    CustomerDeviceRegistrationRequest request,
  ) {
    return _guard(() async {
      final payload = _map(
        await _port.invoke('customer_register_device_v1', {
          'p_installation_id': request.installationId,
          'p_platform': request.platform.wireValue,
          'p_locale': request.locale,
          'p_consent_status': request.consentStatus.wireValue,
          'p_permission_status': request.permissionStatus.wireValue,
          'p_push_token': request.pushToken,
          'p_idempotency_key': request.idempotencyKey,
        }),
      );
      _throwRpcFailure(payload);
      return _parseSnapshot(payload, request.installationId, const {'ok'});
    });
  }

  @override
  Future<CustomerDeviceSnapshot?> revoke({
    required String installationId,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireUuidInput(installationId);
      _requireUuidInput(idempotencyKey);
      final payload = _map(
        await _port.invoke('customer_revoke_device_v1', {
          'p_installation_id': installationId,
          'p_idempotency_key': idempotencyKey,
        }),
      );
      if (_isMinimalStatus(payload, 'not_found')) {
        return null;
      }
      _throwRpcFailure(payload);
      return _parseSnapshot(payload, installationId, const {'revoked'});
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CustomerDeviceRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.timeout,
      );
    } on SocketException {
      throw const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.offline,
      );
    } on AuthException {
      throw const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw CustomerDeviceRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.unexpected,
      );
    } on Object {
      throw const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.unavailable,
      );
    }
  }
}

CustomerDeviceSnapshot _parseSnapshot(
  Map<String, Object?> payload,
  String expectedInstallationId,
  Set<String> statuses,
) {
  const keys = {
    'apiVersion',
    'status',
    'idempotent',
    'deviceId',
    'installationId',
    'platform',
    'locale',
    'consentStatus',
    'permissionStatus',
    'hasToken',
    'consentedAt',
    'revokedAt',
    'lastSeenAt',
    'expiresAt',
    'registrationVersion',
  };
  if (payload.keys.length != keys.length ||
      payload.keys.any((key) => !keys.contains(key)) ||
      payload['apiVersion'] != 'customer-device.v1' ||
      !statuses.contains(payload['status']) ||
      payload['idempotent'] is! bool ||
      payload['hasToken'] is! bool ||
      payload['registrationVersion'] is! int) {
    throw const FormatException('Invalid customer device response.');
  }
  final deviceId = _requiredString(payload, 'deviceId');
  final installationId = _requiredString(payload, 'installationId');
  _requireUuidInput(deviceId);
  _requireUuidInput(installationId);
  if (installationId != expectedInstallationId) {
    throw const FormatException('Customer device installation mismatch.');
  }
  final platform = customerDevicePlatformFromWire(
    _requiredString(payload, 'platform'),
  );
  final locale = _requiredString(payload, 'locale');
  if (!customerDeviceSupportedLocales.contains(locale)) {
    throw const FormatException('Unsupported customer device locale.');
  }
  final consent = customerDeviceConsentFromWire(
    _requiredString(payload, 'consentStatus'),
  );
  final permission = customerDevicePermissionFromWire(
    _requiredString(payload, 'permissionStatus'),
  );
  final consentedAt = _optionalDate(payload, 'consentedAt');
  final revokedAt = _optionalDate(payload, 'revokedAt');
  final expiresAt = _optionalDate(payload, 'expiresAt');
  final hasToken = payload['hasToken']! as bool;
  final registrationVersion = payload['registrationVersion']! as int;
  if (registrationVersion <= 0 ||
      (consent == CustomerDeviceConsentStatus.granted && consentedAt == null) ||
      (consent == CustomerDeviceConsentStatus.revoked && revokedAt == null) ||
      (hasToken && consent != CustomerDeviceConsentStatus.granted) ||
      (hasToken != (expiresAt != null))) {
    throw const FormatException('Inconsistent customer device response.');
  }
  return CustomerDeviceSnapshot(
    deviceId: deviceId,
    installationId: installationId,
    platform: platform,
    locale: locale,
    consentStatus: consent,
    permissionStatus: permission,
    hasToken: hasToken,
    consentedAt: consentedAt,
    revokedAt: revokedAt,
    lastSeenAt: _requiredDate(payload, 'lastSeenAt'),
    expiresAt: expiresAt,
    registrationVersion: registrationVersion,
    idempotent: payload['idempotent']! as bool,
  );
}

void _throwRpcFailure(Map<String, Object?> payload) {
  if (_isMinimalStatus(payload, 'invalid')) {
    throw const CustomerDeviceRepositoryException(
      CustomerDeviceFailureKind.invalidInput,
    );
  }
  if (_isMinimalStatus(payload, 'idempotency_conflict')) {
    throw const CustomerDeviceRepositoryException(
      CustomerDeviceFailureKind.conflict,
    );
  }
}

bool _isMinimalStatus(Map<String, Object?> payload, String status) {
  return payload.length == 2 &&
      payload['apiVersion'] == 'customer-device.v1' &&
      payload['status'] == status;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a customer device object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw const FormatException('Invalid customer device string.');
  }
  return value;
}

DateTime _requiredDate(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String) {
    throw const FormatException('Invalid customer device timestamp.');
  }
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalDate(Map<String, Object?> payload, String key) {
  return payload[key] == null ? null : _requiredDate(payload, key);
}

void _requireUuidInput(String value) {
  if (!isCustomerDeviceUuid(value)) {
    throw const CustomerDeviceRepositoryException(
      CustomerDeviceFailureKind.invalidInput,
    );
  }
}

CustomerDeviceFailureKind _postgrestFailure(String? code) {
  return switch (code) {
    '28000' || '42501' || 'PGRST301' => CustomerDeviceFailureKind.unauthorized,
    '22023' ||
    '23502' ||
    '23514' ||
    'PGRST116' => CustomerDeviceFailureKind.invalidInput,
    '23505' => CustomerDeviceFailureKind.conflict,
    _ => CustomerDeviceFailureKind.unavailable,
  };
}
