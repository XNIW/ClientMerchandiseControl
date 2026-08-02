import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
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
}) => StorefrontCatalogPage(
  catalogVersion: catalogVersion,
  items: items,
  nextCursor: nextCursor,
  sort: StorefrontCatalogSort.catalog,
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

class _CatalogCall {
  const _CatalogCall({required this.cursor, required this.categorySlug});

  final String? cursor;
  final String? categorySlug;
}

final class _CatalogRepository implements StorefrontRepository {
  _CatalogRepository({
    required this.categoryResponses,
    required this.catalogResponses,
  });

  final List<_CategoryResponse> categoryResponses;
  final List<_CatalogResponse> catalogResponses;
  final List<_CatalogCall> catalogCalls = [];
  final List<StorefrontRequestCancellation> cancellations = [];
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
    required StorefrontRequestCancellation cancellation,
  }) {
    cancellations.add(cancellation);
    catalogCalls.add(_CatalogCall(cursor: cursor, categorySlug: categorySlug));
    return catalogResponses[catalogCalls.length - 1]();
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
