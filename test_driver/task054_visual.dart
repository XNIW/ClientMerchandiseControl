import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

import '../integration_test/support/os_frame_sync.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['CMC_VISUAL_OUTPUT_DIR'] ?? 'build/task054/visual',
  );
  await output.create(recursive: true);
  final platform = Platform.environment['CMC_OS_FRAME_PLATFORM'];
  final device = Platform.environment['CMC_OS_FRAME_DEVICE'];
  if ((platform == null) != (device == null)) {
    throw StateError('BLOCKED: configurazione OS frame incompleta');
  }
  final driver = await FlutterDriver.connect(
    logCommunicationToFile: false,
  ).timeout(const Duration(seconds: 20));
  StreamSubscription<dynamic>? osFrames;
  final osJobs = <Future<void>>{};

  Future<void> settleOsJobs() async {
    await osFrames?.cancel();
    osFrames = null;
    await Future.wait(osJobs.toList());
  }

  try {
    if (platform != null || device != null) {
      if (platform == null || device == null) {
        throw StateError('BLOCKED: configurazione OS frame incompleta');
      }
      final service = driver.serviceClient;
      final isolate = driver.appIsolate.id;
      if (isolate == null) {
        throw StateError('FAIL: isolate app non disponibile');
      }
      await service
          .streamListen('Extension')
          .timeout(const Duration(seconds: 5));
      final host = OsFrameHost(
        claim: (parameters) async {
          final response = await service
              .callServiceExtension(
                osFrameClaimExtension,
                isolateId: isolate,
                args: parameters,
              )
              .timeout(const Duration(seconds: 5));
          return response.json?['accepted'] == true;
        },
        capture: (name) async {
          Process? capture;
          try {
            capture = await Process.start('python3', <String>[
              'scripts/capture-task054-os-frame.py',
              '--name',
              name,
              '--platform',
              platform,
              '--device',
              device,
            ]);
            capture.stdout.listen(stdout.add);
            capture.stderr.listen(stderr.add);
            return await capture.exitCode.timeout(
                  const Duration(seconds: 25),
                ) ==
                0;
          } on Object catch (error) {
            capture?.kill(ProcessSignal.sigterm);
            if (capture != null) {
              try {
                await capture.exitCode.timeout(const Duration(seconds: 15));
              } on TimeoutException {
                capture.kill(ProcessSignal.sigkill);
                try {
                  await capture.exitCode.timeout(const Duration(seconds: 5));
                } on Object {
                  stderr.writeln('FAIL: OS frame transport cleanup');
                }
              } on Object {
                stderr.writeln('FAIL: OS frame transport cleanup');
              }
            }
            stderr.writeln('FAIL: OS frame transport ${error.runtimeType}');
            return false;
          }
        },
        acknowledge: (parameters) async {
          await service
              .callServiceExtension(
                osFrameAckExtension,
                isolateId: isolate,
                args: parameters,
              )
              .timeout(const Duration(seconds: 5));
        },
      );
      Future<void> handleRequest(Map<dynamic, dynamic>? request) async {
        try {
          await host.handle(request);
        } on Object catch (error) {
          stderr.writeln('FAIL: OS frame acknowledgement ${error.runtimeType}');
        }
      }

      osFrames = service.onExtensionEvent.listen((event) {
        if (event.extensionKind != osFrameRequestEvent ||
            event.isolate?.id != isolate) {
          return;
        }
        final job = handleRequest(event.extensionData?.data);
        osJobs.add(job);
        unawaited(job.whenComplete(() => osJobs.remove(job)));
      });
      // Una prima capture può precedere FlutterDriver.connect: postEvent non è
      // buffered. Il listener precede lo snapshot; OsFrameHost deduplica l'incrocio.
      final app = await service
          .getIsolate(isolate)
          .timeout(const Duration(seconds: 5));
      if (app.extensionRPCs?.contains(osFramePendingExtension) == true) {
        final pending = await service
            .callServiceExtension(osFramePendingExtension, isolateId: isolate)
            .timeout(const Duration(seconds: 5));
        final request = pending.json?['pending'];
        if (request is Map) await handleRequest(request);
      }
    }
    await integrationDriver(
      driver: driver,
      writeResponseOnFailure: true,
      // integrationDriver chiude con exit(): il drain deve precedere quel punto.
      responseDataCallback: (data) async {
        await settleOsJobs();
        await writeResponseData(data);
      },
      onScreenshot: (name, bytes, [args]) async {
        if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(name) || bytes.isEmpty) {
          return false;
        }
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        return true; // Trasporto della cattura, non approvazione del giudizio visivo.
      },
    );
  } finally {
    await settleOsJobs();
    try {
      await driver.close().timeout(const Duration(seconds: 5));
    } on Object catch (error) {
      stderr.writeln('FAIL: driver cleanup ${error.runtimeType}');
    }
  }
}
