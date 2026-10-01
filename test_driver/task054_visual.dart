import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['CMC_VISUAL_OUTPUT_DIR'] ?? 'build/task054/visual',
  );
  await output.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(name) || bytes.isEmpty) {
        return false;
      }
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true; // Trasporto della cattura, non approvazione del giudizio visivo.
    },
  );
}
