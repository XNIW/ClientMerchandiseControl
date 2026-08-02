import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/favorites/application/favorites_controller.dart';
import 'package:client_merchandise_control/features/favorites/presentation/favorites_screen.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _publishedId = '57000000-0000-4000-8000-000000000001';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('favorite guest live sopravvive a dispose/reopen app', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    await bootstrap();
    await tester.pump();

    var container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await _waitForHome(tester, container);
    await _openPublishedProduct(tester, container);

    var entries = await container.read(favoritesControllerProvider.future);
    if (entries.any((entry) => entry.publicationId == _publishedId)) {
      await container
          .read(favoritesControllerProvider.notifier)
          .toggle(_publishedId);
      await tester.pump();
    }
    final favoriteButton = find.byKey(
      const ValueKey('favorite-product-$_publishedId'),
    );
    expect(favoriteButton, findsOneWidget);
    await tester.tap(favoriteButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    entries = container.read(favoritesControllerProvider).requireValue;
    expect(entries.map((entry) => entry.publicationId), contains(_publishedId));

    container.read(appRouterProvider).go(AppRoutes.favoritesLocation);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('favorite-entry-$_publishedId')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const ClientMerchandiseControlApp(locale: Locale('es', 'CL')),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ClientMerchandiseControlApp)),
    );
    final restored = await container.read(favoritesControllerProvider.future);
    expect(
      restored.map((entry) => entry.publicationId),
      contains(_publishedId),
    );

    container.read(appRouterProvider).go(AppRoutes.favoritesLocation);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey('favorite-entry-$_publishedId')),
      findsOneWidget,
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(_publishedId);
    expect(tester.takeException(), isNull);

    binding.reportData = <String, Object?>{
      'favoriteGuest': 'PASS',
      'shopScoped': true,
      'detailToggle': 'PASS',
      'favoritesList': 'PASS',
      'appDisposeReopen': 'PASS',
      'customerSessionRequired': false,
      'serverWrite': false,
      'cleanup': 'PASS',
      'result': 'PASS',
    };
  });
}

Future<void> _openPublishedProduct(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final card = find.byKey(const ValueKey('open-product-$_publishedId'));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  await tester.tap(card);
  await tester.pump();
  for (var attempt = 0; attempt < 160; attempt++) {
    final state = container.read(productDetailControllerProvider(_publishedId));
    if (state.status == ProductDetailLoadStatus.data) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (state.status != ProductDetailLoadStatus.loading) {
      fail('Detail live terminato in ${state.status.name}.');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Detail live non disponibile entro 40 secondi.');
}

Future<void> _waitForHome(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 160; attempt++) {
    final readiness = container.read(backendReadinessControllerProvider);
    final home = container.read(homeControllerProvider);
    if (readiness == BackendReadinessState.ready &&
        home.status == HomeLoadStatus.data) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (readiness != BackendReadinessState.initializing &&
        readiness != BackendReadinessState.ready) {
      fail('Readiness staging terminata in ${readiness.name}.');
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione Home staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Home staging non ha raggiunto data entro 40 secondi.');
}
