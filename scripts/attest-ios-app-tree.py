#!/usr/bin/env python3
"""Attesta, copia e sigilla in modo bounded un bundle iOS."""

from __future__ import annotations

import hashlib
import ctypes
import errno
import fcntl
import io
import os
import posixpath
import re
import secrets
import select
import stat
import struct
import sys
import tempfile
import zipfile
from typing import Optional


MAX_ENTRIES = 4_096
MAX_DEPTH = 64
MAX_FILE_BYTES = 134_217_728
MAX_TOTAL_BYTES = 536_870_912
MAX_SEAL_BYTES = 603_979_776
MAX_CENTRAL_DIRECTORY_BYTES = 16_777_216
MAX_PATH_BYTES = 4_096
MAX_CLEANUP_DEPTH = 256
MAX_CLEANUP_PASSES = 16
MAX_CLEANUP_OPERATIONS = 65_536
MAX_CLEANUP_QUARANTINE_ATTEMPTS = 16
MAX_RETAINED_TEMP_ROOTS = 512
CHUNK_BYTES = 65_536
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
DIRECTORY_IDENTITY_PATTERN = re.compile(r"^[0-9]+,[0-9]+$")
TEMP_DIRECTORY_RECORD_PATTERN = re.compile(
    r"^(/[^\t\r\n\x00]+)\t([0-9]+,[0-9]+)$"
)
RENAME_EXCL = 0x00000004

_LIBC = ctypes.CDLL(None, use_errno=True)
_RENAMEATX_NP = getattr(_LIBC, "renameatx_np", None)
if _RENAMEATX_NP is not None:
    _RENAMEATX_NP.argtypes = (
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    )
    _RENAMEATX_NP.restype = ctypes.c_int

Record = tuple[bytes, bytes, int, int, bytes]


def _stable_times(value: os.stat_result) -> tuple[int, int]:
    return (
        getattr(value, "st_mtime_ns", int(value.st_mtime * 1_000_000_000)),
        getattr(value, "st_ctime_ns", int(value.st_ctime * 1_000_000_000)),
    )


def _normalized_absolute(path: str) -> str:
    if not os.path.isabs(path) or os.path.normpath(path) != path:
        raise ValueError("non-canonical path")
    return path


def _open_absolute_directory(path: str) -> int:
    _normalized_absolute(path)
    descriptor = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
    try:
        for component in path.split("/")[1:]:
            if component in ("", ".", "..") or "\x00" in component:
                raise ValueError("invalid directory path")
            child = os.open(
                component,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=descriptor,
            )
            os.close(descriptor)
            descriptor = child
        return descriptor
    except BaseException:
        os.close(descriptor)
        raise


def _open_absolute_directory_chain(path: str) -> tuple[list[int], list[str]]:
    _normalized_absolute(path)
    descriptors = [os.open("/", os.O_RDONLY | os.O_DIRECTORY)]
    components: list[str] = []
    try:
        for component in path.split("/")[1:]:
            if component in ("", ".", "..") or "\x00" in component:
                raise ValueError("invalid directory path")
            before = os.stat(
                component,
                dir_fd=descriptors[-1],
                follow_symlinks=False,
            )
            child = os.open(
                component,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=descriptors[-1],
            )
            after = os.fstat(child)
            if (
                not stat.S_ISDIR(before.st_mode)
                or not stat.S_ISDIR(after.st_mode)
                or before.st_dev != after.st_dev
                or before.st_ino != after.st_ino
                or before.st_mode != after.st_mode
            ):
                os.close(child)
                raise ValueError("directory changed before open")
            descriptors.append(child)
            components.append(component)
        return descriptors, components
    except BaseException:
        for descriptor in reversed(descriptors):
            os.close(descriptor)
        raise


def _directory_chain_matches(
    descriptors: list[int], components: list[str]
) -> bool:
    if len(descriptors) != len(components) + 1:
        return False
    for index, component in enumerate(components):
        current = os.stat(
            component,
            dir_fd=descriptors[index],
            follow_symlinks=False,
        )
        opened = os.fstat(descriptors[index + 1])
        if (
            not stat.S_ISDIR(current.st_mode)
            or not stat.S_ISDIR(opened.st_mode)
            or current.st_dev != opened.st_dev
            or current.st_ino != opened.st_ino
            or current.st_mode != opened.st_mode
        ):
            return False
    return True


def _open_absolute_regular(path: str) -> int:
    _normalized_absolute(path)
    parent, name = os.path.split(path)
    if name in ("", ".", "..") or "/" in name or "\x00" in name:
        raise ValueError("invalid file path")
    directory = _open_absolute_directory(parent)
    try:
        return os.open(
            name,
            os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
            dir_fd=directory,
        )
    finally:
        os.close(directory)


def _open_parent(path: str) -> tuple[int, str]:
    _normalized_absolute(path)
    parent, name = os.path.split(path)
    if name in ("", ".", "..") or "/" in name or "\x00" in name:
        raise ValueError("invalid output path")
    descriptor = _open_absolute_directory(parent)
    return descriptor, name


def _open_relative_directory(root: int, relative: str) -> int:
    current = os.dup(root)
    try:
        if relative:
            for component in relative.split("/"):
                if component in ("", ".", "..") or "\x00" in component:
                    raise ValueError("invalid relative directory")
                child = os.open(
                    component,
                    os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                    dir_fd=current,
                )
                os.close(current)
                current = child
        return current
    except BaseException:
        os.close(current)
        raise


def _write_all(descriptor: int, payload: bytes) -> None:
    offset = 0
    while offset < len(payload):
        written = os.write(descriptor, payload[offset:])
        if written <= 0:
            raise OSError("short write")
        offset += written


def _rename_exclusive(
    source_directory: int,
    source: str,
    destination_directory: int,
    destination: str,
) -> None:
    if _RENAMEATX_NP is None:
        raise OSError(errno.ENOTSUP, "exclusive rename unavailable")
    result = _RENAMEATX_NP(
        source_directory,
        os.fsencode(source),
        destination_directory,
        os.fsencode(destination),
        RENAME_EXCL,
    )
    if result != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error))


def _restore_mismatched_entry(
    directory: int,
    quarantine: str,
    original: str,
) -> None:
    try:
        _rename_exclusive(directory, quarantine, directory, original)
    except OSError:
        # Il victim resta preservato nel nome quarantine se il nome originale
        # è stato occupato durante la race. Non viene mai cancellato.
        pass


def _quarantine_bound_entry(
    directory: int,
    name: str,
    expected: os.stat_result,
) -> str:
    for _ in range(MAX_CLEANUP_QUARANTINE_ATTEMPTS):
        quarantine = f".cmc-cleanup-{secrets.token_hex(16)}"
        try:
            _rename_exclusive(directory, name, directory, quarantine)
        except FileExistsError:
            continue
        moved = os.stat(
            quarantine,
            dir_fd=directory,
            follow_symlinks=False,
        )
        if (
            moved.st_dev != expected.st_dev
            or moved.st_ino != expected.st_ino
            or moved.st_mode != expected.st_mode
        ):
            _restore_mismatched_entry(directory, quarantine, name)
            raise OSError("cleanup entry identity mismatch")
        return quarantine
    raise OSError("cleanup quarantine unavailable")


