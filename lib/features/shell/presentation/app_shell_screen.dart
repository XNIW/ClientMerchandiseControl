import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/branding/app_brand.dart';
import '../../../app/design_system/tokens/app_durations.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

class AppShellScreen extends StatelessWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      AppBrand.effectiveDisplayName,
      l10n.catalogTitle,
      l10n.cartTitle,
      l10n.accountTitle,
    ];
    final currentIndex = navigationShell.currentIndex;
    return PopScope<void>(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: AppSizes.appBarBaseHeight,
          titleSpacing: AppSpacing.lg,
          title: SingleChildScrollView(
            key: ValueKey('shell-title-scroll-$currentIndex'),
            scrollDirection: Axis.horizontal,
            child: Text(
              titles[currentIndex],
              key: ValueKey('shell-title-$currentIndex'),
              maxLines: 1,
            ),
          ),
        ),
        body: SafeArea(top: false, bottom: false, child: navigationShell),
        bottomNavigationBar: NavigationBar(
          animationDuration: AppDurations.effective(
            context,
            AppDurations.medium,
          ),
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
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
