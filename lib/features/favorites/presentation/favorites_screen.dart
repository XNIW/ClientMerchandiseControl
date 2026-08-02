import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../storefront/cache/storefront_cache_repository.dart';
import '../application/favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: SafeArea(
        top: false,
        child: favorites.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => StorefrontEmptyState(
            icon: Icons.error_outline,
            title: l10n.favoritesErrorTitle,
            message: l10n.favoritesErrorMessage,
            actionLabel: l10n.backendRetry,
            onAction: ref.read(favoritesControllerProvider.notifier).refresh,
          ),
          data: (entries) => entries.isEmpty
              ? StorefrontEmptyState(
                  icon: Icons.favorite_border,
                  title: l10n.favoritesEmptyTitle,
                  message: l10n.favoritesEmptyMessage,
                  actionLabel: l10n.homeExploreCatalog,
                  onAction: () => context.go(AppRoutes.catalogLocation),
                )
              : _FavoriteList(entries: entries),
        ),
      ),
    );
  }
}

class _FavoriteList extends ConsumerWidget {
  const _FavoriteList({required this.entries});

  final List<StorefrontFavoriteEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      RefreshIndicator.adaptive(
        onRefresh: ref.read(favoritesControllerProvider.notifier).refresh,
        child: ListView.separated(
          key: const ValueKey('favorites-list'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: _FavoriteTile(entry: entries[index]),
            ),
          ),
        ),
      );
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.entry});

  final StorefrontFavoriteEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final product = entry.product;
    return Card(
      child: ListTile(
        key: ValueKey('favorite-entry-${entry.publicationId}'),
        onTap: () =>
            context.push(AppRoutes.productLocation(entry.publicationId)),
        leading: SizedBox.square(
          dimension: 56,
          child: product == null
              ? const Icon(Icons.inventory_2_outlined)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: StorefrontProductImage(
                    productId: product.id,
                    name: product.name,
                    uri: product.images?.thumb,
                    cacheWidth: 168,
                    keyPrefix: 'favorite-image',
                    compactPlaceholder: true,
                  ),
                ),
        ),
        title: Text(product?.name ?? l10n.favoriteUnavailableTitle),
        subtitle: Text(
          product?.category.name ?? l10n.favoriteUnavailableMessage,
        ),
        trailing: Semantics(
          button: true,
          label: l10n.favoriteRemove,
          excludeSemantics: true,
          child: IconButton(
            key: ValueKey('remove-favorite-${entry.publicationId}'),
            tooltip: l10n.favoriteRemove,
            onPressed: () => _remove(context, ref),
            icon: const Icon(Icons.favorite),
          ),
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(favoritesControllerProvider.notifier)
          .toggle(entry.publicationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).favoriteRemoved)),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).favoritesErrorMessage),
          ),
        );
      }
    }
  }
}
