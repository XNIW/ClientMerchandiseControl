import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

part 'storefront_cache_database.g.dart';

const storefrontCacheSchemaVersion = 2;

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

@DriftDatabase(
  tables: [
    StorefrontCacheMetadata,
    CachedStorefrontCategories,
    CachedStorefrontProducts,
    CachedStorefrontDetails,
    StorefrontCacheScopes,
    StorefrontCacheScopeItems,
    StorefrontFavorites,
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
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(storefrontFavorites);
        await _createFavoriteIndex();
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
