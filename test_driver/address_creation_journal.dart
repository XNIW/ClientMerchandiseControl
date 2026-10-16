import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';

Future<void> main() async {
  final output = Platform.environment['CMC_ADDRESS_JOURNAL_RECEIPT'];
  if (output == null) throw StateError('Ricevuta journal non configurata.');
  final driver = await FlutterDriver.connect(
    logCommunicationToFile: false,
  ).timeout(const Duration(seconds: 30));
  try {
    final response = Response.fromJson(
      await driver.requestData(null, timeout: const Duration(seconds: 60)),
    );
    if (!response.allTestsPassed || response.data == null) {
      // Le failure non includono payload o URI della VM nel log persistente.
      throw StateError('Fixture journal fallita; nessun PASS nativo.');
    }
    await File(output).writeAsString(jsonEncode(response.data));
  } finally {
    await driver.close().timeout(const Duration(seconds: 5));
  }
}
