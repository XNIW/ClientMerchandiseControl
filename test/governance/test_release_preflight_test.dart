import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'guard APK reale richiede callback XML esatto oltre al binding AAB',
    () async {
      final script = File(
        'scripts/check-android-release.sh',
      ).readAsStringSync();
      final call = script.indexOf('check-android-test-callback.py');
      expect(call, greaterThan(0));
      final start = script.lastIndexOf('if [[', call);
      final end = script.indexOf('\nfi', call) + 3;
      final guard = script.substring(start, end);
      final canonical = _apkManifest();
      final variants = <String, String>{
        'canonico': canonical,
        'host diverso': _apkManifest(host: 'other.client.example.com'),
        'HTTPS assente': _apkManifest(includeCallback: false),
        'path prefix': canonical.replaceFirst(
          'android:path=',
          'android:pathPrefix=',
        ),
        'autoVerify false': canonical.replaceFirst(
          'autoVerify="true"',
          'autoVerify="false"',
        ),
        'host duplicato': canonical.replaceFirst(
          'android:path="/auth-callback/"',
          'android:host="auth.client.example.com"',
        ),
        'filtro aggiuntivo': canonical.replaceFirst(
          '</activity>',
          '<intent-filter><data android:scheme="https" android:host="other.client.example.com"/></intent-filter></activity>',
        ),
        'DOCTYPE': '<!DOCTYPE manifest []>$canonical',
        'oltre limite': ' ' * (1024 * 1024 + 1),
      };
      for (final entry in variants.entries) {
        final process = await Process.start(
          'bash',
          [
            '-c',
            r'''
set -euo pipefail
cmc_android_release_test=true
cmc_android_release_callback_host=auth.client.example.com
cmc_android_release_script_dir="$CMC_TEST_SCRIPTS_DIR"
cmc_android_release_compiled_manifest="$(cat)"
cmc_android_release_fail() { printf '%s\n' "$1" >&2; exit 1; }
''' +
                guard,
          ],
          environment: {
            'CMC_TEST_SCRIPTS_DIR': '${Directory.current.path}/scripts',
          },
        );
        final output = process.stdout.transform(utf8.decoder).join();
        final errors = process.stderr.transform(utf8.decoder).join();
        process.stdin.write(entry.value);
        await process.stdin.close();
        final code = await process.exitCode;
        final stdout = await output;
        final stderr = await errors;
        expect(
          code,
          entry.key == 'canonico' ? 0 : 1,
          reason: '${entry.key}: $stdout $stderr',
        );
        if (entry.key != 'canonico') {
          expect(stderr, contains('TEST_APK_CALLBACK_BINDING_INVALID'));
        }
      }
    },
  );

  for (final script in [
    'test-android-runtime-binding.py',
    'test-ios-test-callback.py',
  ]) {
    test('Quality esegue regressioni host $script', () {
      final result = Process.runSync(
        'python3',
        ['scripts/$script'],
        environment: {'PYTHONDONTWRITEBYTECODE': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });
  }

  test('checker byte iOS rifiuta marker opposto, duplicato o hash diverso', () {
    final script = File('scripts/check-ios-release.sh').readAsStringSync();
    final program = RegExp(
      r"perl -e '([^']*my \(\$path, \$expected\)[^']*)'",
    ).firstMatch(script)?.group(1);
    expect(program, isNotNull);
    final directory = Directory.systemTemp.createTempSync('cmc-ios-marker-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final executable = File('${directory.path}/synthetic-App');
    final hash = 'a' * 64;
    for (final prefix in [
      'CMC_RELEASE_CONFIG_ATTESTATION_V1:',
      'CMC_TEST_CONFIG_ATTESTATION_V1:',
    ]) {
      final marker = '$prefix$hash';
      final opposite = prefix.contains('TEST')
          ? 'CMC_RELEASE_CONFIG_ATTESTATION_V1:'
          : 'CMC_TEST_CONFIG_ATTESTATION_V1:';
      for (final payload in [
        marker,
        '',
        '$prefix${'b' * 64}',
        '$marker$marker',
        '$marker$opposite$hash',
      ]) {
        executable.writeAsStringSync(payload);
        final result = Process.runSync('perl', [
          '-e',
          program!,
          executable.path,
          marker,
        ]);
        expect(result.exitCode, payload == marker ? 0 : 1);
      }
    }
  });

  for (final platform in ['android', 'ios']) {
    test(
      'preflight $platform TEST non ammette source-only o upload implicito',
      () {
        for (final arguments in [
          ['--test'],
          ['--test', '--source-only'],
          ['--test', '--require-upload-ready', '--source-only'],
        ]) {
          final result = Process.runSync('bash', [
            'scripts/check-$platform-release.sh',
            ...arguments,
          ]);
          expect(result.exitCode, 1);
          expect(result.stderr, contains('TEST_REQUIRES_UPLOAD_PREFLIGHT'));
          expect(result.stdout, isEmpty);
        }
      },
    );
  }

  test('binding TEST deriva SHA e host dalla stessa lettura validata', () {
    final directory = Directory.systemTemp.createTempSync('cmc-test-release-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.resolveSymbolicLinksSync()}/test.json')
      ..writeAsStringSync(jsonEncode(_values));
    final result = Process.runSync('dart', [
      '--disable-dart-dev',
      'tool/check_ios_runtime_config.dart',
      '--config',
      file.path,
      '--test',
      '--binding',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      (result.stdout as String).trim(),
      matches(r'^[0-9a-f]{64} auth\.client\.example\.com$'),
    );
    expect(result.stderr, isEmpty);
  });

  test(
    'TEST staging esplicito attesta config completa senza esporre valori',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'cmc-test-release-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.resolveSymbolicLinksSync()}/test.json')
        ..writeAsStringSync(jsonEncode(_values));

      final result = Process.runSync('dart', [
        '--disable-dart-dev',
        'tool/check_ios_runtime_config.dart',
        '--config',
        file.path,
        '--test',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect((result.stdout as String).trim(), matches(r'^[0-9a-f]{64}$'));
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        isNot(contains(_values['SUPABASE_PUBLISHABLE_KEY'])),
      );
    },
  );

  test('default production continua a rifiutare staging', () {
    final directory = Directory.systemTemp.createTempSync('cmc-test-release-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.resolveSymbolicLinksSync()}/test.json')
      ..writeAsStringSync(
        jsonEncode({..._values}..remove('AUTH_CALLBACK_VERIFIED_HOST')),
      );
    final result = Process.runSync('dart', [
      '--disable-dart-dev',
      'tool/check_ios_runtime_config.dart',
      '--config',
      file.path,
    ]);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('ENVIRONMENT_INVALID'));
    expect(result.stdout, isEmpty);
  });

  for (final entry in <String, Map<String, String>>{
    'production cross-environment': {'APP_ENV': 'production'},
    'progetto diverso': {
      'SUPABASE_URL': 'https://abcdefghijklmnopqrst.supabase.co',
    },
    'callback custom scheme': {
      'AUTH_REDIRECT_URI': 'com.xniw.clientmerchandisecontrol://auth-callback/',
    },
    'callback host diverso': {
      'AUTH_REDIRECT_URI': 'https://other.client.example.com/auth-callback/',
    },
    'callback query': {
      'AUTH_REDIRECT_URI': '${_values['AUTH_REDIRECT_URI']}?code=x',
    },
    'callback sentinel': {
      'AUTH_CALLBACK_VERIFIED_HOST': 'clientmerchandisecontrol.invalid',
      'AUTH_REDIRECT_URI':
          'https://clientmerchandisecontrol.invalid/auth-callback/',
    },
    'Google OFF': {'GOOGLE_AUTH_ENABLED': 'false'},
    'mappe ON': {'DELIVERY_MAPS_ENABLED': 'true'},
    'chiave secret': {'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_synthetic'},
    'service role JWT': {
      'SUPABASE_PUBLISHABLE_KEY': _jwt('service_role', 'jpgoimipbothfgkokyvm'),
    },
    'anon JWT cross-project': {
      'SUPABASE_PUBLISHABLE_KEY': _jwt('anon', 'abcdefghijklmnopqrst'),
    },
  }.entries) {
    test('TEST rifiuta ${entry.key} senza esporre credenziali', () {
      final directory = Directory.systemTemp.createTempSync(
        'cmc-test-release-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.resolveSymbolicLinksSync()}/test.json')
        ..writeAsStringSync(jsonEncode({..._values, ...entry.value}));
      final result = Process.runSync('dart', [
        '--disable-dart-dev',
        'tool/check_ios_runtime_config.dart',
        '--config',
        file.path,
        '--test',
      ]);
      expect(result.exitCode, 1);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isNot(contains('USAGE')));
      expect(result.stderr, isNot(contains('synthetic')));
      expect(result.stderr, isNot(contains('eyJ')));
    });
  }
}

