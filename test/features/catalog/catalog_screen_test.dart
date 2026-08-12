import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/home/presentation/storefront_product_card.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra categorie, griglia reale, prezzi CLP e search attiva', (
    tester,
  ) async {
    final storefront = _CatalogRepository();
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    final strings = _l10n(tester);
    final search = tester.widget<SearchBar>(
      find.byKey(const ValueKey('catalog-search')),
    );

    expect(search.enabled, isTrue);
    expect(find.text(strings.catalogFiltersLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-category-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-category-bebidas')),
      findsOneWidget,
    );
    expect(find.text('Producto 1'), findsOneWidget);
    expect(find.text(r'$1.500'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        r'Producto 1, $1.500, Disponible, Retiro en tienda, Entrega',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'storefront-image-placeholder-50000000-0000-4000-8000-000000000001',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('50000000-'), findsNothing);
    expect(storefront.catalogCalls.single.limit, 24);
    expect(storefront.categoryCalls.single.limit, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search resta pinned, filtri progressivi e griglia compact è 2x',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _catalogApp(storefront: _CatalogRepository(paginated: true)),
      );
      await tester.pumpAndSettle();

      final header = tester.widget<SliverPersistentHeader>(
        find.byKey(const ValueKey('catalog-sticky-search-header')),
      );
      final grid = tester.widget<SliverGrid>(
        find.byKey(const ValueKey('catalog-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(header.pinned, isTrue);
      expect(delegate.crossAxisCount, 2);
      expect(find.text('24 productos cargados'), findsOneWidget);
      expect(
        tester
            .widget<Offstage>(
              find.byKey(
                const ValueKey('catalog-filter-panel'),
                skipOffstage: false,
              ),
            )
            .offstage,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('catalog-toggle-filters')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Offstage>(
              find.byKey(
                const ValueKey('catalog-filter-panel'),
                skipOffstage: false,
              ),
            )
            .offstage,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ricerca usa debounce, risultati reali e clear ripristina catalogo',
    (tester) async {
      final storefront = _CatalogRepository();
      await tester.pumpWidget(_catalogApp(storefront: storefront));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('catalog-search')),
        'ca',
      );
      await tester.pump(const Duration(milliseconds: 299));
      expect(storefront.searchCalls, isEmpty);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();

      expect(storefront.searchCalls.single.query, 'ca');
      expect(find.text('Café encontrado'), findsOneWidget);
      expect(find.text('Producto 1'), findsNothing);
      expect(
        find.byKey(const ValueKey('catalog-search-clear')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('catalog-search-clear')));
      await tester.pumpAndSettle();

      expect(find.text('Producto 1'), findsOneWidget);
      expect(storefront.catalogCalls, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filtri e ordinamento sono inoltrati al contratto catalogo', (
    tester,
  ) async {
    final storefront = _CatalogRepository();
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('catalog-toggle-filters')));
    await tester.pumpAndSettle();
    final available = find.byKey(
      const ValueKey('catalog-availability-available'),
    );
    await Scrollable.ensureVisible(
      tester.element(available),
      alignment: 0.5,
      duration: const Duration(milliseconds: 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(available);
    await tester.pumpAndSettle();

    final discounted = find.byKey(const ValueKey('catalog-discounted-only'));
    await tester.ensureVisible(discounted);
    await tester.tap(discounted);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<StorefrontCatalogSort>>(
      find.byType(DropdownButton<StorefrontCatalogSort>),
    );
    dropdown.onChanged!(StorefrontCatalogSort.priceAscending);
    await tester.pumpAndSettle();

    expect(
      storefront.catalogCalls.last.availability,
      StorefrontAvailability.available,
    );
    expect(storefront.catalogCalls.last.discounted, isTrue);
    expect(
      storefront.catalogCalls.last.sort,
      StorefrontCatalogSort.priceAscending,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ricerca compone categoria e disabilita filtri catalog-only', (
    tester,
  ) async {
    final storefront = _CatalogRepository();
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('catalog-toggle-filters')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('catalog-search')), 'te');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-category-te')));
    await tester.pumpAndSettle();

    expect(storefront.searchCalls.last.categorySlug, 'te');
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('catalog-availability-available')),
          )
          .onSelected,
      isNull,
    );
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey('catalog-discounted-only')),
          )
          .onSelected,
      isNull,
    );
    expect(find.text('Té encontrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selezione categoria ricarica e filtra senza risultati stale', (
    tester,
  ) async {
    final storefront = _CatalogRepository();
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('catalog-category-te')));
    await tester.pumpAndSettle();

    expect(storefront.catalogCalls.last.categorySlug, 'te');
    expect(find.text('Té filtrado'), findsOneWidget);
    expect(find.text('Producto 1'), findsNothing);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('catalog-category-te')),
    );
    expect(chip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('immagine card usa URL pubblico bounded e fallback sicuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      _catalogApp(storefront: _CatalogRepository(withImage: true)),
    );
    await tester.pump();
    await tester.pump();

    final image = tester.widget<StorefrontProductImage>(
      find.byType(StorefrontProductImage).first,
    );
    expect(image.uri.toString(), contains('/storefront-product-images/'));
    expect(image.uri.toString(), isNot(contains('inventory')));
    expect(image.cacheWidth, 480);
    expect(image.sha256Digest, hasLength(64));

    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey(
          'storefront-image-placeholder-50000000-0000-4000-8000-000000000001',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll vicino al fondo richiede la pagina keyset successiva', (
    tester,
  ) async {
    final storefront = _CatalogRepository(paginated: true);
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -12000));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CatalogScreen)),
    );
    expect(storefront.catalogCalls, hasLength(2));
    expect(storefront.catalogCalls.last.cursor, _cursor);
    expect(container.read(catalogControllerProvider).items, hasLength(25));
    expect(container.read(catalogControllerProvider).nextCursor, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offline retry è single-flight e attende la readiness condivisa',
    (tester) async {
      final readiness = _ReadinessRepository(
        initialState: BackendReadinessState.offline,
      );
      final storefront = _CatalogRepository();
      await tester.pumpWidget(
        _catalogApp(readiness: readiness, storefront: storefront),
      );
      await tester.pumpAndSettle();

      final retry = find.byKey(const ValueKey('catalog-retry-action'));
      expect(retry, findsOneWidget);
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.tap(retry);
      await tester.pump();

      expect(readiness.calls, 1);
      expect(storefront.catalogCalls, isEmpty);
      expect(find.byKey(const ValueKey('catalog-loading')), findsOneWidget);

      readiness.completeNext(BackendReadinessState.ready);
      await tester.pumpAndSettle();

      expect(storefront.catalogCalls, hasLength(1));
      expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    },
  );

  testWidgets('stati backend non mostrano dati commerciali inventati', (
    tester,
  ) async {
    final cases = <(BackendReadinessState, String, bool)>[
      (BackendReadinessState.unconfigured, 'catalog-empty', false),
      (BackendReadinessState.initializing, 'catalog-loading', false),
      (BackendReadinessState.offline, 'catalog-offline', true),
      (BackendReadinessState.misconfigured, 'catalog-unavailable', false),
      (
        BackendReadinessState.authenticationRequired,
        'catalog-unavailable',
        false,
      ),
      (BackendReadinessState.recoverableError, 'catalog-failure', true),
    ];

    for (final (state, key, retryable) in cases) {
      final storefront = _CatalogRepository();
      await tester.pumpWidget(
        _catalogApp(
          readiness: _ReadinessRepository(initialState: state, canCheck: false),
          storefront: storefront,
        ),
      );
      await tester.pump();

      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: state.name);
      expect(
        find.byKey(const ValueKey('catalog-retry-action')),
        retryable ? findsOneWidget : findsNothing,
        reason: state.name,
      );
      expect(storefront.catalogCalls, isEmpty, reason: state.name);
      expect(find.byType(Image), findsNothing, reason: state.name);
      expect(find.textContaining(r'$'), findsNothing, reason: state.name);
      expect(tester.takeException(), isNull, reason: state.name);
    }
  });

  testWidgets('errore pagina incrementale conserva dati e offre retry', (
    tester,
  ) async {
    final storefront = _CatalogRepository(
      paginated: true,
      failSecondPageOnce: true,
    );
    await tester.pumpWidget(_catalogApp(storefront: storefront));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -12000));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CatalogScreen)),
    );
    expect(container.read(catalogControllerProvider).items, hasLength(24));
    expect(
      find.byKey(const ValueKey('catalog-load-more-error')),
      findsOneWidget,
    );

    final retry = find.byKey(const ValueKey('catalog-load-more-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(container.read(catalogControllerProvider).items, hasLength(25));
    expect(storefront.catalogCalls, hasLength(3));
  });

  testWidgets('reflow a 200% non overflowa in compact e landscape dark', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _catalogApp(
          storefront: _CatalogRepository(),
          themeMode: size.width > size.height
              ? ThemeMode.dark
              : ThemeMode.light,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('IndexedStack conserva la posizione del tab Catalogo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tabCatalogApp(storefront: _CatalogRepository(paginated: true)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final outerScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final before = tester
        .state<ScrollableState>(outerScrollable)
        .position
        .pixels;
    expect(before, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('test-tab-away')));
    await tester.pumpAndSettle();
    expect(find.text('Altro tab'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('test-tab-catalog')));
    await tester.pumpAndSettle();

    final after = tester
        .state<ScrollableState>(outerScrollable)
        .position
        .pixels;
    expect(after, closeTo(before, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalogo resta localizzato in es, it, en e zh-Hans', (
    tester,
  ) async {
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _catalogApp(storefront: _CatalogRepository(), locale: locale),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('catalog-controls-explanation')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }
  });
}

