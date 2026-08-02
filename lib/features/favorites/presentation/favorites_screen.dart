import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cart/presentation/add_to_cart_button.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../storefront/cache/storefront_cache_repository.dart';
import '../../storefront/presentation/storefront_product_metadata.dart';
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('favorite-entry-${entry.publicationId}'),
            onTap: () =>
                context.push(AppRoutes.productLocation(entry.publicationId)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 64,
                    child: product == null
                        ? const Icon(Icons.inventory_2_outlined)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadii.surface,
                            ),
                            child: StorefrontProductImage(
                              productId: product.id,
                              name: product.name,
                              uri: product.images?.thumb,
                              cacheWidth: 192,
                              keyPrefix: 'favorite-image',
                              compactPlaceholder: true,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.name ?? l10n.favoriteUnavailableTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product?.category.name ??
                              l10n.favoriteUnavailableMessage,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (product != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          StorefrontPrice(product: product, compact: true),
                          const SizedBox(height: AppSpacing.sm),
                          StorefrontAvailabilityBadge(
                            availability: product.availability,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
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
                ],
              ),
            ),
          ),
          if (product != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AddToCartButton(product: product, expanded: true),
            ),
          ],
        ],
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
