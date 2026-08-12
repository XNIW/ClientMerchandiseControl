import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Catalogo guest carica categorie e prodotti Storefront v1 reali',
    (tester) async {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.staging);
      expect(config.isStorefrontConfigured, isTrue);

      await bootstrap();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nav-catalog')));
      await tester.pump();

      expect(find.byType(CatalogScreen), findsOneWidget);
      final context = tester.element(find.byType(CatalogScreen));
      final container = ProviderScope.containerOf(context);
      await _waitForCatalogData(tester, container);

      var state = container.read(catalogControllerProvider);
      expect(state.status, CatalogLoadStatus.data);
      expect(state.categories, isNotEmpty);
      expect(state.items, isNotEmpty);
      expect(state.catalogVersion, greaterThan(0));
      expect(
        state.items,
        everyElement(
          isA<StorefrontProductSummary>().having(
            (item) => item.catalogVersion,
            'catalogVersion',
            state.catalogVersion,
          ),
        ),
      );
      final imageBacked = state.items.where((item) => item.images != null);
      expect(imageBacked, isNotEmpty);
      expect(
        imageBacked,
        everyElement(
          isA<StorefrontProductSummary>().having(
            (item) => item.images!.card.scheme,
            'public card image scheme',
            'https',
          ),
        ),
      );
      expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      final selectedCategory = state.categories.first;
      final selectedSlug = selectedCategory.slug;
      await tester.tap(find.byKey(ValueKey('catalog-category-$selectedSlug')));
      await tester.pump();
      await _waitForSelectedCategory(tester, container, selectedSlug);

      state = container.read(catalogControllerProvider);
      expect(state.items, isNotEmpty);
      expect(
        state.items,
        everyElement(
          isA<StorefrontProductSummary>().having(
            (item) => item.category.slug,
            'category slug',
            selectedSlug,
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      binding.reportData = <String, Object?>{
        'apiVersion': 'storefront.v1',
        'catalogVersion': state.catalogVersion,
        'categories': state.categories.length,
        'selectedCategory': selectedSlug,
        'selectedItems': state.items.length,
        'publicImages': state.items.where((item) => item.images != null).length,
        'customerSession': 'absent',
        'pagination': 'keyset-contract',
        'internalDataAccess': 'denied-by-contract',
        'result': 'PASS',
      };
    },
  );
}

Future<void> _waitForCatalogData(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 160; attempt += 1) {
    final readiness = container.read(backendReadinessControllerProvider);
    final catalog = container.read(catalogControllerProvider);
    if (readiness == BackendReadinessState.ready &&
        catalog.status == CatalogLoadStatus.data) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (readiness != BackendReadinessState.initializing &&
        readiness != BackendReadinessState.ready) {
      fail('Readiness staging terminata in ${readiness.name}.');
    }
    if (catalog.status != CatalogLoadStatus.loading) {
      fail(
        'Catalogo staging terminato in ${catalog.status.name}; '
        'failure=${catalog.failure?.kind.name}/${catalog.failure?.code}.',
      );
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione catalogo staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Catalogo staging non ha raggiunto data entro 40 secondi.');
}

Future<void> _waitForSelectedCategory(
  WidgetTester tester,
  ProviderContainer container,
  String slug,
) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    final catalog = container.read(catalogControllerProvider);
    if (catalog.status == CatalogLoadStatus.data &&
        catalog.selectedCategorySlug == slug) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (catalog.status != CatalogLoadStatus.loading) {
      fail(
        'Filtro categoria staging terminato in ${catalog.status.name}; '
        'selected=${catalog.selectedCategorySlug}.',
      );
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione filtro catalogo: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Categoria $slug non selezionata entro 20 secondi.');
}
