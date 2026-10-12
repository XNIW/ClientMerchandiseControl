import 'dart:io';
import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_controller.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/delivery_live_map.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/google_delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/presentation/customer_delivery_tracking_eta.dart';
import 'package:client_merchandise_control/features/orders/presentation/customer_order_presentation.dart';
import 'package:client_merchandise_control/features/orders/presentation/order_detail_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/delivery_tracking/delivery_tracking_test_support.dart';
import '../test/features/orders/customer_order_test_support.dart';
import '../test/support/client_host_visual_fonts.dart';

void main() => registerCustomerDeliveryTrackingTests();

/// Il wrapper host qualifica componenti con fixture; il percorso nativo resta separato.
void registerCustomerDeliveryTrackingTests({bool hostRenderer = false}) {
  if (hostRenderer) {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(loadClientHostVisualFonts);
  } else {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  testWidgets(
    'owner contract live update stale e terminal redaction restano fail-closed',
    (tester) async {
      final snapshot = ValueNotifier<DeliveryTrackingSnapshot>(
        parseDeliveryTrackingSnapshot(_payload(version: 1)),
      );
      final ownerAuthenticated = ValueNotifier(false);
      final adapter = FakeDeliveryMapAdapter();
      var factoryCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryMapConfigurationProvider.overrideWithValue(
              const DeliveryMapConfiguration(
                enabled: true,
                nativeConfigurationPresent: true,
              ),
            ),
            deliveryMapNativeConfigurationProbeProvider.overrideWithValue(
              () async => true,
            ),
            deliveryMapAdapterFactoryProvider.overrideWithValue(() {
              factoryCalls++;
              return adapter;
            }),
            deliveryMapSurfaceBuilderProvider.overrideWithValue(
              ({
                required adapter,
                required scene,
                required labels,
                required brightness,
              }) => const ColoredBox(
                key: ValueKey('acceptance-map-surface'),
                color: Colors.transparent,
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: ownerAuthenticated,
                builder: (context, owner, _) {
                  return ValueListenableBuilder<DeliveryTrackingSnapshot>(
                    valueListenable: snapshot,
                    builder: (context, current, _) => DeliveryLiveMap(
                      snapshot: current,
                      ownerAuthenticated: owner,
                      orderStatusCompatible:
                          current.orderStatus == 'out_for_delivery',
                      semanticsLabel: 'Delivery status and last update',
                      recenterLabel: 'Recenter delivery map',
                      loadingLabel: 'Loading delivery map',
                      markerLabels: const DeliveryMapMarkerLabels(
                        store: 'Store',
                        destination: 'Destination',
                        courier: 'Courier',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(factoryCalls, 0);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);

      ownerAuthenticated.value = true;
      await _pumpUntil(
        tester,
        () => find
            .byKey(const ValueKey('acceptance-map-surface'))
            .evaluate()
            .isNotEmpty,
      );
      expect(factoryCalls, 1);
      expect(
        find.byKey(const ValueKey('acceptance-map-surface')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delivery-live-map')), findsOneWidget);
      expect(adapter.scenes.single.snapshotVersion, 1);

      snapshot.value = parseDeliveryTrackingSnapshot(
        _payload(version: 2, latitude: -33.4455),
      );
      await _pumpUntil(tester, () => adapter.scenes.last.snapshotVersion == 2);
      expect(adapter.scenes.last.snapshotVersion, 2);
      expect(adapter.scenes.last.courier.latitude, -33.4455);

      snapshot.value = parseDeliveryTrackingSnapshot(
        _payload(version: 3, freshness: 'stale'),
      );
      await _pumpUntil(
        tester,
        () =>
            find.byKey(const ValueKey('delivery-live-map')).evaluate().isEmpty,
      );
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(adapter.disposeCalls, 1);

      final terminal = parseDeliveryTrackingSnapshot(
        _payload(
          version: 4,
          orderStatus: 'completed',
          trackingState: 'completed',
          freshness: 'ended',
          redact: true,
        ),
      );
      snapshot.value = terminal;
      await tester.pump(const Duration(milliseconds: 50));
      expect(terminal.isTerminal, isTrue);
      expect(terminal.courierCoordinate, isNull);
      expect(terminal.destinationCoordinate, isNull);
      expect(terminal.storeCoordinate, isNull);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(factoryCalls, 1);
    },
  );

  // Le catture host non entrano nel manifest o nella numerazione nativa canonica.
  if (!hostRenderer) {
    return;
  }
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'consegna fixture ETA mappa espansa e fallback ${locale.toLanguageTag()} dark=$dark testo200',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final semantics = tester.ensureSemantics();
          final orders = FakeCustomerOrderRepository()
            ..detailOutcomes.add(
              orderTestDetail(
                status: CustomerOrderStatus.outForDelivery,
                version: 2,
                fulfillmentMode: CustomerOrderFulfillmentMode.delivery,
                cancellationAllowed: false,
                serverTime: trackingTestNow,
              ),
            );
          DeliveryTrackingSnapshot snapshot(
            int version,
            DateTime? start,
            DateTime? end,
          ) => parseDeliveryTrackingSnapshot(
            trackingLivePayload(
              orderId: orderTestOrder,
              version: version,
              orderStatusVersion: 2,
            )
              ..['etaStartsAt'] = start?.toIso8601String()
              ..['etaEndsAt'] = end?.toIso8601String(),
          );
          final tracking = FakeDeliveryTrackingRepository()
            ..snapshot = snapshot(1, null, null);
          final adapters = <_VisualTrackingMapAdapter>[];
          final container = ProviderContainer(
            overrides: [
              customerOrderIdentityProvider.overrideWithValue(
                AuthenticatedCustomer.fromUntrustedIdentity(
                  subjectId: orderTestOwner,
                  email: 'customer@example.invalid',
                  metadata: const {'name': 'Cliente sintetico'},
                ),
              ),
              customerOrderShopSlugProvider.overrideWithValue(orderTestShop),
              customerOrderRepositoryProvider.overrideWithValue(orders),
              customerOrderCacheStoreProvider.overrideWithValue(
                MemoryCustomerOrderCacheStore(),
              ),
              customerOrderClockProvider.overrideWithValue(() => orderTestNow),
              customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
                () => orderTestKey,
              ),
              deliveryTrackingRepositoryProvider.overrideWithValue(tracking),
              deliveryTrackingCacheProvider.overrideWithValue(
                MemoryDeliveryTrackingCache(),
              ),
              deliveryTrackingClockProvider.overrideWithValue(
                () => trackingTestNow,
              ),
              deliveryTrackingPollIntervalProvider.overrideWithValue(
                const Duration(hours: 1),
              ),
              deliveryMapConfigurationProvider.overrideWithValue(
                const DeliveryMapConfiguration(
                  enabled: true,
                  nativeConfigurationPresent: true,
                ),
              ),
              deliveryMapNativeConfigurationProbeProvider.overrideWithValue(
                () async => true,
              ),
              deliveryMapAdapterFactoryProvider.overrideWithValue(() {
                final adapter = _VisualTrackingMapAdapter();
                adapters.add(adapter);
                return adapter;
              }),
              deliveryMapSurfaceBuilderProvider.overrideWithValue(
                ({
                  required adapter,
                  required scene,
                  required labels,
                  required brightness,
                }) => ColoredBox(
                  key: const ValueKey('tracking-fixture-provider-surface'),
                  // Superficie neutra: nessuna tile, marker o logo Google simulato.
                  color: brightness == Brightness.dark
                      ? const Color(0xFF263238)
                      : const Color(0xFFECEFF1),
                ),
              ),
            ],
          );
          try {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: clientHostVisualTheme(AppTheme.light()),
                  darkTheme: clientHostVisualTheme(AppTheme.dark()),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  locale: locale,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: const OrderDetailScreen(orderId: orderTestOrder),
                ),
              ),
            );
            final card = find.byKey(const ValueKey('delivery-tracking-card'));
            final map = find.byKey(const ValueKey('delivery-live-map'));
            final eta = find.byKey(const ValueKey('delivery-tracking-eta'));
            await _pumpUntil(tester, () => map.evaluate().isNotEmpty);
            final l10n = AppLocalizations.of(tester.element(card));
            final detailState = tester.state(find.byType(OrderDetailScreen));
            final header = tester.element(
              find.byKey(const ValueKey('order-detail-header')),
            );
            final timeline = tester.element(
              find.byKey(const ValueKey('order-detail-timeline')),
            );
            expect(find.text(l10n.deliveryTrackingEtaUnavailable), findsOneWidget);
            await _showTrackingControl(tester, eta);
            expect(tester.getSemantics(eta).flagsCollection.isLiveRegion, isTrue);

            tracking.stream.add(
              snapshot(
                2,
                trackingTestNow.subtract(const Duration(minutes: 20)),
                trackingTestNow.subtract(const Duration(minutes: 1)),
              ),
            );
            await _pumpUntil(
              tester,
              () => find.text(l10n.deliveryTrackingEtaExpired).evaluate().isNotEmpty,
            );
            final start = trackingTestNow.add(const Duration(minutes: 5));
            final end = trackingTestNow.add(const Duration(minutes: 20));
            tracking.stream.add(snapshot(3, start, end));
            await _pumpUntil(
              tester,
              () => adapters.single.delegate.scenes.last.snapshotVersion == 3,
            );
            final window = l10n.deliveryTrackingWindow(
              customerOrderDate(tester.element(card), start, timeZone: 'America/Santiago'),
              customerOrderDate(tester.element(card), end, timeZone: 'America/Santiago'),
            );
            expect(find.text(window), findsOneWidget);
            expect(find.text(l10n.deliveryTrackingEtaExpired), findsNothing);
            await _showTrackingControl(tester, map);
            expect(
              tester.getSemantics(map).label,
              contains(l10n.checkoutOrderStatusOutForDelivery),
            );
            final expand = find.byKey(const ValueKey('delivery-map-expand'));
            final recenter = find.byKey(const ValueKey('delivery-map-recenter'));
            final compactHeight = tester.getSize(map).height;
            await _showTrackingControl(tester, expand);
            expect(tester.getSize(expand), const Size(48, 48));
            expect(tester.getSemantics(expand).label, contains(l10n.deliveryTrackingMapExpand));
            await tester.tap(expand);
            await tester.pumpAndSettle();
            expect(tester.getSize(map).height, greaterThan(compactHeight));
            expect(adapters, hasLength(1));
            expect(adapters.single.delegate.disposeCalls, 0);
            expect(adapters.single.delegate.recenterCalls, 0);
            await _showTrackingControl(tester, expand);
            expect(tester.getSemantics(expand).label, contains(l10n.deliveryTrackingMapCollapse));
            await _showTrackingControl(tester, recenter);
            expect(tester.getSize(recenter), const Size(48, 48));
            expect(tester.getSemantics(recenter).label, contains(l10n.deliveryTrackingMapRecenter));
            await tester.tap(recenter);
            await tester.pump();
            expect(adapters.single.delegate.recenterCalls, 1);
            expect(adapters.single.delegate.lastRecenterAnimated, isFalse);
            expect(tester.takeException(), isNull);
            final suffix = '${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}-200';
            await _captureTrackingHostCard(
              tester,
              card,
              'delivery-tracking-expanded-$suffix',
            );

            // Il provider già pronto fallisce sul feed successivo; il dettaglio resta.
            adapters.single.failRender = true;
            tracking.stream.add(
              snapshot(
                4,
                trackingTestNow.subtract(const Duration(minutes: 20)),
                trackingTestNow.subtract(const Duration(minutes: 1)),
              ),
            );
            final unavailable = find.byKey(const ValueKey('delivery-map-unavailable'));
            final retry = find.byKey(const ValueKey('delivery-map-retry'));
            await _pumpUntil(tester, () => unavailable.evaluate().isNotEmpty);
            expect(map, findsNothing);
            expect(expand, findsNothing);
            expect(recenter, findsNothing);
            expect(find.byKey(const ValueKey('tracking-fixture-provider-surface')), findsNothing);
            expect(adapters.single.delegate.disposeCalls, 1);
            expect(find.text(l10n.deliveryTrackingMapUnavailable), findsOneWidget);
            expect(find.text(l10n.deliveryTrackingMapRetry), findsOneWidget);
            expect(find.text(l10n.deliveryTrackingEtaExpired), findsOneWidget);
            await _showTrackingControl(tester, unavailable);
            expect(tester.getSemantics(unavailable).flagsCollection.isLiveRegion, isTrue);
            await _showTrackingControl(tester, eta);
            expect(tester.getSemantics(eta).flagsCollection.isLiveRegion, isTrue);
            expect(tester.state(find.byType(OrderDetailScreen)), same(detailState));
            expect(tester.element(find.byKey(const ValueKey('order-detail-header'))), same(header));
            expect(tester.element(find.byKey(const ValueKey('order-detail-timeline'))), same(timeline));
            await _showTrackingControl(tester, retry);
            expect(tester.getSize(retry).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
            expect(tester.getSemantics(retry).label, contains(l10n.deliveryTrackingMapRetry));
            expect(tester.getSemantics(retry).flagsCollection.isButton, isTrue);
            expect(tester.takeException(), isNull);
            await _captureTrackingHostCard(
              tester,
              card,
              'delivery-tracking-fallback-$suffix',
            );

            // Retry della sola mappa: stesso snapshot, nessuna RPC ordine/tracking extra.
            final snapshotBeforeRetry = container.read(deliveryTrackingControllerProvider).snapshot;
            final loadsBeforeRetry = tracking.loadCalls;
            final orderLoadsBeforeRetry = orders.detailRequests.length;
            await tester.tap(retry);
            await _pumpUntil(tester, () => map.evaluate().isNotEmpty);
            expect(adapters, hasLength(2));
            expect(adapters.first.delegate.disposeCalls, 1);
            expect(adapters.last.delegate.disposeCalls, 0);
            expect(container.read(deliveryTrackingControllerProvider).snapshot, same(snapshotBeforeRetry));
            expect(tester.widget<CustomerDeliveryTrackingEta>(find.byType(CustomerDeliveryTrackingEta)).snapshot, same(snapshotBeforeRetry));
            expect(tracking.loadCalls, loadsBeforeRetry);
            expect(orders.detailRequests, hasLength(orderLoadsBeforeRetry));
            expect(unavailable, findsNothing);
            expect(retry, findsNothing);
            expect(find.text(l10n.deliveryTrackingEtaExpired), findsOneWidget);
            expect(tester.state(find.byType(OrderDetailScreen)), same(detailState));
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            await container.read(deliveryTrackingControllerProvider.notifier).close();
            container.dispose();
            await tracking.stream.close();
            semantics.dispose();
          }
        },
      );
    }
  }

}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
  }
  fail('La condizione asincrona non si è verificata entro il limite bounded.');
}

