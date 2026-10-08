import 'dart:async';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'customer_account_test_support.dart';

void main() {
  testWidgets(
    'review: pending manual payload remains exact when editor receives geocoded initial',
    (tester) async {
      final repo = FakeCustomerAccountRepository(addresses: []);
      final container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(
            AuthenticatedCustomer.fromUntrustedIdentity(
              subjectId: testCustomerSubject,
              email: 'review@example.invalid',
              metadata: const {},
            ),
          ),
          customerAccountRepositoryProvider.overrideWithValue(repo),
          customerAccountShopSlugProvider.overrideWithValue('test-shop'),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: CustomerAccountPanel(authDisplayName: 'Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      repo.addressResponseError = const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.offline,
      );
      final original = testCustomerAddress().toDraft();
      expect(original.latitude, isNull);
      expect(await controller.createAddress(original), isNull);
      repo.addressResponseError = null;
      await tester.pumpAndSettle();
      unawaited(
        showCustomerAddressEditor(
          tester.element(find.byType(CustomerAccountPanel)),
          initial: const CustomerAddressEditorInitial(
            latitude: -33.4,
            longitude: -70.6,
            locationSource: CustomerAddressLocationSource.search,
            locationAccuracyMeters: 10,
          ),
          onSave: (draft) async => await controller.createAddress(draft) != null
              ? null
              : container.read(customerAccountControllerProvider).failure,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pumpAndSettle();
      expect(
        repo.reconcileCalls,
        1,
        reason:
            'Unrelated initial geocoding cannot alter the pending payload during verification',
      );
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(repo.createAddressCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
