import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backend/backend_status.dart';
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
    final backendStatus = ref.watch(backendStatusProvider);
    final showDevelopmentBanner =
        kDebugMode &&
        config.environment == AppEnvironment.development &&
        backendStatus == BackendStatus.notConfigured;

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
                MaterialBanner(
                  content: Text(l10n.backendNotConfigured),
                  leading: const Icon(Icons.cloud_off_outlined),
                  actions: const [SizedBox.shrink()],
                ),
              Expanded(child: navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
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
}
