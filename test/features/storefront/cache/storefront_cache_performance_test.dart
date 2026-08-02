import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '20k prodotti rispettano cap e budget warm read/search',
    () async {
      final now = DateTime.utc(2026, 8, 2, 12);
      final openWatch = Stopwatch()..start();
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      await database.customSelect('SELECT 1').get();
      openWatch.stop();
      addTearDown(database.close);
      final cache = DriftStorefrontCacheRepository(database, clock: () => now);
      final products = List.generate(
        20000,
        (index) => _product(index, index.isEven ? 'Café $index' : '茉莉茶 $index'),
        growable: false,
      );

      final writeWatch = Stopwatch()..start();
      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: products,
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );
      writeWatch.stop();
      final seededProducts =
          (await database
                  .customSelect(
                    'SELECT count(*) AS value FROM cached_storefront_products',
                  )
                  .getSingle())
              .read<int>('value');
      final seededScopes =
          (await database
                  .customSelect(
                    'SELECT count(*) AS value FROM storefront_cache_scopes',
                  )
                  .getSingle())
              .read<int>('value');
      expect(seededProducts, 20000);
      expect(seededScopes, 1);

      final catalogReads = <int>[];
      final searches = <int>[];
      for (var index = 0; index < 30; index += 1) {
        final catalogWatch = Stopwatch()..start();
        final catalog = await cache.readCatalog(
          shopSlug: 'storefront-test',
          cursor: null,
          limit: 24,
          categorySlug: null,
          sort: StorefrontCatalogSort.catalog,
        );
        catalogWatch.stop();
        expect(catalog?.value.items, hasLength(24));
        catalogReads.add(catalogWatch.elapsedMicroseconds);

        final searchWatch = Stopwatch()..start();
        final search = await cache.readSearch(
          shopSlug: 'storefront-test',
          query: index.isEven ? 'cafe' : '茉莉',
          cursor: null,
          limit: 24,
          categorySlug: null,
        );
        searchWatch.stop();
        expect(search?.value.items, hasLength(24));
        searches.add(searchWatch.elapsedMicroseconds);
      }

      final extraProducts = List.generate(
        5100,
        (index) => _product(20000 + index, 'Extra $index'),
        growable: false,
      );
      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: extraProducts,
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );
      await cache.cleanup(shopSlug: 'storefront-test');
      final productCount =
          (await database
                  .customSelect(
                    "SELECT count(*) AS value FROM cached_storefront_products "
                    "WHERE shop_slug = 'storefront-test'",
                  )
                  .getSingle())
              .read<int>('value');

      final catalogP50 = _percentile(catalogReads, 0.50);
      final catalogP95 = _percentile(catalogReads, 0.95);
      final catalogP99 = _percentile(catalogReads, 0.99);
      final searchP50 = _percentile(searches, 0.50);
      final searchP95 = _percentile(searches, 0.95);
      final searchP99 = _percentile(searches, 0.99);
      debugPrint(
        'STOREFRONT_CACHE_PERF '
        'open_ms=${openWatch.elapsedMilliseconds} '
        'write_20k_ms=${writeWatch.elapsedMilliseconds} '
        'catalog_us=$catalogP50/$catalogP95/$catalogP99 '
        'search_us=$searchP50/$searchP95/$searchP99 rows=$productCount',
      );

      expect(openWatch.elapsedMilliseconds, lessThan(1000));
      expect(writeWatch.elapsedMilliseconds, lessThan(10000));
      expect(catalogP95, lessThan(100000));
      expect(searchP95, lessThan(250000));
      expect(productCount, storefrontCacheMaximumProducts);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

int _percentile(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

StorefrontProductSummary _product(int index, String name) =>
    StorefrontProductSummary(
      id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
      category: const StorefrontCategory(
        id: '40000000-0000-4000-8000-000000000001',
        slug: 'bebidas',
        name: 'Bebidas',
        sortRank: 1,
      ),
      name: name,
      description: 'Descripción pública',
      brand: 'Marca pública',
      priceClp: 1000 + index,
      compareAtPriceClp: index.isEven ? 2000 + index : null,
      discountBps: index.isEven ? 1000 : null,
      featured: index < 8,
      sortRank: index,
      availability: StorefrontAvailability.available,
      fulfillment: const StorefrontFulfillment(
        pickup: true,
        delivery: true,
        reservation: false,
      ),
      images: StorefrontImageSet(
        version: 'v$index',
        thumb: Uri.parse(
          'https://cdn.example.invalid/storefront-product-images/'
          '$index/thumb.webp',
        ),
        card: Uri.parse(
          'https://cdn.example.invalid/storefront-product-images/'
          '$index/card.webp',
        ),
        detail: Uri.parse(
          'https://cdn.example.invalid/storefront-product-images/'
          '$index/detail.webp',
        ),
        sha256: index.toRadixString(16).padLeft(64, '0'),
      ),
      catalogVersion: 7,
      publishedAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 2),
    );
