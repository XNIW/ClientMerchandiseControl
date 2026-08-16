import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_failure.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_controller.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/presentation/order_detail_screen.dart';
import 'package:client_merchandise_control/features/orders/presentation/orders_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../customer_order_test_support.dart';
import '../../delivery_tracking/delivery_tracking_test_support.dart';

void main() {
  testWidgets('lista accessibile apre il dettaglio owner-scoped', (
    tester,
  ) async {
    final repository = FakeCustomerOrderRepository();
    final harness = _Harness(repository: repository);
    addTearDown(harness.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('order-card-$orderTestOrder'));
    expect(card, findsOneWidget);
    expect(
      tester.getSize(card).height,
      greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    );
    final semanticsData = tester.getSemantics(card).getSemanticsData();
    expect(semanticsData.flagsCollection.isButton, isTrue);
    expect(semanticsData.label, contains(orderTestCode));
    semantics.dispose();
    expect(find.text(r'$2.400'), findsOneWidget);
    expect(find.textContaining(orderTestPublication), findsNothing);

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      harness.router.state.uri.path,
      AppRoutes.orderLocation(orderTestOrder),
    );
    expect(find.byKey(const ValueKey('order-detail-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-detail-items')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-detail-timeline')), findsOneWidget);
    expect(repository.detailRequests.single.orderId, orderTestOrder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancellazione richiede conferma e aggiorna timeline una volta', (
    tester,
  ) async {
    final repository = FakeCustomerOrderRepository()
      ..cancelOutcomes.add(orderTestCancelledDetail());
    final harness = _Harness(
      repository: repository,
      initialLocation: AppRoutes.orderLocation(orderTestOrder),
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.app());
    await _pumpUntil(tester, find.byKey(const ValueKey('order-cancel-button')));
    final cancel = find.byKey(const ValueKey('order-cancel-button'));
    await tester.drag(
      find.byKey(const ValueKey('order-detail-scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(repository.cancelRequests, isEmpty);

    await tester.tap(find.byKey(const ValueKey('order-cancel-confirm')));
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('order-cancellation-card')),
      absent: true,
    );
    expect(repository.cancelRequests, hasLength(1));
    expect(repository.cancelRequests.single.idempotencyKey, orderTestKey);
    expect(find.byKey(const ValueKey('order-cancellation-card')), findsNothing);
    expect(
      harness.container
          .read(customerOrderControllerProvider)
          .selectedOrder
          ?.version,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cache offline mostra banner e resta navigabile read-only', (
    tester,
  ) async {
    final repository = FakeCustomerOrderRepository()
      ..listOutcomes.add(customerOrderOffline)
      ..detailOutcomes.add(customerOrderOffline);
    final harness = _Harness(
      repository: repository,
      cache: MemoryCustomerOrderCacheStore()..snapshot = orderTestCache(),
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('orders-offline-banner')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-card-$orderTestOrder')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('order-detail-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-detail-header')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dettaglio delivery mostra stato testuale live e stale senza coordinate',
    (tester) async {
      final orderRepository = FakeCustomerOrderRepository()
        ..detailOutcomes.add(
          orderTestDetail(
            status: CustomerOrderStatus.outForDelivery,
            version: 2,
            fulfillmentMode: CustomerOrderFulfillmentMode.delivery,
          ),
        );
      final trackingRepository = FakeDeliveryTrackingRepository()
        ..snapshot = trackingLiveSnapshot(orderId: orderTestOrder);
      final harness = _Harness(
        repository: orderRepository,
        trackingRepository: trackingRepository,
        initialLocation: AppRoutes.orderLocation(orderTestOrder),
      );
      addTearDown(harness.dispose);
      addTearDown(trackingRepository.stream.close);

      await tester.pumpWidget(harness.app());
      await _pumpUntil(tester, find.text('La ubicación se está actualizando'));
      expect(find.text('Seguimiento de la entrega'), findsOneWidget);
      expect(find.text('La ubicación se está actualizando'), findsOneWidget);
      expect(find.textContaining('-33.446'), findsNothing);
      expect(find.textContaining('-70.655'), findsNothing);

      trackingRepository.stream.add(
        trackingLiveSnapshot(
          orderId: orderTestOrder,
          version: 5,
          freshness: 'stale',
        ),
      );
      await _pumpUntil(
        tester,
        find.text('La ubicación no se está actualizando'),
      );
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordine terminale prevale sulla cache live e rimuove il tracking preciso',
    (tester) async {
      final orderRepository = FakeCustomerOrderRepository()
        ..detailOutcomes.add(
          orderTestDetail(
            status: CustomerOrderStatus.completed,
            version: 7,
            fulfillmentMode: CustomerOrderFulfillmentMode.delivery,
          ),
        );
      final trackingRepository = FakeDeliveryTrackingRepository()
        ..loadError = const DeliveryTrackingRepositoryException(
          DeliveryTrackingFailureKind.offline,
        );
      final trackingCache = MemoryDeliveryTrackingCache()
        ..snapshot = trackingLiveSnapshot(orderId: orderTestOrder);
      final harness = _Harness(
        repository: orderRepository,
        trackingRepository: trackingRepository,
        trackingCache: trackingCache,
        initialLocation: AppRoutes.orderLocation(orderTestOrder),
      );
      addTearDown(harness.dispose);
      addTearDown(trackingRepository.stream.close);

      await tester.pumpWidget(harness.app());
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('order-detail-header')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('delivery-tracking-card')),
        findsNothing,
      );
      expect(find.textContaining('Repartidor MC'), findsNothing);
      expect(trackingRepository.watchCalls, 0);
      expect(trackingCache.snapshot, isNull);
    },
  );

  testWidgets('320x568 dark e testo 200% non causano overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    final harness = _Harness(repository: FakeCustomerOrderRepository());
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      harness.app(
        themeMode: ThemeMode.dark,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    final refresh = find.byKey(const ValueKey('orders-refresh'));
    expect(
      tester.getSize(refresh).height,
      greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    );
    expect(find.byKey(const ValueKey('orders-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'locale es-CL, it, en e zh-Hans rendono lista senza fallback rotto',
    (tester) async {
      for (final locale in const [
        Locale('es', 'CL'),
        Locale('it'),
        Locale('en'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ]) {
        final harness = _Harness(repository: FakeCustomerOrderRepository());
        await tester.pumpWidget(harness.app(locale: locale));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('order-card-$orderTestOrder')),
          findsOneWidget,
          reason: locale.toLanguageTag(),
        );
        expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
        harness.dispose();
      }
    },
  );
}

final class _Harness {
  _Harness({
    required FakeCustomerOrderRepository repository,
    MemoryCustomerOrderCacheStore? cache,
    FakeDeliveryTrackingRepository? trackingRepository,
    MemoryDeliveryTrackingCache? trackingCache,
    String initialLocation = AppRoutes.ordersLocation,
  }) : container = ProviderContainer(
         overrides: [
           customerOrderIdentityProvider.overrideWithValue(_identity()),
           customerOrderShopSlugProvider.overrideWithValue(orderTestShop),
           customerOrderRepositoryProvider.overrideWithValue(repository),
           customerOrderCacheStoreProvider.overrideWithValue(
             cache ?? MemoryCustomerOrderCacheStore(),
           ),
           customerOrderClockProvider.overrideWithValue(() => orderTestNow),
           customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
             () => orderTestKey,
           ),
           deliveryTrackingRepositoryProvider.overrideWithValue(
             trackingRepository ?? FakeDeliveryTrackingRepository(),
           ),
           deliveryTrackingCacheProvider.overrideWithValue(
             trackingCache ?? MemoryDeliveryTrackingCache(),
           ),
           deliveryTrackingClockProvider.overrideWithValue(
             () => trackingTestNow,
           ),
           deliveryTrackingPollIntervalProvider.overrideWithValue(
             const Duration(hours: 1),
           ),
         ],
       ),
       router = GoRouter(
         initialLocation: initialLocation,
         routes: [
           GoRoute(
             path: AppRoutes.accountLocation,
             builder: (context, state) => const Scaffold(body: Text('account')),
           ),
           GoRoute(
             path: AppRoutes.ordersLocation,
             builder: (context, state) => const OrdersScreen(),
           ),
           GoRoute(
             path: AppRoutes.orderPattern,
             builder: (context, state) => OrderDetailScreen(
               orderId: state.pathParameters['orderId'] ?? '',
             ),
           ),
         ],
       );

  final ProviderContainer container;
  final GoRouter router;

  Widget app({
    Locale locale = const Locale('es', 'CL'),
    ThemeMode themeMode = ThemeMode.light,
    TextScaler textScaler = TextScaler.noScaling,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
    ),
  );

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: orderTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    final matches = finder.evaluate().isNotEmpty;
    if (matches != absent) return;
  }
  throw TestFailure(
    absent ? 'Widget ancora presente: $finder' : 'Widget non trovato: $finder',
  );
}
