import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storefront_test_fixture.dart';

const _shop = 'storefront-test';

void main() {
  test(
    'Home rende cache subito, revalida e persiste il risultato live',
    () async {
      final fixture = validStorefrontHomeData();
      final live = _homeWithName(fixture, 'Café live');
      final pending = Completer<StorefrontHomeData>();
      final remote = _HomeRepository(() => pending.future);
      final resources = await _resources(
        readiness: BackendReadinessState.ready,
        remote: remote,
      );
      addTearDown(resources.dispose);
      await resources.cache.writeHome(shopSlug: _shop, data: fixture);

      resources.container.read(homeControllerProvider);
      await _flush();

      var state = resources.container.read(homeControllerProvider);
      expect(state.status, HomeLoadStatus.data);
      expect(state.data?.featured.single.name, 'Café destacado');
      expect(state.isFromCache, isTrue);
      expect(state.isRefreshing, isTrue);
      expect(remote.calls, 1);

      pending.complete(live);
      await _flush();
      state = resources.container.read(homeControllerProvider);
      expect(state.data?.featured.single.name, 'Café live');
      expect(state.isFromCache, isFalse);
      expect(
        (await resources.cache.readHome(
          shopSlug: _shop,
        ))?.value.featured.single.name,
        'Café live',
      );
    },
  );

  test(
    'Home conserva la copia stale quando la revalidation va offline',
    () async {
      final resources = await _resources(
        readiness: BackendReadinessState.ready,
        remote: _HomeRepository(
          () => Future.error(
            const StorefrontFailure(
              StorefrontFailureKind.timeout,
              code: 'request_timeout',
            ),
          ),
        ),
      );
      addTearDown(resources.dispose);
      await resources.cache.writeHome(
        shopSlug: _shop,
        data: validStorefrontHomeData(),
      );

      resources.container.read(homeControllerProvider);
      await _flush();

      final state = resources.container.read(homeControllerProvider);
      expect(state.status, HomeLoadStatus.data);
      expect(state.isFromCache, isTrue);
      expect(state.isStale, isTrue);
      expect(state.isRefreshing, isFalse);
      expect(state.failure?.kind, StorefrontFailureKind.timeout);
    },
  );

  test(
    'Catalog offline usa categorie e pagina cache senza invocare rete',
    () async {
      final fixture = validStorefrontHomeData();
      final remote = _NeverRepository();
      final resources = await _resources(
        readiness: BackendReadinessState.offline,
        remote: remote,
      );
      addTearDown(resources.dispose);
      await resources.cache.writeCategories(
        shopSlug: _shop,
        page: StorefrontCategoriesPage(
          catalogVersion: fixture.catalogVersion,
          categories: fixture.categories,
          nextCursor: null,
        ),
      );
      await resources.cache.writeCatalog(
        shopSlug: _shop,
        page: StorefrontCatalogPage(
          catalogVersion: fixture.catalogVersion,
          items: fixture.featured,
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );

      resources.container.read(catalogControllerProvider);
      await _flush();

      final state = resources.container.read(catalogControllerProvider);
      expect(state.status, CatalogLoadStatus.data);
      expect(state.items.single.name, 'Café destacado');
      expect(state.isFromCache, isTrue);
      expect(state.isRefreshing, isFalse);
      expect(remote.calls, 0);
    },
  );

  test('Detail offline usa solo un dettaglio già validato e marcato', () async {
    final product = validStorefrontHomeData().featured.single;
    final remote = _NeverRepository();
    final resources = await _resources(
      readiness: BackendReadinessState.offline,
      remote: remote,
    );
    addTearDown(resources.dispose);
    await resources.cache.writeProductDetail(shopSlug: _shop, product: product);

    final provider = productDetailControllerProvider(product.id);
    final subscription = resources.container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _flush();

    final state = resources.container.read(provider);
    expect(state.status, ProductDetailLoadStatus.data);
    expect(state.isFromCache, isTrue);
    expect(state.product?.id, product.id);
    expect(remote.calls, 0);
  });

  test('Detail live unavailable rimuove dalla UI la copia cached', () async {
    final product = validStorefrontHomeData().featured.single;
    final remote = _DetailRepository(
      () => Future.error(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'storefront_unavailable',
        ),
      ),
    );
    final resources = await _resources(
      readiness: BackendReadinessState.ready,
      remote: remote,
    );
    addTearDown(resources.dispose);
    await resources.cache.writeProductDetail(shopSlug: _shop, product: product);

    final provider = productDetailControllerProvider(product.id);
    final subscription = resources.container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _flush();

    final state = resources.container.read(provider);
    expect(state.status, ProductDetailLoadStatus.unavailable);
    expect(state.product, isNull);
    expect(remote.calls, 1);
  });
}

