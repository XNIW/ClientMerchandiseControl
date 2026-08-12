import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storefront/application/storefront_providers.dart';
import '../../storefront/cache/storefront_cache_repository.dart';

abstract interface class ProductFavoriteRepository {
  Future<List<StorefrontFavoriteEntry>> read({required String shopSlug});

  Future<bool> toggle({
    required String shopSlug,
    required String publicationId,
  });
}

final class LocalProductFavoriteRepository
    implements ProductFavoriteRepository {
  const LocalProductFavoriteRepository(this._cache);

  final StorefrontCacheRepository _cache;

  @override
  Future<List<StorefrontFavoriteEntry>> read({required String shopSlug}) =>
      _cache.readFavorites(shopSlug: shopSlug);

  @override
  Future<bool> toggle({
    required String shopSlug,
    required String publicationId,
  }) => _cache.toggleFavorite(shopSlug: shopSlug, publicationId: publicationId);
}

final productFavoriteRepositoryProvider = Provider<ProductFavoriteRepository>(
  (ref) => LocalProductFavoriteRepository(
    ref.watch(storefrontCacheRepositoryProvider),
  ),
);
