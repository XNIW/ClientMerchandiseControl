import 'dart:convert';

const customerAccountSupportedLocales = <String>{
  'es-CL',
  'it',
  'en',
  'zh-Hans',
};

final class CustomerAccountInputException implements Exception {
  const CustomerAccountInputException();

  @override
  String toString() => 'CustomerAccountInputException';
}

final class CustomerProfile {
  const CustomerProfile({
    required this.userId,
    required this.displayName,
    required this.locale,
    required this.privacyConsentVersion,
    required this.privacyConsentedAt,
    required this.updatedAt,
  });

  final String userId;
  final String? displayName;
  final String locale;
  final String? privacyConsentVersion;
  final DateTime? privacyConsentedAt;
  final DateTime updatedAt;

  bool get hasPrivacyConsent =>
      privacyConsentVersion != null && privacyConsentedAt != null;

  @override
  bool operator ==(Object other) {
    return other is CustomerProfile &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.locale == locale &&
        other.privacyConsentVersion == privacyConsentVersion &&
        other.privacyConsentedAt == privacyConsentedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    locale,
    privacyConsentVersion,
    privacyConsentedAt,
    updatedAt,
  );
}

final class CustomerProfileDraft {
  factory CustomerProfileDraft({
    required String? displayName,
    required String locale,
  }) {
    final normalizedName = _optionalSafeText(displayName, maxRunes: 120);
    if (!customerAccountSupportedLocales.contains(locale)) {
      throw const CustomerAccountInputException();
    }
    return CustomerProfileDraft._(displayName: normalizedName, locale: locale);
  }

  const CustomerProfileDraft._({
    required this.displayName,
    required this.locale,
  });

  final String? displayName;
  final String locale;
}

final class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.addressLine1,
    required this.addressLine2,
    required this.commune,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.deliveryInstructions,
    required this.isDefault,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String recipientName;
  final String addressLine1;
  final String? addressLine2;
  final String commune;
  final String region;
  final String? postalCode;
  final String countryCode;
  final String? deliveryInstructions;
  final bool isDefault;
  final DateTime updatedAt;

  CustomerAddressDraft toDraft() {
    return CustomerAddressDraft(
      label: label,
      recipientName: recipientName,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      commune: commune,
      region: region,
      postalCode: postalCode,
      countryCode: countryCode,
      deliveryInstructions: deliveryInstructions,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerAddress &&
        other.id == id &&
        other.label == label &&
        other.recipientName == recipientName &&
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.commune == commune &&
        other.region == region &&
        other.postalCode == postalCode &&
        other.countryCode == countryCode &&
        other.deliveryInstructions == deliveryInstructions &&
        other.isDefault == isDefault &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    recipientName,
    addressLine1,
    addressLine2,
    commune,
    region,
    postalCode,
    countryCode,
    deliveryInstructions,
    isDefault,
    updatedAt,
  );
}

final class CustomerAddressDraft {
  factory CustomerAddressDraft({
    required String label,
    required String recipientName,
    required String addressLine1,
    required String? addressLine2,
    required String commune,
    required String region,
    required String? postalCode,
    required String countryCode,
    required String? deliveryInstructions,
  }) {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedPostalCode = _optionalSafeText(postalCode, maxRunes: 16);
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCountryCode) ||
        (normalizedPostalCode != null &&
            !RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(normalizedPostalCode))) {
      throw const CustomerAccountInputException();
    }
    return CustomerAddressDraft._(
      label: _requiredSafeText(label, maxRunes: 40),
      recipientName: _requiredSafeText(recipientName, maxRunes: 120),
      addressLine1: _requiredSafeText(addressLine1, maxRunes: 200),
      addressLine2: _optionalSafeText(addressLine2, maxRunes: 200),
      commune: _requiredSafeText(commune, maxRunes: 100),
      region: _requiredSafeText(region, maxRunes: 100),
      postalCode: normalizedPostalCode,
      countryCode: normalizedCountryCode,
      deliveryInstructions: _optionalSafeText(
        deliveryInstructions,
        maxRunes: 500,
      ),
    );
  }

  const CustomerAddressDraft._({
    required this.label,
    required this.recipientName,
    required this.addressLine1,
    required this.addressLine2,
    required this.commune,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.deliveryInstructions,
  });

  final String label;
  final String recipientName;
  final String addressLine1;
  final String? addressLine2;
  final String commune;
  final String region;
  final String? postalCode;
  final String countryCode;
  final String? deliveryInstructions;
}

