import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_account_failure.dart';
import '../domain/customer_account_models.dart';
import '../domain/customer_account_repository.dart';

abstract interface class CustomerAccountPort {
  Future<Object?> readProfile();

  Future<Object?> readAddresses();

  Future<Object?> readDeletionRequests();

  Future<Object?> insertProfile(Map<String, Object?> values);

  Future<Object?> updateProfile(
    String expectedSubjectId,
    Map<String, Object?> values,
  );

  Future<void> deleteProfile(String expectedSubjectId);

  Future<void> insertAddress(Map<String, Object?> values);

  Future<void> updateAddress(String addressId, Map<String, Object?> values);

  Future<void> deleteAddress(String addressId);

  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerAccountPort implements CustomerAccountPort {
  PlatformCustomerAccountPort(this._client);

  static const _profileColumns =
      'user_id,display_name,locale,privacy_consent_version,'
      'privacy_consented_at,updated_at';
  static const _addressColumns =
      'id,label,recipient_name,address_line_1,address_line_2,commune,region,'
      'postal_code,country_code,delivery_instructions,is_default,updated_at';
  static const _deletionColumns =
      'id,status,requested_at,cancelled_at,processed_at';

  final SupabaseClient _client;

  @override
  Future<Object?> readProfile() {
    return _client
        .from('customer_profiles')
        .select(_profileColumns)
        .maybeSingle();
  }

  @override
  Future<Object?> readAddresses() {
    return _client
        .from('customer_addresses')
        .select(_addressColumns)
        .order('is_default', ascending: false)
        .order('updated_at', ascending: false)
        .order('id')
        .limit(50);
  }

  @override
  Future<Object?> readDeletionRequests() {
    return _client
        .from('customer_account_deletion_requests')
        .select(_deletionColumns)
        .order('updated_at', ascending: false)
        .order('id')
        .limit(10);
  }

  @override
  Future<Object?> insertProfile(Map<String, Object?> values) {
    return _client
        .from('customer_profiles')
        .insert(values)
        .select(_profileColumns)
        .single();
  }

  @override
  Future<Object?> updateProfile(
    String expectedSubjectId,
    Map<String, Object?> values,
  ) {
    return _client
        .from('customer_profiles')
        .update(values)
        .eq('user_id', expectedSubjectId)
        .select(_profileColumns)
        .maybeSingle();
  }

  @override
  Future<void> deleteProfile(String expectedSubjectId) async {
    await _client
        .from('customer_profiles')
        .delete()
        .eq('user_id', expectedSubjectId);
  }

  @override
  Future<void> insertAddress(Map<String, Object?> values) async {
    await _client
        .from('customer_addresses')
        .insert(values)
        .select('id')
        .single();
  }

  @override
  Future<void> updateAddress(
    String addressId,
    Map<String, Object?> values,
  ) async {
    await _client
        .from('customer_addresses')
        .update(values)
        .eq('id', addressId)
        .select('id')
        .single();
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await _client.from('customer_addresses').delete().eq('id', addressId);
  }

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerAccountRepository
    implements CustomerAccountRepository {
  SupabaseCustomerAccountRepository({
    required this._port,
    this.requestTimeout = const Duration(seconds: 12),
  });

  final CustomerAccountPort _port;
  final Duration requestTimeout;

  @override
  Future<CustomerAccountSnapshot> load(String expectedSubjectId) {
    return _guard(() async {
      final responses = await Future.wait<Object?>([
        _port.readProfile(),
        _port.readAddresses(),
        _port.readDeletionRequests(),
      ]);
      final profile = responses[0] == null
          ? null
          : _parseProfile(_map(responses[0]), expectedSubjectId);
      final addresses = _listOfMaps(
        responses[1],
      ).map(_parseAddress).toList(growable: false);
      final requests = _listOfMaps(
        responses[2],
      ).map(_parseDeletionRequest).toList(growable: false);
      final deletionRequest = requests
          .cast<CustomerDeletionRequest?>()
          .firstWhere(
            (request) => request?.isActive ?? false,
            orElse: () => requests.isEmpty ? null : requests.first,
          );
      return CustomerAccountSnapshot(
        profile: profile,
        addresses: addresses,
        deletionRequest: deletionRequest,
        loadedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<void> saveProfile(
    String expectedSubjectId,
    CustomerProfileDraft draft, {
    required bool profileExists,
  }) {
    return _guard(() async {
      _requireUuid(expectedSubjectId);
      final values = <String, Object?>{
        'display_name': draft.displayName,
        'locale': draft.locale,
      };
      if (!profileExists) {
        await _port.insertProfile(values);
        return;
      }
      final updated = await _port.updateProfile(expectedSubjectId, values);
      if (updated == null) {
        await _port.insertProfile(values);
      }
    });
  }

  @override
  Future<void> deleteProfile(String expectedSubjectId) {
    return _guard(() async {
      _requireUuid(expectedSubjectId);
      await _port.deleteProfile(expectedSubjectId);
    });
  }

  @override
  Future<void> createAddress(CustomerAddressDraft draft) {
    return _guard(() => _port.insertAddress(_addressValues(draft)));
  }

  @override
  Future<void> updateAddress(String addressId, CustomerAddressDraft draft) {
    return _guard(() async {
      _requireUuid(addressId);
      await _port.updateAddress(addressId, _addressValues(draft));
    });
  }

  @override
  Future<void> deleteAddress(String addressId) {
    return _guard(() async {
      _requireUuid(addressId);
      await _port.deleteAddress(addressId);
    });
  }

  @override
  Future<void> setDefaultAddress(String addressId) {
    return _guard(() async {
      _requireUuid(addressId);
      final payload = _map(
        await _port.invoke('customer_set_default_address_v1', {
          'p_address_id': addressId,
        }),
      );
      _requireRpcStatus(payload, const {'ok'});
    });
  }

  @override
  Future<void> recordPrivacyConsent({
    required String version,
    required bool accepted,
  }) {
    return _guard(() async {
      if ((accepted &&
              !RegExp(
                r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$',
              ).hasMatch(version)) ||
          (!accepted && version.isNotEmpty)) {
        throw const CustomerAccountRepositoryException(
          CustomerAccountFailureKind.invalidInput,
        );
      }
      final payload = _map(
        await _port.invoke('customer_record_privacy_consent_v1', {
          'p_version': accepted ? version : null,
          'p_accepted': accepted,
        }),
      );
      _requireRpcStatus(payload, const {'ok'});
    });
  }

  @override
  Future<CustomerDataExport> exportData() {
    return _guard(() async {
      final payload = _map(await _port.invoke('customer_data_export_v1', {}));
      return CustomerDataExport.fromUntrusted(payload);
    });
  }

  @override
  Future<void> requestAccountDeletion(String idempotencyKey) {
    return _guard(() async {
      _requireUuid(idempotencyKey);
      final payload = _map(
        await _port.invoke('customer_request_account_deletion_v1', {
          'p_idempotency_key': idempotencyKey,
        }),
      );
      _requireRpcStatus(payload, const {'requested', 'processing'});
    });
  }

  @override
  Future<void> cancelAccountDeletion(String requestId) {
    return _guard(() async {
      _requireUuid(requestId);
      final payload = _map(
        await _port.invoke('customer_cancel_account_deletion_v1', {
          'p_request_id': requestId,
        }),
      );
      _requireRpcStatus(payload, const {'cancelled'});
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CustomerAccountRepositoryException {
      rethrow;
    } on CustomerAccountInputException {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.invalidInput,
      );
    } on TimeoutException {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.timeout,
      );
    } on SocketException {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.offline,
      );
    } on AuthException {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw CustomerAccountRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unexpected,
      );
    } on Object {
      throw const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unavailable,
      );
    }
  }
}

Map<String, Object?> _addressValues(CustomerAddressDraft draft) {
  return <String, Object?>{
    'label': draft.label,
    'recipient_name': draft.recipientName,
    'address_line_1': draft.addressLine1,
    'address_line_2': draft.addressLine2,
    'commune': draft.commune,
    'region': draft.region,
    'postal_code': draft.postalCode,
    'country_code': draft.countryCode,
    'delivery_instructions': draft.deliveryInstructions,
  };
}

CustomerProfile _parseProfile(
  Map<String, Object?> row,
  String expectedSubjectId,
) {
  final userId = _requiredString(row, 'user_id');
  if (userId != expectedSubjectId) {
    throw const FormatException('Customer profile owner mismatch.');
  }
  _requireUuid(userId);
  final locale = _requiredString(row, 'locale');
  if (!customerAccountSupportedLocales.contains(locale)) {
    throw const FormatException('Unsupported customer locale.');
  }
  final draft = CustomerProfileDraft(
    displayName: _optionalString(row, 'display_name'),
    locale: locale,
  );
  final consentVersion = _optionalString(row, 'privacy_consent_version');
  final consentTimestamp = _optionalDate(row, 'privacy_consented_at');
  if ((consentVersion == null) != (consentTimestamp == null)) {
    throw const FormatException('Invalid privacy consent state.');
  }
  return CustomerProfile(
    userId: userId,
    displayName: draft.displayName,
    locale: draft.locale,
    privacyConsentVersion: consentVersion,
    privacyConsentedAt: consentTimestamp,
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

CustomerAddress _parseAddress(Map<String, Object?> row) {
  final draft = CustomerAddressDraft(
    label: _requiredString(row, 'label'),
    recipientName: _requiredString(row, 'recipient_name'),
    addressLine1: _requiredString(row, 'address_line_1'),
    addressLine2: _optionalString(row, 'address_line_2'),
    commune: _requiredString(row, 'commune'),
    region: _requiredString(row, 'region'),
    postalCode: _optionalString(row, 'postal_code'),
    countryCode: _requiredString(row, 'country_code'),
    deliveryInstructions: _optionalString(row, 'delivery_instructions'),
  );
  return CustomerAddress(
    id: _requiredUuid(row, 'id'),
    label: draft.label,
    recipientName: draft.recipientName,
    addressLine1: draft.addressLine1,
    addressLine2: draft.addressLine2,
    commune: draft.commune,
    region: draft.region,
    postalCode: draft.postalCode,
    countryCode: draft.countryCode,
    deliveryInstructions: draft.deliveryInstructions,
    isDefault: _requiredBool(row, 'is_default'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

CustomerDeletionRequest _parseDeletionRequest(Map<String, Object?> row) {
  final status = _requiredString(row, 'status');
  if (!const {
    'requested',
    'cancelled',
    'processing',
    'completed',
    'rejected',
  }.contains(status)) {
    throw const FormatException('Invalid deletion request status.');
  }
  return CustomerDeletionRequest(
    id: _requiredUuid(row, 'id'),
    status: status,
    requestedAt: _requiredDate(row, 'requested_at'),
    cancelledAt: _optionalDate(row, 'cancelled_at'),
    processedAt: _optionalDate(row, 'processed_at'),
  );
}

List<Map<String, Object?>> _listOfMaps(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected a customer row list.');
  }
  return value.map(_map).toList(growable: false);
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a customer object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw const FormatException('Invalid customer string field.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw const FormatException('Invalid optional customer string field.');
  }
  return value;
}

bool _requiredBool(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! bool) {
    throw const FormatException('Invalid customer boolean field.');
  }
  return value;
}

DateTime _requiredDate(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String) {
    throw const FormatException('Invalid customer timestamp.');
  }
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalDate(Map<String, Object?> row, String key) {
  return row[key] == null ? null : _requiredDate(row, key);
}

String _requiredUuid(Map<String, Object?> row, String key) {
  final value = _requiredString(row, key);
  _requireUuid(value);
  return value;
}

void _requireUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw const CustomerAccountRepositoryException(
      CustomerAccountFailureKind.invalidInput,
    );
  }
}

void _requireRpcStatus(
  Map<String, Object?> payload,
  Set<String> allowedStatuses,
) {
  if (payload['apiVersion'] != 'customer.v1' ||
      !allowedStatuses.contains(payload['status'])) {
    throw const CustomerAccountRepositoryException(
      CustomerAccountFailureKind.unavailable,
    );
  }
}

CustomerAccountFailureKind _postgrestFailure(String? code) {
  return switch (code) {
    '28000' || '42501' || 'PGRST301' => CustomerAccountFailureKind.unauthorized,
    '22023' ||
    '23502' ||
    '23514' ||
    'PGRST116' => CustomerAccountFailureKind.invalidInput,
    '23505' => CustomerAccountFailureKind.conflict,
    _ => CustomerAccountFailureKind.unavailable,
  };
}