Map<String, Object?> _payload({
  required int version,
  double latitude = -33.446,
  String orderStatus = 'out_for_delivery',
  String trackingState = 'active',
  String freshness = 'fresh',
  bool redact = false,
}) {
  final serverTime = DateTime.utc(2026, 8, 16, 12, 0, version);
  return {
    'apiVersion': 'delivery-tracking-snapshot.v1',
    'orderId': '44000000-0000-4000-8000-000000045001',
    'orderStatus': orderStatus,
    'orderStatusVersion': orderStatus == 'completed' ? 6 : 5,
    'fulfillmentMode': 'delivery',
    'trackingMode': 'liveCourier',
    'trackingSessionId': redact ? null : '74000000-0000-4000-8000-000000045001',
    'trackingState': trackingState,
    'courierPublicLabel': redact ? null : 'Repartidor MC',
    'vehicleKind': redact ? null : 'bicycle',
    'latitude': redact ? null : latitude,
    'longitude': redact ? null : -70.655,
    'horizontalAccuracyMeters': redact ? null : 12,
    'bearingDegrees': redact ? null : 90,
    'speedMetersPerSecond': redact ? null : 4,
    'observedAt': redact
        ? null
        : serverTime.subtract(const Duration(seconds: 2)).toIso8601String(),
    'receivedAt': redact
        ? null
        : serverTime.subtract(const Duration(seconds: 1)).toIso8601String(),
    'freshness': freshness,
    'etaStartsAt': serverTime
        .add(const Duration(minutes: 30))
        .toIso8601String(),
    'etaEndsAt': serverTime.add(const Duration(minutes: 50)).toIso8601String(),
    'destinationLatitude': redact ? null : -33.447,
    'destinationLongitude': redact ? null : -70.65,
    'storeLatitude': redact ? null : -33.445,
    'storeLongitude': redact ? null : -70.66,
    'externalCarrier': null,
    'externalTrackingCodeMasked': null,
    'externalTrackingUrl': null,
    'contactCapability': 'none',
    'serverTime': serverTime.toIso8601String(),
    'version': version,
  };
}


