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
    if (FileSystemEntity.isLinkSync(file.path)) {
      fail('FILE_NOT_REGULAR');
    }
    final resolved = file.resolveSymbolicLinksSync();
    if (resolved != file.path) {
      fail('FILE_PATH_NOT_CANONICAL');
    }
    final bytes = _readRegularFile(file.path);
    final attestation = ReleaseConfigAttestation.fromBytes(bytes);
    stdout.writeln(attestation.sha256);
  } on ReleaseConfigValidationException catch (error) {
    fail(error.code);
  } on FileSystemException {
    fail('FILE_UNREADABLE');
  } on ProcessException {
    fail('FILE_UNREADABLE');
  }
}

List<int> _readRegularFile(String path) {
  final result = Process.runSync('python3', [
    '-c',
    _boundedReadScript,
    path,
  ], stdoutEncoding: null);
  switch (result.exitCode) {
    case 0:
      final bytes = result.stdout;
      if (bytes is List<int>) {
        return bytes;
      }
      fail('FILE_UNREADABLE');
    case 41:
      fail('FILE_NOT_REGULAR');
    case 42:
      fail('FILE_SIZE_INVALID');
    case 43:
      fail('FILE_CHANGED_DURING_READ');
    default:
      fail('FILE_UNREADABLE');
  }
}

const _boundedReadScript = r'''
import os
import stat
import sys

path = sys.argv[1]
flags = os.O_RDONLY | os.O_NONBLOCK | getattr(os, "O_NOFOLLOW", 0)
try:
    descriptor = os.open(path, flags)
except OSError:
    sys.exit(44)

try:
    before = os.fstat(descriptor)
    if not stat.S_ISREG(before.st_mode):
        sys.exit(41)
    if before.st_size < 1 or before.st_size > 65536:
        sys.exit(42)
    payload = bytearray()
    while len(payload) <= 65536:
        chunk = os.read(descriptor, min(8192, 65537 - len(payload)))
        if not chunk:
            break
        payload.extend(chunk)
    after = os.fstat(descriptor)
    before_mtime = getattr(before, "st_mtime_ns", int(before.st_mtime * 1000000000))
    after_mtime = getattr(after, "st_mtime_ns", int(after.st_mtime * 1000000000))
    if (
        len(payload) != before.st_size
        or before.st_dev != after.st_dev
        or before.st_ino != after.st_ino
        or before.st_size != after.st_size
        or before_mtime != after_mtime
    ):
        sys.exit(43)
    sys.stdout.buffer.write(payload)
finally:
    os.close(descriptor)
''';
