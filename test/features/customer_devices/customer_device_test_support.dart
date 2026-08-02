import 'dart:async';

import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_repository.dart';

const testDeviceOwner = '00000000-0000-4000-8000-000000022001';
const testSecondDeviceOwner = '00000000-0000-4000-8000-000000022002';
const testInstallationId = '22000000-0000-4000-8000-000000000001';
const testDeviceId = '22000000-0000-4000-8000-000000000002';
const testDeviceKey = '22000000-0000-4000-8000-000000000003';
const testSecondDeviceKey = '22000000-0000-4000-8000-000000000004';
const testPushToken = 'push-token-0123456789-abcdefghijklmnop';
final testDeviceTimestamp = DateTime.utc(2026, 8, 2, 20);

CustomerDeviceLocalRecord testLocalDeviceRecord({
  String? ownerSubjectId,
  CustomerDeviceConsentStatus consent =
      CustomerDeviceConsentStatus.notRequested,
  CustomerDevicePendingOperation? pending,
}) {
  return CustomerDeviceLocalRecord(
    installationId: testInstallationId,
    decisionOwnerSubjectId: ownerSubjectId,
    consentStatus: consent,
    pendingOperation: pending,
  );
}

CustomerDeviceSnapshot testDeviceSnapshot({
  CustomerDeviceConsentStatus consent = CustomerDeviceConsentStatus.granted,
  CustomerDevicePermissionStatus permission =
      CustomerDevicePermissionStatus.authorized,
  bool hasToken = true,
  bool idempotent = false,
  String locale = 'es-CL',
}) {
  return CustomerDeviceSnapshot(
    deviceId: testDeviceId,
    installationId: testInstallationId,
    platform: CustomerDevicePlatform.android,
    locale: locale,
    consentStatus: consent,
    permissionStatus: permission,
    hasToken: hasToken,
    consentedAt: consent == CustomerDeviceConsentStatus.granted
        ? testDeviceTimestamp
        : null,
    revokedAt: consent == CustomerDeviceConsentStatus.revoked
        ? testDeviceTimestamp
        : null,
    lastSeenAt: testDeviceTimestamp,
    expiresAt: hasToken
        ? testDeviceTimestamp.add(const Duration(days: 90))
        : null,
    registrationVersion: 1,
    idempotent: idempotent,
  );
}

final class MemoryCustomerDeviceStore implements CustomerDeviceLocalStore {
  MemoryCustomerDeviceStore([CustomerDeviceLocalRecord? initial])
    : record = initial ?? testLocalDeviceRecord();

  CustomerDeviceLocalRecord record;
  Object? loadError;
  Object? saveError;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<CustomerDeviceLocalRecord> loadOrCreate() async {
    loadCalls++;
    if (loadError case final error?) {
      throw error;
    }
    return record;
  }

  @override
  Future<void> save(CustomerDeviceLocalRecord next) async {
    saveCalls++;
    if (saveError case final error?) {
      throw error;
    }
    record = next;
  }
}

final class FakeCustomerDeviceRepository implements CustomerDeviceRepository {
  FakeCustomerDeviceRepository({List<String>? events})
    : events = events ?? <String>[];

  CustomerDeviceSnapshot? statusResult;
  Object? statusError;
  Object? registerError;
  Object? revokeError;
  Completer<void>? registerBarrier;
  Completer<void>? revokeBarrier;
  int statusCalls = 0;
  int registerCalls = 0;
  int revokeCalls = 0;
  final List<CustomerDeviceRegistrationRequest> registrations = [];
  final List<String> revokeKeys = [];
  final List<String> events;

  @override
  Future<CustomerDeviceSnapshot?> status(String installationId) async {
    statusCalls++;
    if (statusError case final error?) {
      throw error;
    }
    return statusResult;
  }

  @override
  Future<CustomerDeviceSnapshot> register(
    CustomerDeviceRegistrationRequest request,
  ) async {
    registerCalls++;
    registrations.add(request);
    events.add('server-register');
    await registerBarrier?.future;
    if (registerError case final error?) {
      throw error;
    }
    return testDeviceSnapshot(
      consent: request.consentStatus,
      permission: request.permissionStatus,
      hasToken: request.pushToken != null,
      locale: request.locale,
    );
  }

  @override
  Future<CustomerDeviceSnapshot?> revoke({
    required String installationId,
    required String idempotencyKey,
  }) async {
    revokeCalls++;
    revokeKeys.add(idempotencyKey);
    events.add('server-revoke');
    await revokeBarrier?.future;
    if (revokeError case final error?) {
      throw error;
    }
    return statusResult == null
        ? null
        : testDeviceSnapshot(
            consent: CustomerDeviceConsentStatus.revoked,
            permission: statusResult!.permissionStatus,
            hasToken: false,
          );
  }
}

final class FakePushTokenProvider implements CustomerPushTokenProvider {
  FakePushTokenProvider({
    this.availability = CustomerPushProviderAvailability.configured,
    this.permission = CustomerDevicePermissionStatus.authorized,
    this.token = testPushToken,
    this.platform = CustomerDevicePlatform.android,
    this.events,
  });

  CustomerPushProviderAvailability availability;
  CustomerDevicePermissionStatus permission;
  String? token;
  @override
  CustomerDevicePlatform platform;
  final List<String>? events;
  Object? currentError;
  Object? requestError;
  Object? revokeError;
  int currentCalls = 0;
  int requestCalls = 0;
  int revokeCalls = 0;
  final StreamController<String> _tokens = StreamController.broadcast();

  @override
  Stream<String> get tokenChanges => _tokens.stream;

  @override
  Future<CustomerPushCapability> currentCapability() async {
    currentCalls++;
    if (currentError case final error?) {
      throw error;
    }
    return CustomerPushCapability(
      availability: availability,
      permission: permission,
      token: token,
    );
  }

  @override
  Future<CustomerPushCapability> requestAuthorization() async {
    requestCalls++;
    if (requestError case final error?) {
      throw error;
    }
    return CustomerPushCapability(
      availability: availability,
      permission: permission,
      token: token,
    );
  }

  @override
  Future<void> revokeLocalToken() async {
    revokeCalls++;
    events?.add('local-revoke');
    if (revokeError case final error?) {
      throw error;
    }
    token = null;
  }

  void emitToken(String value) => _tokens.add(value);

  Future<void> dispose() => _tokens.close();
}
