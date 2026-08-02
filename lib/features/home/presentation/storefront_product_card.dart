import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../storefront/domain/storefront_models.dart';

class StorefrontProductCollection extends StatelessWidget {
  const StorefrontProductCollection({required this.products, super.key});

  final List<StorefrontProductSummary> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final product in products)
              SizedBox(
                key: ValueKey('home-product-${product.id}'),
                width: width,
                child: StorefrontProductCard(product: product),
              ),
          ],
        );
      },
    );
  }
}

class StorefrontProductCard extends StatelessWidget {
  StorefrontProductCard({required this.product, super.key});

  final StorefrontProductSummary product;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentPrice = _formatter.format(product.priceClp);
    final previousPrice = product.compareAtPriceClp == null
        ? null
        : _formatter.format(product.compareAtPriceClp);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final discountPercent = product.discountBps == null
        ? null
        : NumberFormat('#,##0.##', locale).format(product.discountBps! / 100);
    final semanticLabel = [
      product.name,
      currentPrice,
      if (previousPrice case final price?) l10n.homePreviousPrice(price),
      if (discountPercent case final percent?)
        l10n.homeDiscountPercent(percent),
    ].join(', ');
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: semanticLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('open-product-${product.id}'),
          onTap: () => context.push(AppRoutes.productLocation(product.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: StorefrontProductImage(
                  productId: product.id,
                  name: product.name,
                  uri: product.images?.card,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (discountPercent case final percent?) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            l10n.homeDiscountPercent(percent),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      currentPrice,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (previousPrice case final price?)
                      Text(
                        l10n.homePreviousPrice(price),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StorefrontProductImage extends StatelessWidget {
  const StorefrontProductImage({
    required this.productId,
    required this.name,
    required this.uri,
    this.cacheWidth = 720,
    this.keyPrefix = 'storefront-image',
    super.key,
  });

  final String productId;
  final String name;
  final Uri? uri;
  final int cacheWidth;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (uri == null) return _placeholder(context, l10n);
    return Semantics(
      image: true,
      label: name,
      child: Image.network(
        key: ValueKey('$keyPrefix-$productId'),
        uri.toString(),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _placeholder(context, l10n),
              const Center(child: CircularProgressIndicator.adaptive()),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, l10n),
      ),
    );
  }

  Widget _placeholder(BuildContext context, AppLocalizations l10n) {
    return ColoredBox(
      key: ValueKey('$keyPrefix-placeholder-$productId'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.homeImageUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
