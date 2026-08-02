import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

part 'storefront_cache_database.g.dart';

const storefrontCacheSchemaVersion = 4;

@DataClassName('StorefrontCacheMetadataRow')
class StorefrontCacheMetadata extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  IntColumn get catalogVersion => integer()();
  DateTimeColumn get refreshedAt => dateTime()();
  DateTimeColumn get lastSuccessfulRefreshAt => dateTime()();
  TextColumn get currency => text().nullable()();
  TextColumn get locale => text().nullable()();
  TextColumn get timeZone => text().nullable()();
  IntColumn get defaultPageSize => integer().nullable()();
  IntColumn get maximumPageSize => integer().nullable()();
  BoolColumn get pickupEnabled => boolean().nullable()();
  BoolColumn get deliveryEnabled => boolean().nullable()();
  BoolColumn get reservationEnabled => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug};
}

@DataClassName('CachedStorefrontCategoryRow')
class CachedStorefrontCategories extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get categoryId => text().withLength(min: 36, max: 36)();
  TextColumn get slug => text().withLength(min: 2, max: 63)();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  IntColumn get sortRank => integer()();
  IntColumn get catalogVersion => integer()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, categoryId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {shopSlug, slug},
  ];
}

@DataClassName('CachedStorefrontProductRow')
class CachedStorefrontProducts extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get publicationId => text().withLength(min: 36, max: 36)();
  TextColumn get categoryId => text().withLength(min: 36, max: 36)();
  TextColumn get categorySlug => text().withLength(min: 2, max: 63)();
  TextColumn get categoryName => text().withLength(min: 1, max: 160)();
  IntColumn get categorySortRank => integer()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get normalizedSearchText => text().withLength(min: 1, max: 640)();
  IntColumn get priceClp => integer()();
  IntColumn get compareAtPriceClp => integer().nullable()();
  IntColumn get discountBps => integer().nullable()();
  TextColumn get promotionId => text().nullable()();
  TextColumn get promotionName => text().nullable()();
  DateTimeColumn get promotionStartsAt => dateTime().nullable()();
  DateTimeColumn get promotionEndsAt => dateTime().nullable()();
  BoolColumn get featured => boolean()();
  IntColumn get sortRank => integer()();
  TextColumn get availability => text().withLength(min: 8, max: 32)();
  BoolColumn get pickupEnabled => boolean()();
  BoolColumn get deliveryEnabled => boolean()();
  BoolColumn get reservationEnabled => boolean()();
  TextColumn get imageVersion => text().nullable()();
  TextColumn get imageThumbUrl => text().nullable()();
  TextColumn get imageCardUrl => text().nullable()();
  TextColumn get imageDetailUrl => text().nullable()();
  TextColumn get imageSha256 => text().nullable()();
  IntColumn get catalogVersion => integer()();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, publicationId};
}

@DataClassName('CachedStorefrontDetailRow')
class CachedStorefrontDetails extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get publicationId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, publicationId};
}

@DataClassName('StorefrontCacheScopeRow')
class StorefrontCacheScopes extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get scopeKey => text().withLength(min: 1, max: 320)();
  IntColumn get catalogVersion => integer()();
  DateTimeColumn get refreshedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, scopeKey};
}

@DataClassName('StorefrontCacheScopeItemRow')
class StorefrontCacheScopeItems extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get scopeKey => text().withLength(min: 1, max: 320)();
  TextColumn get publicationId => text().withLength(min: 36, max: 36)();
  IntColumn get ordinal => integer()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, scopeKey, publicationId};
}

@DataClassName('StorefrontFavoriteRow')
class StorefrontFavorites extends Table {
  TextColumn get shopSlug => text().withLength(min: 2, max: 63)();
  TextColumn get publicationId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, publicationId};
}

@DataClassName('StorefrontGuestCartItemRow')
class StorefrontGuestCartItems extends Table {
  TextColumn get shopSlug => text().withLength(min: 3, max: 63)();
  TextColumn get publicationId => text().withLength(min: 36, max: 36)();
  IntColumn get quantity => integer().customConstraint(
    'NOT NULL CHECK (quantity BETWEEN 1 AND 99)',
  )();
  TextColumn get publicName => text().withLength(min: 1, max: 200)();
  IntColumn get priceClp =>
      integer().customConstraint('NOT NULL CHECK (price_clp >= 0)')();
  IntColumn get compareAtPriceClp => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get availability => text().withLength(min: 8, max: 32)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {shopSlug, publicationId};
}

@DriftDatabase(
  tables: [
    StorefrontCacheMetadata,
    CachedStorefrontCategories,
    CachedStorefrontProducts,
    CachedStorefrontDetails,
    StorefrontCacheScopes,
    StorefrontCacheScopeItems,
    StorefrontFavorites,
    StorefrontGuestCartItems,
  ],
)
class StorefrontCacheDatabase extends _$StorefrontCacheDatabase {
  StorefrontCacheDatabase(super.executor);

