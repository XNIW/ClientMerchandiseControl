import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _email = 'release-fixture@owned-project.iam.gserviceaccount.com';
const _project = 'owned-project';
const _fingerprint =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

void main() {
  late Directory fixtureDirectory;
  late File credential;

  setUp(() {
    fixtureDirectory = Directory.systemTemp.createTempSync(
      'cmc-play-credentials.',
    );
    credential = File('${fixtureDirectory.path}/service-account.json');
    credential.writeAsStringSync(jsonEncode(_validCredential()));
  });

  tearDown(() => fixtureDirectory.deleteSync(recursive: true));

  test('accetta input Play completi e coerenti', () {
    final result = _run(credential.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('ANDROID_PLAY_CREDENTIAL_INPUTS_VALID'));
  });

  test('rifiuta device path e JSON malformato', () {
    final device = _run('/dev/null');
    expect(device.exitCode, 1);
    expect(device.stderr, contains('PLAY_SERVICE_ACCOUNT_FILE_INVALID'));

    credential.writeAsStringSync('{malformed');
    final malformed = _run(credential.path);
    expect(malformed.exitCode, 1);
    expect(malformed.stderr, contains('INPUT_INVALID'));
  });

  test('rifiuta account, progetto e signer diversi', () {
    final wrongAccount = _validCredential()
      ..['client_email'] = 'other@owned-project.iam.gserviceaccount.com';
    credential.writeAsStringSync(jsonEncode(wrongAccount));
    expect(_run(credential.path).exitCode, 1);

    credential.writeAsStringSync(jsonEncode(_validCredential()));
    expect(
      _run(
        credential.path,
        artifactFingerprint:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      ).exitCode,
      1,
    );
  });
}

Map<String, Object> _validCredential() {
  final begin = <String>['-----BEGIN ', 'PRIVATE KEY-----'].join();
  final end = <String>['-----END ', 'PRIVATE KEY-----'].join();
  return <String, Object>{
    'type': 'service_account',
    'project_id': _project,
    'private_key_id': 'fixture_key_01',
    'private_key': '$begin\nsynthetic-test-material\n$end\n',
    'client_email': _email,
    'token_uri': 'https://oauth2.googleapis.com/token',
  };
}

ProcessResult _run(String path, {String artifactFingerprint = _fingerprint}) {
  return Process.runSync('dart', <String>[
    '--disable-dart-dev',
    'tool/check_android_play_credentials.dart',
    '--service-account',
    path,
    '--expected-email',
    _email,
    '--expected-project',
    _project,
    '--expected-fingerprint',
    _fingerprint,
    '--artifact-fingerprint',
    artifactFingerprint,
  ], workingDirectory: Directory.current.path);
}
