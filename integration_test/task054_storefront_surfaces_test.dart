import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/storefront_surface_fixtures.dart';
import 'support/visual_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final state in Task054StorefrontState.values) {
    for (final surface in <String, Widget>{
      'home': const Scaffold(body: SafeArea(child: HomeScreen())),
      'catalog': const Scaffold(body: SafeArea(child: CatalogScreen())),
      'product': const ProductDetailScreen(
        publicationId: '50000000-0000-4000-8000-000000000001',
      ),
      'cart': const Scaffold(body: SafeArea(child: CartScreen())),
    }.entries) {
      testWidgets('${surface.key} ${state.name} con fixture senza backend', (
        tester,
      ) async {
        final fixture = await Task054StorefrontFixtures.create(state: state);
        try {
          if (surface.key == 'cart' && state == Task054StorefrontState.error) {
            fixture.cart.readFailure = CartFailureKind.unavailable;
          }
          await tester.pumpWidget(
            fixture.wrap(
              MaterialApp(
                theme: AppTheme.light(),
                locale: const Locale('es', 'CL'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: surface.value,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (surface.key == 'cart' &&
              state == Task054StorefrontState.offline) {
            fixture.cart.offlineMutations = true;
            final increase = find.byKey(
              const ValueKey(
                'cart-increase-50000000-0000-4000-8000-000000000001',
              ),
            );
            await tester.ensureVisible(increase);
            await tester.pumpAndSettle();
            await tester.tap(increase);
            await tester.pumpAndSettle();
          }
          if (surface.key == 'cart' &&
              (state == Task054StorefrontState.offline ||
                  state == Task054StorefrontState.error)) {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(CartScreen)),
            );
            expect(
              container.read(cartControllerProvider).failureKind,
              state == Task054StorefrontState.offline
                  ? CartFailureKind.offline
                  : CartFailureKind.unavailable,
            );
          }
          await captureVisual(tester, '${surface.key}-${state.name}');
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await fixture.dispose();
        }
      });
    }
  }
}
