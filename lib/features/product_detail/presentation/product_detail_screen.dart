import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_breakpoints.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_cache_status.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/presentation/add_to_cart_button.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../reservations/presentation/reservation_hold_panel.dart';
import '../../sharing/application/product_share_service.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/presentation/storefront_product_metadata.dart';
import '../application/product_detail_controller.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.publicationId, super.key});

  final String publicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(productDetailControllerProvider(publicationId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetailTitle),
        actions: switch (state.product) {
          final product? => [
            FavoriteButton(publicationId: product.id),
            ProductShareButton(product: product),
          ],
          null => null,
        },
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          ProductDetailLoadStatus.data => _ProductDetailContent(
            product: state.product!,
            cachedAt: state.isFromCache ? state.cachedAt : null,
            cacheIsStale: state.isStale,
            cacheIsRefreshing: state.isRefreshing,
          ),
          ProductDetailLoadStatus.loading => _ProductDetailStatus(
            key: const ValueKey('product-detail-loading'),
            icon: Icons.inventory_2_outlined,
            title: l10n.productDetailLoading,
            message: l10n.catalogConnectingMessage,
            progress: true,
          ),
          ProductDetailLoadStatus.offline => _ProductDetailStatus(
            key: const ValueKey('product-detail-offline'),
            icon: Icons.cloud_off_outlined,
            title: l10n.productDetailOfflineTitle,
            message: l10n.productDetailOfflineMessage,
            actionLabel: l10n.backendRetry,
            onAction: () => ref
                .read(productDetailControllerProvider(publicationId).notifier)
                .retry(),
          ),
          ProductDetailLoadStatus.unavailable => _ProductDetailStatus(
            key: const ValueKey('product-detail-unavailable'),
            icon: Icons.inventory_2_outlined,
            title: l10n.productDetailUnavailableTitle,
            message: l10n.productDetailUnavailableMessage,
          ),
          ProductDetailLoadStatus.failure => _ProductDetailStatus(
            key: const ValueKey('product-detail-failure'),
            icon: Icons.error_outline,
            title: l10n.productDetailErrorTitle,
            message: l10n.productDetailErrorMessage,
            actionLabel: l10n.backendRetry,
            onAction: () => ref
                .read(productDetailControllerProvider(publicationId).notifier)
                .retry(),
          ),
        },
      ),
      bottomNavigationBar: switch (state.product) {
        final product? => _ProductDetailCartBar(product: product),
        null => null,
      },
    );
  }
}

class _ProductDetailCartBar extends ConsumerWidget {
  const _ProductDetailCartBar({required this.product});

  final StorefrontProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final quantity =
        cart.snapshot?.items
            .where((line) => line.publicationId == product.id)
            .firstOrNull
            ?.quantity ??
        1;
    final canReserve =
        product.fulfillment.reservation &&
        product.availability != StorefrontAvailability.unavailable;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.productDetailContentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddToCartButton(product: product, expanded: true),
                  if (canReserve) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ReservationHoldPanel(
                      publicationId: product.id,
                      quantity: quantity,
                      canCreate: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailStatus extends StatelessWidget {
  const _ProductDetailStatus({
    required this.icon,
    required this.title,
    required this.message,
    this.progress = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(AppSpacing.xl),
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: StorefrontEmptyState(
          icon: icon,
          title: title,
          message: message,
          progress: progress,
          actionLabel: actionLabel,
          onAction: onAction,
          actionKey: onAction == null
              ? null
              : const ValueKey('product-detail-retry'),
        ),
      ),
    ],
  );
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent({
    required this.product,
    required this.cachedAt,
    required this.cacheIsStale,
    required this.cacheIsRefreshing,
  });

  final StorefrontProductSummary product;
  final DateTime? cachedAt;
  final bool cacheIsStale;
  final bool cacheIsRefreshing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppBreakpoints.wide &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5;
        final gallery = _ProductGallery(product: product);
        final details = _ProductInformation(product: product);
        return ListView(
          key: const ValueKey('product-detail-content'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.productDetailContentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (cachedAt case final cachedAt?) ...[
                      StorefrontCacheStatus(
                        cachedAt: cachedAt,
                        isStale: cacheIsStale,
                        isRefreshing: cacheIsRefreshing,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (wide)
                      Row(
                        key: const ValueKey('product-detail-wide-layout'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: gallery),
                          const SizedBox(width: AppSpacing.xxl),
                          Expanded(flex: 5, child: details),
                        ],
                      )
                    else
                      Column(
                        key: const ValueKey('product-detail-compact-layout'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gallery,
                          const SizedBox(height: AppSpacing.xl),
                          details,
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({required this.product});

  final StorefrontProductSummary product;

  @override
  Widget build(BuildContext context) {
    final position = AppLocalizations.of(
      context,
    ).productDetailImagePosition(1, 1);
    return Semantics(
      container: true,
      label: position,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: StorefrontProductImage(
                productId: product.id,
                name: product.name,
                uri: product.images?.detail,
                cacheWidth: 1440,
                keyPrefix: 'storefront-detail-image',
              ),
            ),
          ),
          PositionedDirectional(
            end: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  position,
                  key: const ValueKey('product-detail-gallery-position'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInformation extends StatelessWidget {
  _ProductInformation({required this.product});

  final StorefrontProductSummary product;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticColors = StorefrontSemanticColors.of(context);
    final savings = product.hasDiscount
        ? _formatter.format(product.compareAtPriceClp! - product.priceClp)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.category.name,
          key: const ValueKey('product-detail-category'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          product.name,
          key: const ValueKey('product-detail-name'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (product.brand case final brand?) ...[
          const SizedBox(height: AppSpacing.xs),
          _LabelledValue(
            label: l10n.productDetailBrandLabel,
            value: brand,
            valueKey: const ValueKey('product-detail-brand'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StorefrontPrice(product: product, emphasized: true),
        if (savings case final amount?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.productDetailSavings(amount),
            key: const ValueKey('product-detail-savings'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: semanticColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (product.promotion case final promotion?) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            label: '${l10n.productDetailPromotionLabel}: ${promotion.name}',
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: semanticColors.promotionContainer,
                  borderRadius: BorderRadius.circular(AppRadii.surface),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        color: semanticColors.onPromotionContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          promotion.name,
                          key: const ValueKey('product-detail-promotion'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: semanticColors.onPromotionContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.productDetailAvailabilityLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: KeyedSubtree(
            key: const ValueKey('product-detail-availability'),
            child: StorefrontAvailabilityBadge(
              availability: product.availability,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.productDetailFulfillmentLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        KeyedSubtree(
          key: const ValueKey('product-detail-fulfillment'),
          child: StorefrontFulfillmentBadges(fulfillment: product.fulfillment),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.productDetailDescriptionLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          product.description ?? l10n.productDetailNoDescription,
          key: const ValueKey('product-detail-description'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _LabelledValue extends StatelessWidget {
  const _LabelledValue({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: ExcludeSemantics(
      child: Text(
        value,
        key: valueKey,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