def _validate_retained_entry(
    directory: int,
    name: str,
    expected: os.stat_result,
) -> os.stat_result:
    current = os.stat(
        name,
        dir_fd=directory,
        follow_symlinks=False,
    )
    if (
        current.st_dev != expected.st_dev
        or current.st_ino != expected.st_ino
        or current.st_mode != expected.st_mode
        or _stable_times(current) != _stable_times(expected)
    ):
        raise OSError("cleanup retained entry identity mismatch")
    if stat.S_ISREG(current.st_mode):
        retained = os.open(
            name,
            os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
            dir_fd=directory,
        )
        try:
            opened = os.fstat(retained)
            if (
                opened.st_dev != current.st_dev
                or opened.st_ino != current.st_ino
                or opened.st_mode != current.st_mode
                or _stable_times(opened) != _stable_times(current)
                or opened.st_nlink != 1
                or opened.st_size != 0
            ):
                raise OSError(
                    "cleanup retained file is not empty and private"
                )
            return opened
        finally:
            os.close(retained)
    if stat.S_ISDIR(current.st_mode):
        retained = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=directory,
        )
        try:
            opened = os.fstat(retained)
            if (
                opened.st_dev != current.st_dev
                or opened.st_ino != current.st_ino
                or opened.st_mode != current.st_mode
                or _stable_times(opened) != _stable_times(current)
            ):
                raise OSError("cleanup retained directory changed")
            _validate_zero_payload_tree(retained)
            after = os.fstat(retained)
            if (
                after.st_dev != opened.st_dev
                or after.st_ino != opened.st_ino
                or after.st_mode != opened.st_mode
                or _stable_times(after) != _stable_times(opened)
            ):
                raise OSError("cleanup retained directory changed")
            return after
        finally:
            os.close(retained)
    if stat.S_ISFIFO(current.st_mode):
        if current.st_nlink != 1 or current.st_size != 0:
            raise OSError("cleanup retained fifo is not empty and private")
        return current
    raise OSError("cleanup retained entry type invalid")


def _validate_zero_payload_tree(
    directory: int,
    depth: int = 0,
    operations: Optional[list[int]] = None,
) -> None:
    if depth > MAX_CLEANUP_DEPTH:
        raise OSError("cleanup retained depth exceeded")
    if operations is None:
        operations = [0]
    before = os.fstat(directory)
    with os.scandir(directory) as iterator:
        names = [entry.name for entry in iterator]
    for name in names:
        operations[0] += 1
        if operations[0] > MAX_CLEANUP_OPERATIONS:
            raise OSError("cleanup retained operation limit exceeded")
        metadata = os.stat(name, dir_fd=directory, follow_symlinks=False)
        if stat.S_ISREG(metadata.st_mode):
            if metadata.st_nlink != 1 or metadata.st_size != 0:
                raise OSError("cleanup retained payload is not empty")
        elif stat.S_ISFIFO(metadata.st_mode):
            if metadata.st_nlink != 1 or metadata.st_size != 0:
                raise OSError("cleanup retained fifo is not empty and private")
        elif stat.S_ISDIR(metadata.st_mode):
            child = os.open(
                name,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=directory,
            )
            try:
                opened = os.fstat(child)
                if (
                    opened.st_dev != metadata.st_dev
                    or opened.st_ino != metadata.st_ino
                    or opened.st_mode != metadata.st_mode
                ):
                    raise OSError("cleanup retained child changed")
                _validate_zero_payload_tree(child, depth + 1, operations)
            finally:
                os.close(child)
        else:
            raise OSError("cleanup retained entry type invalid")
    after = os.fstat(directory)
    if (
        after.st_dev != before.st_dev
        or after.st_ino != before.st_ino
        or after.st_mode != before.st_mode
        or _stable_times(after) != _stable_times(before)
    ):
        raise OSError("cleanup retained tree changed")


def _backup_regular(descriptor: int, expected: os.stat_result):
    if expected.st_size < 0 or expected.st_size > MAX_FILE_BYTES:
        raise OSError("cleanup file exceeds recoverable size")
    backup = io.BytesIO()
    try:
        os.lseek(descriptor, 0, os.SEEK_SET)
        remaining = expected.st_size
        while remaining:
            chunk = os.read(descriptor, min(CHUNK_BYTES, remaining))
            if not chunk:
                raise OSError("cleanup backup short read")
            if backup.write(chunk) != len(chunk):
                raise OSError("cleanup backup short write")
            remaining -= len(chunk)
        if os.read(descriptor, 1):
            raise OSError("cleanup backup size changed")
        after = os.fstat(descriptor)
        if (
            after.st_dev != expected.st_dev
            or after.st_ino != expected.st_ino
            or after.st_mode != expected.st_mode
            or after.st_size != expected.st_size
            or after.st_nlink != 1
            or _stable_times(after) != _stable_times(expected)
        ):
            raise OSError("cleanup source changed during backup")
        backup.seek(0)
        return backup
    except BaseException:
        backup.close()
        raise


def _restore_regular_from_backup(
    descriptor: int,
    backup,
    expected: os.stat_result,
) -> None:
    os.ftruncate(descriptor, 0)
    os.lseek(descriptor, 0, os.SEEK_SET)
    backup.seek(0)
    remaining = expected.st_size
    while remaining:
        chunk = backup.read(min(CHUNK_BYTES, remaining))
        if not chunk:
            raise OSError("cleanup restore short read")
        _write_all(descriptor, chunk)
        remaining -= len(chunk)
    os.fchmod(descriptor, stat.S_IMODE(expected.st_mode))
    os.fsync(descriptor)