final class CustomerDeletionRequest {
  const CustomerDeletionRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.cancelledAt,
    required this.processedAt,
  });

  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime? cancelledAt;
  final DateTime? processedAt;

  bool get isActive => status == 'requested' || status == 'processing';
  bool get canCancel => status == 'requested';
}

final class CustomerAccountSnapshot {
  CustomerAccountSnapshot({
    required this.profile,
    required List<CustomerAddress> addresses,
    required this.deletionRequest,
    required this.loadedAt,
  }) : addresses = List<CustomerAddress>.unmodifiable(addresses);

  final CustomerProfile? profile;
  final List<CustomerAddress> addresses;
  final CustomerDeletionRequest? deletionRequest;
  final DateTime loadedAt;
}

final class CustomerDataExport {
  factory CustomerDataExport.fromUntrusted(Map<String, Object?> payload) {
    const rootKeys = {
      'apiVersion',
      'generatedAt',
      'profile',
      'addresses',
      'accountDeletionRequests',
    };
    if (payload['apiVersion'] != 'customer.v1' ||
        payload.keys.length != rootKeys.length ||
        payload.keys.any((key) => !rootKeys.contains(key)) ||
        !_isExportTimestamp(payload['generatedAt']) ||
        !_isValidExportProfile(payload['profile']) ||
        !_isValidExportAddresses(payload['addresses']) ||
        !_isValidExportDeletionRequests(payload['accountDeletionRequests']) ||
        _containsForbiddenExportKey(payload)) {
      throw const FormatException('Invalid customer export contract.');
    }
    final json = jsonEncode(payload);
    if (json.length > 256 * 1024) {
      throw const FormatException('Customer export exceeds the safe limit.');
    }
    return CustomerDataExport._(json);
  }

  const CustomerDataExport._(this.json);

  final String json;
}

bool _hasOnlyKeys(Object? value, Set<String> allowed, {bool nullable = false}) {
  if (value == null) {
    return nullable;
  }
  return value is Map &&
      value.keys.length == allowed.length &&
      value.keys.every((key) => key is String && allowed.contains(key));
}

bool _isValidExportProfile(Object? value) {
  if (value == null) {
    return true;
  }
  const keys = {
    'userId',
    'displayName',
    'locale',
    'privacyConsentVersion',
    'privacyConsentedAt',
    'createdAt',
    'updatedAt',
  };
  if (!_hasOnlyKeys(value, keys)) {
    return false;
  }
  final row = Map<String, Object?>.from(value as Map);
  final displayName = row['displayName'];
  final locale = row['locale'];
  final consentVersion = row['privacyConsentVersion'];
  final consentTimestamp = row['privacyConsentedAt'];
  if (!_isExportUuid(row['userId']) ||
      displayName != null && displayName is! String ||
      locale is! String ||
      consentVersion != null && consentVersion is! String ||
      (consentVersion == null) != (consentTimestamp == null) ||
      consentVersion is String &&
          !RegExp(
            r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$',
          ).hasMatch(consentVersion) ||
      !_isExportTimestamp(consentTimestamp, nullable: true) ||
      !_isExportTimestamp(row['createdAt']) ||
      !_isExportTimestamp(row['updatedAt'])) {
    return false;
  }
  try {
    CustomerProfileDraft(displayName: displayName as String?, locale: locale);
  } on CustomerAccountInputException {
    return false;
  }
  return true;
}

