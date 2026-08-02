import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/widgets/storefront_cache_status.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/backend/supabase_bootstrap.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'staging live persiste, riapre offline dopo app-kill e revalida al reconnect',
    (tester) async {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.staging);
      expect(config.isStorefrontConfigured, isTrue);
      await SupabaseBootstrap.initialize(config);

      final onlineReadiness = _SwitchableReadinessRepository(
        BackendReadinessState.ready,
      );
      await tester.pumpWidget(_app(config, onlineReadiness));
      var container = ProviderScope.containerOf(
        tester.element(find.byType(ClientMerchandiseControlApp)),
      );
      await _waitForLiveHome(tester, container);

      await tester.tap(find.byKey(const ValueKey('nav-catalog')));
      await tester.pump();
      await _waitForLiveCatalog(tester, container);
      final seededCatalog = container.read(catalogControllerProvider);
      final product = seededCatalog.items.first;
      final seededVersion = seededCatalog.catalogVersion;
      await tester.tap(find.byKey(ValueKey('catalog-product-${product.id}')));
      await tester.pump();
      await _waitForDetail(tester, container, product.id, expectCache: false);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      final offlineReadiness = _SwitchableReadinessRepository(
        BackendReadinessState.offline,
      );
      await tester.pumpWidget(_app(config, offlineReadiness));
      container = ProviderScope.containerOf(
        tester.element(find.byType(ClientMerchandiseControlApp)),
      );
      await _waitForCachedHome(tester, container);
      expect(find.byType(StorefrontCacheStatus), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-catalog')));
      await tester.pump();
      await _waitForCachedCatalog(tester, container);
      var catalog = container.read(catalogControllerProvider);
      expect(catalog.catalogVersion, seededVersion);
      expect(catalog.items.map((item) => item.id), contains(product.id));
      expect(find.byType(StorefrontCacheStatus), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('catalog-product-${product.id}')));
      await tester.pump();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      await _waitForDetail(tester, container, product.id, expectCache: true);
      expect(find.byType(StorefrontCacheStatus), findsOneWidget);

      offlineReadiness.next = BackendReadinessState.ready;
      await container.read(backendReadinessControllerProvider.notifier).retry();
      await _waitForDetail(tester, container, product.id, expectCache: false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _waitForLiveCatalog(tester, container);
      catalog = container.read(catalogControllerProvider);
      expect(catalog.catalogVersion, seededVersion);
      expect(catalog.isFromCache, isFalse);
      expect(tester.takeException(), isNull);

      binding.reportData = <String, Object?>{
        'stagingSeed': 'PASS',
        'sqlitePersistence': 'PASS',
        'appKillReopen': 'PASS',
        'offlineHome': 'PASS',
        'offlineCatalog': 'PASS',
        'offlineDetail': 'PASS',
        'freshnessVisible': 'PASS',
        'reconnectRevalidation': 'PASS',
        'catalogVersion': seededVersion,
        'productIdPresent': true,
        'networkLossBoundary': 'controlled_readiness_transition',
        'result': 'PASS',
      };
    },
  );
}

Widget _app(AppConfig config, BackendReadinessRepository readiness) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        backendReadinessRepositoryProvider.overrideWithValue(readiness),
      ],
      child: const ClientMerchandiseControlApp(locale: Locale('es', 'CL')),
    );

class _SwitchableReadinessRepository implements BackendReadinessRepository {
  _SwitchableReadinessRepository(this.initialState) : next = initialState;

  @override
  final BackendReadinessState initialState;

  BackendReadinessState next;

  @override
  bool get canCheck => true;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async =>
      cancellation.isCancelled ? BackendReadinessState.recoverableError : next;
}

Future<void> _waitForLiveHome(
  WidgetTester tester,
  ProviderContainer container,
) => _waitFor(tester, () {
  final state = container.read(homeControllerProvider);
  return state.status == HomeLoadStatus.data &&
      !state.isFromCache &&
      !state.isRefreshing;
}, 'Home live');

Future<void> _waitForCachedHome(
  WidgetTester tester,
  ProviderContainer container,
) => _waitFor(tester, () {
  final state = container.read(homeControllerProvider);
  return state.status == HomeLoadStatus.data &&
      state.isFromCache &&
      !state.isRefreshing;
}, 'Home cached offline');

Future<void> _waitForLiveCatalog(
  WidgetTester tester,
  ProviderContainer container,
) => _waitFor(tester, () {
  final state = container.read(catalogControllerProvider);
  return state.status == CatalogLoadStatus.data &&
      !state.isFromCache &&
      !state.isRefreshing;
}, 'Catalog live');

Future<void> _waitForCachedCatalog(
  WidgetTester tester,
  ProviderContainer container,
) => _waitFor(tester, () {
  final state = container.read(catalogControllerProvider);
  return state.status == CatalogLoadStatus.data &&
      state.isFromCache &&
      !state.isRefreshing;
}, 'Catalog cached offline');

Future<void> _waitForDetail(
  WidgetTester tester,
  ProviderContainer container,
  String publicationId, {
  required bool expectCache,
}) => _waitFor(tester, () {
  final state = container.read(productDetailControllerProvider(publicationId));
  return state.status == ProductDetailLoadStatus.data &&
      state.isFromCache == expectCache &&
      !state.isRefreshing;
}, expectCache ? 'Detail cached offline' : 'Detail live');

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() predicate,
  String label,
) async {
  for (var attempt = 0; attempt < 200; attempt += 1) {
    if (predicate()) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    final exception = tester.takeException();
    if (exception != null) fail('$label ha generato: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('$label non ha raggiunto lo stato atteso entro 50 secondi.');
}
