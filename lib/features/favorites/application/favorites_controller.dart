import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../storefront/cache/storefront_cache_repository.dart';
import '../data/product_favorite_repository.dart';

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<StorefrontFavoriteEntry>>(
      FavoritesController.new,
    );

class FavoritesController extends AsyncNotifier<List<StorefrontFavoriteEntry>> {
  final Map<String, Future<bool>> _mutations = {};

  @override
  Future<List<StorefrontFavoriteEntry>> build() => _read();

  Future<void> refresh() async {
    state = const AsyncLoading<List<StorefrontFavoriteEntry>>()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(_read);
  }

  Future<bool> toggle(String publicationId) {
    final active = _mutations[publicationId];
    if (active != null) return active;
    late final Future<bool> operation;
    operation = _runToggle(publicationId).whenComplete(() {
      if (identical(_mutations[publicationId], operation)) {
        _mutations.remove(publicationId);
      }
    });
    _mutations[publicationId] = operation;
    return operation;
  }

  Future<bool> _runToggle(String publicationId) async {
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (shopSlug == null) return false;
    final repository = ref.read(productFavoriteRepositoryProvider);
    final isFavorite = await repository.toggle(
      shopSlug: shopSlug,
      publicationId: publicationId,
    );
    state = AsyncData(await repository.read(shopSlug: shopSlug));
    return isFavorite;
  }

  Future<List<StorefrontFavoriteEntry>> _read() async {
    final config = ref.watch(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (shopSlug == null) return const [];
    return ref
        .watch(productFavoriteRepositoryProvider)
        .read(shopSlug: shopSlug);
  }
}
