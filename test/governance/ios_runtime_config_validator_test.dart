import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.path;

  test('complete production runtime config returns only its SHA-256', () async {
    final fixture = await _runtimeFixture();
    addTearDown(() => fixture.parent.deleteSync(recursive: true));

    final result = await Process.run('dart', [
      'run',
      '$repositoryRoot/tool/check_ios_runtime_config.dart',
      '--config',
      fixture.path,
    ]);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(
      (result.stdout as String).trim(),
      sha256.convert(fixture.readAsBytesSync()).toString(),
    );
    expect(result.stderr, isNot(contains('sb_publishable_')));
    expect(result.stderr, isNot(contains('production.example.invalid')));
  });

  test('incomplete config fails closed without echoing values', () async {
    final fixture = await _runtimeFixture();
    addTearDown(() => fixture.parent.deleteSync(recursive: true));
    final values =
        jsonDecode(fixture.readAsStringSync()) as Map<String, Object?>;
    values.remove('STOREFRONT_SHOP_SLUG');
    fixture.writeAsStringSync(jsonEncode(values));

    final result = await Process.run('dart', [
      'run',
      '$repositoryRoot/tool/check_ios_runtime_config.dart',
      '--config',
      fixture.path,
    ]);

    expect(result.exitCode, 1);
    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      contains('IOS_RUNTIME_CONFIG_BLOCKED: KEY_SET_INVALID'),
    );
    expect(result.stderr, isNot(contains('sb_publishable_')));
    expect(result.stderr, isNot(contains('production.example.invalid')));
  });

  test('capability enablement and symlink config are rejected', () async {
    final fixture = await _runtimeFixture();
    addTearDown(() => fixture.parent.deleteSync(recursive: true));
    final values =
        jsonDecode(fixture.readAsStringSync()) as Map<String, Object?>;
    values['DELIVERY_MAPS_ENABLED'] = 'true';
    fixture.writeAsStringSync(jsonEncode(values));

    final enabled = await Process.run('dart', [
      'run',
      '$repositoryRoot/tool/check_ios_runtime_config.dart',
      '--config',
      fixture.path,
    ]);
    expect(enabled.exitCode, 1);
    expect(enabled.stderr, contains('CAPABILITY_STATE_INVALID'));

    final link = Link('${fixture.parent.path}/config-link.json')
      ..createSync(fixture.path);
    final linked = await Process.run('dart', [
      'run',
      '$repositoryRoot/tool/check_ios_runtime_config.dart',
      '--config',
      link.path,
    ]);
    expect(linked.exitCode, 1);
    expect(linked.stderr, contains('FILE_NOT_REGULAR'));
  });
}

Future<File> _runtimeFixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'cmc-ios-runtime-config-',
  );
  return File('${directory.path}/production.json')..writeAsStringSync(
    jsonEncode({
      'APP_ENV': 'production',
      'SUPABASE_URL': 'https://production.example.invalid',
      'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_synthetic',
      'AUTH_REDIRECT_URI':
          'https://clientmerchandisecontrol.invalid/auth-callback/',
      'GOOGLE_AUTH_ENABLED': 'false',
      'STOREFRONT_SHOP_SLUG': 'storefront-synthetic',
      'DELIVERY_MAPS_ENABLED': 'false',
      'DELIVERY_MAPS_NATIVE_CONFIGURED': 'false',
    }),
  );
}
