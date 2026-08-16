import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_cache_status.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/design_system/widgets/storefront_search_launcher.dart';
import '../../../app/design_system/widgets/storefront_section.dart';
import '../../../app/design_system/widgets/storefront_skeleton.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_router.dart';
import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/customer_account_controller.dart';
import '../../account/domain/customer_account_models.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../catalog/application/catalog_controller.dart';
import '../../orders/application/customer_order_controller.dart';
import '../../orders/domain/customer_order_models.dart';
import '../../orders/domain/customer_order_selectors.dart';
import '../../orders/presentation/customer_order_presentation.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/presentation/storefront_product_metadata.dart';
import '../application/home_controller.dart';
import 'storefront_product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final backendReadiness = ref.watch(backendReadinessControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final accountState = ref.watch(customerAccountControllerProvider);
    final orderState = ref.watch(customerOrderControllerProvider);
    final authenticated =
        ref.watch(authControllerProvider) is AuthAuthenticated;
    final primaryActiveOrder = selectPrimaryActiveOrder(orderState.orders);
    final defaultAddress = accountState.snapshot?.addresses
        .where((address) => address.isDefault)
        .firstOrNull;
    final compactHeight =
        MediaQuery.sizeOf(context).height < 480 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final banner = config.environment == AppEnvironment.development
        ? kDebugMode && backendReadiness == BackendReadinessState.unconfigured
              ? StorefrontStatusBanner(
                  message: l10n.backendNotConfigured,
                  icon: Icons.cloud_off_outlined,
                  compact: compactHeight,
                )
              : null
        : _readinessBannerFor(
            context,
            backendReadiness,
            onRetry: ref
                .read(backendReadinessControllerProvider.notifier)
                .retry,
            compact: compactHeight,
          );
    final homeStatus = backendReadiness == BackendReadinessState.ready
        ? _homeStatusFor(context, ref, homeState)
        : null;
    final cacheStatus = homeState.isFromCache && homeState.cachedAt != null
        ? StorefrontCacheStatus(
            cachedAt: homeState.cachedAt!,
            isStale: homeState.isStale,
            isRefreshing: homeState.isRefreshing,
            compact: compactHeight,
          )
        : null;
    final showStorefrontSections =
        backendReadiness != BackendReadinessState.ready ||
        homeState.status == HomeLoadStatus.data ||
        homeState.status == HomeLoadStatus.empty;
    void openCatalog() => context.go(AppRoutes.catalogLocation);
    void openCategory(String categorySlug) {
      ref.read(catalogControllerProvider.notifier).selectCategory(categorySlug);
      context.go(AppRoutes.catalogLocation);
    }

    return StorefrontPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banner != null) ...[
            banner,
            const SizedBox(height: AppSpacing.xl),
          ],
          _StoreContextCard(
            address: defaultAddress,
            authenticated: authenticated,
            fulfillment: homeState.data?.settings.fulfillment,
          ),
          const SizedBox(height: AppSpacing.md),
          StorefrontSearchLauncher(
            key: const ValueKey('home-search'),
            label: l10n.homeSearchLabel,
            hint: l10n.homeSearchHint,
            onPressed: openCatalog,
          ),
          if (cacheStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            cacheStatus,
          ],
          if (primaryActiveOrder != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ActiveOrderCard(order: primaryActiveOrder),
          ],
          if (homeState.data?.offers case final offers?)
            if (offers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _PromotionSpotlight(product: offers.first),
            ],
          if (homeStatus != null) ...[
            const SizedBox(height: AppSpacing.md),
            homeStatus,
          ],
          if (showStorefrontSections) ...[
            const SizedBox(height: AppSpacing.xl),
            StorefrontSection(
              title: l10n.homeCategoriesTitle,
              actionLabel: l10n.homeExploreCategories,
              onAction: openCatalog,
              child: _categoriesFor(
                context,
                homeState.data?.categories ?? const [],
                openCategory,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            StorefrontSection(
              title: l10n.homeOffersTitle,
              actionLabel: l10n.homeExploreCatalog,
              onAction: openCatalog,
              child: _productsFor(
                products: homeState.data?.offers ?? const [],
                emptyIcon: Icons.local_offer_outlined,
                emptyTitle: l10n.homeOffersEmptyTitle,
                emptyMessage: l10n.homeOffersEmptyMessage,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            StorefrontSection(
              title: l10n.homeFeaturedTitle,
              actionLabel: l10n.homeExploreCatalog,
              onAction: openCatalog,
              child: _productsFor(
                products: homeState.data?.featured ?? const [],
                emptyIcon: Icons.auto_awesome_outlined,
                emptyTitle: l10n.homeFeaturedEmptyTitle,
                emptyMessage: l10n.homeFeaturedEmptyMessage,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget? _homeStatusFor(BuildContext context, WidgetRef ref, HomeState state) {
    final l10n = AppLocalizations.of(context);
    void retry() => ref.read(homeControllerProvider.notifier).retry();
    return switch (state.status) {
      HomeLoadStatus.loading => StorefrontSkeleton(
        semanticLabel: '${l10n.homeLoadingTitle}. ${l10n.homeLoadingMessage}',
      ),
      HomeLoadStatus.offline || HomeLoadStatus.failure => StorefrontEmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.homeLoadErrorTitle,
        message: l10n.homeLoadErrorMessage,
        actionLabel: l10n.backendRetry,
        onAction: retry,
        actionKey: const ValueKey('home-retry'),
      ),
      HomeLoadStatus.unavailable => StorefrontEmptyState(
        icon: Icons.storefront_outlined,
        title: l10n.homeUnavailableTitle,
        message: l10n.homeUnavailableMessage,
        actionLabel: l10n.backendRetry,
        onAction: retry,
        actionKey: const ValueKey('home-retry'),
      ),
      HomeLoadStatus.data || HomeLoadStatus.empty => null,
    };
  }

  Widget _categoriesFor(
    BuildContext context,
    List<StorefrontCategory> categories,
    ValueChanged<String> openCategory,
  ) {
    final l10n = AppLocalizations.of(context);
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.homeCategoriesMessage),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const ValueKey('home-categories'),
                  onPressed: () => context.go(AppRoutes.catalogLocation),
                  icon: const Icon(Icons.grid_view_outlined),
                  label: Text(l10n.homeExploreCategories),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final visible = categories.take(6).toList(growable: false);
    return LayoutBuilder(
      key: const ValueKey('home-category-grid'),
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 6
            : constraints.maxWidth >= 480
            ? 4
            : 3;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: textScale >= 1.5 ? 96 : 76,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final category = visible[index];
            return Semantics(
              button: true,
              label: category.name,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('home-category-${category.slug}'),
                  onTap: () => openCategory(category.slug),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            category.name,
                            maxLines: textScale >= 1.5 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _productsFor({
    required List<StorefrontProductSummary> products,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (products.isNotEmpty) {
      return StorefrontProductCollection(products: products);
    }
    return StorefrontEmptyState(
      icon: emptyIcon,
      title: emptyTitle,
      message: emptyMessage,
    );
  }

  Widget? _readinessBannerFor(
    BuildContext context,
    BackendReadinessState state, {
    required VoidCallback onRetry,
    required bool compact,
  }) {
    final l10n = AppLocalizations.of(context);

    return switch (state) {
      BackendReadinessState.unconfigured || BackendReadinessState.ready => null,
      BackendReadinessState.initializing => StorefrontStatusBanner(
        message: l10n.backendChecking,
        icon: Icons.cloud_sync_outlined,
        compact: compact,
      ),
      BackendReadinessState.offline => StorefrontStatusBanner(
        message: l10n.backendOffline,
        icon: Icons.cloud_off_outlined,
        actionLabel: l10n.backendRetry,
        onAction: onRetry,
        compact: compact,
      ),
      BackendReadinessState.misconfigured => StorefrontStatusBanner(
        message: l10n.backendUnavailable,
        icon: Icons.cloud_queue_outlined,
        compact: compact,
      ),
      BackendReadinessState.authenticationRequired => StorefrontStatusBanner(
        message: l10n.backendAuthenticationRequired,
        icon: Icons.person_outline,
        compact: compact,
      ),
      BackendReadinessState.recoverableError => StorefrontStatusBanner(
        message: l10n.backendUnavailable,
        icon: Icons.cloud_queue_outlined,
        actionLabel: l10n.backendRetry,
        onAction: onRetry,
        compact: compact,
      ),
    };
  }
}

class _StoreContextCard extends StatelessWidget {
  const _StoreContextCard({
    required this.address,
    required this.authenticated,
    required this.fulfillment,
  });

  final CustomerAddress? address;
  final bool authenticated;
  final StorefrontFulfillment? fulfillment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = <String>[
      if (fulfillment?.pickup == true) l10n.checkoutModePickup,
      if (fulfillment?.delivery == true) l10n.checkoutModeDelivery,
    ];
    final title = address == null
        ? l10n.homeSelectedStore
        : l10n.homeDeliveryDestination;
    final subtitle = address == null
        ? (modes.isEmpty ? l10n.homeStoreContextFallback : modes.join(' · '))
        : '${address!.label} · ${address!.commune}';
    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              address == null
                  ? Icons.storefront_outlined
                  : Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (authenticated) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
    if (!authenticated) return card;
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: InkWell(
        key: const ValueKey('home-store-context'),
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => context.go(AppRoutes.accountLocation),
        child: ExcludeSemantics(child: card),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final CustomerOrderCard order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = customerOrderStatusLabel(l10n, order.status);
    return Semantics(
      button: true,
      label: l10n.homeActiveOrderSemantics(order.code, status),
      child: Card(
        key: const ValueKey('home-active-order'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.orderLocation(order.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: Icon(customerOrderModeIcon(order.fulfillmentMode)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeActiveOrderTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${order.code} · $status',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        order.primaryItemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotionSpotlight extends StatelessWidget {
  const _PromotionSpotlight({required this.product});

  final StorefrontProductSummary product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticColors = StorefrontSemanticColors.of(context);
    final promotionName = product.promotion?.name ?? l10n.homeOffersTitle;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: semanticColors.promotionContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('home-promotion-spotlight'),
          onTap: () => context.push(AppRoutes.productLocation(product.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      promotionName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: semanticColors.onPromotionContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: semanticColors.onPromotionContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StorefrontPrice(product: product),
                  ],
                );
                final icon = Icon(
                  Icons.local_offer_outlined,
                  size: 40,
                  color: semanticColors.onPromotionContainer,
                );
                if (constraints.maxWidth < 520 ||
                    MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(height: AppSpacing.md),
                      details,
                    ],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: details),
                    const Icon(Icons.arrow_forward),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
