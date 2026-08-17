import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'decode target-sized 480px rispetta budget e non conserva full-size',
    (tester) async {
      final samples = await tester.runAsync(() async {
        final encoded = await File(
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-1024x1024@1x.png',
        ).readAsBytes();

        Future<int> decodeOnce() async {
          final stopwatch = Stopwatch()..start();
          final codec = await ui.instantiateImageCodec(
            encoded,
            targetWidth: 480,
            targetHeight: 480,
            allowUpscaling: false,
          );
          final frame = await codec.getNextFrame();
          stopwatch.stop();
          if (frame.image.width != 480 || frame.image.height != 480) {
            throw StateError('image_decode_target_not_respected');
          }
          frame.image.dispose();
          codec.dispose();
          return stopwatch.elapsedMicroseconds;
        }

        for (var warmup = 0; warmup < 5; warmup++) {
          await decodeOnce();
        }
        final measured = <int>[];
        for (var sample = 0; sample < 30; sample++) {
          measured.add(await decodeOnce());
        }
        return measured;
      });
      expect(samples, isNotNull);
      final measured = samples!;
      final p50 = _percentileMicros(measured, 0.50);
      final p95 = _percentileMicros(measured, 0.95);
      final p99 = _percentileMicros(measured, 0.99);
      debugPrint(
        'IMAGE_DECODE_PERF environment=flutter_test_host source_px=1024 '
        'target_px=480 warmup=5 samples=30 '
        'p50_us=$p50 p95_us=$p95 p99_us=$p99',
      );
      expect(p95, lessThan(32000));
    },
    tags: const ['performance'],
  );
}

int _percentileMicros(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}
