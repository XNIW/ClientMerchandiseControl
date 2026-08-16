import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../application/delivery_map_adapter.dart';
import '../domain/delivery_tracking_models.dart';
import 'google_delivery_map_adapter.dart';

typedef DeliveryMapAdapterFactory = DeliveryMapAdapter Function();
typedef DeliveryMapNativeConfigurationProbe = Future<bool> Function();
typedef DeliveryMapSurfaceBuilder =
    Widget Function({
      required DeliveryMapAdapter adapter,
      required DeliveryMapScene scene,
      required DeliveryMapMarkerLabels labels,
      required Brightness brightness,
    });

final deliveryMapConfigurationProvider = Provider<DeliveryMapConfiguration>(
  (ref) => DeliveryMapConfiguration.fromEnvironment(),
);

final deliveryMapAdapterFactoryProvider = Provider<DeliveryMapAdapterFactory>(
  (ref) => GoogleDeliveryMapAdapter.new,
);

const _nativeConfigurationChannel = MethodChannel(
  'com.xniw.clientmerchandisecontrol/delivery_map_configuration',
);

final deliveryMapNativeConfigurationProbeProvider =
    Provider<DeliveryMapNativeConfigurationProbe>((ref) {
      return () async {
        try {
          return await _nativeConfigurationChannel.invokeMethod<bool>(
                'isConfigured',
              ) ==
              true;
        } on Object {
          return false;
        }
      };
    });

final deliveryMapProviderReadyTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

final deliveryMapSurfaceBuilderProvider = Provider<DeliveryMapSurfaceBuilder>((
  ref,
) {
  return ({
    required adapter,
    required scene,
    required labels,
    required brightness,
  }) {
    if (adapter is! GoogleDeliveryMapAdapter) {
      throw StateError('delivery_map_surface_adapter_mismatch');
    }
    return adapter.buildSurface(labels: labels, brightness: brightness);
  };
});

class DeliveryLiveMap extends ConsumerStatefulWidget {
  const DeliveryLiveMap({
    required this.snapshot,
    required this.ownerAuthenticated,
    required this.orderStatusCompatible,
    required this.semanticsLabel,
    required this.recenterLabel,
    required this.loadingLabel,
    required this.markerLabels,
    super.key,
  });

  final DeliveryTrackingSnapshot snapshot;
  final bool ownerAuthenticated;
  final bool orderStatusCompatible;
  final String semanticsLabel;
  final String recenterLabel;
  final String loadingLabel;
  final DeliveryMapMarkerLabels markerLabels;

  @override
  ConsumerState<DeliveryLiveMap> createState() => _DeliveryLiveMapState();
}

class _DeliveryLiveMapState extends ConsumerState<DeliveryLiveMap> {
  DeliveryMapAdapter? _adapter;
  FailClosedDeliveryMapPresenter? _presenter;
  DeliveryMapPresentation? _presentation;
  StreamSubscription<DeliveryMapRuntimeState>? _runtimeSubscription;
  Timer? _providerReadyTimer;
  DeliveryMapAdapter? _runtimeBoundAdapter;
  bool? _nativeConfigurationReady;
  var _providerRuntimeReady = false;
  var _generation = 0;
  var _providerGeneration = 0;

