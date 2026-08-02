import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carica prima pagina e concatena una sola pagina keyset', () async {
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Café')], nextCursor: 'cursor'),
        () async => _catalogPage([_product('2', 'Té')]),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      container.read(catalogControllerProvider).status,
      CatalogLoadStatus.loading,
    );
    await _flush();
    expect(container.read(catalogControllerProvider).items, hasLength(1));

    await container.read(catalogControllerProvider.notifier).loadMore();

    final state = container.read(catalogControllerProvider);
    expect(state.items.map((item) => item.name), ['Café', 'Té']);
    expect(state.nextCursor, isNull);
    expect(repository.catalogCalls.map((call) => call.cursor), [
      null,
      'cursor',
    ]);
    await container.read(catalogControllerProvider.notifier).loadMore();
    expect(repository.catalogCalls, hasLength(2));
  });

  test('cambio categoria cancella e ignora la risposta precedente', () async {
    final stale = Completer<StorefrontCatalogPage>();
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Todos')]),
        () => stale.future,
        () async => _catalogPage([_product('3', 'Té filtrado')]),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    container.read(catalogControllerProvider);
    await _flush();

    final first = container
        .read(catalogControllerProvider.notifier)
        .selectCategory('bebidas');
    await Future<void>.delayed(Duration.zero);
    final second = container
        .read(catalogControllerProvider.notifier)
        .selectCategory('te');
    await second;
    stale.complete(_catalogPage([_product('2', 'Risposta stale')]));
    await first;

    final state = container.read(catalogControllerProvider);
    expect(state.selectedCategorySlug, 'te');
    expect(state.items.single.name, 'Té filtrado');
    expect(repository.cancellations[1].isCancelled, isTrue);
  });

  test(
    'catalog_changed durante load-more ricomincia dalla prima pagina',
    () async {
      final repository = _CatalogRepository(
        categoryResponses: [
          () async => _categoriesPage(),
          () async => _categoriesPage(version: 8),
        ],
        catalogResponses: [
          () async =>
              _catalogPage([_product('1', 'Vecchio')], nextCursor: 'next'),
          () => Future.error(
            const StorefrontFailure(
              StorefrontFailureKind.catalogChanged,
              code: 'catalog_changed',
            ),
          ),
          () async => _catalogPage([_product('4', 'Nuovo')], catalogVersion: 8),
        ],
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      container.read(catalogControllerProvider);
      await _flush();

      await container.read(catalogControllerProvider.notifier).loadMore();

      final state = container.read(catalogControllerProvider);
      expect(state.catalogVersion, 8);
      expect(state.items.single.name, 'Nuovo');
      expect(repository.categoryCalls, 2);
      expect(repository.catalogCalls, hasLength(3));
    },
  );

  test(
    'errore incrementale conserva gli item e retry riprende il cursor',
    () async {
      final repository = _CatalogRepository(
        categoryResponses: [() async => _categoriesPage()],
        catalogResponses: [
          () async => _catalogPage([_product('1', 'Café')], nextCursor: 'next'),
          () => Future.error(
            const StorefrontFailure(
              StorefrontFailureKind.offline,
              code: 'network_offline',
            ),
          ),
          () async => _catalogPage([_product('2', 'Té')]),
        ],
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      container.read(catalogControllerProvider);
      await _flush();

      await container.read(catalogControllerProvider.notifier).loadMore();
      expect(container.read(catalogControllerProvider).loadMoreFailed, isTrue);
      expect(container.read(catalogControllerProvider).items, hasLength(1));

      await container.read(catalogControllerProvider.notifier).retry();
      expect(container.read(catalogControllerProvider).items, hasLength(2));
      expect(container.read(catalogControllerProvider).loadMoreFailed, isFalse);
    },
  );

  test(
    'refresh conserva i dati visibili e sostituisce la prima pagina',
    () async {
      final refreshed = Completer<StorefrontCatalogPage>();
      final repository = _CatalogRepository(
        categoryResponses: [
          () async => _categoriesPage(),
          () async => _categoriesPage(version: 8),
        ],
        catalogResponses: [
          () async => _catalogPage([_product('1', 'Prima')]),
          () => refreshed.future,
        ],
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      container.read(catalogControllerProvider);
      await _flush();

      final operation = container
          .read(catalogControllerProvider.notifier)
          .refresh();
      await Future<void>.delayed(Duration.zero);

      var state = container.read(catalogControllerProvider);
      expect(state.isRefreshing, isTrue);
      expect(state.items.single.name, 'Prima');

      refreshed.complete(
        _catalogPage([_product('2', 'Dopo refresh')], catalogVersion: 8),
      );
      await operation;

      state = container.read(catalogControllerProvider);
      expect(state.isRefreshing, isFalse);
      expect(state.catalogVersion, 8);
      expect(state.items.single.name, 'Dopo refresh');
      expect(repository.catalogCalls.map((call) => call.cursor), [null, null]);
    },
  );

  test(
    'ricerca applica debounce, normalizza e pagina sul cursor search',
    () async {
      final repository = _CatalogRepository(
        categoryResponses: [() async => _categoriesPage()],
        catalogResponses: [
          () async => _catalogPage([_product('1', 'Prima')]),
        ],
        searchResponses: [
          () async => _searchPage(
            [_product('2', 'Café')],
            query: 'cafe',
            nextCursor: 'search-cursor',
          ),
          () async =>
              _searchPage([_product('3', 'Café molido')], query: 'cafe'),
        ],
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      container.read(catalogControllerProvider);
      await _flush();

      container
          .read(catalogControllerProvider.notifier)
          .updateSearchQuery('  cafe  ');
      await Future<void>.delayed(const Duration(milliseconds: 299));
      expect(repository.searchCalls, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await _flush();

      var state = container.read(catalogControllerProvider);
      expect(state.searchQuery, 'cafe');
      expect(state.items.single.name, 'Café');
      expect(repository.searchCalls.single.query, 'cafe');

      await container.read(catalogControllerProvider.notifier).loadMore();
      state = container.read(catalogControllerProvider);
      expect(state.items.map((item) => item.name), ['Café', 'Café molido']);
      expect(repository.searchCalls.last.cursor, 'search-cursor');
    },
  );

  test('filtri e sort sono server-side e reset atomico', () async {
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Prima')]),
        () async => _catalogPage([_product('2', 'Disponibile')]),
        () async => _catalogPage([_product('3', 'Scontato')]),
        () async => _catalogPage([
          _product('4', 'Prezzo'),
        ], sort: StorefrontCatalogSort.priceAscending),
        () async => _catalogPage([_product('5', 'Reset')]),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    container.read(catalogControllerProvider);
    await _flush();

    final controller = container.read(catalogControllerProvider.notifier);
    await controller.selectAvailability(StorefrontAvailability.available);
    await controller.setDiscountedOnly(true);
    await controller.selectSort(StorefrontCatalogSort.priceAscending);

    var state = container.read(catalogControllerProvider);
    expect(state.availabilityFilter, StorefrontAvailability.available);
    expect(state.discountedOnly, isTrue);
    expect(state.sort, StorefrontCatalogSort.priceAscending);
    expect(repository.catalogCalls.last, (
      cursor: null,
      categorySlug: null,
      availability: StorefrontAvailability.available,
      discounted: true,
      sort: StorefrontCatalogSort.priceAscending,
    ));

    await controller.resetFilters();
    state = container.read(catalogControllerProvider);
    expect(state.hasCatalogFilters, isFalse);
    expect(state.items.single.name, 'Reset');
    expect(repository.catalogCalls, hasLength(5));
  });

  test('ricerca compone categoria e blocca filtri catalog-only', () async {
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Prima')]),
      ],
      searchResponses: [
        () async => _searchPage([_product('2', 'Té')], query: 'te'),
        () async => _searchPage([_product('3', 'Té categoria')], query: 'te'),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    container.read(catalogControllerProvider);
    await _flush();

    final controller = container.read(catalogControllerProvider.notifier);
    await controller.submitSearch('te');
    await controller.selectAvailability(StorefrontAvailability.available);
    await controller.setDiscountedOnly(true);
    await controller.selectSort(StorefrontCatalogSort.name);
    await controller.selectCategory('te');

    final state = container.read(catalogControllerProvider);
    expect(state.isSearchActive, isTrue);
    expect(state.selectedCategorySlug, 'te');
    expect(state.hasCatalogFilters, isFalse);
    expect(repository.catalogCalls, hasLength(1));
    expect(repository.searchCalls, hasLength(2));
    expect(repository.searchCalls.last.categorySlug, 'te');
  });

  test('nuova query cancella e scarta una risposta search stale', () async {
    final stale = Completer<StorefrontSearchPage>();
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Prima')]),
      ],
      searchResponses: [
        () => stale.future,
        () async => _searchPage([_product('3', 'Té')], query: 'te'),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    container.read(catalogControllerProvider);
    await _flush();

    final controller = container.read(catalogControllerProvider.notifier);
    final first = controller.submitSearch('cafe');
    await Future<void>.delayed(Duration.zero);
    await controller.submitSearch('te');
    stale.complete(_searchPage([_product('2', 'Stale')], query: 'cafe'));
    await first;

    final state = container.read(catalogControllerProvider);
    expect(state.searchQuery, 'te');
    expect(state.items.single.name, 'Té');
    expect(repository.searchCancellations.first.isCancelled, isTrue);
  });

  test('search empty e timeout usano stati coerenti con retry', () async {
    final repository = _CatalogRepository(
      categoryResponses: [() async => _categoriesPage()],
      catalogResponses: [
        () async => _catalogPage([_product('1', 'Prima')]),
      ],
      searchResponses: [
        () async => _searchPage([], query: 'zz'),
        () => Future.error(
          const StorefrontFailure(
            StorefrontFailureKind.timeout,
            code: 'request_timeout',
          ),
        ),
        () async => _searchPage([_product('2', 'Café')], query: 'cafe'),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    container.read(catalogControllerProvider);
    await _flush();

    final controller = container.read(catalogControllerProvider.notifier);
    await controller.submitSearch('zz');
    expect(
      container.read(catalogControllerProvider).status,
      CatalogLoadStatus.empty,
    );

    await controller.submitSearch('cafe');
    expect(
      container.read(catalogControllerProvider).status,
      CatalogLoadStatus.offline,
    );
    await controller.retry();
    final state = container.read(catalogControllerProvider);
    expect(state.status, CatalogLoadStatus.data);
    expect(state.items.single.name, 'Café');
  });
}

ProviderContainer _container(StorefrontRepository repository) =>
    ProviderContainer(
      overrides: [
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
      ],
    );

Future<void> _flush() async {
  for (var index = 0; index < 5; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

StorefrontCategoriesPage _categoriesPage({int version = 7}) =>
    StorefrontCategoriesPage(
      catalogVersion: version,
      categories: const [
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
      ],
      nextCursor: null,
    );

StorefrontCatalogPage _catalogPage(
  List<StorefrontProductSummary> items, {
  String? nextCursor,
  int catalogVersion = 7,
  StorefrontCatalogSort sort = StorefrontCatalogSort.catalog,
}) => StorefrontCatalogPage(
  catalogVersion: catalogVersion,
  items: items,
  nextCursor: nextCursor,
  sort: sort,
);

StorefrontSearchPage _searchPage(
  List<StorefrontProductSummary> items, {
  required String query,
  String? nextCursor,
  int catalogVersion = 7,
}) => StorefrontSearchPage(
  catalogVersion: catalogVersion,
  query: query,
  items: items,
  nextCursor: nextCursor,
);

StorefrontProductSummary _product(String suffix, String name) {
  final id = '50000000-0000-4000-8000-00000000000$suffix';
  return StorefrontProductSummary(
    id: id,
    category: const StorefrontCategory(
      id: '40000000-0000-4000-8000-000000000001',
      slug: 'bebidas',
      name: 'Bebidas',
      sortRank: 1,
    ),
    name: name,
    priceClp: 1500,
    featured: false,
    sortRank: int.parse(suffix),
    availability: StorefrontAvailability.available,
    fulfillment: const StorefrontFulfillment(
      pickup: true,
      delivery: true,
      reservation: false,
    ),
    catalogVersion: 7,
    publishedAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
}

typedef _CatalogResponse = Future<StorefrontCatalogPage> Function();
typedef _CategoryResponse = Future<StorefrontCategoriesPage> Function();
typedef _SearchResponse = Future<StorefrontSearchPage> Function();

typedef _CatalogCall = ({
  String? cursor,
  String? categorySlug,
  StorefrontAvailability? availability,
  bool? discounted,
  StorefrontCatalogSort sort,
});

typedef _SearchCall = ({String query, String? cursor, String? categorySlug});

final class _CatalogRepository implements StorefrontRepository {
  _CatalogRepository({
    required this.categoryResponses,
    required this.catalogResponses,
    this.searchResponses = const [],
  });

  final List<_CategoryResponse> categoryResponses;
  final List<_CatalogResponse> catalogResponses;
  final List<_SearchResponse> searchResponses;
  final List<_CatalogCall> catalogCalls = [];
  final List<_SearchCall> searchCalls = [];
  final List<StorefrontRequestCancellation> cancellations = [];
  final List<StorefrontRequestCancellation> searchCancellations = [];
  var categoryCalls = 0;

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) {
    cancellations.add(cancellation);
    return categoryResponses[categoryCalls++]();
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
  }) {
    cancellations.add(cancellation);
    catalogCalls.add((
      cursor: cursor,
      categorySlug: categorySlug,
      availability: availability,
      discounted: discounted,
      sort: sort,
    ));
    return catalogResponses[catalogCalls.length - 1]();
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
  }) {
    cancellations.add(cancellation);
    searchCancellations.add(cancellation);
    searchCalls.add((query: query, cursor: cursor, categorySlug: categorySlug));
    return searchResponses[searchCalls.length - 1]();
  }
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
