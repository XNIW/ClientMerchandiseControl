import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/branding/app_brand.dart';
import '../../../app/design_system/tokens/app_breakpoints.dart';
import '../../../app/design_system/tokens/app_durations.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cart/application/cart_controller.dart';
import '../../delivery_tracking/application/delivery_tracking_controller.dart';
import '../../orders/application/customer_order_controller.dart';
import '../../orders/domain/customer_order_selectors.dart';

class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(
      cartControllerProvider.select(
        (state) => state.snapshot?.totalQuantity ?? 0,
      ),
    );
    final activeOrderCount = ref.watch(
      customerOrderControllerProvider.select(
        (state) => completeActiveCustomerOrderCount(
          state.orders,
          hasMore: state.hasMore,
        ),
      ),
    );
    final titles = [
      AppBrand.effectiveDisplayName,
      l10n.catalogTitle,
      l10n.ordersTitle,
      l10n.cartTitle,
      l10n.accountTitle,
    ];
    final currentIndex = navigationShell.currentIndex;
    final canPopCurrentRoute = GoRouter.of(context).canPop();
    void selectDestination(int index) {
      unawaited(
        ref
            .read(deliveryTrackingControllerProvider.notifier)
            .setRouteVisible(index == 2),
      );
      navigationShell.goBranch(index, initialLocation: index == currentIndex);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail =
            constraints.maxWidth >= AppBreakpoints.wide &&
            constraints.maxHeight >= 480;
        return PopScope<void>(
          canPop: currentIndex == 0 || canPopCurrentRoute,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && currentIndex != 0 && !canPopCurrentRoute) {
              navigationShell.goBranch(0);
            }
          },
          child: Scaffold(
            appBar: currentIndex == 2
                ? null
                : AppBar(
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
                            constraints.maxWidth >= AppBreakpoints.extraWide
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        extended:
                            constraints.maxWidth >= AppBreakpoints.extraWide,
                        groupAlignment: -0.8,
                        destinations: [
                          NavigationRailDestination(
                            icon: const SizedBox.square(
                              key: ValueKey('nav-home'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.home_outlined),
                            ),
                            selectedIcon: const SizedBox.square(
                              key: ValueKey('nav-home'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.home),
                            ),
                            label: Text(l10n.navigationHome),
                          ),
                          NavigationRailDestination(
                            icon: const SizedBox.square(
                              key: ValueKey('nav-catalog'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.grid_view_outlined),
                            ),
                            selectedIcon: const SizedBox.square(
                              key: ValueKey('nav-catalog'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.grid_view),
                            ),
                            label: Text(l10n.navigationCatalog),
                          ),
                          NavigationRailDestination(
                            icon: _NavigationIcon(
                              key: const ValueKey('nav-orders'),
                              icon: Icons.receipt_long_outlined,
                              count: activeOrderCount,
                              semanticsLabel: activeOrderCount == null
                                  ? l10n.navigationOrders
                                  : l10n.navigationOrdersBadge(
                                      activeOrderCount,
                                    ),
                            ),
                            selectedIcon: _NavigationIcon(
                              key: const ValueKey('nav-orders'),
                              icon: Icons.receipt_long,
                              count: activeOrderCount,
                              semanticsLabel: activeOrderCount == null
                                  ? l10n.navigationOrders
                                  : l10n.navigationOrdersBadge(
                                      activeOrderCount,
                                    ),
                            ),
                            label: Text(l10n.navigationOrders),
                          ),
                          NavigationRailDestination(
                            icon: _NavigationIcon(
                              key: const ValueKey('nav-cart'),
                              icon: Icons.shopping_cart_outlined,
                              count: cartCount,
                              semanticsLabel: l10n.navigationCartBadge(
                                cartCount,
                              ),
                            ),
                            selectedIcon: _NavigationIcon(
                              key: const ValueKey('nav-cart'),
                              icon: Icons.shopping_cart,
                              count: cartCount,
                              semanticsLabel: l10n.navigationCartBadge(
                                cartCount,
                              ),
                            ),
                            label: Text(l10n.navigationCart),
                          ),
                          NavigationRailDestination(
                            icon: const SizedBox.square(
                              key: ValueKey('nav-account'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.person_outline),
                            ),
                            selectedIcon: const SizedBox.square(
                              key: ValueKey('nav-account'),
                              dimension: AppSizes.minimumTouchTarget,
                              child: Icon(Icons.person),
                            ),
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
                    labelBehavior:
                        constraints.maxWidth <= AppBreakpoints.narrow ||
                            MediaQuery.textScalerOf(context).scale(1) >= 1.5
                        ? NavigationDestinationLabelBehavior.alwaysHide
                        : NavigationDestinationLabelBehavior.onlyShowSelected,
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
                        key: const ValueKey('nav-orders'),
                        icon: _NavigationIcon(
                          icon: Icons.receipt_long_outlined,
                          count: activeOrderCount,
                          semanticsLabel: activeOrderCount == null
                              ? l10n.navigationOrders
                              : l10n.navigationOrdersBadge(activeOrderCount),
                        ),
                        selectedIcon: _NavigationIcon(
                          icon: Icons.receipt_long,
                          count: activeOrderCount,
                          semanticsLabel: activeOrderCount == null
                              ? l10n.navigationOrders
                              : l10n.navigationOrdersBadge(activeOrderCount),
                        ),
                        label: l10n.navigationOrders,
                      ),
                      NavigationDestination(
                        key: const ValueKey('nav-cart'),
                        icon: _NavigationIcon(
                          icon: Icons.shopping_cart_outlined,
                          count: cartCount,
                          semanticsLabel: l10n.navigationCartBadge(cartCount),
                        ),
                        selectedIcon: _NavigationIcon(
                          icon: Icons.shopping_cart,
                          count: cartCount,
                          semanticsLabel: l10n.navigationCartBadge(cartCount),
                        ),
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
      },
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    required this.count,
    required this.semanticsLabel,
    super.key,
  });

  final IconData icon;
  final int? count;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final boundedCount = (count ?? 0).clamp(0, 99);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSizes.minimumTouchTarget,
        child: Center(
          child: Badge.count(
            isLabelVisible: count != null && count! > 0,
            count: boundedCount,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
