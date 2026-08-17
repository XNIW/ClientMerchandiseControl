import 'dart:convert';
import 'dart:io';

const _maximumCredentialBytes = 64 * 1024;
const _fingerprintPattern = r'^[0-9a-f]{64}$';
const _emailPattern =
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.iam\.gserviceaccount\.com$';
const _projectPattern = r'^[a-z][a-z0-9-]{4,62}$';

void main(List<String> arguments) {
  try {
    final values = _parseArguments(arguments);
    final expectedFingerprint = _normalizeFingerprint(
      values['expected-fingerprint'],
    );
    final artifactFingerprint = _normalizeFingerprint(
      values['artifact-fingerprint'],
    );
    if (expectedFingerprint != artifactFingerprint) {
      _fail('APPROVED_SIGNING_FINGERPRINT_MISMATCH');
    }

    final expectedEmail = values['expected-email'];
    final expectedProject = values['expected-project'];
    if (expectedEmail == null ||
        !RegExp(_emailPattern).hasMatch(expectedEmail)) {
      _fail('PLAY_SERVICE_ACCOUNT_IDENTITY_INVALID');
    }
    if (expectedProject == null ||
        !RegExp(_projectPattern).hasMatch(expectedProject)) {
      _fail('PLAY_SERVICE_ACCOUNT_PROJECT_INVALID');
    }

    final path = values['service-account'];
    if (path == null ||
        FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
      _fail('PLAY_SERVICE_ACCOUNT_FILE_INVALID');
    }
    final file = File(path);
    final length = file.lengthSync();
    if (length <= 0 || length > _maximumCredentialBytes) {
      _fail('PLAY_SERVICE_ACCOUNT_SIZE_INVALID');
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      _fail('PLAY_SERVICE_ACCOUNT_JSON_INVALID');
    }
    final privateKeyBegin = <String>['-----BEGIN ', 'PRIVATE KEY-----'].join();
    final privateKeyEnd = <String>['-----END ', 'PRIVATE KEY-----'].join();
    final privateKey = decoded['private_key'];
    if (decoded['type'] != 'service_account' ||
        decoded['client_email'] != expectedEmail ||
        decoded['project_id'] != expectedProject ||
        decoded['token_uri'] != 'https://oauth2.googleapis.com/token' ||
        decoded['private_key_id'] is! String ||
        !RegExp(
          r'^[A-Za-z0-9_-]{8,128}$',
        ).hasMatch(decoded['private_key_id'] as String) ||
        privateKey is! String ||
        !privateKey.startsWith('$privateKeyBegin\n') ||
        !privateKey.endsWith('\n$privateKeyEnd\n') ||
        privateKey.length <=
            privateKeyBegin.length + privateKeyEnd.length + 3) {
      _fail('PLAY_SERVICE_ACCOUNT_CONTENT_INVALID');
    }

    stdout.writeln('ANDROID_PLAY_CREDENTIAL_INPUTS_VALID');
  } on _ValidationException catch (error) {
    stderr.writeln('ANDROID_PLAY_CREDENTIALS_BLOCKED: ${error.code}');
    exitCode = 1;
  } on Object {
    stderr.writeln('ANDROID_PLAY_CREDENTIALS_BLOCKED: INPUT_INVALID');
    exitCode = 1;
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  const supported = <String>{
    'service-account',
    'expected-email',
    'expected-project',
    'expected-fingerprint',
    'artifact-fingerprint',
  };
  if (arguments.length != supported.length * 2) {
    _fail('ARGUMENTS_INVALID');
  }
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final flag = arguments[index];
    if (!flag.startsWith('--')) {
      _fail('ARGUMENTS_INVALID');
    }
    final key = flag.substring(2);
    if (!supported.contains(key) || result.containsKey(key)) {
      _fail('ARGUMENTS_INVALID');
    }
    result[key] = arguments[index + 1];
  }
  if (result.keys.toSet().length != supported.length) {
    _fail('ARGUMENTS_INVALID');
  }
  return result;
}

String _normalizeFingerprint(String? value) {
  final normalized = (value ?? '').replaceAll(':', '').toLowerCase();
  if (!RegExp(_fingerprintPattern).hasMatch(normalized)) {
    _fail('SIGNING_FINGERPRINT_INVALID');
  }
  return normalized;
}

Never _fail(String code) => throw _ValidationException(code);

final class _ValidationException implements Exception {
  const _ValidationException(this.code);

  final String code;
}
