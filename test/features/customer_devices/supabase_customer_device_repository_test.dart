import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/features/customer_devices/data/supabase_customer_device_repository.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_failure.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_device_test_support.dart';

void main() {
  late _FakePort port;
  late SupabaseCustomerDeviceRepository repository;

  setUp(() {
    port = _FakePort();
    repository = SupabaseCustomerDeviceRepository(port: port);
  });

  test(
    'register invia contratto esatto e accetta payload allowlisted',
    () async {
      port.response = _payload();

      final result = await repository.register(_request());

      expect(port.function, 'customer_register_device_v1');
      expect(port.parameters, {
        'p_installation_id': testInstallationId,
        'p_platform': 'android',
        'p_locale': 'es-CL',
        'p_consent_status': 'granted',
        'p_permission_status': 'authorized',
        'p_push_token': testPushToken,
        'p_idempotency_key': testDeviceKey,
      });
      expect(result.installationId, testInstallationId);
      expect(result.hasToken, isTrue);
      expect(result.registrationVersion, 2);
    },
  );

  test('response con token o metadata interna è rifiutata', () async {
    port.response = {..._payload(), 'pushToken': testPushToken};

    await expectLater(
      repository.register(_request()),
      throwsA(
        isA<CustomerDeviceRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerDeviceFailureKind.unexpected,
        ),
      ),
    );
  });

  test('status not_found è assenza confermata e non errore', () async {
    port.response = {'apiVersion': 'customer-device.v1', 'status': 'not_found'};

    expect(await repository.status(testInstallationId), isNull);
    expect(port.parameters, {'p_installation_id': testInstallationId});
  });

  test('revoke usa idempotency key e accetta not_found', () async {
    port.response = {'apiVersion': 'customer-device.v1', 'status': 'not_found'};

    expect(
      await repository.revoke(
        installationId: testInstallationId,
        idempotencyKey: testDeviceKey,
      ),
      isNull,
    );
    expect(port.function, 'customer_revoke_device_v1');
    expect(port.parameters, {
      'p_installation_id': testInstallationId,
      'p_idempotency_key': testDeviceKey,
    });
  });

  test('invalid e idempotency_conflict sono failure tipizzate', () async {
    for (final entry in const {
      'invalid': CustomerDeviceFailureKind.invalidInput,
      'idempotency_conflict': CustomerDeviceFailureKind.conflict,
    }.entries) {
      port.response = {'apiVersion': 'customer-device.v1', 'status': entry.key};
      await expectLater(
        repository.register(_request()),
        throwsA(
          isA<CustomerDeviceRepositoryException>().having(
            (error) => error.kind,
            'kind',
            entry.value,
          ),
        ),
      );
    }
  });

  test('offline e timeout non espongono dettaglio di trasporto', () async {
    port.error = const SocketException('private-network-detail');
    await expectLater(
      repository.status(testInstallationId),
      throwsA(
        isA<CustomerDeviceRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerDeviceFailureKind.offline,
        ),
      ),
    );

    port.error = null;
    port.barrier = Completer<void>();
    repository = SupabaseCustomerDeviceRepository(
      port: port,
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      repository.status(testInstallationId),
      throwsA(
        isA<CustomerDeviceRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerDeviceFailureKind.timeout,
        ),
      ),
    );
  });

  test('timestamp e lifecycle incoerenti falliscono chiusi', () async {
    port.response = {..._payload(), 'consentedAt': null};

    await expectLater(
      repository.status(testInstallationId),
      throwsA(isA<CustomerDeviceRepositoryException>()),
    );
  });
}

CustomerDeviceRegistrationRequest _request() {
  return CustomerDeviceRegistrationRequest(
    installationId: testInstallationId,
    platform: CustomerDevicePlatform.android,
    locale: 'es-CL',
    consentStatus: CustomerDeviceConsentStatus.granted,
    permissionStatus: CustomerDevicePermissionStatus.authorized,
    pushToken: testPushToken,
    idempotencyKey: testDeviceKey,
  );
}

Map<String, Object?> _payload() {
  return {
    'apiVersion': 'customer-device.v1',
    'status': 'ok',
    'idempotent': false,
    'deviceId': testDeviceId,
    'installationId': testInstallationId,
    'platform': 'android',
    'locale': 'es-CL',
    'consentStatus': 'granted',
    'permissionStatus': 'authorized',
    'hasToken': true,
    'consentedAt': testDeviceTimestamp.toIso8601String(),
    'revokedAt': null,
    'lastSeenAt': testDeviceTimestamp.toIso8601String(),
    'expiresAt': testDeviceTimestamp
        .add(const Duration(days: 90))
        .toIso8601String(),
    'registrationVersion': 2,
  };
}

final class _FakePort implements CustomerDevicePort {
  Object? response;
  Object? error;
  Completer<void>? barrier;
  String? function;
  Map<String, Object?>? parameters;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.function = function;
    this.parameters = parameters;
    await barrier?.future;
    if (error case final failure?) {
      throw failure;
    }
    return response;
  }
}
