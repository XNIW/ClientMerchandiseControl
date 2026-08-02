import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _publishedId = '57000000-0000-4000-8000-000000000001';
const _unpublishedId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dettaglio published/unpublished usa Storefront v1 reale', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.isStorefrontConfigured, isTrue);

    await bootstrap();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await _waitForHome(tester, container);

    final publishedCard = find.byKey(
      const ValueKey('open-product-$_publishedId'),
    );
    await tester.ensureVisible(publishedCard);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(publishedCard);
    await tester.pump();
    await _waitForDetail(
      tester,
      container,
      _publishedId,
      ProductDetailLoadStatus.data,
    );

    var state = container.read(productDetailControllerProvider(_publishedId));
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(state.product?.id, _publishedId);
    expect(state.product?.name, 'Café en grano 500 g');
    expect(state.product?.images?.detail, isNotNull);
    expect(
      find.byKey(const ValueKey('storefront-detail-image-$_publishedId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-detail-availability')),
      findsOneWidget,
    );
    expect(Supabase.instance.client.auth.currentSession, isNull);

    final router = container.read(appRouterProvider);
    router.push(AppRoutes.productLocation(_unpublishedId));
    await tester.pump();
    await _waitForDetail(
      tester,
      container,
      _unpublishedId,
      ProductDetailLoadStatus.unavailable,
    );

    state = container.read(productDetailControllerProvider(_unpublishedId));
    expect(state.product, isNull);
    expect(
      find.byKey(const ValueKey('product-detail-unavailable')),
      findsOneWidget,
    );
    expect(find.textContaining(_unpublishedId), findsNothing);
    expect(tester.takeException(), isNull);

    binding.reportData = <String, Object?>{
      'apiVersion': 'storefront.v1',
      'publishedProduct': 'visible',
      'publishedImage': 'detail-public',
      'availability': 'commercial-only',
      'unpublishedProduct': 'unavailable-without-enumeration',
      'customerSession': 'absent',
      'internalDataAccess': 'denied-by-contract',
      'result': 'PASS',
    };
  });
}

Future<void> _waitForHome(
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
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione Home staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Home staging non ha raggiunto data entro 40 secondi.');
}

Future<void> _waitForDetail(
  WidgetTester tester,
  ProviderContainer container,
  String publicationId,
  ProductDetailLoadStatus expected,
) async {
  for (var attempt = 0; attempt < 160; attempt += 1) {
    final state = container.read(
      productDetailControllerProvider(publicationId),
    );
    if (state.status == expected) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      return;
    }
    if (state.status != ProductDetailLoadStatus.loading) {
      fail(
        'Detail $publicationId terminato in ${state.status.name}; '
        'failure=${state.failure?.kind.name}/${state.failure?.code}.',
      );
    }
    final exception = tester.takeException();
    if (exception != null) fail('Eccezione detail staging: $exception');
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail(
    'Detail $publicationId non ha raggiunto ${expected.name} entro 40 secondi.',
  );
}
