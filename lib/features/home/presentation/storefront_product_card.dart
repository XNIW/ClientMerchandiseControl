import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/presentation/storefront_product_metadata.dart';
import '../../storefront/presentation/storefront_verified_image_loader.dart';

class StorefrontProductCollection extends StatelessWidget {
  const StorefrontProductCollection({required this.products, super.key});

  final List<StorefrontProductSummary> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final cardWidth = textScale >= 1.7
            ? mathMin(
                AppSizes.productRailAccessibleCardWidth,
                constraints.maxWidth,
              )
            : mathMin(
                AppSizes.productRailCardWidth,
                constraints.maxWidth * 0.78,
              );
        final railHeight = textScale >= 1.7
            ? 800.0
            : textScale >= 1.3
            ? 580.0
            : 460.0;
        return SizedBox(
          key: const ValueKey('home-product-rail'),
          height: railHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                key: ValueKey('home-product-${product.id}'),
                width: cardWidth,
                child: StorefrontProductCard(product: product),
              );
            },
          ),
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
    final previousPrice = !product.hasDiscount
        ? null
        : _formatter.format(product.compareAtPriceClp);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final discountPercent = !product.hasDiscount || product.discountBps == null
        ? null
        : NumberFormat('#,##0.##', locale).format(product.discountBps! / 100);
    final availability = storefrontAvailabilityLabel(
      l10n,
      product.availability,
    );
    final fulfillment = storefrontFulfillmentOptions(l10n, product.fulfillment);
    final semanticLabel = [
      product.name,
      currentPrice,
      if (previousPrice case final price?) l10n.homePreviousPrice(price),
      if (discountPercent case final percent?)
        l10n.homeDiscountPercent(percent),
      availability,
      ...fulfillment.map((option) => option.label),
    ].join(', ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final narrow = constraints.maxWidth <= AppSizes.productCardCompactWidth;
        final compact = narrow || textScale >= 1.3;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  button: true,
                  label: semanticLabel,
                  child: InkWell(
                    key: ValueKey('open-product-${product.id}'),
                    onTap: () =>
                        context.push(AppRoutes.productLocation(product.id)),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: narrow ? 1 : 16 / 10,
                        child: StorefrontProductImage(
                          productId: product.id,
                          name: product.name,
                          uri: product.images?.card,
                          sha256Digest: product.images?.sha256,
                          cacheWidth: compact ? 480 : 720,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.sm : AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StorefrontAvailabilityBadge(
                              availability: product.availability,
                              compact: compact,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              product.name,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            StorefrontPrice(product: product, compact: compact),
                            const SizedBox(height: AppSpacing.sm),
                            StorefrontFulfillmentBadges(
                              fulfillment: product.fulfillment,
                              compact: compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.xs,
                end: AppSpacing.xs,
                child: Material(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  child: FavoriteButton(publicationId: product.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

double mathMin(double first, double second) => first < second ? first : second;

class StorefrontProductImage extends ConsumerStatefulWidget {
  const StorefrontProductImage({
    required this.productId,
    required this.name,
    required this.uri,
    required this.sha256Digest,
    this.cacheWidth = 720,
    this.keyPrefix = 'storefront-image',
    this.compactPlaceholder = false,
    super.key,
  });

  final String productId;
  final String name;
  final Uri? uri;
  final String? sha256Digest;
  final int cacheWidth;
  final String keyPrefix;
  final bool compactPlaceholder;

  @override
  ConsumerState<StorefrontProductImage> createState() =>
      _StorefrontProductImageState();
}

class _StorefrontProductImageState
    extends ConsumerState<StorefrontProductImage> {
  Future<Uint8List>? _load;

  @override
  void initState() {
    super.initState();
    _load = _loadImage();
  }

  @override
  void didUpdateWidget(StorefrontProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        oldWidget.sha256Digest != widget.sha256Digest) {
      _load = _loadImage();
    }
  }

  Future<Uint8List>? _loadImage() {
    final uri = widget.uri;
    final digest = widget.sha256Digest;
    if (uri == null || digest == null) return null;
    return ref
        .read(storefrontVerifiedImageLoaderProvider)
        .load(uri: uri, sha256Digest: digest);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final load = _load;
    if (load == null) return _placeholder(context, l10n);
    return Semantics(
      image: true,
      label: widget.name,
      child: FutureBuilder<Uint8List>(
        future: load,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _placeholder(context, l10n);
          final bytes = snapshot.data;
          if (bytes == null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _placeholder(context, l10n),
                const Center(child: CircularProgressIndicator.adaptive()),
              ],
            );
          }
          return Image.memory(
            bytes,
            key: ValueKey('${widget.keyPrefix}-${widget.productId}'),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            cacheWidth: widget.cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _placeholder(context, l10n),
          );
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context, AppLocalizations l10n) {
    if (widget.compactPlaceholder) {
      return Semantics(
        image: true,
        label: l10n.homeImageUnavailable,
        child: ColoredBox(
          key: ValueKey('${widget.keyPrefix}-placeholder-${widget.productId}'),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }
    return ColoredBox(
      key: ValueKey('${widget.keyPrefix}-placeholder-${widget.productId}'),
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
