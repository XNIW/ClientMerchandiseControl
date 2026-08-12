import 'dart:io' show Platform;

import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/checkout/presentation/checkout_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../checkout_test_support.dart';

void main() {
  late GoRouter router;

  Widget buildApp({
    required FakeCheckoutRepository repository,
    bool authenticated = true,
    Locale locale = const Locale('es', 'CL'),
    ThemeMode themeMode = ThemeMode.light,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    router = GoRouter(
      initialLocation: AppRoutes.checkoutLocation,
      routes: [
        GoRoute(
          path: AppRoutes.checkoutLocation,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: AppRoutes.cartLocation,
          builder: (context, state) =>
              const Scaffold(body: Text('cart-destination')),
        ),
        GoRoute(
          path: AppRoutes.catalogLocation,
          builder: (context, state) =>
              const Scaffold(body: Text('catalog-destination')),
        ),
        GoRoute(
          path: AppRoutes.accountLocation,
          builder: (context, state) =>
              const Scaffold(body: Text('account-destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final cart = checkoutTestCart();
    final identity = authenticated ? _identity() : null;
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config()),
        customerAccountIdentityProvider.overrideWithValue(identity),
        checkoutCartStateProvider.overrideWithValue(
          CartState(
            status: CartViewStatus.ready,
            isAuthenticated: authenticated,
            snapshot: cart,
          ),
        ),
        checkoutAccountStateProvider.overrideWithValue(
          authenticated
              ? CustomerAccountState(
                  status: CustomerAccountStatus.ready,
                  snapshot: CustomerAccountSnapshot(
                    profile: null,
                    addresses: [checkoutTestCustomerAddress()],
                    deletionRequest: null,
                    loadedAt: checkoutTestNow,
                  ),
                )
              : const CustomerAccountState.signedOut(),
        ),
        checkoutCartRefreshProvider.overrideWithValue(() async {}),
        checkoutRepositoryProvider.overrideWithValue(repository),
        checkoutDraftStoreProvider.overrideWithValue(
          MemoryCheckoutDraftStore(),
        ),
        checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
        customerIdempotencyKeyFactoryProvider.overrideWithValue(
          () => checkoutTestKey,
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        routerConfig: router,
      ),
    );
  }

  testWidgets('guest vede gate Google senza perdere il carrello', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(repository: FakeCheckoutRepository(), authenticated: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('checkout-google-sign-in')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('checkout-google-sign-in')))
          .height,
      greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    );
    expect(find.textContaining(checkoutTestPublication), findsNothing);
    await tester.tap(find.byKey(const ValueKey('checkout-continue-browsing')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.cartLocation);
  });

  testWidgets('pickup crea ordine server-side e mostra receipt accessibile', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = FakeCheckoutRepository()
      ..createOutcomes.add(
        checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
      )
      ..confirmOutcomes.add(
        checkoutTestResponse(
          status: CheckoutRemoteStatus.confirmed,
          quote: checkoutTestQuoteSnapshot(
            status: CheckoutQuoteStatus.confirmed,
          ),
        ),
      )
      ..orderOutcomes.add(
        checkoutTestOrderResponse(order: checkoutTestOrderSnapshot()),
      );
    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('checkout-mode-pickup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-next-mode')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('checkout-pickup-$checkoutTestPoint')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-next-destination')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('checkout-slot-$checkoutTestPickupSlot')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-next-slot')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('checkout-payment-payAtPickup')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('checkout-payment-selector')))
          .label,
      contains('Método de pago'),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('checkout-payment-payAtPickup')))
          .height,
      greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    );
    final paymentMethod = find.byKey(
      const ValueKey('checkout-payment-payAtPickup'),
    );
    await tester.ensureVisible(paymentMethod);
    await tester.tap(paymentMethod);
    await tester.pumpAndSettle();

    expect(find.text('Total estimado'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checkout-create-quote')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('checkout-authoritative-total')),
      findsOneWidget,
    );
    expect(find.text(r'$2.400'), findsWidgets);
    expect(find.textContaining('source_product_id'), findsNothing);
    expect(find.textContaining(checkoutTestPublication), findsNothing);

    await tester.tap(find.byKey(const ValueKey('checkout-confirm-quote')));
    await tester.pumpAndSettle();
    expect(find.text('Resumen confirmado por la tienda.'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final createOrder = find.byKey(const ValueKey('checkout-create-order'));
    await tester.ensureVisible(createOrder);
    await tester.tap(createOrder);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('checkout-order-receipt')),
      findsOneWidget,
    );
    expect(find.text(checkoutTestOrderCode), findsOneWidget);
    expect(
      find.byKey(const ValueKey('checkout-order-authoritative-total')),
      findsOneWidget,
    );
    expect(find.textContaining('Pagar al retirar'), findsOneWidget);
    expect(
      find.textContaining('Pendiente al momento de la entrega o retiro'),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('checkout-order-receipt')))
          .label,
      contains(checkoutTestOrderCode),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('checkout-order-continue')))
          .height,
      greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    );
    expect(repository.createRequests, hasLength(1));
    expect(repository.confirmRequests, hasLength(1));
    expect(repository.orderRequests, hasLength(1));
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics descrive progressione e target primario >= 48', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(buildApp(repository: FakeCheckoutRepository()));
      await tester.pumpAndSettle();

      final next = find.byKey(const ValueKey('checkout-next-mode'));
      expect(
        tester.getSize(next).height,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
      final data = tester
          .getSemantics(find.byType(LinearProgressIndicator))
          .getSemanticsData();
      expect(data.label, contains('Paso 1 de 5'));
      expect(data.hasAction(SemanticsAction.tap), isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('320x568 dark e testo 200% non fanno overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      buildApp(
        repository: FakeCheckoutRepository(),
        themeMode: ThemeMode.dark,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('checkout-next-mode')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'golden checkout review 390x844 es-CL light',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildApp(repository: FakeCheckoutRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-mode-pickup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-mode')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('checkout-pickup-$checkoutTestPoint')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-destination')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('checkout-slot-$checkoutTestPickupSlot')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-slot')));
      await tester.pumpAndSettle();
      final paymentMethod = find.byKey(
        const ValueKey('checkout-payment-payAtPickup'),
      );
      await tester.ensureVisible(paymentMethod);
      await tester.tap(paymentMethod);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CheckoutScreen),
        matchesGoldenFile(
          Platform.isLinux
              ? 'goldens/checkout_review_es_cl_linux.png'
              : 'goldens/checkout_review_es_cl.png',
        ),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('es-CL, it, en e zh-Hans renderizzano senza fallback rotto', (
    tester,
  ) async {
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.pumpWidget(
        buildApp(repository: FakeCheckoutRepository(), locale: locale),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-mode-pickup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-mode')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('checkout-pickup-$checkoutTestPoint')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-destination')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('checkout-slot-$checkoutTestPickupSlot')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkout-next-slot')));
      await tester.pumpAndSettle();

      final selector = find.byKey(const ValueKey('checkout-payment-selector'));
      final l10n = AppLocalizations.of(tester.element(selector));
      expect(selector, findsOneWidget);
      expect(find.text(l10n.checkoutPaymentTitle), findsOneWidget);
      expect(find.text(l10n.checkoutPaymentPayAtPickup), findsOneWidget);
      expect(
        find.byKey(const ValueKey('checkout-payment-online-disabled')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: checkoutTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );
