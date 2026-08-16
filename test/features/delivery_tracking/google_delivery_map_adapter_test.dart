import 'dart:async';

import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/google_delivery_map_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const scene = DeliveryMapScene(
    store: DeliveryCoordinate(latitude: -33.45, longitude: -70.67),
    destination: DeliveryCoordinate(latitude: -33.44, longitude: -70.65),
    courier: DeliveryCoordinate(latitude: -33.445, longitude: -70.66),
    snapshotVersion: 8,
  );

  test(
    'camera failure emette failed, dispone e non lascia errori async',
    () async {
      final adapter = GoogleDeliveryMapAdapter();
      final controller = _CameraController(
        moveError: StateError('synthetic_camera_failure'),
      );
      await adapter.render(scene);
      final event = adapter.runtimeStates.first;

      await adapter.attachController(controller);

      expect(await event, DeliveryMapRuntimeState.failed);
      expect(controller.disposeCalls, 1);
      await adapter.dispose();
      expect(controller.disposeCalls, 1);
    },
  );

  test('camera iniziale completata emette ready', () async {
    final adapter = GoogleDeliveryMapAdapter();
    final controller = _CameraController();
    await adapter.render(scene);
    final event = adapter.runtimeStates.first;

    await adapter.attachController(controller);

    expect(await event, DeliveryMapRuntimeState.ready);
    expect(controller.moveCalls, 1);
    await adapter.dispose();
    expect(controller.disposeCalls, 1);
  });

  test(
    'dispose concorrente alla camera non emette e dispone una volta',
    () async {
      final moveCompleter = Completer<void>();
      final moveStarted = Completer<void>();
      final adapter = GoogleDeliveryMapAdapter();
      final controller = _CameraController(
        moveCompleter: moveCompleter,
        moveStarted: moveStarted,
      );
      final events = <DeliveryMapRuntimeState>[];
      final subscription = adapter.runtimeStates.listen(events.add);
      await adapter.render(scene);

      final attach = adapter.attachController(controller);
      await moveStarted.future;
      await adapter.dispose();
      moveCompleter.complete();
      await attach;

      expect(events, isEmpty);
      expect(controller.disposeCalls, 1);
      await subscription.cancel();
    },
  );
}

final class _CameraController implements DeliveryMapCameraController {
  _CameraController({this.moveError, this.moveCompleter, this.moveStarted});

  final Object? moveError;
  final Completer<void>? moveCompleter;
  final Completer<void>? moveStarted;
  var moveCalls = 0;
  var animateCalls = 0;
  var disposeCalls = 0;

  @override
  Future<void> animateCamera(CameraUpdate update) async {
    animateCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  @override
  Future<void> moveCamera(CameraUpdate update) async {
    moveCalls++;
    if (moveStarted != null && !moveStarted!.isCompleted) {
      moveStarted!.complete();
    }
    if (moveError case final error?) throw error;
    await moveCompleter?.future;
  }
}
