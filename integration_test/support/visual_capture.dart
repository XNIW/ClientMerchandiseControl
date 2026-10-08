import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'os_frame_sync.dart';

const visualCaptureEnabled = bool.fromEnvironment('CMC_VISUAL_CAPTURE');
var _captureIndex = 0;
var _androidSurfaceConverted = false;
const _osFrameCaptureEnabled = bool.fromEnvironment('CMC_OS_FRAME_CAPTURE');
final _osFrameSync = OsFrameSync();

/// Cattura il componente di produzione già montato dal test con fixture sintetiche.
/// Il file prova solo rendering/interazione deterministica, mai API o staging live.
Future<void> captureVisual(
  WidgetTester tester,
  String state, {
  bool settle = true,
}) async {
  if (!visualCaptureEnabled) return;
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid && !_androidSurfaceConverted) {
    await binding.convertFlutterSurfaceToImage();
    _androidSurfaceConverted = true;
    addTearDown(() => _androidSurfaceConverted = false);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final name = '${(++_captureIndex).toString().padLeft(2, '0')}-$state';
  // Attende l'acquisizione Flutter del frame prima della richiesta OS.
  // L'ACK resta necessario e il confronto dei pixel richiede evidence native.
  await binding.takeScreenshot(name);
  if (_osFrameCaptureEnabled && validOsFrameMarker(name)) {
    await _osFrameSync.capture(name);
  }
}