Widget _catalogApp({
  required StorefrontRepository storefront,
  BackendReadinessRepository? readiness,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(_stagingConfig()),
    backendReadinessRepositoryProvider.overrideWithValue(
      readiness ??
          const _ReadinessRepository(initialState: BackendReadinessState.ready),
    ),
    storefrontRepositoryProvider.overrideWithValue(storefront),
    storefrontCacheRepositoryProvider.overrideWithValue(
      const DisabledStorefrontCacheRepository(),
    ),
  ],
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
    home: const Scaffold(body: SafeArea(child: CatalogScreen())),
  ),
);

Widget _tabCatalogApp({required StorefrontRepository storefront}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_stagingConfig()),
        backendReadinessRepositoryProvider.overrideWithValue(
          const _ReadinessRepository(initialState: BackendReadinessState.ready),
        ),
        storefrontRepositoryProvider.overrideWithValue(storefront),
        storefrontCacheRepositoryProvider.overrideWithValue(
          const DisabledStorefrontCacheRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: const _TabHarness(),
      ),
    );

class _TabHarness extends StatefulWidget {
  const _TabHarness();

  @override
  State<_TabHarness> createState() => _TabHarnessState();
}

class _TabHarnessState extends State<_TabHarness> {
  var _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: const [
        SafeArea(child: CatalogScreen()),
        Text('Altro tab'),
      ],
    ),
    bottomNavigationBar: Row(
      children: [
        Expanded(
          child: TextButton(
            key: const ValueKey('test-tab-catalog'),
            onPressed: () => setState(() => _index = 0),
            child: const Text('Catalogo'),
          ),
        ),
        Expanded(
          child: TextButton(
            key: const ValueKey('test-tab-away'),
            onPressed: () => setState(() => _index = 1),
            child: const Text('Altro'),
          ),
        ),
      ],
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CatalogScreen)));