final class _VisualTrackingMapAdapter implements RecenterableDeliveryMapAdapter {
  final delegate = FakeDeliveryMapAdapter();
  var failRender = false;

  @override
  Future<void> render(DeliveryMapScene scene) async {
    if (failRender) {
      throw StateError('synthetic_tracking_provider_failure');
    }
    await delegate.render(scene);
  }

  @override
  Future<void> recenter({required bool animated}) =>
      delegate.recenter(animated: animated);

  @override
  Future<void> dispose() => delegate.dispose();
}

Future<void> _showTrackingControl(WidgetTester tester, Finder control) async {
  await Scrollable.ensureVisible(
    tester.element(control),
    alignment: 1,
  );
  await tester.pumpAndSettle();
  expect(control.hitTestable(), findsOneWidget);
}

/// Rasterizza la card reale dal layer che la dipinge, senza stitching o widget clonati.
/// La card può superare il viewport: il PNG prova il componente, non un frame OS.
Future<void> _captureTrackingHostCard(
  WidgetTester tester,
  Finder card,
  String name,
) async {
  final directory = Platform.environment['CMC_CLIENT_CAPTURE_DIR'];
  if (directory == null) {
    return;
  }
  await tester.pump();
  final render = tester.renderObject<RenderBox>(card);
  RenderObject? ancestor = render;
  while (ancestor != null && ancestor is! RenderRepaintBoundary) {
    ancestor = ancestor.parent;
  }
  if (ancestor is! RenderRepaintBoundary) {
    throw StateError('tracking_fixture_repaint_boundary_missing');
  }
  final layer = ancestor.layer;
  if (layer is! OffsetLayer) {
    throw StateError('tracking_fixture_offset_layer_missing');
  }
  final origin = render.localToGlobal(Offset.zero, ancestor: ancestor);
  final bounds = origin & render.size;
  await tester.runAsync(() async {
    final frame = await layer.toImage(bounds);
    try {
      final bytes = await frame.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('tracking_fixture_png_missing');
      }
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png').writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      frame.dispose();
    }
  });
}
