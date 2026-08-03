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
import '../../features/deep_links/application/storefront_deep_link.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/product_detail/presentation/product_detail_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
import '../../core/config/app_config.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
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

  final config = ref.watch(appConfigProvider);
  final codec = ref.watch(storefrontDeepLinkCodecProvider);
  final linkSource = ref.read(authCallbackSourceProvider);
  StorefrontDeepLinkIntent? pendingIntent;
  Uri? lastAcceptedUri;
  DateTime? lastAcceptedAt;
  var pendingFrame = false;
  var disposed = false;

  void dispatch(StorefrontDeepLinkIntent intent) {
    if (disposed) return;
    switch (intent) {
      case StorefrontProductDeepLink(:final publicationId):
        router.go(AppRoutes.productLocation(publicationId));
      case StorefrontCategoryDeepLink(:final categorySlug):
        router.go(AppRoutes.catalogLocation);
        unawaited(
          ref
              .read(catalogControllerProvider.notifier)
              .openCategoryFromDeepLink(categorySlug),
        );
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
    unawaited(linkSubscription.cancel());
    router.dispose();
  });
  return router;
});
