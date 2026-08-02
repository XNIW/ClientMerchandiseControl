import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storefront_test_fixture.dart';

void main() {
  late StorefrontCacheDatabase database;
  late DateTime now;
  late DriftStorefrontCacheRepository cache;

  setUp(() {
    database = StorefrontCacheDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 8, 2, 12);
    cache = DriftStorefrontCacheRepository(database, clock: () => now);
  });

  tearDown(() => database.close());

  test('schema v1 crea tabelle e indici bounded richiesti', () async {
    final rows = await database
        .customSelect(
          "SELECT type, name FROM sqlite_master "
          "WHERE name LIKE 'storefront_cache_%' "
          "OR name LIKE 'cached_storefront_%' ORDER BY name",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 1);
    expect(
      names,
      containsAll({
        'storefront_cache_metadata',
        'storefront_cache_scopes',
        'storefront_cache_scope_items',
        'cached_storefront_categories',
        'cached_storefront_products',
        'cached_storefront_details',
        'storefront_cache_product_catalog_idx',
        'storefront_cache_product_access_idx',
        'storefront_cache_scope_item_order_idx',
      }),
    );
  });

  test('Home round-trip conserva solo dati pubblici e freshness', () async {
    final home = validStorefrontHomeData();
    await cache.writeHome(shopSlug: 'storefront-test', data: home);

    final snapshot = await cache.readHome(shopSlug: 'storefront-test');

    expect(snapshot, isNotNull);
    expect(snapshot!.isFreshAt(now), isTrue);
    expect(snapshot.value.catalogVersion, 7);
    expect(snapshot.value.settings.currency, 'CLP');
    expect(snapshot.value.categories.single.slug, 'bebidas');
    expect(snapshot.value.featured.single.name, 'Café destacado');
    expect(snapshot.value.offers.single.discountBps, 2000);
    expect(
      await database
          .customSelect('PRAGMA table_info(cached_storefront_products)')
          .get(),
      isNotEmpty,
    );
    final columns =
        (await database
                .customSelect('PRAGMA table_info(cached_storefront_products)')
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(
      columns,
      isNot(
        containsAll(['token', 'email', 'supplier', 'purchase_cost', 'stock']),
      ),
    );
  });

  test(
    'catalogo offline pagina, filtra e ordina senza cursor remoto',
    () async {
      final products = [
        _product(1, 'Café', price: 3000),
        _product(2, 'Agua', price: 1000, discounted: true),
        _product(
          3,
          'Té',
          price: 2000,
          availability: StorefrontAvailability.lowStock,
        ),
      ];
      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: products,
          nextCursor: null,
          sort: StorefrontCatalogSort.priceAscending,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );

      final first = await cache.readCatalog(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 2,
        categorySlug: null,
        sort: StorefrontCatalogSort.priceAscending,
      );
      final second = await cache.readCatalog(
        shopSlug: 'storefront-test',
        cursor: first!.value.nextCursor,
        limit: 2,
        categorySlug: null,
        sort: StorefrontCatalogSort.priceAscending,
      );

      expect(first.value.items.map((item) => item.name), ['Agua', 'Té']);
      expect(first.value.nextCursor, startsWith('cache.v1.'));
      expect(second!.value.items.single.name, 'Café');
      expect(second.value.nextCursor, isNull);

      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: products,
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: 'bebidas',
        availability: StorefrontAvailability.lowStock,
        discounted: null,
      );
      final filtered = await cache.readCatalog(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 24,
        categorySlug: 'bebidas',
        sort: StorefrontCatalogSort.catalog,
        availability: StorefrontAvailability.lowStock,
      );
      expect(filtered!.value.items.single.name, 'Té');
    },
  );

  test('ricerca offline normalizza accenti e preserva zh-Hans', () async {
    final products = [
      _product(1, 'Café molido', price: 3000),
      _product(2, '茉莉花茶', price: 2500),
    ];
    await cache.writeSearch(
      shopSlug: 'storefront-test',
      page: StorefrontSearchPage(
        catalogVersion: 7,
        query: 'seed',
        items: products,
        nextCursor: null,
      ),
      categorySlug: null,
    );

    final latin = await cache.readSearch(
      shopSlug: 'storefront-test',
      query: 'cafe',
      cursor: null,
      limit: 24,
      categorySlug: null,
    );
    final chinese = await cache.readSearch(
      shopSlug: 'storefront-test',
      query: '莉花',
      cursor: null,
      limit: 24,
      categorySlug: null,
    );

    expect(latin!.value.items.single.name, 'Café molido');
    expect(chinese!.value.items.single.name, '茉莉花茶');
    expect(normalizeStorefrontCacheSearch('  Ñandú  '), 'nandu');
  });

  test(
    'detail è leggibile solo dopo marker dedicato e scade onestamente',
    () async {
      final product = _product(1, 'Detalle', price: 3000);
      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: [product],
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );
      expect(
        await cache.readProductDetail(
          shopSlug: 'storefront-test',
          publicationId: product.id,
        ),
        isNull,
      );

      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: product,
      );
      expect(
        (await cache.readProductDetail(
          shopSlug: 'storefront-test',
          publicationId: product.id,
        ))!.value.name,
        'Detalle',
      );

      now = now.add(const Duration(days: 31));
      expect(
        await cache.readProductDetail(
          shopSlug: 'storefront-test',
          publicationId: product.id,
        ),
        isNull,
      );
    },
  );

  test(
    'catalogVersion maggiore invalida atomicamente dati precedenti',
    () async {
      final home = validStorefrontHomeData();
      await cache.writeHome(shopSlug: 'storefront-test', data: home);
      final next = _product(9, 'Versione nuova', price: 4000, version: 8);

      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 8,
          items: [next],
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );

      expect(await cache.readHome(shopSlug: 'storefront-test'), isNull);
      final catalog = await cache.readCatalog(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 24,
        categorySlug: null,
        sort: StorefrontCatalogSort.catalog,
      );
      expect(catalog!.value.catalogVersion, 8);
      expect(catalog.value.items.single.name, 'Versione nuova');
    },
  );

  test('namespace shop impedisce contaminazione cross-shop', () async {
    final product = _product(1, 'Solo shop A', price: 1000);
    await cache.writeCatalog(
      shopSlug: 'shop-a',
      page: StorefrontCatalogPage(
        catalogVersion: 7,
        items: [product],
        nextCursor: null,
        sort: StorefrontCatalogSort.catalog,
      ),
      categorySlug: null,
      availability: null,
      discounted: null,
    );

    expect(
      await cache.readCatalog(
        shopSlug: 'shop-b',
        cursor: null,
        limit: 24,
        categorySlug: null,
        sort: StorefrontCatalogSort.catalog,
      ),
      isNull,
    );
  });

  test(
    'Home conserva membership e ordine server senza contaminazione',
    () async {
      final home = validStorefrontHomeData();
      await cache.writeHome(shopSlug: 'storefront-test', data: home);
      final unrelated = _product(
        20,
        'Scontato ma non in Home',
        price: 1000,
        discounted: true,
      );
      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 7,
          items: [unrelated],
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );

      final cachedHome = await cache.readHome(shopSlug: 'storefront-test');
      expect(
        cachedHome!.value.featured.map((product) => product.id),
        home.featured.map((product) => product.id),
      );
      expect(
        cachedHome.value.offers.map((product) => product.id),
        home.offers.map((product) => product.id),
      );
      expect(
        [
          ...cachedHome.value.featured,
          ...cachedHome.value.offers,
        ].map((product) => product.id),
        isNot(contains(unrelated.id)),
      );
    },
  );

  test('versione item incoerente fallisce prima di mutare la cache', () async {
    final original = _product(1, 'Versione sette', price: 1000);
    await cache.writeCatalog(
      shopSlug: 'storefront-test',
      page: StorefrontCatalogPage(
        catalogVersion: 7,
        items: [original],
        nextCursor: null,
        sort: StorefrontCatalogSort.catalog,
      ),
      categorySlug: null,
      availability: null,
      discounted: null,
    );

    await expectLater(
      cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 8,
          items: [_product(2, 'Item incoerente', price: 2000)],
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      ),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.code,
          'code',
          'cache_product_version_mismatch',
        ),
      ),
    );

    final snapshot = await cache.readCatalog(
      shopSlug: 'storefront-test',
      cursor: null,
      limit: 24,
      categorySlug: null,
      sort: StorefrontCatalogSort.catalog,
    );
    expect(snapshot!.value.catalogVersion, 7);
    expect(snapshot.value.items.single.name, 'Versione sette');
  });
}

StorefrontProductSummary _product(
  int index,
  String name, {
  required int price,
  int version = 7,
  bool discounted = false,
  StorefrontAvailability availability = StorefrontAvailability.available,
}) => StorefrontProductSummary(
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
  priceClp: price,
  compareAtPriceClp: discounted ? price + 500 : null,
  discountBps: discounted ? 1000 : null,
  featured: index.isEven,
  sortRank: index,
  availability: availability,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: true,
    reservation: false,
  ),
  catalogVersion: version,
  publishedAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 2),
);
