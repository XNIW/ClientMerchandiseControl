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

  testWidgets('Search, filtri e sort usano il contratto staging reale', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.isStorefrontConfigured, isTrue);

    await bootstrap();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav-catalog')));
    await tester.pump();

    expect(find.byType(CatalogScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CatalogScreen)),
    );
    await _waitForDiscovery(
      tester,
      container,
      (state) => !state.isSearchActive,
    );

    final controller = container.read(catalogControllerProvider.notifier);
    await controller.submitSearch('cafe');
    await _waitForDiscovery(
      tester,
      container,
      (state) => state.searchQuery == 'cafe',
    );

    var state = container.read(catalogControllerProvider);
    expect(state.items, isNotEmpty);
    expect(
      state.items.map((item) => item.name.toLowerCase()),
      everyElement(anyOf(contains('café'), contains('cafe'))),
    );
    expect(state.hasCatalogFilters, isFalse);
    final searchItemCount = state.items.length;

    await controller.clearSearch();
    await controller.selectAvailability(StorefrontAvailability.available);
    await controller.setDiscountedOnly(true);
    await controller.selectSort(StorefrontCatalogSort.priceAscending);
    await _waitForDiscovery(
      tester,
      container,
      (candidate) =>
          !candidate.isSearchActive &&
          candidate.availabilityFilter == StorefrontAvailability.available &&
          candidate.discountedOnly &&
          candidate.sort == StorefrontCatalogSort.priceAscending,
    );

    state = container.read(catalogControllerProvider);
    expect(state.items, isNotEmpty);
    expect(
      state.items,
      everyElement(
        isA<StorefrontProductSummary>()
            .having(
              (item) => item.availability,
              'availability',
              StorefrontAvailability.available,
            )
            .having((item) => item.discountBps, 'discount', isNotNull),
      ),
    );
    final prices = state.items.map((item) => item.priceClp).toList();
    expect(prices, orderedEquals([...prices]..sort()));
    expect(tester.takeException(), isNull);

    binding.reportData = <String, Object?>{
      'apiVersion': 'storefront.v1',
      'catalogVersion': state.catalogVersion,
      'search': 'cafe',
      'searchItems': searchItemCount,
      'availability': 'available',
      'discounted': true,
      'sort': 'price_asc',
      'pagination': 'keyset-contract',
      'customerSession': 'absent',
      'internalDataAccess': 'denied-by-contract',
      'result': 'PASS',
    };
  });
}

Future<void> _waitForDiscovery(
  WidgetTester tester,
  ProviderContainer container,
  bool Function(CatalogState state) criteria,
) async {
  for (var attempt = 0; attempt < 160; attempt += 1) {
    final readiness = container.read(backendReadinessControllerProvider);
    final catalog = container.read(catalogControllerProvider);
    if (readiness == BackendReadinessState.ready &&
        catalog.status == CatalogLoadStatus.data &&
        criteria(catalog)) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (readiness != BackendReadinessState.initializing &&
        readiness != BackendReadinessState.ready) {
      fail('Readiness staging terminata in ${readiness.name}.');
    }
    if (catalog.status != CatalogLoadStatus.loading &&
        catalog.status != CatalogLoadStatus.data) {
      fail(
        'Discovery staging terminata in ${catalog.status.name}; '
        'failure=${catalog.failure?.kind.name}/${catalog.failure?.code}.',
      );
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione discovery staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Discovery staging non ha raggiunto lo stato atteso entro 40 secondi.');
}