bool _isValidExportAddresses(Object? value) {
  const keys = {
    'id',
    'label',
    'recipientName',
    'addressLine1',
    'addressLine2',
    'commune',
    'region',
    'postalCode',
    'countryCode',
    'deliveryInstructions',
    'isDefault',
    'createdAt',
    'updatedAt',
  };
  if (value is! List || value.length > 1000) {
    return false;
  }
  for (final item in value) {
    if (!_hasOnlyKeys(item, keys)) {
      return false;
    }
    final row = Map<String, Object?>.from(item as Map);
    final label = row['label'];
    final recipientName = row['recipientName'];
    final addressLine1 = row['addressLine1'];
    final addressLine2 = row['addressLine2'];
    final commune = row['commune'];
    final region = row['region'];
    final postalCode = row['postalCode'];
    final countryCode = row['countryCode'];
    final instructions = row['deliveryInstructions'];
    if (!_isExportUuid(row['id']) ||
        label is! String ||
        recipientName is! String ||
        addressLine1 is! String ||
        addressLine2 != null && addressLine2 is! String ||
        commune is! String ||
        region is! String ||
        postalCode != null && postalCode is! String ||
        countryCode is! String ||
        instructions != null && instructions is! String ||
        row['isDefault'] is! bool ||
        !_isExportTimestamp(row['createdAt']) ||
        !_isExportTimestamp(row['updatedAt'])) {
      return false;
    }
    try {
      CustomerAddressDraft(
        label: label,
        recipientName: recipientName,
        addressLine1: addressLine1,
        addressLine2: addressLine2 as String?,
        commune: commune,
        region: region,
        postalCode: postalCode as String?,
        countryCode: countryCode,
        deliveryInstructions: instructions as String?,
      );
    } on CustomerAccountInputException {
      return false;
    }
  }
  return true;
}

bool _isValidExportDeletionRequests(Object? value) {
  const keys = {
    'requestId',
    'status',
    'requestedAt',
    'cancelledAt',
    'processedAt',
    'updatedAt',
  };
  const statuses = {
    'requested',
    'cancelled',
    'processing',
    'completed',
    'rejected',
  };
  if (value is! List || value.length > 1000) {
    return false;
  }
  for (final item in value) {
    if (!_hasOnlyKeys(item, keys)) {
      return false;
    }
    final row = Map<String, Object?>.from(item as Map);
    if (!_isExportUuid(row['requestId']) ||
        row['status'] is! String ||
        !statuses.contains(row['status']) ||
        !_isExportTimestamp(row['requestedAt']) ||
        !_isExportTimestamp(row['cancelledAt'], nullable: true) ||
        !_isExportTimestamp(row['processedAt'], nullable: true) ||
        !_isExportTimestamp(row['updatedAt'])) {
      return false;
    }
  }
  return true;
}

bool _isExportUuid(Object? value) {
  return value is String &&
      RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);
}

bool _isExportTimestamp(Object? value, {bool nullable = false}) {
  if (value == null) {
    return nullable;
  }
  return value is String &&
      RegExp(r'(?:Z|[+-][0-9]{2}:[0-9]{2})$').hasMatch(value) &&
      DateTime.tryParse(value) != null;
}

String _requiredSafeText(String value, {required int maxRunes}) {
  final normalized = _normalizeText(value);
  if (normalized.isEmpty || normalized.runes.length > maxRunes) {
    throw const CustomerAccountInputException();
  }
  return normalized;
}

String? _optionalSafeText(String? value, {required int maxRunes}) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return _requiredSafeText(value, maxRunes: maxRunes);
}

String _normalizeText(String value) {
  for (final rune in value.runes) {
    final isControl = rune < 0x20 || (rune >= 0x7f && rune <= 0x9f);
    final isBidiControl =
        rune == 0x061c ||
        (rune >= 0x200e && rune <= 0x200f) ||
        (rune >= 0x202a && rune <= 0x202e) ||
        (rune >= 0x2066 && rune <= 0x2069);
    if (isControl || isBidiControl) {
      throw const CustomerAccountInputException();
    }
  }
  return value.trim().replaceAll(RegExp(r' +'), ' ');
}

bool _containsForbiddenExportKey(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (const {
        'email',
        'password',
        'token',
        'secret',
        'oauth',
        'credential',
        'idempotencykey',
        'sourceproductid',
        'owneruserid',
        'supplierid',
        'purchaseprice',
      }.contains(key.replaceAll('_', ''))) {
        return true;
      }
      if (_containsForbiddenExportKey(entry.value)) {
        return true;
      }
    }
  } else if (value is Iterable) {
    return value.any(_containsForbiddenExportKey);
  }
  return false;
}
