import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../application/delivery_map_adapter.dart';

final class DeliveryMapMarkerLabels {
  const DeliveryMapMarkerLabels({
    required this.store,
    required this.destination,
    required this.courier,
  });

  final String store;
  final String destination;
  final String courier;
}

final class GoogleDeliveryMapAdapter implements RecenterableDeliveryMapAdapter {
  final ValueNotifier<DeliveryMapScene?> _scene = ValueNotifier(null);
  GoogleMapController? _controller;
  var _disposed = false;

  @override
  Future<void> render(DeliveryMapScene scene) async {
    if (_disposed) throw StateError('delivery_map_adapter_disposed');
    for (final coordinate in [scene.store, scene.destination, scene.courier]) {
      if (!coordinate.latitude.isFinite ||
          !coordinate.longitude.isFinite ||
          coordinate.latitude < -90 ||
          coordinate.latitude > 90 ||
          coordinate.longitude < -180 ||
          coordinate.longitude > 180) {
        throw const FormatException('delivery_map_invalid_coordinate');
      }
    }
    if (_sameScene(_scene.value, scene)) return;
    _scene.value = scene;
  }

  Widget buildSurface({
    required DeliveryMapMarkerLabels labels,
    required Brightness brightness,
  }) {
    if (_disposed || _scene.value == null) {
      throw StateError('delivery_map_scene_unavailable');
    }
    return _GoogleDeliveryMapSurface(
      adapter: this,
      labels: labels,
      brightness: brightness,
    );
  }

  @override
  Future<void> recenter({required bool animated}) async {
    if (_disposed) throw StateError('delivery_map_adapter_disposed');
    final controller = _controller;
    final scene = _scene.value;
    if (controller == null || scene == null) return;
    await _fitScene(controller, scene, animated: animated);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    _scene.dispose();
  }

  Future<void> _didCreateController(GoogleMapController controller) async {
    if (_disposed) {
      controller.dispose();
      return;
    }
    final previous = _controller;
    _controller = controller;
    previous?.dispose();
    final scene = _scene.value;
    if (scene != null) {
      await _fitScene(controller, scene, animated: false);
    }
  }

  static Future<void> _fitScene(
    GoogleMapController controller,
    DeliveryMapScene scene, {
    required bool animated,
  }) async {
    final points = [scene.store, scene.destination, scene.courier];
    final minLatitude = points.map((point) => point.latitude).reduce(math.min);
    final maxLatitude = points.map((point) => point.latitude).reduce(math.max);
    final minLongitude = points
        .map((point) => point.longitude)
        .reduce(math.min);
    final maxLongitude = points
        .map((point) => point.longitude)
        .reduce(math.max);
    final CameraUpdate update;
    if (minLatitude == maxLatitude && minLongitude == maxLongitude) {
      update = CameraUpdate.newLatLngZoom(
        LatLng(scene.courier.latitude, scene.courier.longitude),
        15,
      );
    } else {
      update = CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLatitude, minLongitude),
          northeast: LatLng(maxLatitude, maxLongitude),
        ),
        40,
      );
    }
    if (animated) {
      await controller.animateCamera(update);
    } else {
      await controller.moveCamera(update);
    }
  }
}

class _GoogleDeliveryMapSurface extends StatelessWidget {
  const _GoogleDeliveryMapSurface({
    required this.adapter,
    required this.labels,
    required this.brightness,
  });

  final GoogleDeliveryMapAdapter adapter;
  final DeliveryMapMarkerLabels labels;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DeliveryMapScene?>(
      valueListenable: adapter._scene,
      builder: (context, scene, _) {
        if (scene == null) return const SizedBox.shrink();
        return GoogleMap(
          key: const ValueKey('delivery-google-map-surface'),
          initialCameraPosition: CameraPosition(
            target: LatLng(scene.courier.latitude, scene.courier.longitude),
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('store'),
              position: LatLng(scene.store.latitude, scene.store.longitude),
              infoWindow: InfoWindow(title: labels.store),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(
                scene.destination.latitude,
                scene.destination.longitude,
              ),
              infoWindow: InfoWindow(title: labels.destination),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('courier'),
              position: LatLng(scene.courier.latitude, scene.courier.longitude),
              infoWindow: InfoWindow(title: labels.courier),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          },
          mapType: MapType.normal,
          onMapCreated: adapter._didCreateController,
          compassEnabled: false,
          indoorViewEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          trafficEnabled: false,
          zoomControlsEnabled: false,
          style: brightness == Brightness.dark ? _darkMapStyle : null,
        );
      },
    );
  }
}

bool _sameScene(DeliveryMapScene? left, DeliveryMapScene right) {
  if (left == null) return false;
  return left.snapshotVersion == right.snapshotVersion &&
      left.store.latitude == right.store.latitude &&
      left.store.longitude == right.store.longitude &&
      left.destination.latitude == right.destination.latitude &&
      left.destination.longitude == right.destination.longitude &&
      left.courier.latitude == right.courier.latitude &&
      left.courier.longitude == right.courier.longitude;
}

const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1c1b1f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#cac4d0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1c1b1f"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#49454f"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#263238"}]}
]
''';
