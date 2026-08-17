import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_release_metadata.dart';

void main() {
  test('canonical release metadata validates', () async {
    expect(await validateRepository(Directory.current), isEmpty);
  });

  test(
    'configuration validator rejects incomplete and secret-like fixtures',
    () {
      final source =
          jsonDecode(
                File(
                  'config/release_configuration_matrix.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final fixture = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
      final first =
          (fixture['capabilities'] as List).first as Map<String, dynamic>;
      (first['production'] as Map<String, dynamic>).remove('validation');
      (first['staging'] as Map<String, dynamic>)['credential'] =
          'AIza012345678901234567890123456789';

      final errors = <String>[];
      validateConfigurationMatrix(fixture, errors);

      expect(errors, contains(contains('invalid validation')));
      expect(errors, contains(contains('unknown fields')));
      expect(errors, contains(contains('credential-like value')));
    },
  );

  test('PNG inspection detects an alpha color type', () {
    final opaque = File('assets/release/app-icon-master.png').readAsBytesSync();
    expect(inspectPng(opaque).hasAlpha, isFalse);

    final alphaFixture = List<int>.from(opaque);
    alphaFixture[25] = 6;
    expect(inspectPng(Uint8List.fromList(alphaFixture)).hasAlpha, isTrue);
  });
}
