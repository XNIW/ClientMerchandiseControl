import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/checkout/presentation/checkout_screen.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/commerce_surface_fixtures.dart';
import 'checkout_test_support.dart';

void main() {
  testWidgets(
    'indirizzo manuale ambiguo verificato torna a checkout delivery e riepilogo',
    (tester) async {
      final fixture = Task054VisualFixtures();
      fixture.account.addresses = [];
      final store = MemoryCheckoutDraftStore();
      final router = GoRouter(
        initialLocation: AppRoutes.checkoutLocation,
        routes: [
          GoRoute(
            path: AppRoutes.checkoutLocation,
            builder: (_, _) => const CheckoutScreen(),
          ),
          GoRoute(
            path: AppRoutes.deliveryContextLocation,
            builder: (_, _) => const DeliveryContextScreen(),
          ),
        ],
      );
      Future<void> tapKey(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
      await tester.binding.setSurfaceSize(const Size(320, 568));
      try {
        await tester.pumpWidget(
          fixture.wrap(
            MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(),
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
            additionalOverrides: [
              checkoutCartStateProvider.overrideWithValue(
                CartState(
                  status: CartViewStatus.ready,
                  isAuthenticated: true,
                  snapshot: checkoutTestCart(),
                ),
              ),
              checkoutCartRefreshProvider.overrideWithValue(() async {}),
              checkoutDraftStoreProvider.overrideWithValue(store),
              checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
              customerIdempotencyKeyFactoryProvider.overrideWithValue(
                () => '21000000-0000-4000-8000-000000000778',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tapKey('checkout-mode-delivery');
        await tapKey('checkout-next-mode');
        expect(
          tester.widget<FilledButton>(
            find.byKey(const ValueKey('checkout-next-destination')),
          ).onPressed,
          isNull,
        );
        await tapKey('checkout-manage-addresses');
        expect(router.state.uri.path, AppRoutes.deliveryContextLocation);
        await tapKey('delivery-address-add');
        // Validazione locale prima di qualsiasi richiesta.
        await tapKey('customer-address-submit');
        expect(fixture.account.createAddressAttempts, 0);
        expect(find.byKey(const ValueKey('customer-address-dialog')), findsOneWidget);
        for (final entry in const {
          'label': 'Casa entrega',
          'recipient': 'Cliente sintético',
          'line1': 'Calle manual sintética 456',
          'commune': 'Santiago',
          'region': 'Metropolitana',
        }.entries) {
          final field = find.byKey(ValueKey('customer-address-field-${entry.key}'));
          await tester.ensureVisible(field);
          await tester.enterText(field, entry.value);
        }
        final line1 = find.byKey(const ValueKey('customer-address-field-line1'));
        await tester.showKeyboard(line1);
        expect(tester.testTextInput.isVisible, isTrue);
        // Il fake conserva l'indirizzo, poi perde la risposta.
        fixture.account.addressResponseError = const CustomerAccountRepositoryException(
          CustomerAccountFailureKind.offline,
        );
        await tapKey('customer-address-submit');
        expect(fixture.account.createAddressCalls, 1);
        expect(fixture.delivery.selected, isNull);
        expect(tester.widget<TextFormField>(line1).controller!.text, 'Calle manual sintética 456');
        final l10n = AppLocalizations.of(tester.element(line1));
        expect(find.widgetWithText(FilledButton, l10n.customerAddressVerify), findsOneWidget);
        fixture.account.addressResponseError = null;
        await tapKey('customer-address-submit');
        expect(fixture.account.createAddressAttempts, 1);
        expect(fixture.account.reconcileCalls, 1);
        expect(fixture.account.addresses, hasLength(1));
        expect(find.byKey(const ValueKey('customer-address-dialog')), findsNothing);
        final created = fixture.account.addresses.single;
        expect(created.locationSource, CustomerAddressLocationSource.manual);
        expect(fixture.delivery.selected?.addressId, created.id);
        final deliveryContext = tester.element(find.byType(DeliveryContextScreen));
        await tester.tap(find.byTooltip(
          MaterialLocalizations.of(deliveryContext).backButtonTooltip,
        ));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.checkoutLocation);
        final container = ProviderScope.containerOf(tester.element(find.byType(CheckoutScreen)));
        final returned = container.read(checkoutControllerProvider);
        expect(returned.step, CheckoutStep.destination);
        expect(returned.selection.mode, CheckoutFulfillmentMode.delivery);
        expect(returned.selectedAddress?.id, created.id);
        expect(returned.hasValidDeliveryContext, isTrue);
        expect(returned.deliveryContext?.deliveryZoneId, checkoutTestZone);
        await tapKey('checkout-next-destination');
        await tapKey('checkout-slot-$checkoutTestDeliverySlot');
        await tapKey('checkout-next-slot');
        await tapKey('checkout-payment-cashOnDelivery');
        final summary = container.read(checkoutControllerProvider);
        expect(summary.step, CheckoutStep.review);
        expect(summary.selection.addressId, created.id);
        expect(summary.selection.slotId, checkoutTestDeliverySlot);
        expect(summary.selection.paymentMethod, CheckoutPaymentMethod.cashOnDelivery);
        expect(find.text('${created.label} · ${created.commune}'), findsOneWidget);
        expect(find.text(summary.selectedSlot!.label), findsOneWidget);
        expect(store.draft?.selection.addressId, created.id);
        // Riepilogo locale: nessuna conferma server inventata.
        expect(summary.quote, isNull);
        expect(fixture.checkout.createRequests, isEmpty);
        expect(fixture.checkout.orderRequests, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        router.dispose();
        await tester.binding.setSurfaceSize(null);
      }
    },
  );
}
