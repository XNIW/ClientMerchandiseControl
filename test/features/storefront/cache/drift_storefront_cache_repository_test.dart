import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/drift.dart' show Variable;
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

  test('schema v3 crea cache, favorite, cart e indici bounded', () async {
    final rows = await database
        .customSelect(
          "SELECT type, name FROM sqlite_master "
          "WHERE name LIKE 'storefront_cache_%' "
          "OR name LIKE 'cached_storefront_%' "
          "OR name LIKE 'storefront_favorite%' "
          "OR name LIKE 'storefront_guest_cart%' ORDER BY name",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 3);
    expect(
      names,
      containsAll({
        'storefront_cache_metadata',
        'storefront_cache_scopes',
        'storefront_cache_scope_items',
        'storefront_favorites',
        'storefront_guest_cart_items',
        'cached_storefront_categories',
        'cached_storefront_products',
        'cached_storefront_details',
        'storefront_cache_product_catalog_idx',
        'storefront_cache_product_access_idx',
        'storefront_cache_scope_item_order_idx',
        'storefront_favorite_order_idx',
        'storefront_guest_cart_order_idx',
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

  test('favorite guest è idempotente, shop-scoped e rimovibile', () async {
    final product = _product(1, 'Favorito', price: 1000);
    await cache.writeProductDetail(
      shopSlug: 'storefront-test',
      product: product,
    );

    expect(
      await cache.toggleFavorite(
        shopSlug: 'storefront-test',
        publicationId: product.id,
      ),
      isTrue,
    );
    var favorites = await cache.readFavorites(shopSlug: 'storefront-test');
    expect(favorites.single.publicationId, product.id);
    expect(favorites.single.product?.name, 'Favorito');
    expect(await cache.readFavorites(shopSlug: 'other-shop'), isEmpty);

    expect(
      await cache.toggleFavorite(
        shopSlug: 'storefront-test',
        publicationId: product.id,
      ),
      isFalse,
    );
    favorites = await cache.readFavorites(shopSlug: 'storefront-test');
    expect(favorites, isEmpty);
  });

  test(
    'favorite resta bounded a mille e conserva la mutazione più recente',
    () async {
      final oldTimestamp = now.subtract(const Duration(days: 1));
      await database.batch((batch) {
        batch.insertAll(
          database.storefrontFavorites,
          List.generate(
            1000,
            (index) => StorefrontFavoritesCompanion.insert(
              shopSlug: 'storefront-test',
              publicationId:
                  '50000000-0000-4000-8000-'
                  '${(index + 1).toString().padLeft(12, '0')}',
              createdAt: oldTimestamp,
              updatedAt: oldTimestamp,
            ),
            growable: false,
          ),
        );
      });
      final newest = _product(1001, 'Più recente', price: 1000);
      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: newest,
      );

      expect(
        await cache.toggleFavorite(
          shopSlug: 'storefront-test',
          publicationId: newest.id,
        ),
        isTrue,
      );

      final count = await database
          .customSelect(
            'SELECT COUNT(*) AS count FROM storefront_favorites '
            'WHERE shop_slug = ?',
            variables: [Variable.withString('storefront-test')],
          )
          .getSingle();
      final favorites = await cache.readFavorites(shopSlug: 'storefront-test');
      expect(count.read<int>('count'), storefrontMaximumFavorites);
      expect(favorites, hasLength(storefrontMaximumFavorites));
      expect(favorites.first.publicationId, newest.id);
    },
  );

  test(
    'catalogVersion invalida il prodotto ma preserva la scelta favorite',
    () async {
      final original = _product(1, 'Versione sette', price: 1000);
      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: original,
      );
      await cache.toggleFavorite(
        shopSlug: 'storefront-test',
        publicationId: original.id,
      );

      await cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: 8,
          items: [_product(9, 'Versione otto', price: 2000, version: 8)],
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );
      var favorites = await cache.readFavorites(shopSlug: 'storefront-test');
      expect(favorites.single.publicationId, original.id);
      expect(favorites.single.product, isNull);

      final refreshed = _product(1, 'Ripubblicato', price: 1200, version: 8);
      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: refreshed,
      );
      favorites = await cache.readFavorites(shopSlug: 'storefront-test');
      expect(favorites.single.product?.name, 'Ripubblicato');
    },
  );

  test('favorite rifiuta chiavi malformate e prodotti non cached', () async {
    await expectLater(
      cache.toggleFavorite(
        shopSlug: '../storefront-test',
        publicationId: _product(1, 'Valido', price: 1000).id,
      ),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.code,
          'code',
          'invalid_favorite_key',
        ),
      ),
    );
    await expectLater(
      cache.toggleFavorite(
        shopSlug: 'storefront-test',
        publicationId: _product(2, 'Assente', price: 1000).id,
      ),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.code,
          'code',
          'favorite_product_unavailable',
        ),
      ),
    );
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
