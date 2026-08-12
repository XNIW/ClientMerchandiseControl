import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/favorites/application/favorites_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  test(
    'toggle guest persiste quando il lifecycle provider viene ricreato',
    () async {
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cache = DriftStorefrontCacheRepository(database);
      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: _product(),
      );

      var container = _container(cache);
      expect(await container.read(favoritesControllerProvider.future), isEmpty);
      expect(
        await container
            .read(favoritesControllerProvider.notifier)
            .toggle(_publicationId),
        isTrue,
      );
      expect(
        container
            .read(favoritesControllerProvider)
            .requireValue
            .single
            .product
            ?.name,
        'Café favorito',
      );

      // Login, session restore e logout ricreano lo stato applicativo, non il DB
      // pubblico locale: la preferenza guest deve restare indipendente da Auth.
      container.dispose();
      container = _container(cache);
      final restored = await container.read(favoritesControllerProvider.future);
      expect(restored.single.publicationId, _publicationId);

      expect(
        await container
            .read(favoritesControllerProvider.notifier)
            .toggle(_publicationId),
        isFalse,
      );
      expect(container.read(favoritesControllerProvider).requireValue, isEmpty);
      container.dispose();
    },
  );

  test(
    'doppi tap sullo stesso prodotto condividono una sola mutazione',
    () async {
      final repository = _ControlledFavoritesRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(favoritesControllerProvider.future);

      final controller = container.read(favoritesControllerProvider.notifier);
      final first = controller.toggle(_publicationId);
      final second = controller.toggle(_publicationId);

      expect(identical(first, second), isTrue);
      expect(repository.toggleCalls, 1);
      repository.complete(true);
      expect(await first, isTrue);
      expect(repository.readCalls, 2);
    },
  );
}

ProviderContainer _container(StorefrontCacheRepository repository) =>
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
        storefrontCacheRepositoryProvider.overrideWithValue(repository),
      ],
    );

StorefrontProductSummary _product() => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  name: 'Café favorito',
  priceClp: 1200,
  featured: false,
  sortRank: 1,
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

final class _ControlledFavoritesRepository
    implements StorefrontCacheRepository {
  final _completer = Completer<bool>();
  var toggleCalls = 0;
  var readCalls = 0;

  void complete(bool value) => _completer.complete(value);

  @override
  Future<List<StorefrontFavoriteEntry>> readFavorites({
    required String shopSlug,
  }) async {
    readCalls++;
    return toggleCalls == 0
        ? const []
        : [
            StorefrontFavoriteEntry(
              publicationId: _publicationId,
              updatedAt: DateTime.utc(2026, 8, 2),
              product: _product(),
            ),
          ];
  }

  @override
  Future<bool> toggleFavorite({
    required String shopSlug,
    required String publicationId,
  }) {
    toggleCalls++;
    return _completer.future;
  }

  @override
  Future<void> cleanup({required String shopSlug}) async {}

  @override
  Future<void> clearShop({required String shopSlug}) async {}

  @override
  Future<StorefrontCacheSnapshot<StorefrontCatalogPage>?> readCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
  }) async => null;

  @override
  Future<StorefrontCacheSnapshot<StorefrontCategoriesPage>?> readCategories({
    required String shopSlug,
  }) async => null;

  @override
  Future<StorefrontCacheSnapshot<StorefrontHomeData>?> readHome({
    required String shopSlug,
  }) async => null;

  @override
  Future<StorefrontCacheSnapshot<StorefrontProductSummary>?> readProductDetail({
    required String shopSlug,
    required String publicationId,
  }) async => null;

  @override
  Future<StorefrontCacheSnapshot<StorefrontSearchPage>?> readSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
  }) async => null;

  @override
  Future<void> writeCatalog({
    required String shopSlug,
    required StorefrontCatalogPage page,
    required String? categorySlug,
    required StorefrontAvailability? availability,
    required bool? discounted,
  }) async {}

  @override
  Future<void> writeCategories({
    required String shopSlug,
    required StorefrontCategoriesPage page,
  }) async {}

  @override
  Future<void> writeHome({
    required String shopSlug,
    required StorefrontHomeData data,
  }) async {}

  @override
  Future<void> writeProductDetail({
    required String shopSlug,
    required StorefrontProductSummary product,
  }) async {}

  @override
  Future<void> writeSearch({
    required String shopSlug,
    required StorefrontSearchPage page,
    required String? categorySlug,
  }) async {}
}