def _clear_directory(
    directory: int,
    depth: int = 0,
    operations: Optional[list[int]] = None,
) -> None:
    if depth > MAX_CLEANUP_DEPTH:
        raise OSError("cleanup depth exceeded")
    if operations is None:
        operations = [0]
    retained: dict[str, os.stat_result] = {}
    stable_passes = 0
    for _ in range(MAX_CLEANUP_PASSES):
        with os.scandir(directory) as iterator:
            names = [entry.name for entry in iterator]
        current_names = set(names)
        if not set(retained).issubset(current_names):
            raise OSError("cleanup retained entry disappeared")
        for retained_name, retained_metadata in retained.items():
            _validate_retained_entry(
                directory,
                retained_name,
                retained_metadata,
            )
        pending = [name for name in names if name not in retained]
        if not pending:
            stable_passes += 1
            if stable_passes >= 2:
                return
            continue
        stable_passes = 0
        for name in pending:
            operations[0] += 1
            if operations[0] > MAX_CLEANUP_OPERATIONS:
                raise OSError("cleanup operation limit exceeded")
            try:
                metadata = os.stat(
                    name,
                    dir_fd=directory,
                    follow_symlinks=False,
                )
                if stat.S_ISDIR(metadata.st_mode):
                    child = os.open(
                        name,
                        os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                        dir_fd=directory,
                    )
                    opened = os.fstat(child)
                    if (
                        not stat.S_ISDIR(opened.st_mode)
                        or opened.st_dev != metadata.st_dev
                        or opened.st_ino != metadata.st_ino
                        or opened.st_mode != metadata.st_mode
                    ):
                        os.close(child)
                        raise OSError("cleanup child identity mismatch")
                    try:
                        quarantine = _quarantine_bound_entry(
                            directory, name, opened
                        )
                        _clear_directory(child, depth + 1, operations)
                        os.fsync(child)
                        retained[quarantine] = os.fstat(child)
                    finally:
                        os.close(child)
                else:
                    descriptor: Optional[int] = None
                    writable: Optional[int] = None
                    backup = None
                    quarantine_expected = metadata
                    if stat.S_ISREG(metadata.st_mode):
                        descriptor = os.open(
                            name,
                            os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                            dir_fd=directory,
                        )
                        opened = os.fstat(descriptor)
                        if (
                            not stat.S_ISREG(opened.st_mode)
                            or opened.st_dev != metadata.st_dev
                            or opened.st_ino != metadata.st_ino
                            or opened.st_mode != metadata.st_mode
                            or opened.st_nlink != 1
                        ):
                            os.close(descriptor)
                            raise OSError("cleanup file identity mismatch")
                        os.fchmod(
                            descriptor,
                            stat.S_IMODE(opened.st_mode) | stat.S_IWUSR,
                        )
                        quarantine_expected = os.fstat(descriptor)
                        writable = os.open(
                            name,
                            os.O_RDWR | os.O_NOFOLLOW | os.O_NONBLOCK,
                            dir_fd=directory,
                        )
                        writable_metadata = os.fstat(writable)
                        if (
                            writable_metadata.st_dev != opened.st_dev
                            or writable_metadata.st_ino != opened.st_ino
                        ):
                            os.close(writable)
                            writable = None
                            raise OSError("cleanup writable identity mismatch")
                    try:
                        quarantine = _quarantine_bound_entry(
                            directory, name, quarantine_expected
                        )
                        if writable is not None:
                            quarantined = os.fstat(writable)
                            visible = os.stat(
                                quarantine,
                                dir_fd=directory,
                                follow_symlinks=False,
                            )
                            if (
                                quarantined.st_dev != opened.st_dev
                                or quarantined.st_ino != opened.st_ino
                                or quarantined.st_nlink != 1
                                or visible.st_dev != quarantined.st_dev
                                or visible.st_ino != quarantined.st_ino
                                or visible.st_mode != quarantined.st_mode
                                or visible.st_nlink != 1
                            ):
                                raise OSError(
                                    "cleanup quarantined file identity mismatch"
                                )
                            backup = _backup_regular(writable, quarantined)
                            try:
                                os.ftruncate(writable, 0)
                                os.fchmod(
                                    writable,
                                    stat.S_IMODE(metadata.st_mode),
                                )
                                os.fsync(writable)
                                cleaned = os.fstat(writable)
                                if cleaned.st_nlink != 1:
                                    _restore_regular_from_backup(
                                        writable,
                                        backup,
                                        quarantined,
                                    )
                                    raise OSError(
                                        "cleanup quarantined file link changed"
                                    )
                                if cleaned.st_size != 0:
                                    raise OSError(
                                        "cleanup quarantined file is not empty"
                                    )
                            finally:
                                backup.close()
                                backup = None
                            retained[quarantine] = cleaned
                        else:
                            retained[quarantine] = os.stat(
                                quarantine,
                                dir_fd=directory,
                                follow_symlinks=False,
                            )
                    finally:
                        if writable is not None:
                            os.close(writable)
                        if backup is not None:
                            backup.close()
                        if descriptor is not None:
                            try:
                                descriptor_mode = stat.S_IMODE(
                                    os.fstat(descriptor).st_mode
                                )
                                original_mode = stat.S_IMODE(metadata.st_mode)
                                if descriptor_mode != original_mode:
                                    os.fchmod(descriptor, original_mode)
                            except OSError:
                                pass
                            os.close(descriptor)
            except FileNotFoundError:
                continue
    raise OSError("cleanup did not converge")


def _cleanup_created_directory(
    parent: int,
    name: str,
    identity: Optional[tuple[int, int]],
    directory: Optional[int],
) -> None:
    if identity is None or directory is None:
        return
    opened = os.fstat(directory)
    if (
        not stat.S_ISDIR(opened.st_mode)
        or (opened.st_dev, opened.st_ino) != identity
    ):
        raise OSError("cleanup identity mismatch")
    quarantine = _quarantine_bound_entry(parent, name, opened)
    detached = os.fstat(directory)
    if (detached.st_dev, detached.st_ino) != identity:
        raise OSError("cleanup detached identity mismatch")
    _clear_directory(directory)
    os.fsync(directory)
    os.fsync(parent)
    # Il root è rimosso dal path operativo e resta come tombstone bounded. Il
    # cleanup non esegue mai unlink/rmdir name-based su namespace concorrente.
    # File regolari sono già troncati via descriptor e nessun payload persiste.


def create_temp_directory(parent_path: str) -> str:
    record_probe = (
        f"{parent_path.rstrip('/')}/cmc-ios-release."
        f"{'0' * 32}\t0,0"
    )
    if not TEMP_DIRECTORY_RECORD_PATTERN.fullmatch(record_probe):
        raise ValueError("temporary directory parent is not record-safe")
    descriptors, components = _open_absolute_directory_chain(parent_path)
    parent = descriptors[-1]
    try:
        fcntl.flock(parent, fcntl.LOCK_EX)
        if not _directory_chain_matches(descriptors, components):
            raise OSError("temporary directory parent changed")
        retained_count = _retained_temp_root_count(parent)
        if retained_count >= MAX_RETAINED_TEMP_ROOTS:
            raise OSError("temporary directory retention limit exceeded")
        for _ in range(MAX_CLEANUP_QUARANTINE_ATTEMPTS):
            name = f"cmc-ios-release.{secrets.token_hex(16)}"
            try:
                os.mkdir(name, 0o700, dir_fd=parent)
            except FileExistsError:
                continue
            directory: Optional[int] = None
            try:
                before = os.stat(name, dir_fd=parent, follow_symlinks=False)
                directory = os.open(
                    name,
                    os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                    dir_fd=parent,
                )
                opened = os.fstat(directory)
                after = os.stat(name, dir_fd=parent, follow_symlinks=False)
                if (
                    not stat.S_ISDIR(before.st_mode)
                    or not stat.S_ISDIR(opened.st_mode)
                    or (before.st_dev, before.st_ino)
                    != (opened.st_dev, opened.st_ino)
                    or (after.st_dev, after.st_ino)
                    != (opened.st_dev, opened.st_ino)
                    or before.st_mode != opened.st_mode
                    or after.st_mode != opened.st_mode
                ):
                    raise OSError("temporary directory identity mismatch")
                if not _directory_chain_matches(descriptors, components):
                    raise OSError("temporary directory parent changed")
                path = f"{parent_path.rstrip('/')}/{name}"
                record = f"{path}\t{opened.st_dev},{opened.st_ino}"
                if not TEMP_DIRECTORY_RECORD_PATTERN.fullmatch(record):
                    raise ValueError("temporary directory record invalid")
                for _ in range(2):
                    if not _directory_chain_matches(descriptors, components):
                        raise OSError("temporary directory parent changed")
                    if (
                        _retained_temp_root_count(parent)
                        > MAX_RETAINED_TEMP_ROOTS
                    ):
                        _remove_empty_created_directory(
                            parent,
                            name,
                            directory,
                        )
                        raise OSError(
                            "temporary directory retention limit exceeded"
                        )
                return record
            finally:
                if directory is not None:
                    os.close(directory)
        raise OSError("temporary directory unavailable")
    finally:
        for descriptor in reversed(descriptors):
            os.close(descriptor)


