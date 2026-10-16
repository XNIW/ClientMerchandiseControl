import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/address_creation_intent.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'customer_account_test_support.dart';

AuthenticatedCustomer user(String owner) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: owner,
      email: 'review@example.invalid',
      metadata: const {},
    );
void main() {
  for (final transition in ['owner', 'shop', 'A-B-A']) {
    testWidgets('Cambio $transition prima del mount invalida la bozza privata', (
      tester,
    ) async {
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => user(testCustomerSubject),
      );
      final shop = StateProvider<String?>((ref) => 'shop-a');
      final repo = FakeCustomerAccountRepository(addresses: []);
      await repo.addressCreationJournal.write(
        testCustomerSubject,
        AddressCreationIntent(
          id: '21000000-0000-4000-8000-000000000777',
          draft: CustomerAddressDraft(
            label: 'Private pending A',
            recipientName: 'Cliente A',
            addressLine1: 'Private address owner A 123',
            commune: 'Santiago',
            region: 'Metropolitana',
            countryCode: 'CL',
            addressLine2: null,
            postalCode: null,
            deliveryInstructions: null,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          customerAccountShopSlugProvider.overrideWith(
            (ref) => ref.watch(shop),
          ),
          customerAccountRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: CustomerAccountPanel(authDisplayName: 'Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(customerAccountControllerProvider).pendingAddressDraft,
        isNotNull,
      );
      final add = find.byKey(const ValueKey('customer-address-add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      // Intentionally no frame: listener in dialog has not been installed.
      if (transition == 'shop') {
        container.read(shop.notifier).state = 'shop-b';
        container.read(customerAccountShopSlugProvider);
      } else {
        container.read(identity.notifier).state = user(
          '00000000-0000-4000-8000-000000021002',
        );
        container.read(customerAccountIdentityProvider);
        if (transition == 'A-B-A') {
          container.read(identity.notifier).state = user(testCustomerSubject);
          container.read(customerAccountIdentityProvider);
        }
      }
      await tester.pumpAndSettle();
      final dialog = find.byKey(const ValueKey('customer-address-dialog'));
      expect(
        dialog,
        findsNothing,
        reason:
            'An opening intent cannot outlive an intervening owner/shop scope',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
