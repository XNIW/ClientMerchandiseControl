import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client_merchandise_control/core/config/release_config_attestation.dart';
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
      ReleaseConfigAttestation.fromBytes(fixture.readAsBytesSync()).sha256,
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

  test('JWT legacy header non JSON e URL non canonici sono respinti', () async {
    final fixture = await _runtimeFixture();
    addTearDown(() => fixture.parent.deleteSync(recursive: true));
    final values =
        jsonDecode(fixture.readAsStringSync()) as Map<String, Object?>;
    values['SUPABASE_PUBLISHABLE_KEY'] = _jwt(
      header: utf8.encode('not-json'),
      payload: utf8.encode('{"role":"anon"}'),
    );
    fixture.writeAsStringSync(jsonEncode(values));

    final badHeader = await _runValidator(repositoryRoot, fixture.path);
    expect(badHeader.exitCode, 1);
    expect(badHeader.stderr, contains('PUBLISHABLE_KEY_INVALID'));

    values['SUPABASE_PUBLISHABLE_KEY'] = 'sb_publishable_synthetic';
    values['AUTH_REDIRECT_URI'] =
        ' https://clientmerchandisecontrol.invalid/auth-callback/';
    fixture.writeAsStringSync(jsonEncode(values));
    final whitespace = await _runValidator(repositoryRoot, fixture.path);
    expect(whitespace.exitCode, 1);
    expect(whitespace.stderr, contains('VALUE_NOT_CANONICAL'));

    values['AUTH_REDIRECT_URI'] =
        'https://clientmerchandisecontrol.invalid:443/auth-callback/';
    fixture.writeAsStringSync(jsonEncode(values));
    final port = await _runValidator(repositoryRoot, fixture.path);
    expect(port.exitCode, 1);
    expect(port.stderr, contains('AUTH_REDIRECT_INVALID'));
  });

  test('duplicate keys e path ancestor symlink falliscono chiusi', () async {
    final fixture = await _runtimeFixture();
    addTearDown(() => fixture.parent.deleteSync(recursive: true));
    final original = fixture.readAsStringSync();
    fixture.writeAsStringSync(
      original.replaceFirst('{', '{"APP_ENV":"production",'),
    );
    final duplicate = await _runValidator(repositoryRoot, fixture.path);
    expect(duplicate.exitCode, 1);
    expect(duplicate.stderr, contains('DUPLICATE_KEY'));

    final linkedDirectory = Link('${fixture.parent.path}-link')
      ..createSync(fixture.parent.path);
    addTearDown(() {
      if (linkedDirectory.existsSync()) {
        linkedDirectory.deleteSync();
      }
    });
    fixture.writeAsStringSync(original);
    final ancestorLink = await _runValidator(
      repositoryRoot,
      '${linkedDirectory.path}/${fixture.uri.pathSegments.last}',
    );
    expect(ancestorLink.exitCode, 1);
    expect(ancestorLink.stderr, contains('FILE_PATH_NOT_CANONICAL'));
  });

  test(
    'runtime config oltre il limite viene respinta prima del parsing',
    () async {
      final fixture = await _runtimeFixture();
      addTearDown(() => fixture.parent.deleteSync(recursive: true));
      fixture.writeAsStringSync(
        '${fixture.readAsStringSync()}${List.filled(65536, ' ').join()}',
      );

      final result = await _runValidator(repositoryRoot, fixture.path);

      expect(result.exitCode, 1);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('FILE_SIZE_INVALID'));
    },
  );

  test(
    'runtime config FIFO viene respinta senza bloccare la lettura',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cmc-ios-runtime-fifo-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final fifoPath = '${directory.path}/production.json';
      final created = await Process.run('mkfifo', [fifoPath]);
      expect(created.exitCode, 0, reason: created.stderr as String);

      final result = await _runValidatorBounded(repositoryRoot, fifoPath);

      expect(result.exitCode, 1);
      expect(result.stdout, isEmpty);
      expect(
        result.stderr,
        contains('IOS_RUNTIME_CONFIG_BLOCKED: FILE_NOT_REGULAR'),
      );
    },
  );
}

Future<ProcessResult> _runValidator(String repositoryRoot, String path) {
  return Process.run('dart', [
    'run',
    '$repositoryRoot/tool/check_ios_runtime_config.dart',
    '--config',
    path,
  ]);
}

Future<ProcessResult> _runValidatorBounded(
  String repositoryRoot,
  String path,
) async {
  final process = await Process.start('dart', [
    'run',
    '$repositoryRoot/tool/check_ios_runtime_config.dart',
    '--config',
    path,
  ]);
  final stdout = process.stdout.transform(utf8.decoder).join();
  final stderr = process.stderr.transform(utf8.decoder).join();
  try {
    final exitCode = await process.exitCode.timeout(const Duration(seconds: 5));
    return ProcessResult(process.pid, exitCode, await stdout, await stderr);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    throw TestFailure('runtime config validator blocked on a FIFO');
  }
}

String _jwt({required List<int> header, required List<int> payload}) {
  final signature = base64Url
      .encode(List<int>.filled(32, 7))
      .replaceAll('=', '');
  return '${base64Url.encode(header).replaceAll('=', '')}.'
      '${base64Url.encode(payload).replaceAll('=', '')}.$signature';
}

Future<File> _runtimeFixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'cmc-ios-runtime-config-',
  );
  final file = File('${directory.path}/production.json')
    ..writeAsStringSync(
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
  return File(file.resolveSymbolicLinksSync());
}