def _retained_temp_root_count(parent: int) -> int:
    with os.scandir(parent) as iterator:
        return sum(
            1
            for entry in iterator
            if entry.name.startswith("cmc-ios-release.")
            or entry.name.startswith(".cmc-cleanup-")
        )


def _remove_empty_created_directory(
    parent: int,
    name: str,
    directory: int,
) -> None:
    opened = os.fstat(directory)
    visible = os.stat(name, dir_fd=parent, follow_symlinks=False)
    if (
        not stat.S_ISDIR(opened.st_mode)
        or visible.st_dev != opened.st_dev
        or visible.st_ino != opened.st_ino
        or visible.st_mode != opened.st_mode
    ):
        raise OSError("temporary directory rollback identity mismatch")
    with os.scandir(directory) as iterator:
        if next(iterator, None) is not None:
            raise OSError("temporary directory rollback is not empty")
    os.rmdir(name, dir_fd=parent)


def directory_identity(path: str) -> str:
    directory = _open_absolute_directory(path)
    try:
        metadata = os.fstat(directory)
        if not stat.S_ISDIR(metadata.st_mode):
            raise ValueError("directory identity target invalid")
        return f"{metadata.st_dev},{metadata.st_ino}"
    finally:
        os.close(directory)


def cleanup_directory(path: str, expected_identity: str) -> None:
    if not DIRECTORY_IDENTITY_PATTERN.fullmatch(expected_identity):
        raise ValueError("invalid directory identity")
    expected = tuple(int(value) for value in expected_identity.split(","))
    parent: Optional[int] = None
    directory: Optional[int] = None
    try:
        parent, name = _open_parent(path)
        directory = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=parent,
        )
        metadata = os.fstat(directory)
        if (
            not stat.S_ISDIR(metadata.st_mode)
            or (metadata.st_dev, metadata.st_ino) != expected
        ):
            raise OSError("cleanup root identity mismatch")
        _cleanup_created_directory(parent, name, expected, directory)
    finally:
        if directory is not None:
            os.close(directory)
        if parent is not None:
            os.close(parent)


def _read_regular(
    directory: int,
    name: str,
    expected: os.stat_result,
    remaining_total: int,
    destination: Optional[int] = None,
) -> tuple[os.stat_result, bytes, bytes]:
    descriptor: Optional[int] = None
    try:
        descriptor = os.open(
            name,
            os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
            dir_fd=directory,
        )
        before = os.fstat(descriptor)
        if (
            not stat.S_ISREG(before.st_mode)
            or before.st_dev != expected.st_dev
            or before.st_ino != expected.st_ino
            or before.st_size < 0
            or before.st_size > MAX_FILE_BYTES
            or before.st_size > remaining_total
        ):
            raise ValueError("invalid file")
        digest = hashlib.sha256()
        payload = bytearray()
        remaining = MAX_FILE_BYTES + 1
        length = 0
        while remaining > 0:
            chunk = os.read(descriptor, min(CHUNK_BYTES, remaining))
            if not chunk:
                break
            digest.update(chunk)
            payload.extend(chunk)
            if destination is not None:
                _write_all(destination, chunk)
            length += len(chunk)
            remaining -= len(chunk)
        if length > MAX_FILE_BYTES or os.read(descriptor, 1):
            raise ValueError("file exceeds limit")
        after = os.fstat(descriptor)
        if (
            length != before.st_size
            or before.st_dev != after.st_dev
            or before.st_ino != after.st_ino
            or before.st_mode != after.st_mode
            or before.st_size != after.st_size
            or _stable_times(before) != _stable_times(after)
        ):
            raise ValueError("file changed during read")
        return before, digest.digest(), bytes(payload)
    finally:
        if descriptor is not None:
            os.close(descriptor)


def _zip_info(name: str, mode: int, is_directory: bool) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    info.create_system = 3
    info.compress_type = zipfile.ZIP_STORED
    file_type = stat.S_IFDIR if is_directory else stat.S_IFREG
    info.external_attr = ((file_type | (mode & 0o7777)) & 0xFFFF) << 16
    if is_directory:
        info.external_attr |= 0x10
    return info