AppConfig _stagingConfig() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);

const _cursor = 'eyJ2IjoxLCJzb3J0IjoiY2F0YWxvZyJ9';

const _categories = [
  StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000002',
    slug: 'te',
    name: 'Té',
    sortRank: 2,
  ),
];

StorefrontProductSummary _product(
  int value, {
  String? name,
  bool withImage = false,
}) {
  final suffix = value.toString().padLeft(12, '0');
  final category = name == 'Té filtrado' ? _categories[1] : _categories[0];
  return StorefrontProductSummary(
    id: '50000000-0000-4000-8000-$suffix',
    category: category,
    name: name ?? 'Producto $value',
    priceClp: 1500,
    featured: false,
    sortRank: value,
    availability: StorefrontAvailability.available,
    fulfillment: const StorefrontFulfillment(
      pickup: true,
      delivery: true,
      reservation: false,
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
    updatedAt: DateTime.utc(2026, 8, 1),
  );
}

final class _ReadinessRepository implements BackendReadinessRepository {
  const _ReadinessRepository({
    required this.initialState,
    this.canCheck = true,
  });

  @override
  final BackendReadinessState initialState;
  @override
  final bool canCheck;

  static final Map<_ReadinessRepository, List<Completer<BackendReadinessState>>>
  _pending = {};

  int get calls => _pending[this]?.length ?? 0;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) {
    final completer = Completer<BackendReadinessState>();
    (_pending[this] ??= []).add(completer);
    return completer.future;
  }

  void completeNext(BackendReadinessState state) => _pending[this]!
      .firstWhere((completer) => !completer.isCompleted)
      .complete(state);
}

