import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/catalog/application/catalog_controller.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/customer_notifications/application/customer_notification_route_controller.dart';
import '../../features/customer_notifications/domain/customer_notification_models.dart';
import '../../features/deep_links/application/storefront_deep_link.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/domain/customer_order_selectors.dart';
import '../../features/product_detail/presentation/product_detail_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
import '../../core/config/app_config.dart';
import '../../core/observability/observability_event.dart';
import '../../core/observability/observability_providers.dart';
import '../../core/time/app_scheduler.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final observability = ref.read(observabilityProvider);
  final clock = ref.read(appClockProvider);
  String? pendingProtectedOrdersLocation;

  String? protectedOrderRedirect(BuildContext _, GoRouterState state) {
    if (ref.read(authControllerProvider) is AuthAuthenticated) return null;
    pendingProtectedOrdersLocation = state.uri.toString();
    return AppRoutes.accountLocation;
  }

  final router = GoRouter(
    initialLocation: AppRoutes.homeLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeLocation,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalogLocation,
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ordersLocation,
                redirect: protectedOrderRedirect,
                builder: (context, state) => OrdersScreen(
                  initialFilter: customerOrderListFilterFromName(
                    state.uri.queryParameters['filter'],
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cartLocation,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accountLocation,
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.checkoutLocation,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.productPattern,
        builder: (context, state) => ProductDetailScreen(
          publicationId: state.pathParameters['publicationId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.favoritesLocation,
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  );

  AppScreen? lastObservedScreen;
  void recordScreen() {
    final screen = appScreenForPath(
      router.routeInformationProvider.value.uri.path,
    );
    if (screen == lastObservedScreen) return;
    lastObservedScreen = screen;
    recordObservabilityBestEffort(
      observability,
      ObservabilityEvent.screenView(occurredAt: clock(), screen: screen),
    );
  }

  router.routeInformationProvider.addListener(recordScreen);
  scheduleMicrotask(recordScreen);

  final config = ref.watch(appConfigProvider);
  final codec = ref.watch(storefrontDeepLinkCodecProvider);
  final linkSource = ref.read(authCallbackSourceProvider);
  StorefrontDeepLinkIntent? pendingIntent;
  Uri? lastAcceptedUri;
  DateTime? lastAcceptedAt;
  String? pendingProtectedOrderId;
  String? pendingProtectedNotificationToken;
  var notificationDispatchGeneration = 0;
  var pendingFrame = false;
  var disposed = false;

  Future<void> dispatchNotification(String routeToken) async {
    final shopSlug = config.storefrontShopSlug;
    if (disposed || shopSlug == null) return;
    if (ref.read(authControllerProvider) is! AuthAuthenticated) {
      pendingProtectedOrderId = null;
      pendingProtectedNotificationToken = routeToken;
      notificationDispatchGeneration++;
      router.go(AppRoutes.accountLocation);
      return;
    }
    pendingProtectedNotificationToken = null;
    final generation = ++notificationDispatchGeneration;
    final destination = await ref
        .read(customerNotificationRouteControllerProvider.notifier)
        .resolve(shopSlug: shopSlug, routeToken: routeToken);
    if (disposed ||
        generation != notificationDispatchGeneration ||
        ref.read(authControllerProvider) is! AuthAuthenticated) {
      return;
    }
    if (destination == null) {
      recordObservabilityBestEffort(
        observability,
        ObservabilityEvent.notificationRouting(
          occurredAt: clock(),
          destination: NotificationDestination.unsupported,
          outcome: ObservabilityOutcome.failure,
          failure: BackendFailureCategory.invalidPayload,
        ),
      );
      return;
    }
    switch (destination) {
      case CustomerNotificationOrderDestination(:final orderId):
        recordObservabilityBestEffort(
          observability,
          ObservabilityEvent.notificationRouting(
            occurredAt: clock(),
            destination: NotificationDestination.order,
            outcome: ObservabilityOutcome.success,
          ),
        );
        router.go(AppRoutes.orderLocation(orderId));
      case CustomerNotificationCartDestination():
        recordObservabilityBestEffort(
          observability,
          ObservabilityEvent.notificationRouting(
            occurredAt: clock(),
            destination: NotificationDestination.cart,
            outcome: ObservabilityOutcome.success,
          ),
        );
        router.go(AppRoutes.cartLocation);
    }
  }

  void dispatch(StorefrontDeepLinkIntent intent) {
    if (disposed) return;
    switch (intent) {
      case StorefrontProductDeepLink(:final publicationId):
        notificationDispatchGeneration++;
        pendingProtectedOrdersLocation = null;
        pendingProtectedOrderId = null;
        pendingProtectedNotificationToken = null;
        router.go(AppRoutes.productLocation(publicationId));
      case StorefrontCategoryDeepLink(:final categorySlug):
        notificationDispatchGeneration++;
        pendingProtectedOrdersLocation = null;
        pendingProtectedOrderId = null;
        pendingProtectedNotificationToken = null;
        router.go(AppRoutes.catalogLocation);
        unawaited(
          ref
              .read(catalogControllerProvider.notifier)
              .openCategoryFromDeepLink(categorySlug),
        );
      case StorefrontOrderDeepLink(:final orderId):
        notificationDispatchGeneration++;
        pendingProtectedOrdersLocation = null;
        pendingProtectedNotificationToken = null;
        if (ref.read(authControllerProvider) is AuthAuthenticated) {
          pendingProtectedOrderId = null;
          router.go(AppRoutes.orderLocation(orderId));
        } else {
          pendingProtectedOrderId = orderId;
          router.go(AppRoutes.accountLocation);
        }
      case StorefrontNotificationDeepLink(:final routeToken):
        pendingProtectedOrdersLocation = null;
        pendingProtectedOrderId = null;
        unawaited(dispatchNotification(routeToken));
    }
  }

  void enqueue(StorefrontDeepLinkIntent intent) {
    if (router.routerDelegate.currentConfiguration.isNotEmpty) {
      dispatch(intent);
      return;
    }
    pendingIntent = intent;
    if (pendingFrame) return;
    pendingFrame = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pendingFrame = false;
      final queued = pendingIntent;
      pendingIntent = null;
      if (queued != null) dispatch(queued);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  final linkSubscription = linkSource.callbacks.listen((uri) {
    final shopSlug = config.storefrontShopSlug;
    if (shopSlug == null) return;
    final intent = codec.decode(uri, shopSlug: shopSlug);
    if (intent == null) return;
    final now = DateTime.now().toUtc();
    if (lastAcceptedUri == uri &&
        lastAcceptedAt != null &&
        now.difference(lastAcceptedAt!) < const Duration(seconds: 2)) {
      return;
    }
    lastAcceptedUri = uri;
    lastAcceptedAt = now;
    enqueue(intent);
  }, onError: (Object _, StackTrace _) {});

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (next is AuthAuthenticated &&
        pendingProtectedNotificationToken != null) {
      final routeToken = pendingProtectedNotificationToken!;
      pendingProtectedNotificationToken = null;
      unawaited(dispatchNotification(routeToken));
      return;
    }
    if (next is AuthAuthenticated && pendingProtectedOrderId != null) {
      final orderId = pendingProtectedOrderId!;
      pendingProtectedOrderId = null;
      router.go(AppRoutes.orderLocation(orderId));
      return;
    }
    if (next is AuthAuthenticated && pendingProtectedOrdersLocation != null) {
      final destination = pendingProtectedOrdersLocation!;
      pendingProtectedOrdersLocation = null;
      router.go(destination);
      return;
    }
    if (previous is AuthAuthenticated && next is! AuthAuthenticated) {
      notificationDispatchGeneration++;
      pendingProtectedOrdersLocation = null;
      pendingProtectedNotificationToken = null;
    }
    final isCallbackAuthentication =
        next is AuthAuthenticated && next.origin == AuthSessionOrigin.callback;
    final wasCallbackAuthentication =
        previous is AuthAuthenticated &&
        previous.origin == AuthSessionOrigin.callback;
    if (isCallbackAuthentication && !wasCallbackAuthentication) {
      if (router.state.uri.path != AppRoutes.checkoutLocation) {
        router.go(AppRoutes.accountLocation);
      }
    }
  });

  ref.onDispose(() {
    disposed = true;
    pendingIntent = null;
    pendingProtectedOrderId = null;
    pendingProtectedOrdersLocation = null;
    pendingProtectedNotificationToken = null;
    notificationDispatchGeneration++;
    router.routeInformationProvider.removeListener(recordScreen);
    unawaited(linkSubscription.cancel());
    router.dispose();
  });
  return router;
});

@visibleForTesting
AppScreen appScreenForPath(String path) {
  if (path == AppRoutes.homeLocation) return AppScreen.home;
  if (path == AppRoutes.catalogLocation) return AppScreen.catalog;
  if (path == AppRoutes.ordersLocation) return AppScreen.orders;
  if (path.startsWith('${AppRoutes.ordersLocation}/')) {
    return AppScreen.orderDetail;
  }
  if (path == AppRoutes.cartLocation) return AppScreen.cart;
  if (path == AppRoutes.accountLocation) return AppScreen.account;
  if (path == AppRoutes.checkoutLocation) return AppScreen.checkout;
  if (path == AppRoutes.favoritesLocation) return AppScreen.favorites;
  if (path.startsWith('/product/')) return AppScreen.productDetail;
  return AppScreen.unknown;
}