  StorefrontCacheDatabase.defaults()
    : super(
        driftDatabase(
          name: 'storefront_public_cache',
          native: DriftNativeOptions(
            databasePath: _storefrontCachePath,
            setup: _configureStorefrontCache,
          ),
        ),
      );

  @override
  int get schemaVersion => storefrontCacheSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE INDEX storefront_cache_category_order_idx '
        'ON cached_storefront_categories '
        '(shop_slug, sort_rank, name, category_id)',
      );
      await customStatement(
        'CREATE INDEX storefront_cache_product_catalog_idx '
        'ON cached_storefront_products '
        '(shop_slug, sort_rank, name, publication_id)',
      );
      await customStatement(
        'CREATE INDEX storefront_cache_product_category_idx '
        'ON cached_storefront_products '
        '(shop_slug, category_slug, sort_rank, publication_id)',
      );
      await customStatement(
        'CREATE INDEX storefront_cache_product_price_idx '
        'ON cached_storefront_products '
        '(shop_slug, price_clp, name, publication_id)',
      );
      await customStatement(
        'CREATE INDEX storefront_cache_product_access_idx '
        'ON cached_storefront_products '
        '(shop_slug, last_accessed_at, publication_id)',
      );
      await customStatement(
        'CREATE INDEX storefront_cache_scope_item_order_idx '
        'ON storefront_cache_scope_items '
        '(shop_slug, scope_key, ordinal, publication_id)',
      );
      await _createFavoriteIndex();
      await _createGuestCartIndex();
      await _createGuestCartProductRefreshTrigger();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(storefrontFavorites);
        await _createFavoriteIndex();
      }
      if (from < 3) {
        await migrator.createTable(storefrontGuestCartItems);
        await _createGuestCartIndex();
      }
      if (from < 4) {
        await _createGuestCartProductRefreshTrigger();
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createFavoriteIndex() => customStatement(
    'CREATE INDEX storefront_favorite_order_idx '
    'ON storefront_favorites '
    '(shop_slug, updated_at DESC, publication_id)',
  );

  Future<void> _createGuestCartIndex() => customStatement(
    'CREATE INDEX storefront_guest_cart_order_idx '
    'ON storefront_guest_cart_items '
    '(shop_slug, updated_at DESC, publication_id)',
  );

  Future<void> _createGuestCartProductRefreshTrigger() => customStatement(
    'CREATE TRIGGER IF NOT EXISTS storefront_guest_cart_product_refresh '
    'AFTER INSERT ON cached_storefront_products '
    'FOR EACH ROW BEGIN '
    'UPDATE storefront_guest_cart_items SET '
    'public_name = NEW.name, '
    'price_clp = NEW.price_clp, '
    'compare_at_price_clp = NEW.compare_at_price_clp, '
    'image_url = NEW.image_thumb_url, '
    'availability = NEW.availability, '
    'updated_at = NEW.cached_at '
    'WHERE shop_slug = NEW.shop_slug '
    'AND publication_id = NEW.publication_id; '
    'END',
  );
}

Future<String> _storefrontCachePath() async {
  final directory = await getApplicationSupportDirectory();
  final path = p.join(directory.path, 'storefront_public_cache.sqlite');
  await Isolate.run(() => prepareStorefrontCacheFile(path));
  return path;
}

void prepareStorefrontCacheFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  Database? database;
  var mustRebuild = false;
  try {
    database = sqlite3.open(path);
    final integrity = database.select('PRAGMA quick_check(1)');
    final quickCheck = integrity.isEmpty
        ? null
        : integrity.first.values.firstOrNull;
    final versionRows = database.select('PRAGMA user_version');
    final version = versionRows.isEmpty
        ? null
        : versionRows.first.values.firstOrNull;
    mustRebuild =
        quickCheck != 'ok' ||
        version is! int ||
        version > storefrontCacheSchemaVersion;
  } on Object {
    mustRebuild = true;
  } finally {
    database?.close();
  }
  if (!mustRebuild) return;
  for (final suffix in const ['', '-wal', '-shm']) {
    final artifact = File('$path$suffix');
    if (artifact.existsSync()) artifact.deleteSync();
  }
}

void _configureStorefrontCache(CommonDatabase database) {
  database.execute('PRAGMA journal_mode = WAL');
  database.execute('PRAGMA synchronous = NORMAL');
  database.execute('PRAGMA busy_timeout = 5000');
  database.execute('PRAGMA page_size = 4096');
  database.execute('PRAGMA max_page_count = 16384');
}
