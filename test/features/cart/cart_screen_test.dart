import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/presentation/storefront_product_metadata.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  late GoRouter router;

  Widget buildApp({
    required _FakeGuestCartStore store,
    Locale locale = const Locale('es', 'CL'),
    ThemeMode themeMode = ThemeMode.light,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    router = GoRouter(
      initialLocation: AppRoutes.cartLocation,
      routes: [
        GoRoute(
          path: AppRoutes.cartLocation,
          builder: (context, state) => const Scaffold(body: CartScreen()),
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
        GoRoute(
          path: AppRoutes.checkoutLocation,
          builder: (context, state) =>
              const Scaffold(body: Text('checkout-destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config()),
        customerAccountIdentityProvider.overrideWithValue(null),
        guestCartStoreProvider.overrideWithValue(store),
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

  testWidgets('stato vuoto onesto raggiunge il catalogo', (tester) async {
    await tester.pumpWidget(buildApp(store: _FakeGuestCartStore()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CartScreen));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.cartEmptyTitle), findsOneWidget);
    expect(find.text(l10n.cartEmptyMessage), findsOneWidget);
    expect(find.text(l10n.cartExploreCatalog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cart-explore-catalog')));
    await tester.pumpAndSettle();

    expect(find.text('catalog-destination'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.catalogLocation);
  });

  testWidgets('renderizza snapshot pubblico, subtotal indicativo e controlli', (
    tester,
  ) async {
    final store = _FakeGuestCartStore(snapshot: _cartSnapshot(quantity: 2));
    await tester.pumpWidget(buildApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Café público'), findsOneWidget);
    expect(find.text(r'$1.200'), findsOneWidget);
    expect(find.text(r'$2.400'), findsOneWidget);
    expect(find.text('Estimado'), findsOneWidget);
    expect(
      find.byKey(ValueKey('cart-decrease-$_publicationId')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('cart-increase-$_publicationId')),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('cart-remove-$_publicationId')), findsOneWidget);
    expect(find.textContaining(_publicationId), findsNothing);
    expect(find.textContaining('source_product_id'), findsNothing);
    expect(find.textContaining('supplier'), findsNothing);
  });

  testWidgets('incremento e remove aggiornano lo storage locale', (
    tester,
  ) async {
    final store = _FakeGuestCartStore(snapshot: _cartSnapshot());
    await tester.pumpWidget(buildApp(store: store));
    await tester.pumpAndSettle();

    final increase = find.byKey(ValueKey('cart-increase-$_publicationId'));
    await tester.ensureVisible(increase);
    await tester.pump();
    await tester.tap(increase);
    await tester.pumpAndSettle();
    expect(store.quantityCalls, [2]);
    expect(find.text('Cantidad: 2'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(CartScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ValueKey('cart-remove-$_publicationId')),
    );
    await tester.tap(find.byKey(ValueKey('cart-remove-$_publicationId')));
    await tester.pumpAndSettle();
    expect(store.removeCalls, 1);
    expect(find.text('Tu carrito está vacío'), findsOneWidget);
  });

  testWidgets(
    'CTA guest apre checkout, che governa il gate di autenticazione',
    (tester) async {
      await tester.pumpWidget(
        buildApp(store: _FakeGuestCartStore(snapshot: _cartSnapshot())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();

      expect(find.text('checkout-destination'), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.checkoutLocation);
    },
  );

  testWidgets(
    'navigazione cart checkout rispetta budget e non duplica letture',
    (tester) async {
      final store = _FakeGuestCartStore(snapshot: _cartSnapshot());
      await tester.pumpWidget(buildApp(store: store));
      await tester.pumpAndSettle();

      Future<int> navigateAndReturn() async {
        final readsBeforeCheckout = store.readCalls;
        final stopwatch = Stopwatch()..start();
        await tester.tap(find.byKey(const ValueKey('cart-checkout')));
        await tester.pumpAndSettle();
        stopwatch.stop();
        expect(router.state.uri.path, AppRoutes.checkoutLocation);
        expect(
          store.readCalls,
          readsBeforeCheckout,
          reason: 'la singola navigazione non legge nuovamente il carrello',
        );
        router.go(AppRoutes.cartLocation);
        await tester.pumpAndSettle();
        return stopwatch.elapsedMicroseconds;
      }

      for (var warmup = 0; warmup < 5; warmup++) {
        await navigateAndReturn();
      }
      final samples = <int>[];
      for (var sample = 0; sample < 30; sample++) {
        samples.add(await navigateAndReturn());
      }
      final p50 = _percentileMicros(samples, 0.50);
      final p95 = _percentileMicros(samples, 0.95);
      final p99 = _percentileMicros(samples, 0.99);
      debugPrint(
        'CHECKOUT_NAVIGATION_PERF environment=flutter_test_host '
        'warmup=5 samples=30 p50_us=$p50 p95_us=$p95 p99_us=$p99 '
        'extra_reads_per_navigation=0',
      );
      expect(p95, lessThan(400000));
      expect(tester.takeException(), isNull);
    },
    tags: const ['performance'],
  );

  testWidgets('semantics e target quantità rispettano 48 logical pixel', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildApp(store: _FakeGuestCartStore(snapshot: _cartSnapshot())),
      );
      await tester.pumpAndSettle();

      for (final key in [
        ValueKey('cart-decrease-$_publicationId'),
        ValueKey('cart-increase-$_publicationId'),
        ValueKey('cart-remove-$_publicationId'),
      ]) {
        final finder = find.byKey(key);
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
        );
      }
      final increase = tester
          .getSemantics(find.byKey(ValueKey('cart-increase-$_publicationId')))
          .getSemanticsData();
      expect(increase.label, contains('Aumentar cantidad'));
      expect(increase.hasAction(SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('viewport 320x568, dark e testo 200% non fanno overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      buildApp(
        store: _FakeGuestCartStore(snapshot: _cartSnapshot()),
        themeMode: ThemeMode.dark,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart-checkout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quattro locale renderizzano cart senza eccezioni', (
    tester,
  ) async {
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.pumpWidget(
        buildApp(
          store: _FakeGuestCartStore(snapshot: _cartSnapshot()),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cart-subtotal')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('cart presenta tutti i sei stati commerciali localizzati', (
    tester,
  ) async {
    for (final availability in StorefrontAvailability.values) {
      await tester.pumpWidget(
        buildApp(
          store: _FakeGuestCartStore(
            snapshot: _cartSnapshot(availability: availability),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(CartScreen)));
      expect(
        find.text(storefrontAvailabilityLabel(l10n, availability)),
        findsOneWidget,
        reason: availability.name,
      );
      expect(find.textContaining('stock:'), findsNothing);
      expect(tester.takeException(), isNull, reason: availability.name);
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

CustomerCartSnapshot _cartSnapshot({
  int quantity = 1,
  StorefrontAvailability availability = StorefrontAvailability.available,
}) {
  final unavailable = availability == StorefrontAvailability.unavailable;
  final line = CartLine(
    publicationId: _publicationId,
    publicName: 'Café público',
    quantity: quantity,
    priceClp: 1200,
    snapshotPriceClp: 1200,
    availability: availability,
    status: unavailable ? CartLineStatus.unavailable : CartLineStatus.available,
    changeType: unavailable
        ? CartLineChangeType.unavailable
        : CartLineChangeType.none,
    isGuest: true,
  );
  return CustomerCartSnapshot(
    shopSlug: 'storefront-test',
    version: 0,
    items: [line],
    source: CartSource.guest,
    quoteStatus: CartQuoteStatus.indicative,
    requiresCustomerReview: false,
    subtotalClp: line.lineSubtotalClp,
    idempotent: true,
  );
}

final class _FakeGuestCartStore implements GuestCartStore {
  _FakeGuestCartStore({CustomerCartSnapshot? snapshot})
    : snapshot =
          snapshot ??
          CustomerCartSnapshot.empty(
            shopSlug: 'storefront-test',
            source: CartSource.guest,
          );

  CustomerCartSnapshot snapshot;
  final List<int> quantityCalls = [];
  int removeCalls = 0;
  int readCalls = 0;

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async {
    readCalls++;
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async {
    quantityCalls.add(quantity);
    final line = snapshot.items.single.copyWith(quantity: quantity);
    snapshot = CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: 0,
      items: [line],
      source: CartSource.guest,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: line.lineSubtotalClp,
      idempotent: true,
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async {
    removeCalls++;
    snapshot = CustomerCartSnapshot.empty(
      shopSlug: shopSlug,
      source: CartSource.guest,
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async {
    snapshot = CustomerCartSnapshot.empty(
      shopSlug: shopSlug,
      source: CartSource.guest,
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async => snapshot;

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async => snapshot;
}

int _percentileMicros(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}
