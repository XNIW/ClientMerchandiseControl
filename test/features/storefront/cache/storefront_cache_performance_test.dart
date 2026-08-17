import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'small medium e 25k rispettano budget warm read/search e cap',
    () async {
      final now = DateTime.utc(2026, 8, 2, 12);
      for (final profile in const [
        (name: 'small', rows: 1000),
        (name: 'medium', rows: 10000),
        (name: 'extreme', rows: storefrontCacheMaximumProducts),
      ]) {
        final result = await _benchmarkProfile(
          name: profile.name,
          rows: profile.rows,
          now: now,
        );
        expect(result.openMs, lessThan(1000), reason: profile.name);
        expect(result.writeMs, lessThan(2000), reason: profile.name);
        expect(result.catalogP95Us, lessThan(15000), reason: profile.name);
        expect(result.searchP95Us, lessThan(15000), reason: profile.name);
        expect(result.categories, 250, reason: profile.name);
        expect(result.rows, profile.rows, reason: profile.name);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
    tags: const ['performance'],
  );
}

Future<
  ({
    int openMs,
    int writeMs,
    int catalogP95Us,
    int searchP95Us,
    int categories,
    int rows,
  })
>
_benchmarkProfile({
  required String name,
  required int rows,
  required DateTime now,
}) async {
  final openWatch = Stopwatch()..start();
  final database = StorefrontCacheDatabase(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  openWatch.stop();
  final cache = DriftStorefrontCacheRepository(database, clock: () => now);
  try {
    final products = List.generate(
      rows,
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

    final counts = await database
        .customSelect(
          'SELECT count(*) AS rows, count(DISTINCT category_slug) AS categories '
          'FROM cached_storefront_products',
        )
        .getSingle();
    expect(
      (await database.select(database.storefrontCacheScopes).get()),
      hasLength(1),
    );

    for (var warmUp = 0; warmUp < 5; warmUp++) {
      await _readCatalog(cache);
      await _readSearch(cache, warmUp);
    }
    final catalogReads = <int>[];
    final searches = <int>[];
    for (var index = 0; index < 30; index++) {
      final catalogWatch = Stopwatch()..start();
      await _readCatalog(cache);
      catalogWatch.stop();
      catalogReads.add(catalogWatch.elapsedMicroseconds);

      final searchWatch = Stopwatch()..start();
      await _readSearch(cache, index);
      searchWatch.stop();
      searches.add(searchWatch.elapsedMicroseconds);
    }

    final catalogP50 = _percentile(catalogReads, 0.50);
    final catalogP95 = _percentile(catalogReads, 0.95);
    final catalogP99 = _percentile(catalogReads, 0.99);
    final searchP50 = _percentile(searches, 0.50);
    final searchP95 = _percentile(searches, 0.95);
    final searchP99 = _percentile(searches, 0.99);
    final categoryCount = counts.read<int>('categories');
    final rowCount = counts.read<int>('rows');
    debugPrint(
      'STOREFRONT_CACHE_PERF profile=$name rows=$rowCount '
      'categories=$categoryCount open_ms=${openWatch.elapsedMilliseconds} '
      'write_ms=${writeWatch.elapsedMilliseconds} '
      'catalog_us=$catalogP50/$catalogP95/$catalogP99 '
      'search_us=$searchP50/$searchP95/$searchP99',
    );
    return (
      openMs: openWatch.elapsedMilliseconds,
      writeMs: writeWatch.elapsedMilliseconds,
      catalogP95Us: catalogP95,
      searchP95Us: searchP95,
      categories: categoryCount,
      rows: rowCount,
    );
  } finally {
    await database.close();
  }
}

Future<void> _readCatalog(DriftStorefrontCacheRepository cache) async {
  final catalog = await cache.readCatalog(
    shopSlug: 'storefront-test',
    cursor: null,
    limit: 24,
    categorySlug: null,
    sort: StorefrontCatalogSort.catalog,
  );
  expect(catalog?.value.items, hasLength(24));
}

Future<void> _readSearch(
  DriftStorefrontCacheRepository cache,
  int index,
) async {
  final search = await cache.readSearch(
    shopSlug: 'storefront-test',
    query: index.isEven ? 'cafe' : '茉莉',
    cursor: null,
    limit: 24,
    categorySlug: null,
  );
  expect(search?.value.items, hasLength(24));
}

int _percentile(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

StorefrontProductSummary _product(int index, String name) =>
    StorefrontProductSummary(
      id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
      category: StorefrontCategory(
        id:
            '40000000-0000-4000-8000-'
            '${(index % 250).toString().padLeft(12, '0')}',
        slug: 'categoria-${index % 250}',
        name: 'Categoría ${index % 250}',
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
