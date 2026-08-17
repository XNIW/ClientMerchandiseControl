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
      final googleKeyFixture = <String>[
        'AI',
        'za',
        '012345678901234567890123456789',
      ].join();
      (first['staging'] as Map<String, dynamic>)['credential'] =
          googleKeyFixture;

      final errors = <String>[];
      validateConfigurationMatrix(fixture, errors);

      expect(errors, contains(contains('invalid validation')));
      expect(errors, contains(contains('unknown fields')));
      expect(errors, contains(contains('credential-like value')));
    },
  );

  test(
    'privacy manifest validator rejects empty and incomplete declarations',
    () {
      final errors = <String>[];
      validatePrivacyManifest('''
<key>NSPrivacyCollectedDataTypes</key>
<array/>
<key>NSPrivacyTracking</key>
<false/>
''', errors);
      expect(errors, contains(contains('collected-data array is missing')));

      errors.clear();
      validatePrivacyManifest('''
<key>NSPrivacyCollectedDataTypes</key>
<array>
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeName</string>
    <key>NSPrivacyCollectedDataTypeLinked</key><true/>
    <key>NSPrivacyCollectedDataTypeTracking</key><false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
  </dict>
</array>
<key>NSPrivacyTracking</key>
<false/>
''', errors);
      expect(errors, contains(contains('collected-data types are incomplete')));
    },
  );

  test('privacy manifest includes the in-app form of payment', () {
    final manifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();
    expect(
      expectedIosCollectedDataTypes,
      contains('NSPrivacyCollectedDataTypePaymentInfo'),
    );
    expect(
      manifest,
      contains('<string>NSPrivacyCollectedDataTypePaymentInfo</string>'),
    );

    final errors = <String>[];
    validatePrivacyManifest(
      manifest.replaceFirst(
        'NSPrivacyCollectedDataTypePaymentInfo',
        'NSPrivacyCollectedDataTypePurchaseHistory',
      ),
      errors,
    );
    expect(errors, contains(contains('invalid or duplicate data type')));
    expect(errors, contains(contains('collected-data types are incomplete')));
  });

  test('PNG inspection detects an alpha color type', () {
    final opaque = File('assets/release/app-icon-master.png').readAsBytesSync();
    expect(inspectPng(opaque).hasAlpha, isFalse);

    final alphaFixture = List<int>.from(opaque);
    alphaFixture[25] = 6;
    expect(inspectPng(Uint8List.fromList(alphaFixture)).hasAlpha, isTrue);
  });
}
