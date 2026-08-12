import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/storefront_models.dart';

class StorefrontPrice extends StatelessWidget {
  StorefrontPrice({
    required this.product,
    super.key,
    this.emphasized = false,
    this.compact = false,
  });

  final StorefrontProductSummary product;
  final bool emphasized;
  final bool compact;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticColors = StorefrontSemanticColors.of(context);
    final currentPrice = _formatter.format(product.priceClp);
    final previousPrice = product.hasDiscount
        ? _formatter.format(product.compareAtPriceClp)
        : null;
    final discountPercent = product.hasDiscount && product.discountBps != null
        ? NumberFormat(
            '#,##0.##',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(product.discountBps! / 100)
        : null;
    final semanticLabel = [
      '${l10n.productDetailPriceLabel}: $currentPrice',
      if (previousPrice case final price?) l10n.homePreviousPrice(price),
      if (discountPercent case final percent?)
        l10n.homeDiscountPercent(percent),
    ].join(', ');

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentPrice,
              key: ValueKey('product-price-${product.id}'),
              style:
                  (emphasized
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(
                        color: semanticColors.price,
                        fontWeight: FontWeight.w800,
                      ),
            ),
            if (previousPrice != null || discountPercent != null) ...[
              SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (previousPrice case final price?)
                    Text(
                      l10n.homePreviousPrice(price),
                      key: ValueKey('product-previous-price-${product.id}'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: semanticColors.originalPrice,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (discountPercent case final percent?)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: semanticColors.promotionContainer,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Text(
                          l10n.homeDiscountPercent(percent),
                          key: ValueKey('product-discount-${product.id}'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: semanticColors.onPromotionContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StorefrontAvailabilityBadge extends StatelessWidget {
  const StorefrontAvailabilityBadge({
    required this.availability,
    super.key,
    this.compact = false,
  });

  final StorefrontAvailability availability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = storefrontAvailabilityLabel(l10n, availability);
    final semanticColors = StorefrontSemanticColors.of(context);
    final color = switch (availability) {
      StorefrontAvailability.available => semanticColors.availabilityPositive,
      StorefrontAvailability.lowStock => semanticColors.availabilityLimited,
      StorefrontAvailability.unavailable =>
        semanticColors.availabilityUnavailable,
      StorefrontAvailability.reservationOnly ||
      StorefrontAvailability.pickupOnly ||
      StorefrontAvailability.deliveryOnly => semanticColors.information,
    };
    final icon = switch (availability) {
      StorefrontAvailability.available => Icons.check_circle_outline,
      StorefrontAvailability.lowStock => Icons.warning_amber_outlined,
      StorefrontAvailability.unavailable => Icons.remove_circle_outline,
      StorefrontAvailability.reservationOnly => Icons.event_available_outlined,
      StorefrontAvailability.pickupOnly => Icons.storefront_outlined,
      StorefrontAvailability.deliveryOnly => Icons.local_shipping_outlined,
    };
    final background = Color.alphaBlend(
      color.withValues(alpha: 0.12),
      Theme.of(context).colorScheme.surface,
    );
    return Semantics(
      container: true,
      label: '${l10n.productDetailAvailabilityLabel}: $label',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StorefrontFulfillmentBadges extends StatelessWidget {
  const StorefrontFulfillmentBadges({
    required this.fulfillment,
    super.key,
    this.compact = false,
  });

  final StorefrontFulfillment fulfillment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = storefrontFulfillmentOptions(l10n, fulfillment);
    if (options.isEmpty) return const SizedBox.shrink();
    final visibleOptions = compact ? options.take(2) : options;
    return Semantics(
      container: true,
      label:
          '${l10n.productDetailFulfillmentLabel}: '
          '${options.map((option) => option.label).join(', ')}',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in visibleOptions)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(option.icon, size: 15),
                      if (!compact) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          option.label,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String storefrontAvailabilityLabel(
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

List<({IconData icon, String label})> storefrontFulfillmentOptions(
  AppLocalizations l10n,
  StorefrontFulfillment fulfillment,
) => [
  if (fulfillment.pickup)
    (icon: Icons.storefront_outlined, label: l10n.productDetailPickup),
  if (fulfillment.delivery)
    (icon: Icons.local_shipping_outlined, label: l10n.productDetailDelivery),
  if (fulfillment.reservation)
    (
      icon: Icons.event_available_outlined,
      label: l10n.productDetailReservation,
    ),
];
