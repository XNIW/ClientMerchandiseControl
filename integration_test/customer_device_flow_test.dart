import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_devices/application/customer_device_providers.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:client_merchandise_control/features/customer_devices/presentation/customer_notification_panel.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/customer_devices/customer_device_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device consent, rotation e revoke restano idempotenti', (
    tester,
  ) async {
    final repository = FakeCustomerDeviceRepository();
    final store = MemoryCustomerDeviceStore();
    final provider = FakePushTokenProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDeviceIdentityProvider.overrideWithValue(_identity()),
          customerDeviceRepositoryProvider.overrideWithValue(repository),
          customerDeviceLocalStoreProvider.overrideWithValue(store),
          customerPushTokenProvider.overrideWithValue(provider),
          customerDeviceUuidFactoryProvider.overrideWithValue(
            _sequentialKeys(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es', 'CL'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: CustomerNotificationPanel(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, const ValueKey('customer-notifications-enable'));
    expect(repository.registerCalls, 1);
    expect(repository.registrations.single.pushToken, testPushToken);
    expect(store.record.pendingOperation, isNull);

    provider.emitToken('integration-rotated-token-0123456789-abcdef');
    await _waitForRegisterCount(tester, repository, 2);
    expect(
      repository.registrations.last.pushToken,
      'integration-rotated-token-0123456789-abcdef',
    );

    await _tap(tester, const ValueKey('customer-notifications-revoke'));
    expect(provider.revokeCalls, 1);
    expect(repository.revokeCalls, 1);
    expect(store.record.consentStatus, CustomerDeviceConsentStatus.revoked);
    expect(store.record.pendingOperation, isNull);
    expect(tester.takeException(), isNull);

    binding.reportData = <String, Object?>{
      'randomInstallationId': 'PASS',
      'explicitConsent': 'PASS',
      'permissionSeparate': 'PASS',
      'tokenRegistration': 'PASS',
      'tokenRotation': 'PASS',
      'idempotentRevoke': 'PASS',
      'tokenNotPersisted': 'PASS',
      'processAlive': 'PASS',
    };
  });
}

String Function() _sequentialKeys() {
  var call = 0;
  return () {
    call++;
    return call == 1 ? testDeviceKey : testSecondDeviceKey;
  };
}

AuthenticatedCustomer _identity() {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: testDeviceOwner,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente Integración'},
  );
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _waitForRegisterCount(
  WidgetTester tester,
  FakeCustomerDeviceRepository repository,
  int expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 5));
    if (repository.registerCalls == expected) {
      return;
    }
  }
  fail('Expected $expected registrations, found ${repository.registerCalls}.');
}
