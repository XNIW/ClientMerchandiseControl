import 'dart:io';

import 'package:client_merchandise_control/core/config/release_config_attestation.dart';

Never fail(String code) {
  stderr.writeln('IOS_RUNTIME_CONFIG_BLOCKED: $code');
  exit(1);
}

void main(List<String> arguments) {
  if (arguments.length != 2 || arguments[0] != '--config') {
    fail('USAGE');
  }

  try {
    final file = File(arguments[1]).absolute;
    if (!file.existsSync() || FileSystemEntity.isLinkSync(file.path)) {
      fail('FILE_NOT_REGULAR');
    }
    final resolved = file.resolveSymbolicLinksSync();
    if (resolved != file.path) {
      fail('FILE_PATH_NOT_CANONICAL');
    }
    final handle = file.openSync(mode: FileMode.read);
    late final List<int> bytes;
    try {
      final length = handle.lengthSync();
      if (length < 1 || length > 65536) {
        fail('FILE_SIZE_INVALID');
      }
      bytes = handle.readSync(65537);
      if (bytes.length != length || handle.readByteSync() != -1) {
        fail('FILE_CHANGED_DURING_READ');
      }
    } finally {
      handle.closeSync();
    }
    final attestation = ReleaseConfigAttestation.fromBytes(bytes);
    stdout.writeln(attestation.sha256);
  } on ReleaseConfigValidationException catch (error) {
    fail(error.code);
  } on FileSystemException {
    fail('FILE_UNREADABLE');
  }
}
