import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_cache_status.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/design_system/widgets/storefront_search_launcher.dart';
import '../../../app/design_system/widgets/storefront_section.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_router.dart';
import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../storefront/domain/storefront_models.dart';
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

    return StorefrontPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banner != null) ...[
            banner,
            const SizedBox(height: AppSpacing.xl),
          ],
          Semantics(
            header: true,
            child: Text(
              l10n.homeWelcomeTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.homeWelcomeMessage,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          StorefrontSearchLauncher(
            key: const ValueKey('home-search'),
            label: l10n.homeSearchLabel,
            hint: l10n.homeSearchHint,
            onPressed: openCatalog,
          ),
          if (cacheStatus != null) ...[
            const SizedBox(height: AppSpacing.lg),
            cacheStatus,
          ],
          if (homeStatus != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            homeStatus,
          ],
          if (showStorefrontSections) ...[
            const SizedBox(height: AppSpacing.xxl),
            StorefrontSection(
              title: l10n.homeCategoriesTitle,
              child: _categoriesFor(
                context,
                homeState.data?.categories ?? const [],
                openCatalog,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            StorefrontSection(
              title: l10n.homeOffersTitle,
              child: _productsFor(
                products: homeState.data?.offers ?? const [],
                emptyIcon: Icons.local_offer_outlined,
                emptyTitle: l10n.homeOffersEmptyTitle,
                emptyMessage: l10n.homeOffersEmptyMessage,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            StorefrontSection(
              title: l10n.homeFeaturedTitle,
              child: _productsFor(
                products: homeState.data?.featured ?? const [],
                emptyIcon: Icons.auto_awesome_outlined,
                emptyTitle: l10n.homeFeaturedEmptyTitle,
                emptyMessage: l10n.homeFeaturedEmptyMessage,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              key: const ValueKey('home-open-catalog'),
              onPressed: openCatalog,
              icon: const Icon(Icons.grid_view_outlined),
              label: Text(l10n.homeExploreCatalog),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _homeStatusFor(BuildContext context, WidgetRef ref, HomeState state) {
    final l10n = AppLocalizations.of(context);
    void retry() => ref.read(homeControllerProvider.notifier).retry();
    return switch (state.status) {
      HomeLoadStatus.loading => StorefrontEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: l10n.homeLoadingTitle,
        message: l10n.homeLoadingMessage,
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
    VoidCallback openCatalog,
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
                  onPressed: openCatalog,
                  icon: const Icon(Icons.grid_view_outlined),
                  label: Text(l10n.homeExploreCategories),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final category in categories)
              ActionChip(
                key: ValueKey('home-category-${category.slug}'),
                avatar: const Icon(Icons.category_outlined),
                label: Text(category.name),
                onPressed: openCatalog,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const ValueKey('home-categories'),
          onPressed: openCatalog,
          icon: const Icon(Icons.grid_view_outlined),
          label: Text(l10n.homeExploreCategories),
        ),
      ],
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
