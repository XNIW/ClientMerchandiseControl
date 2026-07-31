import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_durations.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../l10n/generated/app_localizations.dart';

class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final backendReadiness = ref.watch(backendReadinessControllerProvider);
    final showDevelopmentBanner =
        kDebugMode &&
        config.environment == AppEnvironment.development &&
        backendReadiness == BackendReadinessState.unconfigured;
    final readinessBanner = _readinessBannerFor(
      context,
      backendReadiness,
      onRetry: ref.read(backendReadinessControllerProvider.notifier).retry,
    );

    return PopScope<void>(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showDevelopmentBanner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: StorefrontStatusBanner(
                    message: l10n.backendNotConfigured,
                    icon: Icons.cloud_off_outlined,
                  ),
                ),
              if (readinessBanner != null &&
                  config.environment != AppEnvironment.development)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: readinessBanner,
                ),
              Expanded(child: navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          animationDuration: AppDurations.effective(
            context,
            AppDurations.medium,
          ),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              key: const ValueKey('nav-home'),
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navigationHome,
            ),
            NavigationDestination(
              key: const ValueKey('nav-catalog'),
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view),
              label: l10n.navigationCatalog,
            ),
            NavigationDestination(
              key: const ValueKey('nav-cart'),
              icon: const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: l10n.navigationCart,
            ),
            NavigationDestination(
              key: const ValueKey('nav-account'),
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navigationAccount,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _readinessBannerFor(
    BuildContext context,
    BackendReadinessState state, {
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context);

    return switch (state) {
      BackendReadinessState.unconfigured || BackendReadinessState.ready => null,
      BackendReadinessState.initializing => StorefrontStatusBanner(
        message: l10n.backendChecking,
        icon: Icons.cloud_sync_outlined,
      ),
      BackendReadinessState.offline => StorefrontStatusBanner(
        message: l10n.backendOffline,
        icon: Icons.cloud_off_outlined,
        actionLabel: l10n.backendRetry,
        onAction: onRetry,
      ),
      BackendReadinessState.misconfigured => StorefrontStatusBanner(
        message: l10n.backendUnavailable,
        icon: Icons.cloud_queue_outlined,
      ),
      BackendReadinessState.authenticationRequired => StorefrontStatusBanner(
        message: l10n.backendAuthenticationRequired,
        icon: Icons.person_outline,
      ),
      BackendReadinessState.recoverableError => StorefrontStatusBanner(
        message: l10n.backendUnavailable,
        icon: Icons.cloud_queue_outlined,
        actionLabel: l10n.backendRetry,
        onAction: onRetry,
      ),
    };
  }
}