def _walk(
    directory: int,
    relative: str,
    records: list[Record],
    budget: list[int],
    depth: int,
    destination: Optional[int] = None,
    archive: Optional[zipfile.ZipFile] = None,
) -> None:
    if depth > MAX_DEPTH:
        raise ValueError("tree exceeds depth limit")
    before = os.fstat(directory)
    names: list[str] = []
    with os.scandir(directory) as iterator:
        for entry in iterator:
            names.append(entry.name)
            budget[0] += 1
            if budget[0] > MAX_ENTRIES:
                raise ValueError("too many entries")
    names.sort(key=lambda value: value.encode("utf-8"))
    for name in names:
        if name in ("", ".", "..") or "/" in name or "\x00" in name:
            raise ValueError("invalid path")
        child_relative = f"{relative}/{name}" if relative else name
        metadata = os.stat(name, dir_fd=directory, follow_symlinks=False)
        if stat.S_ISDIR(metadata.st_mode):
            child = os.open(
                name,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=directory,
            )
            child_metadata = os.fstat(child)
            if (
                child_metadata.st_dev != metadata.st_dev
                or child_metadata.st_ino != metadata.st_ino
                or child_metadata.st_mode != metadata.st_mode
            ):
                os.close(child)
                raise ValueError("directory changed before open")
            destination_child: Optional[int] = None
            try:
                if destination is not None:
                    os.mkdir(name, 0o700, dir_fd=destination)
                    destination_child = os.open(
                        name,
                        os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                        dir_fd=destination,
                    )
                records.append(
                    (
                        b"D",
                        child_relative.encode("utf-8"),
                        child_metadata.st_mode & 0o7777,
                        0,
                        b"",
                    )
                )
                if archive is not None:
                    archive.writestr(
                        _zip_info(
                            f"Runner.app/{child_relative}/",
                            child_metadata.st_mode,
                            True,
                        ),
                        b"",
                    )
                _walk(
                    child,
                    child_relative,
                    records,
                    budget,
                    depth + 1,
                    destination_child,
                    archive,
                )
                if destination_child is not None:
                    os.fchmod(destination_child, child_metadata.st_mode & 0o7777)
                    os.fsync(destination_child)
            finally:
                if destination_child is not None:
                    os.close(destination_child)
                os.close(child)
        elif stat.S_ISREG(metadata.st_mode):
            destination_file: Optional[int] = None
            try:
                if destination is not None:
                    destination_file = os.open(
                        name,
                        os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                        metadata.st_mode & 0o7777,
                        dir_fd=destination,
                    )
                stable, digest, payload = _read_regular(
                    directory,
                    name,
                    metadata,
                    MAX_TOTAL_BYTES - budget[1],
                    destination_file,
                )
                if destination_file is not None:
                    os.fchmod(destination_file, stable.st_mode & 0o7777)
                    os.fsync(destination_file)
            finally:
                if destination_file is not None:
                    os.close(destination_file)
            budget[1] += stable.st_size
            records.append(
                (
                    b"F",
                    child_relative.encode("utf-8"),
                    stable.st_mode & 0o7777,
                    stable.st_size,
                    digest,
                )
            )
            if archive is not None:
                archive.writestr(
                    _zip_info(
                        f"Runner.app/{child_relative}",
                        stable.st_mode,
                        False,
                    ),
                    payload,
                )
        else:
            raise ValueError("non-regular entry")
    after = os.fstat(directory)
    if (
        before.st_dev != after.st_dev
        or before.st_ino != after.st_ino
        or before.st_mode != after.st_mode
        or _stable_times(before) != _stable_times(after)
    ):
        raise ValueError("directory changed during read")


def _digest_records(records: list[Record]) -> str:
    output = hashlib.sha256()
    for kind, relative, mode, length, digest in sorted(records):
        output.update(kind)
        output.update(b"\0")
        output.update(relative)
        output.update(b"\0")
        output.update(f"{mode:o}".encode("ascii"))
        output.update(b"\0")
        output.update(str(length).encode("ascii"))
        output.update(b"\0")
        output.update(digest.hex().encode("ascii"))
        output.update(b"\0")
    return output.hexdigest()


def _open_root(path: str) -> tuple[int, os.stat_result]:
    descriptor = _open_absolute_directory(path)
    metadata = os.fstat(descriptor)
    if not stat.S_ISDIR(metadata.st_mode):
        os.close(descriptor)
        raise ValueError("root is not a directory")
    return descriptor, metadata


def _collect_descriptor(
    descriptor: int,
    destination: Optional[int] = None,
    archive: Optional[zipfile.ZipFile] = None,
) -> tuple[str, os.stat_result]:
    root = os.fstat(descriptor)
    if not stat.S_ISDIR(root.st_mode):
        raise ValueError("root is not a directory")
    records: list[Record] = [(b"D", b"", root.st_mode & 0o7777, 0, b"")]
    budget = [0, 0]
    if archive is not None:
        archive.writestr(_zip_info("Runner.app/", root.st_mode, True), b"")
    _walk(descriptor, "", records, budget, 0, destination, archive)
    after = os.fstat(descriptor)
    if (
        root.st_dev != after.st_dev
        or root.st_ino != after.st_ino
        or root.st_mode != after.st_mode
        or _stable_times(root) != _stable_times(after)
    ):
        raise ValueError("root changed during read")
    return _digest_records(records), root


def _collect(
    path: str,
    destination: Optional[int] = None,
    archive: Optional[zipfile.ZipFile] = None,
) -> tuple[str, os.stat_result]:
    descriptor, _ = _open_root(path)
    try:
        return _collect_descriptor(descriptor, destination, archive)
    finally:
        os.close(descriptor)


def attest(path: str) -> str:
    digest, _ = _collect(path)
    return digest


def snapshot(source: str, destination: str) -> str:
    parent: Optional[int] = None
    target: Optional[int] = None
    target_identity: Optional[tuple[int, int]] = None
    completed = False
    try:
        parent, name = _open_parent(destination)
        os.mkdir(name, 0o700, dir_fd=parent)
        target = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=parent,
        )
        target_metadata = os.fstat(target)
        target_identity = (target_metadata.st_dev, target_metadata.st_ino)
        digest, root = _collect(source, destination=target)
        os.fchmod(target, root.st_mode & 0o7777)
        os.fsync(target)
        os.fsync(parent)
        completed = True
        return digest
    finally:
        try:
            if not completed and parent is not None:
                _cleanup_created_directory(parent, name, target_identity, target)
        finally:
            if target is not None:
                os.close(target)
            if parent is not None:
                os.close(parent)


def _hash_descriptor(descriptor: int, maximum: int) -> str:
    before = os.fstat(descriptor)
    if not stat.S_ISREG(before.st_mode) or before.st_size > maximum:
        raise ValueError("sealed payload exceeds limit")
    os.lseek(descriptor, 0, os.SEEK_SET)
    digest = hashlib.sha256()
    length = 0
    while True:
        chunk = os.read(descriptor, CHUNK_BYTES)
        if not chunk:
            break
        length += len(chunk)
        if length > maximum:
            raise ValueError("sealed payload exceeds limit")
        digest.update(chunk)
    after = os.fstat(descriptor)
    if (
        length != before.st_size
        or before.st_dev != after.st_dev
        or before.st_ino != after.st_ino
        or before.st_mode != after.st_mode
        or before.st_size != after.st_size
        or _stable_times(before) != _stable_times(after)
    ):
        raise ValueError("sealed payload changed during read")
    return digest.hexdigest()


def _verified_payload_snapshot(
    descriptor: int,
    expected_sha256: str,
):
    before = os.fstat(descriptor)
    if (
        not stat.S_ISREG(before.st_mode)
        or before.st_size < 0
        or before.st_size > MAX_SEAL_BYTES
    ):
        raise ValueError("invalid sealed payload")
    snapshot = tempfile.TemporaryFile(mode="w+b")
    try:
        os.lseek(descriptor, 0, os.SEEK_SET)
        digest = hashlib.sha256()
        length = 0
        while True:
            chunk = os.read(descriptor, CHUNK_BYTES)
            if not chunk:
                break
            length += len(chunk)
            if length > MAX_SEAL_BYTES:
                raise ValueError("sealed payload exceeds limit")
            digest.update(chunk)
            snapshot.write(chunk)
        after = os.fstat(descriptor)
        if (
            length != before.st_size
            or before.st_dev != after.st_dev
            or before.st_ino != after.st_ino
            or before.st_mode != after.st_mode
            or before.st_size != after.st_size
            or _stable_times(before) != _stable_times(after)
            or digest.hexdigest() != expected_sha256
        ):
            raise ValueError("sealed payload changed during snapshot")
        snapshot.flush()
        os.fsync(snapshot.fileno())
        snapshot.seek(0)
        return snapshot
    except BaseException:
        snapshot.close()
        raise


