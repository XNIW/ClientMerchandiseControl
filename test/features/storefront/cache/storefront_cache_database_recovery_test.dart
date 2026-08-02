import 'dart:io';

import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'storefront-cache-recovery-',
    );
    databasePath = '${temporaryDirectory.path}/cache.sqlite';
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('schema v2 riapre senza perdere una cache compatibile', () async {
    final first = StorefrontCacheDatabase(NativeDatabase(File(databasePath)));
    await first.customStatement(
      "INSERT INTO storefront_cache_metadata "
      "(shop_slug, catalog_version, refreshed_at, "
      "last_successful_refresh_at) VALUES "
      "('storefront-test', 7, 1, 1)",
    );
    await first.close();

    prepareStorefrontCacheFile(databasePath);
    final reopened = StorefrontCacheDatabase(
      NativeDatabase(File(databasePath)),
    );
    addTearDown(reopened.close);

    final rows = await reopened
        .customSelect(
          "SELECT catalog_version FROM storefront_cache_metadata "
          "WHERE shop_slug = 'storefront-test'",
        )
        .get();
    expect(rows.single.read<int>('catalog_version'), 7);
  });

  test('migration v1 a v2 aggiunge favorite senza perdere la cache', () async {
    final legacy = StorefrontCacheDatabase(NativeDatabase(File(databasePath)));
    await legacy.customStatement(
      "INSERT INTO storefront_cache_metadata "
      "(shop_slug, catalog_version, refreshed_at, "
      "last_successful_refresh_at) VALUES "
      "('storefront-test', 7, 1, 1)",
    );
    await legacy.customStatement('DROP INDEX storefront_favorite_order_idx');
    await legacy.customStatement('DROP TABLE storefront_favorites');
    await legacy.customStatement('PRAGMA user_version = 1');
    await legacy.close();

    prepareStorefrontCacheFile(databasePath);
    final migrated = StorefrontCacheDatabase(
      NativeDatabase(File(databasePath)),
    );
    addTearDown(migrated.close);
    final cached = await migrated
        .customSelect(
          "SELECT catalog_version FROM storefront_cache_metadata "
          "WHERE shop_slug = 'storefront-test'",
        )
        .get();
    final favoriteTable = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'storefront_favorites'",
        )
        .get();

    expect(cached.single.read<int>('catalog_version'), 7);
    expect(favoriteTable, hasLength(1));
    expect(
      (await migrated.customSelect('PRAGMA user_version').get()).single
          .read<int>('user_version'),
      2,
    );
  });

  test('file SQLite corrotto viene eliminato e ricreato fail-closed', () async {
    File(databasePath).writeAsBytesSync(
      List<int>.generate(512, (index) => (index * 31) & 0xff),
      flush: true,
    );

    prepareStorefrontCacheFile(databasePath);
    expect(File(databasePath).existsSync(), isFalse);

    final rebuilt = StorefrontCacheDatabase(NativeDatabase(File(databasePath)));
    addTearDown(rebuilt.close);
    final tables = await rebuilt
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE name = 'cached_storefront_products'",
        )
        .get();
    expect(tables, hasLength(1));
  });

  test(
    'schema futuro incompatibile viene ricostruito senza downgrade',
    () async {
      final future = StorefrontCacheDatabase(
        NativeDatabase(File(databasePath)),
      );
      await future.customStatement('PRAGMA user_version = 99');
      await future.close();

      prepareStorefrontCacheFile(databasePath);
      expect(File(databasePath).existsSync(), isFalse);

      final rebuilt = StorefrontCacheDatabase(
        NativeDatabase(File(databasePath)),
      );
      addTearDown(rebuilt.close);
      expect(rebuilt.schemaVersion, storefrontCacheSchemaVersion);
      expect(
        (await rebuilt.customSelect('PRAGMA user_version').get()).single
            .read<int>('user_version'),
        storefrontCacheSchemaVersion,
      );
    },
  );

  test('transazione interrotta non lascia metadata parziale', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.customSelect('SELECT 1').get();

    await expectLater(
      database.transaction(() async {
        await database.customStatement(
          "INSERT INTO storefront_cache_metadata "
          "(shop_slug, catalog_version, refreshed_at, "
          "last_successful_refresh_at) VALUES "
          "('storefront-test', 7, 1, 1)",
        );
        throw StateError('simulated_app_kill');
      }),
      throwsStateError,
    );

    expect(
      await database.select(database.storefrontCacheMetadata).get(),
      isEmpty,
    );
  });
}