typedef _CatalogCall = ({
  String? cursor,
  int limit,
  String? categorySlug,
  StorefrontAvailability? availability,
  bool? discounted,
  StorefrontCatalogSort sort,
});

typedef _SearchCall = ({
  String query,
  String? cursor,
  int limit,
  String? categorySlug,
});

final class _CatalogRepository implements StorefrontRepository {
  _CatalogRepository({
    this.paginated = false,
    this.failSecondPageOnce = false,
    this.withImage = false,
  });

  final bool paginated;
  final bool failSecondPageOnce;
  final bool withImage;
  var _secondPageFailures = 0;
  final List<({String? cursor, int limit})> categoryCalls = [];
  final List<_CatalogCall> catalogCalls = [];
  final List<_SearchCall> searchCalls = [];

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) async {
    categoryCalls.add((cursor: cursor, limit: limit));
    return StorefrontCategoriesPage(
      catalogVersion: 7,
      categories: _categories,
      nextCursor: null,
    );
  }

  @override
  Future<StorefrontCatalogPage> fetchCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
    required StorefrontRequestCancellation cancellation,
  }) async {
    catalogCalls.add((
      cursor: cursor,
      limit: limit,
      categorySlug: categorySlug,
      availability: availability,
      discounted: discounted,
      sort: sort,
    ));
    if (cursor == _cursor && failSecondPageOnce && _secondPageFailures++ == 0) {
      throw const StorefrontFailure(
        StorefrontFailureKind.timeout,
        code: 'test_timeout',
      );
    }
    final items = switch ((categorySlug, cursor, paginated)) {
      ('te', _, _) => [
        _product(900, name: 'Té filtrado', withImage: withImage),
      ],
      (_, _cursor, _) => [_product(25, withImage: withImage)],
      (_, _, true) => [
        for (var value = 1; value <= 24; value++)
          _product(value, withImage: withImage),
      ],
      _ => [_product(1, withImage: withImage)],
    };
    return StorefrontCatalogPage(
      catalogVersion: 7,
      items: items,
      nextCursor: paginated && cursor == null ? _cursor : null,
      sort: sort,
    );
  }

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchHome is outside this test');

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchProductDetail is outside this test');

  @override
  Future<StorefrontSearchPage> fetchSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontRequestCancellation cancellation,
  }) async {
    searchCalls.add((
      query: query,
      cursor: cursor,
      limit: limit,
      categorySlug: categorySlug,
    ));
    return StorefrontSearchPage(
      catalogVersion: 7,
      query: query,
      items: [
        _product(
          categorySlug == 'te' ? 902 : 901,
          name: categorySlug == 'te' ? 'Té encontrado' : 'Café encontrado',
          withImage: withImage,
        ),
      ],
      nextCursor: null,
    );
  }
}
