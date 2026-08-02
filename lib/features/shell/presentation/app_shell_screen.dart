import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/branding/app_brand.dart';
import '../../../app/design_system/tokens/app_breakpoints.dart';
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
    final useNavigationRail =
        MediaQuery.sizeOf(context).width >= 960 &&
        MediaQuery.textScalerOf(context).scale(1) < 1.5;
    void selectDestination(int index) {
      navigationShell.goBranch(index, initialLocation: index == currentIndex);
    }

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
        body: useNavigationRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: selectDestination,
                    labelType:
                        MediaQuery.sizeOf(context).width >=
                            AppBreakpoints.extraWide
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    extended:
                        MediaQuery.sizeOf(context).width >=
                        AppBreakpoints.extraWide,
                    groupAlignment: -0.8,
                    destinations: [
                      NavigationRailDestination(
                        icon: const SizedBox.square(
                          key: ValueKey('nav-home'),
                          dimension: AppSizes.minimumTouchTarget,
                          child: Icon(Icons.home_outlined),
                        ),
                        selectedIcon: const Icon(Icons.home),
                        label: Text(l10n.navigationHome),
                      ),
                      NavigationRailDestination(
                        icon: const SizedBox.square(
                          key: ValueKey('nav-catalog'),
                          dimension: AppSizes.minimumTouchTarget,
                          child: Icon(Icons.grid_view_outlined),
                        ),
                        selectedIcon: const Icon(Icons.grid_view),
                        label: Text(l10n.navigationCatalog),
                      ),
                      NavigationRailDestination(
                        icon: const SizedBox.square(
                          key: ValueKey('nav-cart'),
                          dimension: AppSizes.minimumTouchTarget,
                          child: Icon(Icons.shopping_cart_outlined),
                        ),
                        selectedIcon: const Icon(Icons.shopping_cart),
                        label: Text(l10n.navigationCart),
                      ),
                      NavigationRailDestination(
                        icon: const SizedBox.square(
                          key: ValueKey('nav-account'),
                          dimension: AppSizes.minimumTouchTarget,
                          child: Icon(Icons.person_outline),
                        ),
                        selectedIcon: const Icon(Icons.person),
                        label: Text(l10n.navigationAccount),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: navigationShell,
                    ),
                  ),
                ],
              )
            : SafeArea(top: false, bottom: false, child: navigationShell),
        bottomNavigationBar: useNavigationRail
            ? null
            : NavigationBar(
                animationDuration: AppDurations.effective(
                  context,
                  AppDurations.medium,
                ),
                selectedIndex: currentIndex,
                onDestinationSelected: selectDestination,
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
