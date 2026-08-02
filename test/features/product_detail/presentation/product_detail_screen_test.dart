import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/home/presentation/storefront_product_card.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../storefront/storefront_test_fixture.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  testWidgets(
    'mostra soltanto dati pubblici, prezzo e fulfillment commerciale',
    (tester) async {
      final repository = _DetailRepository(product: _detailProduct());
      await tester.pumpWidget(_detailApp(repository: repository));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product-detail-content')),
        findsOneWidget,
      );
      expect(find.text('Café público'), findsOneWidget);
      expect(find.text('Descripción cliente'), findsOneWidget);
      expect(find.text('Marca pública'), findsOneWidget);
      expect(find.text(r'$1.200'), findsOneWidget);
      expect(find.text(r'Antes $1.500'), findsOneWidget);
      expect(find.text('20% de descuento'), findsOneWidget);
      expect(find.text('Oferta vigente'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Retiro en tienda'), findsOneWidget);
      expect(find.text('Entrega'), findsOneWidget);
      expect(find.text('Reserva'), findsOneWidget);
      expect(find.textContaining('supplier'), findsNothing);
      expect(find.textContaining('inventory'), findsNothing);
      expect(find.textContaining(_publicationId), findsNothing);
      expect(repository.calls.single, _publicationId);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('usa la variante detail pubblica con decode bounded', (
    tester,
  ) async {
    final repository = _DetailRepository(
      product: _detailProduct(withImage: true),
    );
    await tester.pumpWidget(_detailApp(repository: repository));
    await tester.pump();
    await tester.pump();

    final image = tester.widget<Image>(
      find.byKey(ValueKey('storefront-detail-image-$_publicationId')),
    );
    final resized = image.image as ResizeImage;
    final network = resized.imageProvider as NetworkImage;
    expect(network.url, contains('/storefront-product-images/'));
    expect(network.url, endsWith('/detail.webp'));
    expect(resized.width, 1440);
    expect(network.url, isNot(contains('inventory')));

    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey('storefront-detail-image-placeholder-$_publicationId'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('route card apre il dettaglio e back torna alla lista', (
    tester,
  ) async {
    final repository = _DetailRepository(product: _detailProduct());
    final router = GoRouter(
      initialLocation: '/list',
      routes: [
        GoRoute(
          path: '/list',
          builder: (context, state) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: StorefrontProductCard(product: _detailProduct()),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.productPattern,
          builder: (context, state) => ProductDetailScreen(
            publicationId: state.pathParameters['publicationId'] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerApp(repository: repository, router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('open-product-$_publicationId')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.productLocation(_publicationId));
    expect(find.byType(ProductDetailScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/list');
    expect(find.byType(StorefrontProductCard), findsOneWidget);
  });

  testWidgets('ID route invalido è unavailable e non effettua RPC', (
    tester,
  ) async {
    final repository = _DetailRepository(product: _detailProduct());
    await tester.pumpWidget(
      _detailApp(repository: repository, publicationId: '../inventory'),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('product-detail-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('share-product-$_publicationId')),
      findsNothing,
    );
    expect(repository.calls, isEmpty);
  });

  testWidgets('timeout mostra retry e recupera senza dati parziali', (
    tester,
  ) async {
    final repository = _DetailRepository(
      product: _detailProduct(),
      failOnce: const StorefrontFailure(
        StorefrontFailureKind.timeout,
        code: 'request_timeout',
      ),
    );
    await tester.pumpWidget(_detailApp(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-detail-offline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('share-product-$_publicationId')),
      findsNothing,
    );
    expect(find.text('Café público'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('product-detail-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Café público'), findsOneWidget);
    expect(repository.calls, hasLength(2));
  });

  testWidgets('sei availability restano commerciali e localizzate', (
    tester,
  ) async {
    for (final availability in StorefrontAvailability.values) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _detailApp(
          repository: _DetailRepository(
            product: _detailProduct(availability: availability),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product-detail-availability')),
        findsOneWidget,
        reason: availability.name,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              RegExp(r'\b\d+\s+unidades\b').hasMatch(widget.data!),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull, reason: availability.name);
    }
  });

  testWidgets('rifluisce a 200% in compact landscape dark e quattro locale', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.binding.setSurfaceSize(const Size(568, 320));
      await tester.pumpWidget(
        _detailApp(
          repository: _DetailRepository(product: _detailProduct()),
          locale: locale,
          themeMode: ThemeMode.dark,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product-detail-content')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }
  });
}

Widget _detailApp({
  required StorefrontRepository repository,
  String publicationId = _publicationId,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) => ProviderScope(
  overrides: _overrides(repository),
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: ProductDetailScreen(publicationId: publicationId),
  ),
);

Widget _routerApp({
  required StorefrontRepository repository,
  required GoRouter router,
}) => ProviderScope(
  overrides: _overrides(repository),
  child: MaterialApp.router(
    routerConfig: router,
    locale: const Locale('es', 'CL'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
  ),
);

List<Override> _overrides(StorefrontRepository repository) => [
  appConfigProvider.overrideWithValue(
    AppConfig.fromValues(
      appEnvironment: 'staging',
      supabaseUrl: 'https://staging.example.invalid',
      supabasePublishableKey: 'sb_publishable_staging',
      authRedirectUri: AppConfig.allowedAuthRedirectUri,
      googleAuthEnabled: 'false',
      storefrontShopSlug: 'storefront-test',
    ),
  ),
  backendReadinessRepositoryProvider.overrideWithValue(
    const _ReadyRepository(),
  ),
  storefrontRepositoryProvider.overrideWithValue(repository),
  storefrontCacheRepositoryProvider.overrideWithValue(
    const DisabledStorefrontCacheRepository(),
  ),
];

StorefrontProductSummary _detailProduct({
  StorefrontAvailability availability = StorefrontAvailability.available,
  bool withImage = false,
}) => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  name: 'Café público',
  description: 'Descripción cliente',
  brand: 'Marca pública',
  priceClp: 1200,
  compareAtPriceClp: 1500,
  discountBps: 2000,
  promotion: StorefrontPromotion(
    id: '70000000-0000-4000-8000-000000000001',
    name: 'Oferta vigente',
    startsAt: DateTime.utc(2026, 8, 1),
    endsAt: DateTime.utc(2026, 8, 3),
  ),
  featured: true,
  sortRank: 1,
  availability: availability,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: true,
    reservation: true,
  ),
  images: withImage
      ? StorefrontImageSet(
          version: '90000000-0000-4000-8000-000000000001',
          thumb: Uri.parse(
            'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/thumb.webp',
          ),
          card: Uri.parse(
            'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/card.webp',
          ),
          detail: Uri.parse(
            'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/detail.webp',
          ),
          sha256:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        )
      : null,
  catalogVersion: 7,
  publishedAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1, 1),
);

final class _DetailRepository extends HomeOnlyStorefrontRepository {
  _DetailRepository({required this.product, this.failOnce});

  final StorefrontProductSummary product;
  final StorefrontFailure? failOnce;
  final List<String> calls = [];

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) async {
    calls.add(publicationId);
    if (failOnce != null && calls.length == 1) throw failOnce!;
    return product;
  }

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchHome is outside this test');
}

final class _ReadyRepository implements BackendReadinessRepository {
  const _ReadyRepository();

  @override
  BackendReadinessState get initialState => BackendReadinessState.ready;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.ready;
}