  bool get _potentiallyEligible {
    final configuration = ref.read(deliveryMapConfigurationProvider);
    return configuration.enabled &&
        configuration.nativeConfigurationPresent &&
        isDeliveryLiveMapEligible(
          widget.snapshot,
          ownerAuthenticated: widget.ownerAuthenticated,
          orderStatusCompatible: widget.orderStatusCompatible,
        );
  }

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_present);
  }

  @override
  void didUpdateWidget(covariant DeliveryLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameInput(oldWidget, widget)) scheduleMicrotask(_present);
  }

  Future<void> _present() async {
    final generation = ++_generation;
    final configuration = ref.read(deliveryMapConfigurationProvider);
    if (!_potentiallyEligible) {
      await _releaseProvider();
      if (!mounted || generation != _generation) return;
      setState(() {
        _presentation = DeliveryMapUnavailable(
          !configuration.enabled
              ? DeliveryMapUnavailableReason.featureFlagOff
              : !configuration.nativeConfigurationPresent
              ? DeliveryMapUnavailableReason.missingNativeConfiguration
              : DeliveryMapUnavailableReason.trackingUnavailable,
        );
      });
      return;
    }

    if (_nativeConfigurationReady != true) {
      final nativeConfigurationReady =
          _nativeConfigurationReady ??
          await ref.read(deliveryMapNativeConfigurationProbeProvider)();
      if (!mounted || generation != _generation) return;
      _nativeConfigurationReady = nativeConfigurationReady;
      if (!nativeConfigurationReady) {
        await _releaseProvider();
        if (!mounted || generation != _generation) return;
        setState(
          () => _presentation = const DeliveryMapUnavailable(
            DeliveryMapUnavailableReason.missingNativeConfiguration,
          ),
        );
        return;
      }
    }

    late final DeliveryMapPresentation result;
    try {
      final adapter = _adapter ??= ref.read(
        deliveryMapAdapterFactoryProvider,
      )();
      final presenter = _presenter ??= FailClosedDeliveryMapPresenter(
        configuration: configuration,
        adapter: adapter,
      );
      result = await presenter.present(
        widget.snapshot,
        ownerAuthenticated: widget.ownerAuthenticated,
        orderStatusCompatible: widget.orderStatusCompatible,
      );
    } on Object {
      await _releaseProvider();
      if (!mounted || generation != _generation) return;
      setState(
        () => _presentation = const DeliveryMapUnavailable(
          DeliveryMapUnavailableReason.providerException,
        ),
      );
      return;
    }
    if (!mounted || generation != _generation) return;
    if (result is DeliveryMapUnavailable) {
      await _releaseProvider();
      if (!mounted || generation != _generation) return;
    } else if (result is DeliveryMapReady) {
      _bindProviderRuntime(_adapter!);
    }
    setState(() => _presentation = result);
  }

  void _bindProviderRuntime(DeliveryMapAdapter adapter) {
    if (identical(_runtimeBoundAdapter, adapter)) return;
    final providerGeneration = ++_providerGeneration;
    _runtimeBoundAdapter = adapter;
    _providerReadyTimer?.cancel();
    unawaited(_runtimeSubscription?.cancel());
    final runtimeSource = adapter is DeliveryMapRuntimeStateSource
        ? adapter as DeliveryMapRuntimeStateSource
        : null;
    if (runtimeSource == null) {
      _providerRuntimeReady = true;
      return;
    }
    _providerRuntimeReady = false;
    _runtimeSubscription = runtimeSource.runtimeStates.listen(
      (runtimeState) {
        if (!mounted || providerGeneration != _providerGeneration) return;
        switch (runtimeState) {
          case DeliveryMapRuntimeState.ready:
            _providerReadyTimer?.cancel();
            if (_providerRuntimeReady) return;
            setState(() => _providerRuntimeReady = true);
            break;
          case DeliveryMapRuntimeState.failed:
            unawaited(_failProvider(providerGeneration));
            break;
        }
      },
      onError: (_) => unawaited(_failProvider(providerGeneration)),
      onDone: () {
        if (!_providerRuntimeReady) {
          unawaited(_failProvider(providerGeneration));
        }
      },
    );
    _providerReadyTimer = Timer(
      ref.read(deliveryMapProviderReadyTimeoutProvider),
      () => unawaited(_failProvider(providerGeneration)),
    );
  }

  Future<void> _failProvider(int providerGeneration) async {
    if (!mounted || providerGeneration != _providerGeneration) return;
    final generation = ++_generation;
    await _releaseProvider();
    if (!mounted || generation != _generation) return;
    setState(
      () => _presentation = const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.providerException,
      ),
    );
  }

  Future<void> _releaseProvider() async {
    _providerGeneration++;
    _providerReadyTimer?.cancel();
    _providerReadyTimer = null;
    final runtimeSubscription = _runtimeSubscription;
    _runtimeSubscription = null;
    _runtimeBoundAdapter = null;
    _providerRuntimeReady = false;
    unawaited(runtimeSubscription?.cancel());
    final presenter = _presenter;
    final adapter = _adapter;
    _presenter = null;
    _adapter = null;
    if (presenter != null) {
      await presenter.dispose();
    } else {
      await adapter?.dispose();
    }
  }

  Future<void> _recenter() async {
    final adapter = _adapter;
    if (adapter is! RecenterableDeliveryMapAdapter) return;
    try {
      await adapter.recenter(
        animated: !MediaQuery.disableAnimationsOf(context),
      );
    } on Object {
      final generation = ++_generation;
      await _releaseProvider();
      if (!mounted || generation != _generation) return;
      setState(
        () => _presentation = const DeliveryMapUnavailable(
          DeliveryMapUnavailableReason.providerException,
        ),
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_releaseProvider());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_potentiallyEligible) return const SizedBox.shrink();
    final presentation = _presentation;
    if (presentation is DeliveryMapUnavailable) {
      return const SizedBox.shrink(key: ValueKey('delivery-map-unavailable'));
    }
    if (presentation is! DeliveryMapReady || _adapter == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Semantics(
          liveRegion: true,
          label: widget.loadingLabel,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              key: const ValueKey('delivery-map-loading'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.surface),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }
    final surfaceBuilder = ref.read(deliveryMapSurfaceBuilderProvider);
    Widget surface;
    try {
      surface = surfaceBuilder(
        adapter: _adapter!,
        scene: presentation.scene,
        labels: widget.markerLabels,
        brightness: Theme.of(context).brightness,
      );
    } on Object {
      final failureGeneration = _generation;
      scheduleMicrotask(() async {
        if (!mounted || failureGeneration != _generation) return;
        final generation = ++_generation;
        await _releaseProvider();
        if (!mounted || generation != _generation) return;
        setState(
          () => _presentation = const DeliveryMapUnavailable(
            DeliveryMapUnavailableReason.providerException,
          ),
        );
      });
      return const SizedBox.shrink(key: ValueKey('delivery-map-unavailable'));
    }
    final providerRuntimeReady = _providerRuntimeReady;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Semantics(
        key: ValueKey(
          providerRuntimeReady ? 'delivery-live-map' : 'delivery-map-loading',
        ),
        container: true,
        liveRegion: !providerRuntimeReady,
        label: providerRuntimeReady
            ? widget.semanticsLabel
            : widget.loadingLabel,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.surface),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  ignoring: !providerRuntimeReady,
                  child: ExcludeSemantics(child: surface),
                ),
                if (!providerRuntimeReady)
                  ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else
                  PositionedDirectional(
                    end: 8,
                    bottom: 8,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 2,
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const ValueKey('delivery-map-recenter'),
                        tooltip: widget.recenterLabel,
                        constraints: const BoxConstraints.tightFor(
                          width: AppSizes.minimumTouchTarget,
                          height: AppSizes.minimumTouchTarget,
                        ),
                        onPressed: _recenter,
                        icon: const Icon(Icons.center_focus_strong_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameInput(DeliveryLiveMap left, DeliveryLiveMap right) =>
    identical(left.snapshot, right.snapshot) &&
    left.ownerAuthenticated == right.ownerAuthenticated &&
    left.orderStatusCompatible == right.orderStatusCompatible &&
    left.semanticsLabel == right.semanticsLabel &&
    left.recenterLabel == right.recenterLabel &&
    left.loadingLabel == right.loadingLabel;
