import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const visualCaptureEnabled = bool.fromEnvironment('CMC_VISUAL_CAPTURE');
var _captureIndex = 0;
var _androidSurfaceConverted = false;

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
  await binding.takeScreenshot(
    '${(++_captureIndex).toString().padLeft(2, '0')}-$state',
  );
}
