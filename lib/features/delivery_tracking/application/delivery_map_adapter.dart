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

final class FailClosedDeliveryMapPresenter {
  FailClosedDeliveryMapPresenter({
    required this.configuration,
    required this.adapter,
  });

  final DeliveryMapConfiguration configuration;
  final DeliveryMapAdapter adapter;
  var _disposed = false;

  Future<DeliveryMapPresentation> present(
    DeliveryTrackingSnapshot snapshot,
  ) async {
    if (_disposed) {
      return const DeliveryMapUnavailable(
        DeliveryMapUnavailableReason.disposed,
      );
    }
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
    return DeliveryMapReady(scene);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await adapter.dispose();
    } on Object {
      // Il teardown del provider non deve esporre errori tecnici alla UI.
    }
  }
}

final class FakeDeliveryMapAdapter implements DeliveryMapAdapter {
  FakeDeliveryMapAdapter({this.renderException});

  final Object? renderException;
  final List<DeliveryMapScene> scenes = [];
  var disposeCalls = 0;

  @override
  Future<void> render(DeliveryMapScene scene) async {
    if (renderException case final error?) throw error;
    scenes.add(scene);
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}
