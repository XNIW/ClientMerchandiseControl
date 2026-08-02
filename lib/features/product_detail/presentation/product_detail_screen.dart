import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_cache_status.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../sharing/application/product_share_service.dart';
import '../../storefront/domain/storefront_models.dart';
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
  _ProductDetailContent({
    required this.product,
    required this.cachedAt,
    required this.cacheIsStale,
    required this.cacheIsRefreshing,
  });

  final StorefrontProductSummary product;
  final DateTime? cachedAt;
  final bool cacheIsStale;
  final bool cacheIsRefreshing;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price = _formatter.format(product.priceClp);
    final previousPrice = product.compareAtPriceClp == null
        ? null
        : _formatter.format(product.compareAtPriceClp);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final discount = product.discountBps == null
        ? null
        : NumberFormat('#,##0.##', locale).format(product.discountBps! / 100);
    return ListView(
      key: const ValueKey('product-detail-content'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  product.category.name,
                  key: const ValueKey('product-detail-category'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.name,
                  key: const ValueKey('product-detail-name'),
                  style: Theme.of(context).textTheme.headlineMedium,
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
                Semantics(
                  container: true,
                  label: '${l10n.productDetailPriceLabel}: $price',
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          key: const ValueKey('product-detail-price'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (previousPrice case final previous?)
                          Text(
                            l10n.homePreviousPrice(previous),
                            key: const ValueKey(
                              'product-detail-previous-price',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                        if (discount case final percent?)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Chip(
                              key: const ValueKey('product-detail-discount'),
                              label: Text(l10n.homeDiscountPercent(percent)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (product.promotion case final promotion?) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LabelledValue(
                    label: l10n.productDetailPromotionLabel,
                    value: promotion.name,
                    valueKey: const ValueKey('product-detail-promotion'),
                  ),
                ],
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.productDetailAvailabilityLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(
                    key: const ValueKey('product-detail-availability'),
                    avatar: const Icon(Icons.inventory_2_outlined),
                    label: Text(_availabilityLabel(l10n, product.availability)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.productDetailFulfillmentLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  key: const ValueKey('product-detail-fulfillment'),
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (product.fulfillment.pickup)
                      Chip(
                        avatar: const Icon(Icons.storefront_outlined),
                        label: Text(l10n.productDetailPickup),
                      ),
                    if (product.fulfillment.delivery)
                      Chip(
                        avatar: const Icon(Icons.local_shipping_outlined),
                        label: Text(l10n.productDetailDelivery),
                      ),
                    if (product.fulfillment.reservation)
                      Chip(
                        avatar: const Icon(Icons.event_available_outlined),
                        label: Text(l10n.productDetailReservation),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _availabilityLabel(
    AppLocalizations l10n,
    StorefrontAvailability availability,
  ) => switch (availability) {
    StorefrontAvailability.available => l10n.catalogAvailabilityAvailable,
    StorefrontAvailability.lowStock => l10n.catalogAvailabilityLowStock,
    StorefrontAvailability.unavailable => l10n.catalogAvailabilityUnavailable,
    StorefrontAvailability.reservationOnly =>
      l10n.catalogAvailabilityReservationOnly,
    StorefrontAvailability.pickupOnly => l10n.catalogAvailabilityPickupOnly,
    StorefrontAvailability.deliveryOnly => l10n.catalogAvailabilityDeliveryOnly,
  };
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
