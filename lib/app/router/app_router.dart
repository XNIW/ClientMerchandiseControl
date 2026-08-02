import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/product_detail/presentation/product_detail_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
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
        path: AppRoutes.productPattern,
        builder: (context, state) => ProductDetailScreen(
          publicationId: state.pathParameters['publicationId'] ?? '',
        ),
      ),
    ],
  );

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    final isCallbackAuthentication =
        next is AuthAuthenticated && next.origin == AuthSessionOrigin.callback;
    final wasCallbackAuthentication =
        previous is AuthAuthenticated &&
        previous.origin == AuthSessionOrigin.callback;
    if (isCallbackAuthentication && !wasCallbackAuthentication) {
      router.go(AppRoutes.accountLocation);
    }
  });

  ref.onDispose(router.dispose);
  return router;
});
