import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_failure.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/checkout/presentation/checkout_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/checkout/checkout_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tap reali, timeout idempotente, repricing e conferma server-side',
    (tester) async {
      const priceChange = CheckoutQuoteChange(
        publicationId: checkoutTestPublication,
        type: CheckoutChangeType.priceChanged,
        previousPriceClp: 1300,
        currentPriceClp: 1200,
      );
      final changedQuote = checkoutTestQuoteSnapshot(
        status: CheckoutQuoteStatus.requiresReview,
        requiresReview: true,
        changes: const [priceChange],
      );
      final repository = FakeCheckoutRepository()
        ..createOutcomes.addAll([
          const CheckoutRepositoryException(CheckoutFailureKind.timeout),
          checkoutTestResponse(
            status: CheckoutRemoteStatus.requiresReview,
            quote: changedQuote,
          ),
        ])
        ..confirmOutcomes.add(
          checkoutTestResponse(
            status: CheckoutRemoteStatus.confirmed,
            quote: checkoutTestQuoteSnapshot(
              status: CheckoutQuoteStatus.confirmed,
            ),
          ),
        )
        ..orderOutcomes.addAll([
          const CheckoutRepositoryException(CheckoutFailureKind.timeout),
          checkoutTestOrderResponse(
            order: checkoutTestOrderSnapshot(idempotent: true),
            idempotent: true,
          ),
        ]);
      final store = MemoryCheckoutDraftStore();

      await tester.pumpWidget(_buildApp(repository, store));
      await tester.pumpAndSettle();
      await _tap(tester, const ValueKey('checkout-mode-pickup'));
      await _tap(tester, const ValueKey('checkout-next-mode'));
      await _tap(tester, const ValueKey('checkout-pickup-$checkoutTestPoint'));
      await _tap(tester, const ValueKey('checkout-next-destination'));
      await _tap(
        tester,
        const ValueKey('checkout-slot-$checkoutTestPickupSlot'),
      );
      await _tap(tester, const ValueKey('checkout-next-slot'));
      await _tap(tester, const ValueKey('checkout-create-quote'));

      expect(
        find.byKey(const ValueKey('checkout-failure-banner')),
        findsOneWidget,
      );
      expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      await _tap(tester, const ValueKey('storefront-status-action'));

      expect(
        find.byKey(const ValueKey('checkout-authoritative-total')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'checkout-change-$checkoutTestPublication-priceChanged',
          ),
        ),
        findsOneWidget,
      );
      expect(
        repository.createRequests
            .map((request) => request.idempotencyKey)
            .toSet(),
        {checkoutTestKey},
      );
      expect(
        repository.createRequests.map((request) => request.cartVersion),
        everyElement(7),
      );

      await _tap(tester, const ValueKey('checkout-confirm-quote'));
      expect(repository.confirmRequests, hasLength(1));
      expect(repository.confirmRequests.single.key, checkoutTestKey);
      expect(find.text('Resumen confirmado por la tienda.'), findsWidgets);
      expect(find.textContaining('source_product_id'), findsNothing);
      expect(find.textContaining(checkoutTestPublication), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, const ValueKey('checkout-create-order'));
      expect(
        store.draft?.pendingOperation?.kind,
        CheckoutPendingOperationKind.order,
      );
      expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      await _tap(tester, const ValueKey('storefront-status-action'));

      expect(
        find.byKey(const ValueKey('checkout-order-receipt')),
        findsOneWidget,
      );
      expect(find.text(checkoutTestOrderCode), findsOneWidget);
      expect(repository.orderRequests, hasLength(2));
      expect(repository.orderRequests.map((request) => request.key).toSet(), {
        checkoutTestKey,
      });
      expect(store.draft?.orderId, checkoutTestOrder);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      binding.reportData = <String, Object?>{
        'realWidgetTaps': 'PASS',
        'fiveStepFlow': 'PASS',
        'serverAuthoritativePricing': 'PASS',
        'ambiguousTimeoutRetry': 'PASS',
        'sameIdempotencyKey': 'PASS',
        'explicitPriceChangeAcceptance': 'PASS',
        'atomicOrderReceipt': 'PASS',
        'ambiguousOrderRetry': 'PASS',
        'sameOrderIdempotencyKey': 'PASS',
        'internalIdentifiers': 'absent',
        'processAlive': 'PASS',
      };
    },
  );
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) break;
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _buildApp(
  FakeCheckoutRepository repository,
  MemoryCheckoutDraftStore store,
) {
  final identity = AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: checkoutTestOwner,
    email: 'checkout-integration@example.invalid',
    metadata: const {'name': 'Checkout Integration'},
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(_config()),
      customerAccountIdentityProvider.overrideWithValue(identity),
      checkoutCartStateProvider.overrideWithValue(
        CartState(
          status: CartViewStatus.ready,
          isAuthenticated: true,
          snapshot: checkoutTestCart(),
        ),
      ),
      checkoutAccountStateProvider.overrideWithValue(
        CustomerAccountState(
          status: CustomerAccountStatus.ready,
          snapshot: CustomerAccountSnapshot(
            profile: null,
            addresses: [checkoutTestCustomerAddress()],
            deletionRequest: null,
            loadedAt: checkoutTestNow,
          ),
        ),
      ),
      checkoutCartRefreshProvider.overrideWithValue(() async {}),
      checkoutRepositoryProvider.overrideWithValue(repository),
      checkoutDraftStoreProvider.overrideWithValue(store),
      checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        () => checkoutTestKey,
      ),
    ],
    child: MaterialApp(
      locale: const Locale('es', 'CL'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const CheckoutScreen(),
    ),
  );
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);
