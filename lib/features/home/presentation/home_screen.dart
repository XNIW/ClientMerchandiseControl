import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_spacing.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final backendReadiness = ref.watch(backendReadinessControllerProvider);
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
          const SizedBox(height: AppSpacing.xxl),
          StorefrontSection(
            title: l10n.homeCategoriesTitle,
            child: Card(
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
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StorefrontSection(
            title: l10n.homeOffersTitle,
            child: StorefrontEmptyState(
              icon: Icons.local_offer_outlined,
              title: l10n.homeOffersEmptyTitle,
              message: l10n.homeOffersEmptyMessage,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StorefrontSection(
            title: l10n.homeFeaturedTitle,
            child: StorefrontEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: l10n.homeFeaturedEmptyTitle,
              message: l10n.homeFeaturedEmptyMessage,
            ),
          ),
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