String _jwt(String role, String projectRef) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'role': role, 'ref': projectRef})}.c3ludGhldGlj';
}

const _values = <String, String>{
  'APP_ENV': 'staging',
  'SUPABASE_URL': 'https://jpgoimipbothfgkokyvm.supabase.co',
  'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_synthetic',
  'AUTH_REDIRECT_URI': 'https://auth.client.example.com/auth-callback/',
  'GOOGLE_AUTH_ENABLED': 'true',
  'STOREFRONT_SHOP_SLUG': 'storefront-synthetic',
  'DELIVERY_MAPS_ENABLED': 'false',
  'DELIVERY_MAPS_NATIVE_CONFIGURED': 'false',
  'AUTH_CALLBACK_VERIFIED_HOST': 'auth.client.example.com',
};

String _apkManifest({
  String host = 'auth.client.example.com',
  bool includeCallback = true,
}) =>
    '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.xniw.clientmerchandisecontrol">
<application><activity android:name="com.xniw.clientmerchandisecontrol.MainActivity" android:exported="true">
${includeCallback ? '''<intent-filter android:autoVerify="true">
<action android:name="android.intent.action.VIEW"/>
<category android:name="android.intent.category.DEFAULT"/>
<category android:name="android.intent.category.BROWSABLE"/>
<data android:scheme="https" android:host="$host" android:path="/auth-callback/"/>
</intent-filter>''' : ''}
</activity></application></manifest>
''';
