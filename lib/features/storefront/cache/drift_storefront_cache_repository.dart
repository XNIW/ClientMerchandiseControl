import 'package:drift/drift.dart';

import '../domain/storefront_failure.dart';
import '../domain/storefront_models.dart';
import 'storefront_cache_database.dart';
import 'storefront_cache_repository.dart';

class DriftStorefrontCacheRepository implements StorefrontCacheRepository {
  static final _publicationId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  static final _shopSlug = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');

  DriftStorefrontCacheRepository(this.database, {DateTime Function()? clock})
    : _clock = clock ?? _utcNow;

  final StorefrontCacheDatabase database;
  final DateTime Function() _clock;

  @override
  Future<StorefrontCacheSnapshot<StorefrontHomeData>?> readHome({
    required String shopSlug,
  }) => _safeRead(shopSlug, () async {
    final refreshedAt = await _scopeTime(shopSlug, _homeScope);
    final metadata = await _metadata(shopSlug);
    if (refreshedAt == null || metadata == null || !_usable(refreshedAt)) {
      return null;
    }
    final settings = _settingsFromMetadata(metadata);
    if (settings == null) return null;

    final categoryQuery = database.select(database.cachedStorefrontCategories)
      ..where((row) => row.shopSlug.equals(shopSlug))
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortRank),
        (row) => OrderingTerm.asc(row.name),
        (row) => OrderingTerm.asc(row.categoryId),
      ])
      ..limit(12);
    final results = await Future.wait<Object>([
      categoryQuery.get(),
      _productsForScope(shopSlug, _homeFeaturedScope),
      _productsForScope(shopSlug, _homeOffersScope),
    ]);
    return StorefrontCacheSnapshot(
      value: StorefrontHomeData(
        catalogVersion: metadata.catalogVersion,
        settings: settings,
        categories: (results[0] as List<CachedStorefrontCategoryRow>)
            .map(_categoryFromRow)
            .toList(growable: false),
        featured: (results[1] as List<CachedStorefrontProductRow>)
            .map(_productFromRow)
            .toList(growable: false),
        offers: (results[2] as List<CachedStorefrontProductRow>)
            .map(_productFromRow)
            .toList(growable: false),
      ),
      refreshedAt: refreshedAt,
    );
  });

  @override
  Future<StorefrontCacheSnapshot<StorefrontCategoriesPage>?> readCategories({
    required String shopSlug,
  }) => _safeRead(shopSlug, () async {
    final refreshedAt = await _scopeTime(shopSlug, _categoriesScope);
    final metadata = await _metadata(shopSlug);
    if (refreshedAt == null || metadata == null || !_usable(refreshedAt)) {
      return null;
    }
    final query = database.select(database.cachedStorefrontCategories)
      ..where((row) => row.shopSlug.equals(shopSlug))
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortRank),
        (row) => OrderingTerm.asc(row.name),
        (row) => OrderingTerm.asc(row.categoryId),
      ]);
    final rows = await query.get();
    return StorefrontCacheSnapshot(
      value: StorefrontCategoriesPage(
        catalogVersion: metadata.catalogVersion,
        categories: rows.map(_categoryFromRow).toList(growable: false),
        nextCursor: null,
      ),
      refreshedAt: refreshedAt,
    );
  });

  @override
  Future<StorefrontCacheSnapshot<StorefrontCatalogPage>?> readCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
  }) => _safeRead(shopSlug, () async {
    _validateLimit(limit);
    final offset = _decodeCursor(cursor);
    final scope = _catalogScope(
      categorySlug: categorySlug,
      availability: availability,
      discounted: discounted,
      sort: sort,
    );
    final refreshedAt = await _scopeTime(shopSlug, scope);
    final metadata = await _metadata(shopSlug);
    if (refreshedAt == null || metadata == null || !_usable(refreshedAt)) {
      return null;
    }

    final query = database.select(database.cachedStorefrontProducts)
      ..where((row) {
        var predicate = row.shopSlug.equals(shopSlug);
        if (categorySlug != null) {
          predicate &= row.categorySlug.equals(categorySlug);
        }
        if (availability != null) {
          predicate &= row.availability.equals(
            _availabilityValue(availability),
          );
        }
        if (discounted == true) predicate &= row.discountBps.isNotNull();
        return predicate;
      })
      ..orderBy(_orderingFor(sort))
      ..limit(limit + 1, offset: offset);
    final rows = await query.get();
    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.take(limit) : rows;
    return StorefrontCacheSnapshot(
      value: StorefrontCatalogPage(
        catalogVersion: metadata.catalogVersion,
        items: pageRows.map(_productFromRow).toList(growable: false),
        nextCursor: hasMore ? _encodeCursor(offset + limit) : null,
        sort: sort,
      ),
      refreshedAt: refreshedAt,
    );
  });

  @override
  Future<StorefrontCacheSnapshot<StorefrontSearchPage>?> readSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
  }) => _safeRead(shopSlug, () async {
    _validateLimit(limit);
    final normalizedQuery = normalizeStorefrontCacheSearch(query);
    if (normalizedQuery.length < 2 || normalizedQuery.length > 120) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_cache_search_query',
      );
    }
    final offset = _decodeCursor(cursor);
    final metadata = await _metadata(shopSlug);
    if (metadata == null || !_usable(metadata.refreshedAt)) return null;
    final escaped = _escapeLike(normalizedQuery);
    final search = '%$escaped%';
    final select = database.select(database.cachedStorefrontProducts)
      ..where((row) {
        var predicate =
            row.shopSlug.equals(shopSlug) &
            row.normalizedSearchText.like(search, escapeChar: r'\');
        if (categorySlug != null) {
          predicate &= row.categorySlug.equals(categorySlug);
        }
        return predicate;
      })
      ..orderBy([
        (row) => OrderingTerm.asc(row.name),
        (row) => OrderingTerm.asc(row.publicationId),
      ])
      ..limit(limit + 1, offset: offset);
    final rows = await select.get();
    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.take(limit) : rows;
    return StorefrontCacheSnapshot(
      value: StorefrontSearchPage(
        catalogVersion: metadata.catalogVersion,
        query: query.trim().replaceAll(RegExp(r'\s+'), ' '),
        items: pageRows.map(_productFromRow).toList(growable: false),
        nextCursor: hasMore ? _encodeCursor(offset + limit) : null,
      ),
      refreshedAt: metadata.refreshedAt,
    );
  });

  @override
  Future<StorefrontCacheSnapshot<StorefrontProductSummary>?> readProductDetail({
    required String shopSlug,
    required String publicationId,
  }) => _safeRead(shopSlug, () async {
    final detailQuery = database.select(database.cachedStorefrontDetails)
      ..where(
        (row) =>
            row.shopSlug.equals(shopSlug) &
            row.publicationId.equals(publicationId),
      );
    final detail = await detailQuery.getSingleOrNull();
    if (detail == null || !_usable(detail.cachedAt)) return null;
    final productQuery = database.select(database.cachedStorefrontProducts)
      ..where(
        (row) =>
            row.shopSlug.equals(shopSlug) &
            row.publicationId.equals(publicationId),
      );
    final product = await productQuery.getSingleOrNull();
    if (product == null) return null;
    final accessedAt = _clock().toUtc();
    await (database.update(database.cachedStorefrontDetails)..where(
          (row) =>
              row.shopSlug.equals(shopSlug) &
              row.publicationId.equals(publicationId),
        ))
        .write(
          CachedStorefrontDetailsCompanion(lastAccessedAt: Value(accessedAt)),
        );
    return StorefrontCacheSnapshot(
      value: _productFromRow(product),
      refreshedAt: detail.cachedAt,
    );
  });

  @override
  Future<void> writeHome({
    required String shopSlug,
    required StorefrontHomeData data,
  }) async {
    _validateShop(shopSlug, data.settings.shopSlug);
    _validateProductVersions([
      ...data.featured,
      ...data.offers,
    ], data.catalogVersion);
    final now = _clock().toUtc();
    await database.transaction(() async {
      await _prepareVersion(
        shopSlug,
        data.catalogVersion,
        now,
        settings: data.settings,
      );
      await _replaceCategories(
        shopSlug,
        data.categories,
        data.catalogVersion,
        now,
      );
      await _replaceProducts(shopSlug, [...data.featured, ...data.offers], now);
      await _replaceScopeItems(shopSlug, _homeFeaturedScope, data.featured);
      await _replaceScopeItems(shopSlug, _homeOffersScope, data.offers);
      await _writeScope(shopSlug, _homeScope, data.catalogVersion, now);
    });
  }

  @override
  Future<void> writeCategories({
    required String shopSlug,
    required StorefrontCategoriesPage page,
  }) async {
    final now = _clock().toUtc();
    await database.transaction(() async {
      await _prepareVersion(shopSlug, page.catalogVersion, now);
      await _replaceCategories(
        shopSlug,
        page.categories,
        page.catalogVersion,
        now,
      );
      await _writeScope(shopSlug, _categoriesScope, page.catalogVersion, now);
    });
  }

  @override
  Future<void> writeCatalog({
    required String shopSlug,
    required StorefrontCatalogPage page,
    required String? categorySlug,
    required StorefrontAvailability? availability,
    required bool? discounted,
  }) async {
    _validateProductVersions(page.items, page.catalogVersion);
    final now = _clock().toUtc();
    await database.transaction(() async {
      await _prepareVersion(shopSlug, page.catalogVersion, now);
      await _replaceProducts(shopSlug, page.items, now);
      await _writeScope(
        shopSlug,
        _catalogScope(
          categorySlug: categorySlug,
          availability: availability,
          discounted: discounted,
          sort: page.sort,
        ),
        page.catalogVersion,
        now,
      );
    });
  }

  @override
  Future<void> writeSearch({
    required String shopSlug,
    required StorefrontSearchPage page,
    required String? categorySlug,
  }) async {
    _validateProductVersions(page.items, page.catalogVersion);
    final now = _clock().toUtc();
    await database.transaction(() async {
      await _prepareVersion(shopSlug, page.catalogVersion, now);
      await _replaceProducts(shopSlug, page.items, now);
      await _writeScope(
        shopSlug,
        _searchScope(page.query, categorySlug),
        page.catalogVersion,
        now,
      );
    });
  }

  @override
  Future<void> writeProductDetail({
    required String shopSlug,
    required StorefrontProductSummary product,
  }) async {
    final now = _clock().toUtc();
    await database.transaction(() async {
      await _prepareVersion(shopSlug, product.catalogVersion, now);
      await _replaceProducts(shopSlug, [product], now);
      await database
          .into(database.cachedStorefrontDetails)
          .insertOnConflictUpdate(
            CachedStorefrontDetailsCompanion.insert(
              shopSlug: shopSlug,
              publicationId: product.id,
              cachedAt: now,
              lastAccessedAt: now,
            ),
          );
    });
  }

  @override
  Future<List<StorefrontFavoriteEntry>> readFavorites({
    required String shopSlug,
  }) async {
    _validateFavoriteKey(shopSlug, null);
    try {
      final favoritesQuery = database.select(database.storefrontFavorites)
        ..where((row) => row.shopSlug.equals(shopSlug))
        ..orderBy([
          (row) => OrderingTerm.desc(row.updatedAt),
          (row) => OrderingTerm.asc(row.publicationId),
        ])
        ..limit(storefrontMaximumFavorites);
      final favorites = await favoritesQuery.get();
      if (favorites.isEmpty) return const [];
      final publicationIds = favorites
          .map((favorite) => favorite.publicationId)
          .toList(growable: false);
      final productRows =
          await (database.select(database.cachedStorefrontProducts)..where(
                (row) =>
                    row.shopSlug.equals(shopSlug) &
                    row.publicationId.isIn(publicationIds),
              ))
              .get();
      final products = {
        for (final row in productRows) row.publicationId: _productFromRow(row),
      };
      return List.unmodifiable(
        favorites.map(
          (favorite) => StorefrontFavoriteEntry(
            publicationId: favorite.publicationId,
            updatedAt: favorite.updatedAt,
            product: products[favorite.publicationId],
          ),
        ),
      );
    } on StorefrontFailure {
      rethrow;
    } on Object {
      throw const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'favorite_cache_read_failed',
      );
    }
  }

  @override
  Future<bool> toggleFavorite({
    required String shopSlug,
    required String publicationId,
  }) async {
    _validateFavoriteKey(shopSlug, publicationId);
    final now = _clock().toUtc();
    try {
      return await database.transaction(() async {
        final existing =
            await (database.select(database.storefrontFavorites)..where(
                  (row) =>
                      row.shopSlug.equals(shopSlug) &
                      row.publicationId.equals(publicationId),
                ))
                .getSingleOrNull();
        if (existing != null) {
          await (database.delete(database.storefrontFavorites)..where(
                (row) =>
                    row.shopSlug.equals(shopSlug) &
                    row.publicationId.equals(publicationId),
              ))
              .go();
          return false;
        }

        final product =
            await (database.select(database.cachedStorefrontProducts)..where(
                  (row) =>
                      row.shopSlug.equals(shopSlug) &
                      row.publicationId.equals(publicationId),
                ))
                .getSingleOrNull();
        if (product == null) {
          throw const StorefrontFailure(
            StorefrontFailureKind.unavailable,
            code: 'favorite_product_unavailable',
          );
        }

        await database
            .into(database.storefrontFavorites)
            .insert(
              StorefrontFavoritesCompanion.insert(
                shopSlug: shopSlug,
                publicationId: publicationId,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database.customUpdate(
          'DELETE FROM storefront_favorites '
          'WHERE shop_slug = ? AND publication_id IN ('
          'SELECT publication_id FROM storefront_favorites '
          'WHERE shop_slug = ? ORDER BY updated_at DESC, publication_id '
          'LIMIT -1 OFFSET ?)',
          variables: [
            Variable.withString(shopSlug),
            Variable.withString(shopSlug),
            Variable.withInt(storefrontMaximumFavorites),
          ],
          updates: {database.storefrontFavorites},
        );
        return true;
      });
    } on StorefrontFailure {
      rethrow;
    } on Object {
      throw const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'favorite_cache_write_failed',
      );
    }
  }

  @override
  Future<void> cleanup({required String shopSlug}) async {
    final metadata = await _metadata(shopSlug);
    if (metadata != null && !_usable(metadata.refreshedAt)) {
      await clearShop(shopSlug: shopSlug);
      return;
    }
    await database.transaction(() async {
      await database.customUpdate(
        'DELETE FROM cached_storefront_details '
        'WHERE shop_slug = ? AND publication_id IN ('
        'SELECT publication_id FROM cached_storefront_details '
        'WHERE shop_slug = ? ORDER BY last_accessed_at DESC, publication_id '
        'LIMIT -1 OFFSET ?)',
        variables: [
          Variable.withString(shopSlug),
          Variable.withString(shopSlug),
          Variable.withInt(storefrontCacheMaximumDetails),
        ],
        updates: {database.cachedStorefrontDetails},
      );
      await database.customUpdate(
        'DELETE FROM cached_storefront_products '
        'WHERE shop_slug = ? AND publication_id IN ('
        'SELECT publication_id FROM cached_storefront_products '
        'WHERE shop_slug = ? ORDER BY last_accessed_at DESC, publication_id '
        'LIMIT -1 OFFSET ?)',
        variables: [
          Variable.withString(shopSlug),
          Variable.withString(shopSlug),
          Variable.withInt(storefrontCacheMaximumProducts),
        ],
        updates: {database.cachedStorefrontProducts},
      );
      await database.customUpdate(
        'DELETE FROM cached_storefront_details WHERE shop_slug = ? '
        'AND NOT EXISTS (SELECT 1 FROM cached_storefront_products p '
        'WHERE p.shop_slug = cached_storefront_details.shop_slug '
        'AND p.publication_id = cached_storefront_details.publication_id)',
        variables: [Variable.withString(shopSlug)],
        updates: {database.cachedStorefrontDetails},
      );
      await database.customUpdate(
        'DELETE FROM storefront_cache_scope_items WHERE shop_slug = ? '
        'AND NOT EXISTS (SELECT 1 FROM cached_storefront_products p '
        'WHERE p.shop_slug = storefront_cache_scope_items.shop_slug '
        'AND p.publication_id = '
        'storefront_cache_scope_items.publication_id)',
        variables: [Variable.withString(shopSlug)],
        updates: {database.storefrontCacheScopeItems},
      );
    });
  }

  @override
  Future<void> clearShop({required String shopSlug}) =>
      database.transaction(() async {
        await (database.delete(
          database.cachedStorefrontDetails,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
        await (database.delete(
          database.cachedStorefrontProducts,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
        await (database.delete(
          database.cachedStorefrontCategories,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
        await (database.delete(
          database.storefrontCacheScopeItems,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
        await (database.delete(
          database.storefrontCacheScopes,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
        await (database.delete(
          database.storefrontCacheMetadata,
        )..where((row) => row.shopSlug.equals(shopSlug))).go();
      });

  Future<void> _prepareVersion(
    String shopSlug,
    int catalogVersion,
    DateTime now, {
    StorefrontSettings? settings,
  }) async {
    if (catalogVersion < 1) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'invalid_cache_catalog_version',
      );
    }
    final existing = await _metadata(shopSlug);
    if (existing != null && catalogVersion < existing.catalogVersion) {
      throw const StorefrontFailure(
        StorefrontFailureKind.catalogChanged,
        code: 'cache_catalog_version_regressed',
      );
    }
    if (existing != null && catalogVersion > existing.catalogVersion) {
      await (database.delete(
        database.cachedStorefrontDetails,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
      await (database.delete(
        database.cachedStorefrontProducts,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
      await (database.delete(
        database.cachedStorefrontCategories,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
      await (database.delete(
        database.storefrontCacheScopeItems,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
      await (database.delete(
        database.storefrontCacheScopes,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
    }
    await database
        .into(database.storefrontCacheMetadata)
        .insertOnConflictUpdate(
          StorefrontCacheMetadataCompanion.insert(
            shopSlug: shopSlug,
            catalogVersion: catalogVersion,
            refreshedAt: now,
            lastSuccessfulRefreshAt: now,
            currency: Value.absentIfNull(settings?.currency),
            locale: Value.absentIfNull(settings?.locale),
            timeZone: Value.absentIfNull(settings?.timeZone),
            defaultPageSize: Value.absentIfNull(settings?.defaultPageSize),
            maximumPageSize: Value.absentIfNull(settings?.maximumPageSize),
            pickupEnabled: Value.absentIfNull(settings?.fulfillment.pickup),
            deliveryEnabled: Value.absentIfNull(settings?.fulfillment.delivery),
            reservationEnabled: Value.absentIfNull(
              settings?.fulfillment.reservation,
            ),
          ),
        );
  }

  Future<void> _replaceCategories(
    String shopSlug,
    List<StorefrontCategory> categories,
    int catalogVersion,
    DateTime now,
  ) => database.batch((batch) {
    batch.insertAll(
      database.cachedStorefrontCategories,
      categories
          .map(
            (category) => CachedStorefrontCategoriesCompanion.insert(
              shopSlug: shopSlug,
              categoryId: category.id,
              slug: category.slug,
              name: category.name,
              sortRank: category.sortRank,
              catalogVersion: catalogVersion,
              cachedAt: now,
            ),
          )
          .toList(growable: false),
      mode: InsertMode.insertOrReplace,
    );
  });

  Future<void> _replaceProducts(
    String shopSlug,
    Iterable<StorefrontProductSummary> products,
    DateTime now,
  ) {
    final unique = <String, StorefrontProductSummary>{
      for (final product in products) product.id: product,
    };
    if (unique.isEmpty) return Future<void>.value();
    return database.batch((batch) {
      batch.insertAll(
        database.cachedStorefrontProducts,
        unique.values
            .map((product) => _productCompanion(shopSlug, product, now))
            .toList(growable: false),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  CachedStorefrontProductsCompanion _productCompanion(
    String shopSlug,
    StorefrontProductSummary product,
    DateTime now,
  ) => CachedStorefrontProductsCompanion.insert(
    shopSlug: shopSlug,
    publicationId: product.id,
    categoryId: product.category.id,
    categorySlug: product.category.slug,
    categoryName: product.category.name,
    categorySortRank: product.category.sortRank,
    name: product.name,
    description: Value.absentIfNull(product.description),
    brand: Value.absentIfNull(product.brand),
    normalizedSearchText: normalizeStorefrontCacheSearch(
      '${product.name} ${product.category.name} ${product.brand ?? ''}',
    ),
    priceClp: product.priceClp,
    compareAtPriceClp: Value.absentIfNull(product.compareAtPriceClp),
    discountBps: Value.absentIfNull(product.discountBps),
    promotionId: Value.absentIfNull(product.promotion?.id),
    promotionName: Value.absentIfNull(product.promotion?.name),
    promotionStartsAt: Value.absentIfNull(product.promotion?.startsAt),
    promotionEndsAt: Value.absentIfNull(product.promotion?.endsAt),
    featured: product.featured,
    sortRank: product.sortRank,
    availability: _availabilityValue(product.availability),
    pickupEnabled: product.fulfillment.pickup,
    deliveryEnabled: product.fulfillment.delivery,
    reservationEnabled: product.fulfillment.reservation,
    imageVersion: Value.absentIfNull(product.images?.version),
    imageThumbUrl: Value.absentIfNull(product.images?.thumb.toString()),
    imageCardUrl: Value.absentIfNull(product.images?.card.toString()),
    imageDetailUrl: Value.absentIfNull(product.images?.detail.toString()),
    imageSha256: Value.absentIfNull(product.images?.sha256),
    catalogVersion: product.catalogVersion,
    publishedAt: product.publishedAt,
    updatedAt: product.updatedAt,
    cachedAt: now,
    lastAccessedAt: now,
  );

  Future<void> _writeScope(
    String shopSlug,
    String scopeKey,
    int catalogVersion,
    DateTime now,
  ) => database
      .into(database.storefrontCacheScopes)
      .insertOnConflictUpdate(
        StorefrontCacheScopesCompanion.insert(
          shopSlug: shopSlug,
          scopeKey: scopeKey,
          catalogVersion: catalogVersion,
          refreshedAt: now,
        ),
      );

  Future<void> _replaceScopeItems(
    String shopSlug,
    String scopeKey,
    List<StorefrontProductSummary> products,
  ) async {
    await (database.delete(database.storefrontCacheScopeItems)..where(
          (row) =>
              row.shopSlug.equals(shopSlug) & row.scopeKey.equals(scopeKey),
        ))
        .go();
    if (products.isEmpty) return;
    await database.batch((batch) {
      batch.insertAll(
        database.storefrontCacheScopeItems,
        products.indexed
            .map(
              (entry) => StorefrontCacheScopeItemsCompanion.insert(
                shopSlug: shopSlug,
                scopeKey: scopeKey,
                publicationId: entry.$2.id,
                ordinal: entry.$1,
              ),
            )
            .toList(growable: false),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<CachedStorefrontProductRow>> _productsForScope(
    String shopSlug,
    String scopeKey,
  ) async {
    final memberQuery = database.select(database.storefrontCacheScopeItems)
      ..where(
        (row) => row.shopSlug.equals(shopSlug) & row.scopeKey.equals(scopeKey),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.ordinal),
        (row) => OrderingTerm.asc(row.publicationId),
      ]);
    final members = await memberQuery.get();
    if (members.isEmpty) return const [];
    final ids = members.map((member) => member.publicationId).toList();
    final productQuery = database.select(database.cachedStorefrontProducts)
      ..where(
        (row) => row.shopSlug.equals(shopSlug) & row.publicationId.isIn(ids),
      );
    final products = await productQuery.get();
    final byId = {
      for (final product in products) product.publicationId: product,
    };
    return members
        .map((member) => byId[member.publicationId])
        .whereType<CachedStorefrontProductRow>()
        .toList(growable: false);
  }

  Future<StorefrontCacheMetadataRow?> _metadata(String shopSlug) {
    final query = database.select(database.storefrontCacheMetadata)
      ..where((row) => row.shopSlug.equals(shopSlug));
    return query.getSingleOrNull();
  }

  Future<DateTime?> _scopeTime(String shopSlug, String scopeKey) async {
    final query = database.select(database.storefrontCacheScopes)
      ..where(
        (row) => row.shopSlug.equals(shopSlug) & row.scopeKey.equals(scopeKey),
      );
    return (await query.getSingleOrNull())?.refreshedAt;
  }

  StorefrontSettings? _settingsFromMetadata(StorefrontCacheMetadataRow row) {
    final currency = row.currency;
    final locale = row.locale;
    final timeZone = row.timeZone;
    final defaultPageSize = row.defaultPageSize;
    final maximumPageSize = row.maximumPageSize;
    final pickup = row.pickupEnabled;
    final delivery = row.deliveryEnabled;
    final reservation = row.reservationEnabled;
    if (currency != 'CLP' ||
        locale == null ||
        timeZone == null ||
        defaultPageSize == null ||
        maximumPageSize == null ||
        pickup == null ||
        delivery == null ||
        reservation == null) {
      return null;
    }
    return StorefrontSettings(
      shopSlug: row.shopSlug,
      currency: 'CLP',
      locale: locale,
      timeZone: timeZone,
      defaultPageSize: defaultPageSize,
      maximumPageSize: maximumPageSize,
      fulfillment: StorefrontFulfillment(
        pickup: pickup,
        delivery: delivery,
        reservation: reservation,
      ),
    );
  }

  StorefrontCategory _categoryFromRow(CachedStorefrontCategoryRow row) =>
      StorefrontCategory(
        id: row.categoryId,
        slug: row.slug,
        name: row.name,
        sortRank: row.sortRank,
      );

  StorefrontProductSummary _productFromRow(CachedStorefrontProductRow row) {
    final promotionFields = [
      row.promotionId,
      row.promotionName,
      row.promotionStartsAt,
      row.promotionEndsAt,
    ];
    final hasPromotion = promotionFields.every((value) => value != null);
    if (promotionFields.any((value) => value != null) && !hasPromotion) {
      throw const FormatException('cache_promotion_shape');
    }
    final imageFields = [
      row.imageVersion,
      row.imageThumbUrl,
      row.imageCardUrl,
      row.imageDetailUrl,
      row.imageSha256,
    ];
    final hasImages = imageFields.every((value) => value != null);
    if (imageFields.any((value) => value != null) && !hasImages) {
      throw const FormatException('cache_image_shape');
    }
    return StorefrontProductSummary(
      id: row.publicationId,
      category: StorefrontCategory(
        id: row.categoryId,
        slug: row.categorySlug,
        name: row.categoryName,
        sortRank: row.categorySortRank,
      ),
      name: row.name,
      description: row.description,
      brand: row.brand,
      priceClp: row.priceClp,
      compareAtPriceClp: row.compareAtPriceClp,
      discountBps: row.discountBps,
      promotion: hasPromotion
          ? StorefrontPromotion(
              id: row.promotionId!,
              name: row.promotionName!,
              startsAt: row.promotionStartsAt!,
              endsAt: row.promotionEndsAt!,
            )
          : null,
      featured: row.featured,
      sortRank: row.sortRank,
      availability: _availabilityFromValue(row.availability),
      fulfillment: StorefrontFulfillment(
        pickup: row.pickupEnabled,
        delivery: row.deliveryEnabled,
        reservation: row.reservationEnabled,
      ),
      images: hasImages
          ? StorefrontImageSet(
              version: row.imageVersion!,
              thumb: _publicImageUri(row.imageThumbUrl!),
              card: _publicImageUri(row.imageCardUrl!),
              detail: _publicImageUri(row.imageDetailUrl!),
              sha256: row.imageSha256!,
            )
          : null,
      catalogVersion: row.catalogVersion,
      publishedAt: row.publishedAt,
      updatedAt: row.updatedAt,
    );
  }

  Uri _publicImageUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.pathSegments.contains('storefront-product-images') ||
        uri.pathSegments.contains('product-images')) {
      throw const FormatException('cache_image_url');
    }
    return uri;
  }

  List<OrderClauseGenerator<$CachedStorefrontProductsTable>> _orderingFor(
    StorefrontCatalogSort sort,
  ) => switch (sort) {
    StorefrontCatalogSort.catalog => _catalogOrdering,
    StorefrontCatalogSort.name => [
      (row) => OrderingTerm.asc(row.name),
      (row) => OrderingTerm.asc(row.publicationId),
    ],
    StorefrontCatalogSort.priceAscending => [
      (row) => OrderingTerm.asc(row.priceClp),
      (row) => OrderingTerm.asc(row.name),
      (row) => OrderingTerm.asc(row.publicationId),
    ],
    StorefrontCatalogSort.priceDescending => [
      (row) => OrderingTerm.desc(row.priceClp),
      (row) => OrderingTerm.asc(row.name),
      (row) => OrderingTerm.asc(row.publicationId),
    ],
  };

  List<OrderClauseGenerator<$CachedStorefrontProductsTable>>
  get _catalogOrdering => [
    (row) => OrderingTerm.asc(row.sortRank),
    (row) => OrderingTerm.asc(row.name),
    (row) => OrderingTerm.asc(row.publicationId),
  ];

  Future<T?> _safeRead<T>(String shopSlug, Future<T?> Function() read) async {
    try {
      return await read();
    } on StorefrontFailure {
      rethrow;
    } on Object {
      try {
        await clearShop(shopSlug: shopSlug);
      } on Object {
        // Una cache non apribile resta un miss ricostruibile; nessun dettaglio
        // del driver deve attraversare il boundary Storefront.
      }
      return null;
    }
  }

  bool _usable(DateTime refreshedAt) {
    final age = _clock().toUtc().difference(refreshedAt.toUtc());
    return !age.isNegative && age <= storefrontCacheMaximumStale;
  }

  void _validateLimit(int limit) {
    if (limit < 1 || limit > 100) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_cache_page_limit',
      );
    }
  }

  void _validateShop(String expected, String received) {
    if (expected != received) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'cache_shop_mismatch',
      );
    }
  }

  void _validateFavoriteKey(String shopSlug, String? publicationId) {
    if (!_shopSlug.hasMatch(shopSlug) ||
        (publicationId != null && !_publicationId.hasMatch(publicationId))) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_favorite_key',
      );
    }
  }

  void _validateProductVersions(
    Iterable<StorefrontProductSummary> products,
    int expectedVersion,
  ) {
    if (products.any((product) => product.catalogVersion != expectedVersion)) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'cache_product_version_mismatch',
      );
    }
  }

  int _decodeCursor(String? cursor) {
    if (cursor == null) return 0;
    final match = RegExp(r'^cache\.v1\.([0-9a-z]+)$').firstMatch(cursor);
    final offset = match == null
        ? null
        : int.tryParse(match.group(1)!, radix: 36);
    if (offset == null ||
        offset < 1 ||
        offset > storefrontCacheMaximumProducts) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_cache_cursor',
      );
    }
    return offset;
  }

  String _encodeCursor(int offset) => 'cache.v1.${offset.toRadixString(36)}';

  StorefrontAvailability _availabilityFromValue(String value) =>
      switch (value) {
        'available' => StorefrontAvailability.available,
        'low_stock' => StorefrontAvailability.lowStock,
        'unavailable' => StorefrontAvailability.unavailable,
        'reservation_only' => StorefrontAvailability.reservationOnly,
        'pickup_only' => StorefrontAvailability.pickupOnly,
        'delivery_only' => StorefrontAvailability.deliveryOnly,
        _ => throw const FormatException('cache_availability'),
      };

  String _availabilityValue(StorefrontAvailability availability) =>
      switch (availability) {
        StorefrontAvailability.available => 'available',
        StorefrontAvailability.lowStock => 'low_stock',
        StorefrontAvailability.unavailable => 'unavailable',
        StorefrontAvailability.reservationOnly => 'reservation_only',
        StorefrontAvailability.pickupOnly => 'pickup_only',
        StorefrontAvailability.deliveryOnly => 'delivery_only',
      };

  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  String _catalogScope({
    required String? categorySlug,
    required StorefrontAvailability? availability,
    required bool? discounted,
    required StorefrontCatalogSort sort,
  }) =>
      'catalog|category=${categorySlug ?? '-'}|availability='
      '${availability?.name ?? '-'}|discounted=${discounted == true ? '1' : '0'}|'
      'sort=${sort.name}';

  String _searchScope(String query, String? categorySlug) =>
      'search|category=${categorySlug ?? '-'}|query='
      '${normalizeStorefrontCacheSearch(query)}';

  static const _homeScope = 'home';
  static const _homeFeaturedScope = 'home:featured';
  static const _homeOffersScope = 'home:offers';
  static const _categoriesScope = 'categories';
}

String normalizeStorefrontCacheSearch(String value) {
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final collapsed = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final result = StringBuffer();
  for (final rune in collapsed.runes) {
    final character = String.fromCharCode(rune);
    result.write(replacements[character] ?? character);
  }
  return result.toString();
}

DateTime _utcNow() => DateTime.now().toUtc();
