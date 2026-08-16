import 'dart:async';

import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/google_delivery_map_adapter.dart';
import 'package:flutter/material.dart';
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

  test('failure dispose precedente emette failed e dispone il nuovo', () async {
    final adapter = GoogleDeliveryMapAdapter();
    final previous = _CameraController();
    final replacement = _CameraController();
    final events = <DeliveryMapRuntimeState>[];
    final subscription = adapter.runtimeStates.listen(events.add);
    await adapter.render(scene);
    await adapter.attachController(previous);
    previous.disposeError = StateError('synthetic_previous_dispose_failure');

    await adapter.attachController(replacement);
    await Future<void>.delayed(Duration.zero);

    expect(events, [
      DeliveryMapRuntimeState.ready,
      DeliveryMapRuntimeState.failed,
    ]);
    expect(previous.disposeCalls, 1);
    expect(replacement.disposeCalls, 1);
    await adapter.dispose();
    await subscription.cancel();
  });

  test('callback tardivo con dispose fallibile non propaga errori', () async {
    final adapter = GoogleDeliveryMapAdapter();
    final lateController = _CameraController(
      disposeError: StateError('synthetic_late_dispose_failure'),
    );
    await adapter.dispose();

    await adapter.attachController(lateController);

    expect(lateController.disposeCalls, 1);
  });

  test(
    'failure durante dispose chiude lo stream e resta idempotente',
    () async {
      final adapter = GoogleDeliveryMapAdapter();
      final controller = _CameraController(
        disposeError: StateError('synthetic_dispose_failure'),
      );
      await adapter.render(scene);
      final done = adapter.runtimeStates.drain<void>();
      await adapter.attachController(controller);

      await adapter.dispose();
      await done;
      await adapter.dispose();

      expect(controller.disposeCalls, 1);
      expect(
        () => adapter.buildSurface(
          labels: const DeliveryMapMarkerLabels(
            store: 'Store',
            destination: 'Destination',
            courier: 'Courier',
          ),
          brightness: Brightness.light,
        ),
        throwsStateError,
      );
    },
  );
}

final class _CameraController implements DeliveryMapCameraController {
  _CameraController({
    this.moveError,
    this.moveCompleter,
    this.moveStarted,
    this.disposeError,
  });

  final Object? moveError;
  final Completer<void>? moveCompleter;
  final Completer<void>? moveStarted;
  Object? disposeError;
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
    if (disposeError case final error?) throw error;
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
