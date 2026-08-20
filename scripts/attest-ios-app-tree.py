#!/usr/bin/env python3
"""Attesta, copia e sigilla in modo bounded un bundle iOS."""

from __future__ import annotations

import hashlib
import os
import posixpath
import re
import stat
import struct
import sys
import zipfile
from typing import Optional


MAX_ENTRIES = 4_096
MAX_DEPTH = 64
MAX_FILE_BYTES = 134_217_728
MAX_TOTAL_BYTES = 536_870_912
MAX_SEAL_BYTES = 603_979_776
MAX_CENTRAL_DIRECTORY_BYTES = 16_777_216
MAX_PATH_BYTES = 4_096
CHUNK_BYTES = 65_536
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")

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


def _clear_directory(directory: int, depth: int = 0) -> None:
    if depth > MAX_DEPTH + 1:
        raise ValueError("cleanup depth exceeded")
    with os.scandir(directory) as iterator:
        names = [entry.name for entry in iterator]
    for name in names:
        metadata = os.stat(name, dir_fd=directory, follow_symlinks=False)
        if stat.S_ISDIR(metadata.st_mode):
            child = os.open(
                name,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=directory,
            )
            try:
                _clear_directory(child, depth + 1)
            finally:
                os.close(child)
            os.rmdir(name, dir_fd=directory)
        else:
            os.unlink(name, dir_fd=directory)


def _cleanup_created_directory(
    parent: int,
    name: str,
    identity: Optional[tuple[int, int]],
) -> None:
    if identity is None:
        return
    try:
        current = os.stat(name, dir_fd=parent, follow_symlinks=False)
        if (
            not stat.S_ISDIR(current.st_mode)
            or (current.st_dev, current.st_ino) != identity
        ):
            return
        directory = os.open(
            name,
            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
            dir_fd=parent,
        )
        try:
            _clear_directory(directory)
        finally:
            os.close(directory)
        os.rmdir(name, dir_fd=parent)
    except OSError:
        pass


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
        if target is not None:
            os.close(target)
        if not completed and parent is not None:
            _cleanup_created_directory(parent, name, target_identity)
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


def _preflight_zip_descriptor(payload: int) -> None:
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


def _extract_descriptor(
    payload: int,
    expected_sha256: str,
    destination: str,
) -> str:
    if _hash_descriptor(payload, MAX_SEAL_BYTES) != expected_sha256:
        raise ValueError("sealed payload digest mismatch")
    _preflight_zip_descriptor(payload)
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
        with os.fdopen(os.dup(payload), "rb") as stream:
            os.lseek(stream.fileno(), 0, os.SEEK_SET)
            with zipfile.ZipFile(stream, mode="r") as archive:
                infos = archive.infolist()
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
        if _hash_descriptor(payload, MAX_SEAL_BYTES) != expected_sha256:
            raise ValueError("sealed payload changed during extraction")
        digest, _ = _collect_descriptor(target)
        os.fsync(parent)
        completed = True
        return digest
    finally:
        if target is not None:
            os.close(target)
        if not completed and parent is not None:
            _cleanup_created_directory(parent, name, target_identity)
        if parent is not None:
            os.close(parent)


def extract(payload_path: str, expected_sha256: str, destination: str) -> str:
    if not SHA256_PATTERN.fullmatch(expected_sha256):
        raise ValueError("invalid expected digest")
    payload = _open_absolute_regular(payload_path)
    try:
        return _extract_descriptor(payload, expected_sha256, destination)
    finally:
        os.close(payload)


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