def seal(
    source: str,
    output_path: str,
    snapshot_destination: Optional[str] = None,
) -> tuple[str, str]:
    parent: Optional[int] = None
    output: Optional[int] = None
    output_identity: Optional[tuple[int, int]] = None
    completed = False
    try:
        parent, name = _open_parent(output_path)
        output = os.open(
            name,
            os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o400,
            dir_fd=parent,
        )
        output_metadata = os.fstat(output)
        output_identity = (output_metadata.st_dev, output_metadata.st_ino)
        with os.fdopen(os.dup(output), "w+b") as stream:
            with zipfile.ZipFile(
                stream,
                mode="w",
                compression=zipfile.ZIP_STORED,
                allowZip64=True,
            ) as archive:
                tree_digest, _ = _collect(source, archive=archive)
            stream.flush()
            os.fsync(stream.fileno())
        payload_digest = _hash_descriptor(output, MAX_SEAL_BYTES)
        if snapshot_destination is not None:
            extracted_digest = _extract_descriptor(
                output,
                payload_digest,
                snapshot_destination,
            )
            if extracted_digest != tree_digest:
                raise ValueError("sealed snapshot digest mismatch")
        os.fchmod(output, 0o444)
        os.fsync(output)
        os.fsync(parent)
        completed = True
        return tree_digest, payload_digest
    finally:
        if (
            not completed
            and parent is not None
            and output_identity is not None
        ):
            try:
                current = os.stat(name, dir_fd=parent, follow_symlinks=False)
                if (current.st_dev, current.st_ino) == output_identity:
                    os.unlink(name, dir_fd=parent)
            except OSError:
                pass
        if output is not None:
            os.close(output)
        if parent is not None:
            os.close(parent)


def publish_seal(
    payload_path: str,
    expected_sha256: str,
    output_path: str,
) -> str:
    if not SHA256_PATTERN.fullmatch(expected_sha256):
        raise ValueError("invalid expected digest")
    payload = _open_absolute_regular(payload_path)
    parent: Optional[int] = None
    output: Optional[int] = None
    output_identity: Optional[tuple[int, int]] = None
    completed = False
    try:
        if _hash_descriptor(payload, MAX_SEAL_BYTES) != expected_sha256:
            raise ValueError("sealed payload digest mismatch")
        parent, name = _open_parent(output_path)
        output = os.open(
            name,
            os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o400,
            dir_fd=parent,
        )
        output_metadata = os.fstat(output)
        output_identity = (output_metadata.st_dev, output_metadata.st_ino)
        os.lseek(payload, 0, os.SEEK_SET)
        copied = 0
        while True:
            chunk = os.read(payload, CHUNK_BYTES)
            if not chunk:
                break
            copied += len(chunk)
            if copied > MAX_SEAL_BYTES:
                raise ValueError("sealed payload exceeds limit")
            _write_all(output, chunk)
        if _hash_descriptor(payload, MAX_SEAL_BYTES) != expected_sha256:
            raise ValueError("sealed payload changed during publish")
        if _hash_descriptor(output, MAX_SEAL_BYTES) != expected_sha256:
            raise ValueError("published payload digest mismatch")
        os.fchmod(output, 0o444)
        os.fsync(output)
        os.fsync(parent)
        completed = True
        return expected_sha256
    finally:
        if not completed and parent is not None and output_identity is not None:
            try:
                current = os.stat(name, dir_fd=parent, follow_symlinks=False)
                if (current.st_dev, current.st_ino) == output_identity:
                    os.unlink(name, dir_fd=parent)
            except OSError:
                pass
        if output is not None:
            os.close(output)
        if parent is not None:
            os.close(parent)
        os.close(payload)


def _safe_zip_relative(name: str) -> tuple[str, bool]:
    if len(name.encode("utf-8")) > MAX_PATH_BYTES:
        raise ValueError("sealed path exceeds limit")
    if not name.startswith("Runner.app/"):
        raise ValueError("invalid sealed path")
    is_directory = name.endswith("/")
    relative = name[len("Runner.app/") :]
    if is_directory:
        relative = relative[:-1]
    if relative == "":
        if name != "Runner.app/":
            raise ValueError("invalid sealed root")
        return "", True
    if (
        relative.startswith("/")
        or posixpath.normpath(relative) != relative
        or any(part in ("", ".", "..") for part in relative.split("/"))
        or len(relative.split("/")) > MAX_DEPTH
        or "\x00" in relative
    ):
        raise ValueError("invalid sealed path")
    return relative, is_directory


def _preflight_zip_descriptor(payload: int) -> int:
    metadata = os.fstat(payload)
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_size < 22:
        raise ValueError("invalid sealed payload")
    tail_length = min(metadata.st_size, 65_557)
    tail = os.pread(payload, tail_length, metadata.st_size - tail_length)
    marker = b"PK\x05\x06"
    offset = tail.rfind(marker)
    if offset < 0 or offset + 22 > len(tail):
        raise ValueError("sealed central directory missing")
    (
        signature,
        disk_number,
        central_disk,
        disk_entries,
        total_entries,
        central_size,
        central_offset,
        comment_length,
    ) = struct.unpack_from("<4s4H2LH", tail, offset)
    absolute_eocd = metadata.st_size - tail_length + offset
    if (
        signature != marker
        or disk_number != 0
        or central_disk != 0
        or disk_entries != total_entries
        or total_entries == 0
        or total_entries > MAX_ENTRIES + 1
        or total_entries == 0xFFFF
        or central_size == 0xFFFFFFFF
        or central_offset == 0xFFFFFFFF
        or central_size > MAX_CENTRAL_DIRECTORY_BYTES
        or central_offset + central_size != absolute_eocd
        or absolute_eocd + 22 + comment_length != metadata.st_size
    ):
        raise ValueError("sealed central directory invalid")
    central = os.pread(payload, central_size, central_offset)
    if len(central) != central_size:
        raise ValueError("sealed central directory unreadable")
    cursor = 0
    actual_entries = 0
    while cursor < len(central):
        if cursor + 46 > len(central):
            raise ValueError("sealed central directory truncated")
        fields = struct.unpack_from("<4s6H3L5H2L", central, cursor)
        if fields[0] != b"PK\x01\x02" or fields[13] != 0:
            raise ValueError("sealed central directory entry invalid")
        record_length = 46 + fields[10] + fields[11] + fields[12]
        if record_length < 46 or cursor + record_length > len(central):
            raise ValueError("sealed central directory entry truncated")
        actual_entries += 1
        if actual_entries > MAX_ENTRIES + 1:
            raise ValueError("too many sealed entries")
        cursor += record_length
    if cursor != len(central) or actual_entries != total_entries:
        raise ValueError("sealed central directory count mismatch")
    return actual_entries


