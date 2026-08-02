import 'package:client_merchandise_control/app/design_system/widgets/storefront_status_banner.dart';
import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home guest carica il contratto Storefront v1 reale', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.isStorefrontConfigured, isTrue);

    await bootstrap();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    final context = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(context);
    await _waitForHomeData(tester, container);

    final state = container.read(homeControllerProvider);
    expect(state.status, HomeLoadStatus.data);
    final data = state.data!;
    expect(data.settings.currency, 'CLP');
    expect(data.categories, isNotEmpty);
    expect(data.featured, isNotEmpty);
    expect(data.offers, isNotEmpty);
    final products = [...data.featured, ...data.offers];
    expect(
      products,
      everyElement(
        isA<StorefrontProductSummary>().having(
          (item) => item.catalogVersion,
          'catalogVersion',
          data.catalogVersion,
        ),
      ),
    );
    final imageBacked = products.where((item) => item.images != null).toList();
    expect(imageBacked, isNotEmpty);
    expect(
      imageBacked,
      everyElement(
        isA<StorefrontProductSummary>()
            .having(
              (item) => item.images!.card.scheme,
              'public card image scheme',
              'https',
            )
            .having(
              (item) => item.images!.detail.scheme,
              'public detail image scheme',
              'https',
            ),
      ),
    );
    expect(find.byType(StorefrontStatusBanner), findsNothing);
    expect(find.byType(Image), findsWidgets);
    final renderedProduct = data.offers.first;
    expect(
      find.byKey(ValueKey('home-product-${renderedProduct.id}')),
      findsOneWidget,
    );
    expect(find.text(renderedProduct.name), findsWidgets);
    expect(tester.takeException(), isNull);

    binding.reportData = <String, Object?>{
      'apiVersion': 'storefront.v1',
      'catalogVersion': data.catalogVersion,
      'categories': data.categories.length,
      'featured': data.featured.length,
      'offers': data.offers.length,
      'publicImages': imageBacked.length,
      'productsWithoutImages': products.length - imageBacked.length,
      'customerSession': 'absent',
      'internalDataAccess': 'denied-by-contract',
      'result': 'PASS',
    };
  });
}

Future<void> _waitForHomeData(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 160; attempt += 1) {
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
    if (home.status != HomeLoadStatus.loading) {
      final failure = home.failure;
      final failureSummary = failure == null
          ? 'none'
          : '${failure.kind.name}/${failure.code}';
      fail(
        'Home staging terminata in ${home.status.name}; '
        'readiness=${readiness.name}; failure=$failureSummary.',
      );
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione Home staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  final readiness = container.read(backendReadinessControllerProvider);
  final home = container.read(homeControllerProvider);
  final failure = home.failure;
  final failureSummary = failure == null
      ? 'none'
      : '${failure.kind.name}/${failure.code}';
  fail(
    'Home staging non ha raggiunto data entro 40 secondi; '
    'readiness=${readiness.name}; home=${home.status.name}; '
    'failure=$failureSummary.',
  );
}
