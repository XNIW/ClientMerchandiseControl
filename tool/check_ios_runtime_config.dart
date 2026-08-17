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
    case 45:
      fail('FILE_PATH_NOT_CANONICAL');
    default:
      fail('FILE_UNREADABLE');
  }
}

const _boundedReadScript = r'''
import os
import errno
import stat
import sys

path = sys.argv[1]
if (
    not os.path.isabs(path)
    or os.path.normpath(path) != path
    or not hasattr(os, "O_DIRECTORY")
    or not hasattr(os, "O_NOFOLLOW")
):
    sys.exit(45)

components = path.split(os.sep)[1:]
if not components or any(component in ("", ".", "..") for component in components):
    sys.exit(45)

directory_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
file_flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW
directory_descriptor = None
descriptor = None
try:
    directory_descriptor = os.open(os.sep, directory_flags)
    for component in components[:-1]:
        try:
            next_descriptor = os.open(
                component,
                directory_flags,
                dir_fd=directory_descriptor,
            )
        except OSError as error:
            if error.errno in (errno.ELOOP, errno.ENOTDIR):
                sys.exit(45)
            sys.exit(44)
        os.close(directory_descriptor)
        directory_descriptor = next_descriptor
    try:
        descriptor = os.open(
            components[-1],
            file_flags,
            dir_fd=directory_descriptor,
        )
    except OSError as error:
        if error.errno == errno.ELOOP:
            sys.exit(41)
        sys.exit(44)

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
    if descriptor is not None:
        os.close(descriptor)
    if directory_descriptor is not None:
        os.close(directory_descriptor)
''';