def _extract_descriptor(
    payload: int,
    expected_sha256: str,
    destination: str,
) -> str:
    payload_snapshot = _verified_payload_snapshot(payload, expected_sha256)
    parent: Optional[int] = None
    target: Optional[int] = None
    target_identity: Optional[tuple[int, int]] = None
    completed = False
    try:
        payload_descriptor = payload_snapshot.fileno()
        expected_entries = _preflight_zip_descriptor(payload_descriptor)
        parent, name = _open_parent(destination)
        os.mkdir(name, 0o700, dir_fd=parent)
        target = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=parent,
        )
        target_metadata = os.fstat(target)
        target_identity = (target_metadata.st_dev, target_metadata.st_ino)
        payload_snapshot.seek(0)
        with zipfile.ZipFile(payload_snapshot, mode="r") as archive:
                infos = archive.infolist()
                if len(infos) != expected_entries:
                    raise ValueError("sealed entry count changed")
                if len(infos) > MAX_ENTRIES + 1:
                    raise ValueError("too many sealed entries")
                seen: set[str] = set()
                total = 0
                root_mode: Optional[int] = None
                directory_modes: dict[str, int] = {}
                for info in infos:
                    relative, is_directory = _safe_zip_relative(info.filename)
                    if (
                        info.filename in seen
                        or info.compress_type != zipfile.ZIP_STORED
                        or info.flag_bits & 0x1
                    ):
                        raise ValueError("invalid sealed entry")
                    seen.add(info.filename)
                    mode = (info.external_attr >> 16) & 0xFFFF
                    expected_type = stat.S_IFDIR if is_directory else stat.S_IFREG
                    if stat.S_IFMT(mode) != expected_type:
                        raise ValueError("invalid sealed mode")
                    if is_directory and (info.file_size != 0 or info.compress_size != 0):
                        raise ValueError("invalid sealed directory")
                    if not is_directory and info.compress_size != info.file_size:
                        raise ValueError("invalid sealed compression")
                    if relative == "":
                        if root_mode is not None:
                            raise ValueError("duplicate sealed root")
                        root_mode = mode & 0o7777
                        continue
                    parent_relative, leaf = posixpath.split(relative)
                    current = _open_relative_directory(target, parent_relative)
                    try:
                        if is_directory:
                            os.mkdir(leaf, 0o700, dir_fd=current)
                            directory_modes[relative] = mode & 0o7777
                        else:
                            if (
                                info.file_size < 0
                                or info.file_size > MAX_FILE_BYTES
                                or total + info.file_size > MAX_TOTAL_BYTES
                            ):
                                raise ValueError("sealed file exceeds limit")
                            descriptor = os.open(
                                leaf,
                                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                mode & 0o7777,
                                dir_fd=current,
                            )
                            try:
                                length = 0
                                with archive.open(info, "r") as source:
                                    while True:
                                        chunk = source.read(CHUNK_BYTES)
                                        if not chunk:
                                            break
                                        length += len(chunk)
                                        if length > info.file_size:
                                            raise ValueError("sealed size mismatch")
                                        _write_all(descriptor, chunk)
                                if length != info.file_size:
                                    raise ValueError("sealed size mismatch")
                                os.fchmod(descriptor, mode & 0o7777)
                                os.fsync(descriptor)
                            finally:
                                os.close(descriptor)
                            total += length
                    finally:
                        os.close(current)
                if root_mode is None:
                    raise ValueError("sealed root missing")
                for relative, mode in sorted(
                    directory_modes.items(),
                    key=lambda item: item[0].count("/"),
                    reverse=True,
                ):
                    descriptor = _open_relative_directory(target, relative)
                    try:
                        os.fchmod(descriptor, mode)
                        os.fsync(descriptor)
                    finally:
                        os.close(descriptor)
                os.fchmod(target, root_mode)
                os.fsync(target)
        digest, _ = _collect_descriptor(target)
        os.fsync(parent)
        completed = True
        return digest
    finally:
        try:
            if not completed and parent is not None:
                _cleanup_created_directory(parent, name, target_identity, target)
        finally:
            if target is not None:
                os.close(target)
            if parent is not None:
                os.close(parent)
            payload_snapshot.close()


def extract(payload_path: str, expected_sha256: str, destination: str) -> str:
    if not SHA256_PATTERN.fullmatch(expected_sha256):
        raise ValueError("invalid expected digest")
    payload = _open_absolute_regular(payload_path)
    try:
        return _extract_descriptor(payload, expected_sha256, destination)
    finally:
        os.close(payload)


def _open_guard_descriptors(root: int, parent: int) -> list[int]:
    del parent
    descriptors = [os.dup(root)]
    budget = [0]

    def visit(directory: int, depth: int) -> None:
        if depth > MAX_DEPTH:
            raise ValueError("guard tree exceeds depth limit")
        with os.scandir(directory) as iterator:
            names = sorted(
                (entry.name for entry in iterator),
                key=lambda value: value.encode("utf-8"),
            )
        for name in names:
            budget[0] += 1
            if budget[0] > MAX_ENTRIES:
                raise ValueError("guard tree exceeds entry limit")
            metadata = os.stat(name, dir_fd=directory, follow_symlinks=False)
            if stat.S_ISDIR(metadata.st_mode):
                child = os.open(
                    name,
                    os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                    dir_fd=directory,
                )
                actual = os.fstat(child)
                if (
                    actual.st_dev != metadata.st_dev
                    or actual.st_ino != metadata.st_ino
                    or actual.st_mode != metadata.st_mode
                ):
                    os.close(child)
                    raise ValueError("guard directory changed before open")
                descriptors.append(child)
                visit(child, depth + 1)
            elif stat.S_ISREG(metadata.st_mode):
                child = os.open(
                    name,
                    os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                    dir_fd=directory,
                )
                actual = os.fstat(child)
                if (
                    actual.st_dev != metadata.st_dev
                    or actual.st_ino != metadata.st_ino
                    or actual.st_mode != metadata.st_mode
                ):
                    os.close(child)
                    raise ValueError("guard file changed before open")
                descriptors.append(child)
            else:
                raise ValueError("guard tree contains non-regular entry")

    try:
        visit(root, 0)
        return descriptors
    except BaseException:
        for descriptor in reversed(descriptors):
            os.close(descriptor)
        raise


