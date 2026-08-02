import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/favorites/application/favorites_controller.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'TASK-019 misura first usable, discovery, immagini e frame sul dataset staging esteso',
    (tester) async {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.staging);
      expect(config.storefrontShopSlug, 'task010-load');
      expect(config.isStorefrontConfigured, isTrue);

      final frameMicros = <int>[];
      void collectFrames(List<FrameTiming> timings) {
        frameMicros.addAll(
          timings.map(
            (timing) =>
                timing.buildDuration.inMicroseconds +
                timing.rasterDuration.inMicroseconds,
          ),
        );
      }

      SchedulerBinding.instance.addTimingsCallback(collectFrames);
      addTearDown(
        () => SchedulerBinding.instance.removeTimingsCallback(collectFrames),
      );

      final startup = Stopwatch()..start();
      await bootstrap();
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await _waitFor(
        tester,
        () {
          final home = container.read(homeControllerProvider);
          return home.status == HomeLoadStatus.data && !home.isRefreshing;
        },
        'Home first usable',
        attempts: 400,
        diagnostics: () {
          final readiness = container.read(backendReadinessControllerProvider);
          final home = container.read(homeControllerProvider);
          return 'readiness=${readiness.name}, home=${home.status.name}, '
              'fromCache=${home.isFromCache}, refreshing=${home.isRefreshing}, '
              'failure=${home.failure?.kind.name}/${home.failure?.code}';
        },
      );
      final firstUsableMs = startup.elapsedMilliseconds;
      final home = container.read(homeControllerProvider);
      expect(home.data?.featured, isNotEmpty);
      expect(home.data!.featured.first.images?.card, isNotNull);
      await _waitFor(
        tester,
        () =>
            container.read(backendReadinessControllerProvider) ==
            BackendReadinessState.ready,
        'Backend readiness',
        diagnostics: () =>
            'readiness=${container.read(backendReadinessControllerProvider).name}',
      );
      final backendReadyMs = startup.elapsedMilliseconds;
      startup.stop();

      final catalogWatch = Stopwatch()..start();
      await tester.tap(find.byKey(const ValueKey('nav-catalog')));
      await tester.pump();
      await _waitFor(tester, () {
        final state = container.read(catalogControllerProvider);
        return state.status == CatalogLoadStatus.data &&
            !state.isSearchActive &&
            !state.isRefreshing;
      }, 'Catalog page');
      catalogWatch.stop();
      expect(find.byType(CatalogScreen), findsOneWidget);
      var catalog = container.read(catalogControllerProvider);
      expect(catalog.items, isNotEmpty);
      expect(catalog.items.first.images?.card, isNotNull);

      frameMicros.clear();
      final catalogScroll = find.descendant(
        of: find.byKey(const PageStorageKey<String>('catalog-scroll')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
          description: 'vertical catalog Scrollable',
        ),
      );
      expect(catalogScroll, findsOneWidget);
      for (var index = 0; index < 6; index += 1) {
        await tester.fling(catalogScroll, const Offset(0, -520), 1800);
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);

      final searchWatch = Stopwatch()..start();
      await container
          .read(catalogControllerProvider.notifier)
          .submitSearch('cafe producto');
      await _waitFor(tester, () {
        final state = container.read(catalogControllerProvider);
        return state.status == CatalogLoadStatus.data &&
            state.searchQuery == 'cafe producto' &&
            !state.isRefreshing;
      }, 'Search');
      searchWatch.stop();
      catalog = container.read(catalogControllerProvider);
      expect(catalog.items, isNotEmpty);
      final product = catalog.items.first;

      final detailWatch = Stopwatch()..start();
      container
          .read(appRouterProvider)
          .go(AppRoutes.productLocation(product.id));
      await tester.pump();
      await _waitFor(tester, () {
        final detail = container.read(
          productDetailControllerProvider(product.id),
        );
        return detail.status == ProductDetailLoadStatus.data &&
            !detail.isRefreshing;
      }, 'Product detail deep link');
      detailWatch.stop();
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      final favoriteWatch = Stopwatch()..start();
      var favorites = await container.read(favoritesControllerProvider.future);
      if (favorites.any((entry) => entry.publicationId == product.id)) {
        await container
            .read(favoritesControllerProvider.notifier)
            .toggle(product.id);
      }
      await container
          .read(favoritesControllerProvider.notifier)
          .toggle(product.id);
      favorites = container.read(favoritesControllerProvider).requireValue;
      expect(
        favorites.map((entry) => entry.publicationId),
        contains(product.id),
      );
      await container
          .read(favoritesControllerProvider.notifier)
          .toggle(product.id);
      favoriteWatch.stop();

      final sortedFrames = [...frameMicros]..sort();
      final frameP50Us = _percentile(sortedFrames, 0.50);
      final frameP95Us = _percentile(sortedFrames, 0.95);
      final frameP99Us = _percentile(sortedFrames, 0.99);
      final severeFrames = sortedFrames.where((value) => value > 32000).length;

      expect(firstUsableMs, lessThanOrEqualTo(3000));
      expect(sortedFrames, isNotEmpty);
      expect(frameP99Us, lessThan(200000));
      expect(tester.takeException(), isNull);

      binding.reportData = <String, Object?>{
        'datasetProfile': 'staging-task019-20k-v1',
        'firstUsableMs': firstUsableMs,
        'backendReadyMs': backendReadyMs,
        'catalogMs': catalogWatch.elapsedMilliseconds,
        'searchMs': searchWatch.elapsedMilliseconds,
        'detailDeepLinkMs': detailWatch.elapsedMilliseconds,
        'favoriteRoundTripMs': favoriteWatch.elapsedMilliseconds,
        'frameSamples': sortedFrames.length,
        'frameP50Us': frameP50Us,
        'frameP95Us': frameP95Us,
        'frameP99Us': frameP99Us,
        'severeFramesOver32Ms': severeFrames,
        'imageBackedFirstProduct': true,
        'result': 'PASS',
      };
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() predicate,
  String label, {
  int attempts = 120,
  String Function()? diagnostics,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    if (predicate()) {
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      return;
    }
    final exception = tester.takeException();
    if (exception != null) fail('$label ha generato: $exception');
    await tester.pump(const Duration(milliseconds: 100));
  }
  final diagnostic = diagnostics == null ? '' : ' ${diagnostics()}';
  fail(
    '$label non ha raggiunto lo stato atteso entro '
    '${attempts * 100 ~/ 1000} secondi.$diagnostic',
  );
}

int _percentile(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return 0;
  final index = ((sortedValues.length - 1) * percentile).ceil();
  return sortedValues[index];
}
