import '../domain/storefront_models.dart';

const storefrontCacheFreshTtl = Duration(minutes: 15);
const storefrontCacheMaximumStale = Duration(days: 30);
const storefrontCacheMaximumProducts = 25000;
const storefrontCacheMaximumDetails = 500;
const storefrontMaximumFavorites = 1000;

class StorefrontFavoriteEntry {
  const StorefrontFavoriteEntry({
    required this.publicationId,
    required this.updatedAt,
    required this.product,
  });

  final String publicationId;
  final DateTime updatedAt;
  final StorefrontProductSummary? product;
}

class StorefrontCacheSnapshot<T> {
  const StorefrontCacheSnapshot({
    required this.value,
    required this.refreshedAt,
  });

  final T value;
  final DateTime refreshedAt;

  bool isFreshAt(DateTime now) {
    final age = now.toUtc().difference(refreshedAt.toUtc());
    return !age.isNegative && age <= storefrontCacheFreshTtl;
  }

  bool isUsableAt(DateTime now) {
    final age = now.toUtc().difference(refreshedAt.toUtc());
    return !age.isNegative && age <= storefrontCacheMaximumStale;
  }
}

abstract interface class StorefrontCacheRepository {
  Future<StorefrontCacheSnapshot<StorefrontHomeData>?> readHome({
    required String shopSlug,
  });

  Future<StorefrontCacheSnapshot<StorefrontCategoriesPage>?> readCategories({
    required String shopSlug,
  });

  Future<StorefrontCacheSnapshot<StorefrontCatalogPage>?> readCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
  });

  Future<StorefrontCacheSnapshot<StorefrontSearchPage>?> readSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
  });

  Future<StorefrontCacheSnapshot<StorefrontProductSummary>?> readProductDetail({
    required String shopSlug,
    required String publicationId,
  });

  Future<void> writeHome({
    required String shopSlug,
    required StorefrontHomeData data,
  });

  Future<void> writeCategories({
    required String shopSlug,
    required StorefrontCategoriesPage page,
  });

  Future<void> writeCatalog({
    required String shopSlug,
    required StorefrontCatalogPage page,
    required String? categorySlug,
    required StorefrontAvailability? availability,
    required bool? discounted,
  });

  Future<void> writeSearch({
    required String shopSlug,
    required StorefrontSearchPage page,
    required String? categorySlug,
  });

  Future<void> writeProductDetail({
    required String shopSlug,
    required StorefrontProductSummary product,
  });

  Future<List<StorefrontFavoriteEntry>> readFavorites({
    required String shopSlug,
  });

  Future<bool> toggleFavorite({
    required String shopSlug,
    required String publicationId,
  });

  Future<void> cleanup({required String shopSlug});

  Future<void> clearShop({required String shopSlug});
}

final class DisabledStorefrontCacheRepository
    implements StorefrontCacheRepository {
  const DisabledStorefrontCacheRepository();

  @override
  Future<void> cleanup({required String shopSlug}) async {}

  @override
  Future<void> clearShop({required String shopSlug}) async {}

  @override
  Future<List<StorefrontFavoriteEntry>> readFavorites({
    required String shopSlug,
  }) async => const [];

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

  @override
  Future<bool> toggleFavorite({
    required String shopSlug,
    required String publicationId,
  }) async => false;
}