Future<_TestResources> _resources({
  required BackendReadinessState readiness,
  required StorefrontRepository remote,
}) async {
  final now = DateTime.now().toUtc();
  final database = StorefrontCacheDatabase(NativeDatabase.memory());
  final cache = DriftStorefrontCacheRepository(database, clock: () => now);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://staging.example.invalid',
          supabasePublishableKey: 'sb_publishable_staging',
          authRedirectUri: AppConfig.allowedAuthRedirectUri,
          googleAuthEnabled: 'false',
          storefrontShopSlug: _shop,
        ),
      ),
      backendReadinessRepositoryProvider.overrideWithValue(
        _StaticReadinessRepository(readiness),
      ),
      storefrontRepositoryProvider.overrideWithValue(remote),
      storefrontCacheRepositoryProvider.overrideWithValue(cache),
    ],
  );
  return _TestResources(container, database, cache);
}

class _TestResources {
  const _TestResources(this.container, this.database, this.cache);

  final ProviderContainer container;
  final StorefrontCacheDatabase database;
  final DriftStorefrontCacheRepository cache;

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

class _StaticReadinessRepository implements BackendReadinessRepository {
  const _StaticReadinessRepository(this.initialState);

  @override
  final BackendReadinessState initialState;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => initialState;
}

class _HomeRepository extends HomeOnlyStorefrontRepository {
  _HomeRepository(this.response);

  final Future<StorefrontHomeData> Function() response;
  int calls = 0;

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls += 1;
    return response();
  }
}

class _NeverRepository extends HomeOnlyStorefrontRepository {
  int calls = 0;

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls += 1;
    throw StateError('network_must_not_be_called');
  }

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls += 1;
    throw StateError('network_must_not_be_called');
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
    calls += 1;
    throw StateError('network_must_not_be_called');
  }

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls += 1;
    throw StateError('network_must_not_be_called');
  }
}

class _DetailRepository extends HomeOnlyStorefrontRepository {
  _DetailRepository(this.response);

  final Future<StorefrontProductSummary> Function() response;
  int calls = 0;

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls += 1;
    return response();
  }

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchHome is outside this test');
}

StorefrontHomeData _homeWithName(StorefrontHomeData source, String name) {
  final product = source.featured.single;
  final renamed = StorefrontProductSummary(
    id: product.id,
    category: product.category,
    name: name,
    description: product.description,
    brand: product.brand,
    priceClp: product.priceClp,
    compareAtPriceClp: product.compareAtPriceClp,
    discountBps: product.discountBps,
    promotion: product.promotion,
    featured: product.featured,
    sortRank: product.sortRank,
    availability: product.availability,
    fulfillment: product.fulfillment,
    images: product.images,
    catalogVersion: product.catalogVersion,
    publishedAt: product.publishedAt,
    updatedAt: product.updatedAt,
  );
  return StorefrontHomeData(
    catalogVersion: source.catalogVersion,
    settings: source.settings,
    categories: source.categories,
    featured: [renamed],
    offers: source.offers,
  );
}

Future<void> _flush() async {
  for (var index = 0; index < 12; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
