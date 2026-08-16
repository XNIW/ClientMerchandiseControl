import 'dart:async';

import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/delivery_live_map.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/google_delivery_map_adapter.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  const enabledConfiguration = DeliveryMapConfiguration(
    enabled: true,
    nativeConfigurationPresent: true,
  );

  testWidgets(
    'live owner-scoped rende il fake, aggiorna marker e rimuove lo stale',
    (tester) async {
      final adapter = FakeDeliveryMapAdapter();
      final builtScenes = <DeliveryMapScene>[];
      final semantics = tester.ensureSemantics();

      Future<void> pump(DeliveryTrackingSnapshot snapshot) async {
        await tester.pumpWidget(
          _mapApp(
            snapshot: snapshot,
            configuration: enabledConfiguration,
            adapterFactory: () => adapter,
            surfaceBuilder:
                ({
                  required adapter,
                  required scene,
                  required labels,
                  required brightness,
                }) {
                  builtScenes.add(scene);
                  return const ColoredBox(
                    key: ValueKey('fake-delivery-map-surface'),
                    color: Colors.transparent,
                  );
                },
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(trackingLiveSnapshot());

      expect(find.byKey(const ValueKey('delivery-live-map')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fake-delivery-map-surface')),
        findsOneWidget,
      );
      expect(adapter.scenes.single.snapshotVersion, 4);
      expect(builtScenes.single.courier.latitude, -33.446);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('delivery-live-map')))
            .label,
        contains('Entrega en curso'),
      );
      final recenter = find.byKey(const ValueKey('delivery-map-recenter'));
      expect(tester.getSize(recenter), const Size(48, 48));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(iOSTapTargetGuideline));
      await tester.tap(recenter);
      await tester.pump();
      expect(adapter.recenterCalls, 1);
      expect(adapter.lastRecenterAnimated, isTrue);

      await pump(trackingLiveSnapshot(version: 5));
      expect(adapter.scenes.last.snapshotVersion, 5);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsOneWidget);

      await pump(trackingLiveSnapshot(version: 6, freshness: 'stale'));
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(adapter.disposeCalls, 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'flag, chiave, owner, stato ordine e mode non istanziano il provider',
    (tester) async {
      var factoryCalls = 0;
      final configurations = [
        const DeliveryMapConfiguration(
          enabled: false,
          nativeConfigurationPresent: true,
        ),
        const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: false,
        ),
      ];

      for (final configuration in configurations) {
        await tester.pumpWidget(
          _mapApp(
            snapshot: trackingLiveSnapshot(),
            configuration: configuration,
            adapterFactory: () {
              factoryCalls++;
              return FakeDeliveryMapAdapter();
            },
          ),
        );
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        _mapApp(
          snapshot: trackingLiveSnapshot(),
          configuration: enabledConfiguration,
          nativeConfigurationProbe: () async => false,
          adapterFactory: () {
            factoryCalls++;
            return FakeDeliveryMapAdapter();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('delivery-map-unavailable')),
        findsOneWidget,
      );

      for (final input in [
        (snapshot: trackingLiveSnapshot(), owner: false, compatible: true),
        (snapshot: trackingLiveSnapshot(), owner: true, compatible: false),
        (
          snapshot: _nonLiveSnapshot(DeliveryTrackingMode.statusOnly),
          owner: true,
          compatible: true,
        ),
        (
          snapshot: _nonLiveSnapshot(DeliveryTrackingMode.externalCarrier),
          owner: true,
          compatible: true,
        ),
      ]) {
        await tester.pumpWidget(
          _mapApp(
            snapshot: input.snapshot,
            configuration: enabledConfiguration,
            ownerAuthenticated: input.owner,
            orderStatusCompatible: input.compatible,
            adapterFactory: () {
              factoryCalls++;
              return FakeDeliveryMapAdapter();
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      }

      expect(factoryCalls, 0);
    },
  );

  testWidgets('provider exception degrada e reduced motion evita animazione', (
    tester,
  ) async {
    final failingAdapter = FakeDeliveryMapAdapter(
      renderException: StateError('synthetic_provider_failure'),
    );
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => failingAdapter,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
    expect(failingAdapter.disposeCalls, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final reducedMotionAdapter = FakeDeliveryMapAdapter();
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => reducedMotionAdapter,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delivery-map-recenter')));
    await tester.pump();
    expect(reducedMotionAdapter.lastRecenterAnimated, isFalse);
  });

  testWidgets('factory exception degrada senza montare la superficie', (
    tester,
  ) async {
    var surfaceCalls = 0;
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => throw StateError('synthetic_factory_failure'),
        surfaceBuilder:
            ({
              required adapter,
              required scene,
              required labels,
              required brightness,
            }) {
              surfaceCalls++;
              return const SizedBox();
            },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
    expect(
      find.byKey(const ValueKey('delivery-map-unavailable')),
      findsOneWidget,
    );
    expect(surfaceCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider nativo diventa visibile solo dopo runtime ready', (
    tester,
  ) async {
    final adapter = _RuntimeDeliveryMapAdapter();
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => adapter,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('delivery-map-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);

    adapter.emit(DeliveryMapRuntimeState.ready);
    await tester.pump();

    expect(find.byKey(const ValueKey('delivery-live-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('delivery-map-recenter')), findsOneWidget);
  });

  testWidgets('errore runtime del provider degrada e dispone senza eccezioni', (
    tester,
  ) async {
    final adapter = _RuntimeDeliveryMapAdapter();
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => adapter,
      ),
    );
    await tester.pump();
    await tester.pump();
    adapter.emit(DeliveryMapRuntimeState.failed);
    await tester.pump();
    await tester.pump();

    expect(adapter.disposeCalls, 1);
    expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
    expect(
      find.byKey(const ValueKey('delivery-map-unavailable')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider che non diventa ready scade in modo fail-closed', (
    tester,
  ) async {
    final adapter = _RuntimeDeliveryMapAdapter();
    await tester.pumpWidget(
      _mapApp(
        snapshot: trackingLiveSnapshot(),
        configuration: enabledConfiguration,
        adapterFactory: () => adapter,
        providerReadyTimeout: const Duration(milliseconds: 10),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
    expect(adapter.disposeCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matrice bounded rifluisce, localizza e mantiene target 48 dp', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const cases = <({Size size, double scale, Locale locale, ThemeMode theme})>[
      (
        size: Size(320, 568),
        scale: 2,
        locale: Locale('es', 'CL'),
        theme: ThemeMode.dark,
      ),
      (
        size: Size(360, 800),
        scale: 1,
        locale: Locale('it'),
        theme: ThemeMode.light,
      ),
      (
        size: Size(390, 844),
        scale: 1.3,
        locale: Locale('en'),
        theme: ThemeMode.dark,
      ),
      (
        size: Size(430, 932),
        scale: 2,
        locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        theme: ThemeMode.light,
      ),
      (
        size: Size(768, 1024),
        scale: 1.3,
        locale: Locale('es', 'CL'),
        theme: ThemeMode.dark,
      ),
      (
        size: Size(1024, 768),
        scale: 1,
        locale: Locale('it'),
        theme: ThemeMode.light,
      ),
      (
        size: Size(844, 390),
        scale: 2,
        locale: Locale('en'),
        theme: ThemeMode.dark,
      ),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(testCase.size);
      await tester.pumpWidget(
        _mapApp(
          snapshot: trackingLiveSnapshot(),
          configuration: enabledConfiguration,
          adapterFactory: FakeDeliveryMapAdapter.new,
          locale: testCase.locale,
          themeMode: testCase.theme,
          textScaler: TextScaler.linear(testCase.scale),
        ),
      );
      await tester.pumpAndSettle();

      final map = find.byKey(const ValueKey('delivery-live-map'));
      final recenter = find.byKey(const ValueKey('delivery-map-recenter'));
      expect(map, findsOneWidget, reason: '$testCase');
      expect(tester.getSize(recenter), const Size(48, 48), reason: '$testCase');
      expect(tester.getRect(map).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(map).right, lessThanOrEqualTo(testCase.size.width));
      expect(tester.takeException(), isNull, reason: '$testCase');
    }
  });
}

Widget _mapApp({
  required DeliveryTrackingSnapshot snapshot,
  required DeliveryMapConfiguration configuration,
  required DeliveryMapAdapterFactory adapterFactory,
  DeliveryMapNativeConfigurationProbe? nativeConfigurationProbe,
  DeliveryMapSurfaceBuilder? surfaceBuilder,
  Duration providerReadyTimeout = const Duration(seconds: 10),
  bool ownerAuthenticated = true,
  bool orderStatusCompatible = true,
  bool disableAnimations = false,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      deliveryMapConfigurationProvider.overrideWithValue(configuration),
      deliveryMapNativeConfigurationProbeProvider.overrideWithValue(
        nativeConfigurationProbe ??
            () async => configuration.nativeConfigurationPresent,
      ),
      deliveryMapProviderReadyTimeoutProvider.overrideWithValue(
        providerReadyTimeout,
      ),
      deliveryMapAdapterFactoryProvider.overrideWithValue(adapterFactory),
      deliveryMapSurfaceBuilderProvider.overrideWithValue(
        surfaceBuilder ??
            ({
              required adapter,
              required scene,
              required labels,
              required brightness,
            }) => const ColoredBox(color: Colors.transparent),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      theme: ThemeData(colorSchemeSeed: const Color(0xff006c4c)),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xff006c4c),
      ),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: _LocalizedDeliveryMap(
          snapshot: snapshot,
          ownerAuthenticated: ownerAuthenticated,
          orderStatusCompatible: orderStatusCompatible,
        ),
      ),
    ),
  );
}

final class _RuntimeDeliveryMapAdapter
    implements RecenterableDeliveryMapAdapter, DeliveryMapRuntimeStateSource {
  final StreamController<DeliveryMapRuntimeState> _states =
      StreamController<DeliveryMapRuntimeState>.broadcast();
  final List<DeliveryMapScene> scenes = [];
  var disposeCalls = 0;

  @override
  Stream<DeliveryMapRuntimeState> get runtimeStates => _states.stream;

  void emit(DeliveryMapRuntimeState state) => _states.add(state);

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _states.close();
  }

  @override
  Future<void> recenter({required bool animated}) async {}

  @override
  Future<void> render(DeliveryMapScene scene) async => scenes.add(scene);
}

class _LocalizedDeliveryMap extends StatelessWidget {
  const _LocalizedDeliveryMap({
    required this.snapshot,
    required this.ownerAuthenticated,
    required this.orderStatusCompatible,
  });

  final DeliveryTrackingSnapshot snapshot;
  final bool ownerAuthenticated;
  final bool orderStatusCompatible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DeliveryLiveMap(
      snapshot: snapshot,
      ownerAuthenticated: ownerAuthenticated,
      orderStatusCompatible: orderStatusCompatible,
      semanticsLabel: l10n.deliveryTrackingMapSemantics(
        l10n.deliveryTrackingInDeliveryIndicator,
        l10n.deliveryTrackingFresh,
      ),
      recenterLabel: l10n.deliveryTrackingMapRecenter,
      loadingLabel: l10n.deliveryTrackingMapLoading,
      markerLabels: DeliveryMapMarkerLabels(
        store: l10n.deliveryTrackingMapStoreMarker,
        destination: l10n.deliveryTrackingMapDestinationMarker,
        courier: l10n.deliveryTrackingMapCourierMarker,
      ),
    );
  }
}

DeliveryTrackingSnapshot _nonLiveSnapshot(DeliveryTrackingMode mode) {
  return DeliveryTrackingSnapshot(
    orderId: trackingTestOrder,
    orderStatus: 'out_for_delivery',
    orderStatusVersion: 5,
    fulfillmentMode: 'delivery',
    trackingMode: mode,
    trackingState: DeliveryTrackingState.active,
    freshness: DeliveryTrackingFreshness.unavailable,
    contactCapability: DeliveryContactCapability.none,
    serverTime: trackingTestNow,
    version: 4,
    externalCarrier: mode == DeliveryTrackingMode.externalCarrier
        ? 'Carrier sintético'
        : null,
    externalTrackingUrl: mode == DeliveryTrackingMode.externalCarrier
        ? Uri.https('carrier.example', '/track')
        : null,
  );
}
