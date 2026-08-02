const customerDeviceSupportedLocales = <String>{'es-CL', 'it', 'en', 'zh-Hans'};

enum CustomerDevicePlatform { android, ios }

enum CustomerDeviceConsentStatus { notRequested, granted, denied, revoked }

enum CustomerDevicePermissionStatus {
  notDetermined,
  authorized,
  denied,
  provisional,
}

enum CustomerPushProviderAvailability { configured, notConfigured }

enum CustomerDevicePendingOperationKind { register, revoke }

extension CustomerDevicePlatformWire on CustomerDevicePlatform {
  String get wireValue => name;
}

extension CustomerDeviceConsentStatusWire on CustomerDeviceConsentStatus {
  String get wireValue => switch (this) {
    CustomerDeviceConsentStatus.notRequested => 'not_requested',
    CustomerDeviceConsentStatus.granted => 'granted',
    CustomerDeviceConsentStatus.denied => 'denied',
    CustomerDeviceConsentStatus.revoked => 'revoked',
  };
}

extension CustomerDevicePermissionStatusWire on CustomerDevicePermissionStatus {
  String get wireValue => switch (this) {
    CustomerDevicePermissionStatus.notDetermined => 'not_determined',
    CustomerDevicePermissionStatus.authorized => 'authorized',
    CustomerDevicePermissionStatus.denied => 'denied',
    CustomerDevicePermissionStatus.provisional => 'provisional',
  };
}

final class CustomerPushCapability {
  const CustomerPushCapability({
    required this.availability,
    required this.permission,
    required this.token,
  });

  final CustomerPushProviderAvailability availability;
  final CustomerDevicePermissionStatus permission;

  /// Segreto di routing effimero. Non deve essere persistito né loggato.
  final String? token;
}

final class CustomerDeviceRegistrationRequest {
  CustomerDeviceRegistrationRequest({
    required this.installationId,
    required this.platform,
    required this.locale,
    required this.consentStatus,
    required this.permissionStatus,
    required this.pushToken,
    required this.idempotencyKey,
  }) {
    _requireUuid(installationId);
    _requireUuid(idempotencyKey);
    if (!customerDeviceSupportedLocales.contains(locale) ||
        (pushToken != null &&
            consentStatus != CustomerDeviceConsentStatus.granted) ||
        (pushToken != null && !_isValidPushToken(pushToken!))) {
      throw const FormatException('Invalid customer device registration.');
    }
  }

  final String installationId;
  final CustomerDevicePlatform platform;
  final String locale;
  final CustomerDeviceConsentStatus consentStatus;
  final CustomerDevicePermissionStatus permissionStatus;

  /// Segreto di routing destinato esclusivamente alla chiamata RPC corrente.
  final String? pushToken;
  final String idempotencyKey;
}

final class CustomerDeviceSnapshot {
  const CustomerDeviceSnapshot({
    required this.deviceId,
    required this.installationId,
    required this.platform,
    required this.locale,
    required this.consentStatus,
    required this.permissionStatus,
    required this.hasToken,
    required this.consentedAt,
    required this.revokedAt,
    required this.lastSeenAt,
    required this.expiresAt,
    required this.registrationVersion,
    required this.idempotent,
  });

  final String deviceId;
  final String installationId;
  final CustomerDevicePlatform platform;
  final String locale;
  final CustomerDeviceConsentStatus consentStatus;
  final CustomerDevicePermissionStatus permissionStatus;
  final bool hasToken;
  final DateTime? consentedAt;
  final DateTime? revokedAt;
  final DateTime lastSeenAt;
  final DateTime? expiresAt;
  final int registrationVersion;
  final bool idempotent;
}

final class CustomerDevicePendingOperation {
  const CustomerDevicePendingOperation({
    required this.kind,
    required this.ownerSubjectId,
    required this.idempotencyKey,
  });

  final CustomerDevicePendingOperationKind kind;
  final String ownerSubjectId;
  final String idempotencyKey;
}

final class CustomerDeviceLocalRecord {
  const CustomerDeviceLocalRecord({
    required this.installationId,
    required this.decisionOwnerSubjectId,
    required this.consentStatus,
    required this.pendingOperation,
  });

  final String installationId;
  final String? decisionOwnerSubjectId;
  final CustomerDeviceConsentStatus consentStatus;
  final CustomerDevicePendingOperation? pendingOperation;

  CustomerDeviceConsentStatus consentFor(String ownerSubjectId) {
    return decisionOwnerSubjectId == ownerSubjectId
        ? consentStatus
        : CustomerDeviceConsentStatus.notRequested;
  }

  CustomerDeviceLocalRecord copyWith({
    String? decisionOwnerSubjectId,
    CustomerDeviceConsentStatus? consentStatus,
    CustomerDevicePendingOperation? pendingOperation,
    bool clearPendingOperation = false,
  }) {
    return CustomerDeviceLocalRecord(
      installationId: installationId,
      decisionOwnerSubjectId:
          decisionOwnerSubjectId ?? this.decisionOwnerSubjectId,
      consentStatus: consentStatus ?? this.consentStatus,
      pendingOperation: clearPendingOperation
          ? null
          : pendingOperation ?? this.pendingOperation,
    );
  }
}

CustomerDevicePlatform customerDevicePlatformFromWire(String value) {
  return switch (value) {
    'android' => CustomerDevicePlatform.android,
    'ios' => CustomerDevicePlatform.ios,
    _ => throw const FormatException('Unsupported customer device platform.'),
  };
}

CustomerDeviceConsentStatus customerDeviceConsentFromWire(String value) {
  return switch (value) {
    'not_requested' => CustomerDeviceConsentStatus.notRequested,
    'granted' => CustomerDeviceConsentStatus.granted,
    'denied' => CustomerDeviceConsentStatus.denied,
    'revoked' => CustomerDeviceConsentStatus.revoked,
    _ => throw const FormatException('Unsupported customer device consent.'),
  };
}

CustomerDevicePermissionStatus customerDevicePermissionFromWire(String value) {
  return switch (value) {
    'not_determined' => CustomerDevicePermissionStatus.notDetermined,
    'authorized' => CustomerDevicePermissionStatus.authorized,
    'denied' => CustomerDevicePermissionStatus.denied,
    'provisional' => CustomerDevicePermissionStatus.provisional,
    _ => throw const FormatException('Unsupported push permission.'),
  };
}

bool isCustomerDeviceUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

void _requireUuid(String value) {
  if (!isCustomerDeviceUuid(value)) {
    throw const FormatException('Invalid UUID.');
  }
}

bool _isValidPushToken(String value) {
  if (value.length < 16 || value.length > 4096 || value.trim() != value) {
    return false;
  }
  for (final rune in value.runes) {
    if (rune <= 0x20 || (rune >= 0x7f && rune <= 0x9f)) {
      return false;
    }
  }
  return !RegExp(r'\s').hasMatch(value);
}