def guard(path: str, expected_sha256: str) -> None:
    if not SHA256_PATTERN.fullmatch(expected_sha256):
        raise ValueError("invalid expected tree digest")
    if not hasattr(select, "kqueue"):
        raise RuntimeError("filesystem guard unavailable")
    ancestors: list[int] = []
    ancestor_components: list[str] = []
    root: Optional[int] = None
    descriptors: list[int] = []
    queue = None
    try:
        _normalized_absolute(path)
        parent_path, name = os.path.split(path)
        if name in ("", ".", "..") or "/" in name or "\x00" in name:
            raise ValueError("invalid guard path")
        ancestors, ancestor_components = _open_absolute_directory_chain(
            parent_path
        )
        parent = ancestors[-1]
        root = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=parent,
        )
        root_metadata = os.fstat(root)
        descriptors = _open_guard_descriptors(root, parent)
        descriptor_states = {
            descriptor: (
                metadata.st_dev,
                metadata.st_ino,
                metadata.st_mode,
                getattr(
                    metadata,
                    "st_ctime_ns",
                    int(metadata.st_ctime * 1_000_000_000),
                ),
            )
            for descriptor in descriptors
            for metadata in (os.fstat(descriptor),)
        }
        queue = select.kqueue()
        vnode_flags = (
            select.KQ_NOTE_WRITE
            | select.KQ_NOTE_DELETE
            | select.KQ_NOTE_EXTEND
            | select.KQ_NOTE_ATTRIB
            | select.KQ_NOTE_LINK
            | select.KQ_NOTE_RENAME
            | select.KQ_NOTE_REVOKE
        )
        registrations = [
            select.kevent(
                descriptor,
                filter=select.KQ_FILTER_VNODE,
                flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
                fflags=vnode_flags,
            )
            for descriptor in descriptors
        ]
        # Gli ancestor ospitano modifiche legittime ai figli: osserviamo la
        # sostituzione/revoca della directory, non le normali child writes.
        parent_flags = (
            select.KQ_NOTE_DELETE
            | select.KQ_NOTE_RENAME
            | select.KQ_NOTE_REVOKE
        )
        registrations.extend(
            select.kevent(
                ancestor,
                filter=select.KQ_FILTER_VNODE,
                flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
                fflags=parent_flags,
            )
            for ancestor in ancestors
        )
        registrations.append(
            select.kevent(
                sys.stdin.fileno(),
                filter=select.KQ_FILTER_READ,
                flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
            )
        )
        queue.control(registrations, 0, 0)
        initial_digest, _ = _collect_descriptor(root)
        current = os.stat(name, dir_fd=parent, follow_symlinks=False)
        if (
            initial_digest != expected_sha256
            or not stat.S_ISDIR(current.st_mode)
            or current.st_dev != root_metadata.st_dev
            or current.st_ino != root_metadata.st_ino
        ):
            raise ValueError("guard initial identity mismatch")
        print("IOS_ARTIFACT_GUARD_READY", flush=True)

        def event_changed(event: object) -> bool:
            if event.filter == select.KQ_FILTER_READ:
                return False
            non_attribute_flags = event.fflags & ~select.KQ_NOTE_ATTRIB
            if non_attribute_flags:
                return True
            if event.fflags & select.KQ_NOTE_ATTRIB:
                # Le letture possono aggiornare atime e generare NOTE_ATTRIB;
                # mode/ctime distinguono quelle letture da chmod/chown ABA.
                before = descriptor_states.get(event.ident)
                if before is None:
                    return True
                after = os.fstat(event.ident)
                current_state = (
                    after.st_dev,
                    after.st_ino,
                    after.st_mode,
                    getattr(
                        after,
                        "st_ctime_ns",
                        int(after.st_ctime * 1_000_000_000),
                    ),
                )
                return current_state != before
            return True

        changed = False
        stop = False
        while not stop:
            for event in queue.control(None, 64, None):
                if (
                    event.filter == select.KQ_FILTER_READ
                    and event.ident == sys.stdin.fileno()
                ):
                    if sys.stdin.buffer.readline(16) != b"STOP\n":
                        raise ValueError("guard command invalid")
                    stop = True
                elif event_changed(event):
                    changed = True
        for event in queue.control(None, 64, 0.05):
            if event_changed(event):
                changed = True
        final_digest, _ = _collect_descriptor(root)
        current = os.stat(name, dir_fd=parent, follow_symlinks=False)
        metadata_changed = any(
            (
                current_metadata.st_dev,
                current_metadata.st_ino,
                current_metadata.st_mode,
                getattr(
                    current_metadata,
                    "st_ctime_ns",
                    int(current_metadata.st_ctime * 1_000_000_000),
                ),
            )
            != descriptor_states[descriptor]
            for descriptor in descriptors
            for current_metadata in (os.fstat(descriptor),)
        )
        if (
            changed
            or metadata_changed
            or final_digest != expected_sha256
            or not _directory_chain_matches(
                ancestors, ancestor_components
            )
            or not stat.S_ISDIR(current.st_mode)
            or current.st_dev != root_metadata.st_dev
            or current.st_ino != root_metadata.st_ino
        ):
            raise ValueError("guard detected artifact change")
        print("IOS_ARTIFACT_GUARD_OK", flush=True)
    finally:
        if queue is not None:
            queue.close()
        for descriptor in reversed(descriptors):
            os.close(descriptor)
        if root is not None:
            os.close(root)
        for ancestor in reversed(ancestors):
            os.close(ancestor)


def main(arguments: list[str]) -> int:
    try:
        if len(arguments) == 1:
            print(attest(arguments[0]))
        elif len(arguments) == 3 and arguments[0] == "--snapshot":
            print(snapshot(arguments[1], arguments[2]))
        elif len(arguments) == 3 and arguments[0] == "--seal":
            tree_digest, payload_digest = seal(arguments[1], arguments[2])
            print(f"{tree_digest},{payload_digest}")
        elif len(arguments) == 4 and arguments[0] == "--seal-snapshot":
            tree_digest, payload_digest = seal(
                arguments[1], arguments[2], arguments[3]
            )
            print(f"{tree_digest},{payload_digest}")
        elif len(arguments) == 4 and arguments[0] == "--publish-seal":
            print(publish_seal(arguments[1], arguments[2], arguments[3]))
        elif len(arguments) == 4 and arguments[0] == "--extract":
            print(extract(arguments[1], arguments[2], arguments[3]))
        elif len(arguments) == 3 and arguments[0] == "--guard":
            guard(arguments[1], arguments[2])
        elif len(arguments) == 2 and arguments[0] == "--directory-identity":
            print(directory_identity(arguments[1]))
        elif len(arguments) == 2 and arguments[0] == "--create-temp-directory":
            print(create_temp_directory(arguments[1]))
        elif len(arguments) == 3 and arguments[0] == "--cleanup-directory":
            cleanup_directory(arguments[1], arguments[2])
        else:
            return 1
    except (
        OSError,
        UnicodeError,
        ValueError,
        OverflowError,
        MemoryError,
        RecursionError,
        zipfile.BadZipFile,
        zipfile.LargeZipFile,
        RuntimeError,
    ):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
