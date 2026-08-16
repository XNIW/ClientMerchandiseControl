import '../domain/delivery_tracking_models.dart';

enum DeliveryMapUnavailableReason {
  featureFlagOff,
  missingNativeConfiguration,
  trackingUnavailable,
  providerException,
  disposed,
}

final class DeliveryMapConfiguration {
  const DeliveryMapConfiguration({
    required this.enabled,
    required this.nativeConfigurationPresent,
  });

  factory DeliveryMapConfiguration.fromEnvironment() {
    return const DeliveryMapConfiguration(
      enabled: bool.fromEnvironment('DELIVERY_MAPS_ENABLED'),
      nativeConfigurationPresent: bool.fromEnvironment(
        'DELIVERY_MAPS_NATIVE_CONFIGURED',
      ),
    );
  }

  final bool enabled;
  final bool nativeConfigurationPresent;
}

final class DeliveryMapScene {
  const DeliveryMapScene({
    required this.store,
    required this.destination,
    required this.courier,
    required this.snapshotVersion,
  });

  factory DeliveryMapScene.fromSnapshot(DeliveryTrackingSnapshot snapshot) {
    if (!snapshot.hasFreshLiveLocation ||
        snapshot.storeCoordinate == null ||
        snapshot.destinationCoordinate == null) {
      throw const FormatException('delivery_map_tracking_unavailable');
    }
    return DeliveryMapScene(
      store: snapshot.storeCoordinate!,
      destination: snapshot.destinationCoordinate!,
      courier: snapshot.courierCoordinate!,
      snapshotVersion: snapshot.version,
    );
  }

  final DeliveryCoordinate store;
  final DeliveryCoordinate destination;
  final DeliveryCoordinate courier;
  final int snapshotVersion;
}

bool isDeliveryLiveMapEligible(
  DeliveryTrackingSnapshot snapshot, {
  required bool ownerAuthenticated,
  required bool orderStatusCompatible,
}) =>
    ownerAuthenticated &&
    orderStatusCompatible &&
    snapshot.hasFreshLiveLocation &&
    snapshot.storeCoordinate != null &&
    snapshot.destinationCoordinate != null;

sealed class DeliveryMapPresentation {
  const DeliveryMapPresentation();
}

final class DeliveryMapReady extends DeliveryMapPresentation {
  const DeliveryMapReady(this.scene);

  final DeliveryMapScene scene;
}

final class DeliveryMapUnavailable extends DeliveryMapPresentation {
  const DeliveryMapUnavailable(this.reason);

  final DeliveryMapUnavailableReason reason;
}

abstract interface class DeliveryMapAdapter {
  Future<void> render(DeliveryMapScene scene);

  Future<void> dispose();
}

abstract interface class RecenterableDeliveryMapAdapter
    implements DeliveryMapAdapter {
  Future<void> recenter({required bool animated});
}

enum DeliveryMapRuntimeState { ready, failed }

/// Segnala quando una superficie nativa e il suo controller sono realmente
/// utilizzabili. Gli adapter deterministici che non espongono questo contratto
/// sono considerati pronti dopo [DeliveryMapAdapter.render].
abstract interface class DeliveryMapRuntimeStateSource {
  Stream<DeliveryMapRuntimeState> get runtimeStates;
}

final class FailClosedDeliveryMapPresenter {
  FailClosedDeliveryMapPresenter({
    required this.configuration,
    required this.adapter,
  });

  final DeliveryMapConfiguration configuration;
  final DeliveryMapAdapter adapter;
  var _disposed = false;
  var _generation = 0;

  Future<DeliveryMapPresentation> present(
    DeliveryTrackingSnapshot snapshot, {
    required bool ownerAuthenticated,
    required bool orderStatusCompatible,
  }) async {
    if (_disposed) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.disposed,
      );
    }
    final generation = _generation;
    if (!configuration.enabled) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.featureFlagOff,
      );
    }
    if (!configuration.nativeConfigurationPresent) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.missingNativeConfiguration,
      );
    }
    if (!isDeliveryLiveMapEligible(
      snapshot,
      ownerAuthenticated: ownerAuthenticated,
      orderStatusCompatible: orderStatusCompatible,
    )) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.trackingUnavailable,
      );
    }

    late final DeliveryMapScene scene;
    try {
      scene = DeliveryMapScene.fromSnapshot(snapshot);
      await adapter.render(scene);
    } on FormatException {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.trackingUnavailable,
      );
    } on Object {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.providerException,
      );
    }
    if (_disposed || generation != _generation) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.disposed,
      );
    }
    return DeliveryMapReady(scene);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    try {
      await adapter.dispose();
    } on Object {
      // Il teardown del provider non deve esporre errori tecnici alla UI.
    }
  }
}

final class FakeDeliveryMapAdapter implements RecenterableDeliveryMapAdapter {
  FakeDeliveryMapAdapter({this.renderException});

  final Object? renderException;
  final List<DeliveryMapScene> scenes = [];
  var disposeCalls = 0;
  var recenterCalls = 0;
  bool? lastRecenterAnimated;

  @override
  Future<void> render(DeliveryMapScene scene) async {
    if (renderException case final error?) throw error;
    scenes.add(scene);
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  @override
  Future<void> recenter({required bool animated}) async {
    recenterCalls++;
    lastRecenterAnimated = animated;
  }
}
