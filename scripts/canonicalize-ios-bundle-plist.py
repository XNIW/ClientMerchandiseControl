#!/usr/bin/env python3
"""Canonicalizza in modo bounded gli Info.plist dei resource bundle iOS."""

from __future__ import annotations

import hashlib
import errno
import os
import plistlib
import stat
import struct
import sys
import xml.parsers.expat
from collections.abc import Mapping, Sequence
from typing import Optional


MAX_INPUT_BYTES = 1_048_576
MAX_CANONICAL_BYTES = 4_194_304
MAX_STRUCTURE_OBJECTS = 16_384


def _read_bounded_regular_file(path: str) -> bytes:
    if (
        not os.path.isabs(path)
        or os.path.normpath(path) != path
        or not hasattr(os, "O_DIRECTORY")
        or not hasattr(os, "O_NOFOLLOW")
    ):
        raise ValueError("non-canonical path")
    components = path.split(os.sep)[1:]
    if not components or any(
        component in ("", ".", "..") for component in components
    ):
        raise ValueError("non-canonical path")

    directory_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    file_flags = os.O_RDONLY | os.O_NOFOLLOW
    directory_descriptor: Optional[int] = os.open(os.sep, directory_flags)
    descriptor: Optional[int] = None
    try:
        for component in components[:-1]:
            try:
                next_descriptor = os.open(
                    component,
                    directory_flags,
                    dir_fd=directory_descriptor,
                )
            except OSError as error:
                if error.errno in (errno.ELOOP, errno.ENOTDIR):
                    raise ValueError("non-canonical path") from error
                raise
            os.close(directory_descriptor)
            directory_descriptor = next_descriptor
        descriptor = os.open(
            components[-1],
            file_flags,
            dir_fd=directory_descriptor,
        )
        before = os.fstat(descriptor)
        if (
            not stat.S_ISREG(before.st_mode)
            or before.st_size < 1
            or before.st_size > MAX_INPUT_BYTES
        ):
            raise ValueError("invalid input")
        chunks: list[bytes] = []
        remaining = MAX_INPUT_BYTES + 1
        while remaining > 0:
            chunk = os.read(descriptor, min(65_536, remaining))
            if not chunk:
                break
            chunks.append(chunk)
            remaining -= len(chunk)
        payload = b"".join(chunks)
        if len(payload) > MAX_INPUT_BYTES or os.read(descriptor, 1):
            raise ValueError("input exceeds limit")
        after = os.fstat(descriptor)
        before_mtime = getattr(
            before,
            "st_mtime_ns",
            int(before.st_mtime * 1_000_000_000),
        )
        after_mtime = getattr(
            after,
            "st_mtime_ns",
            int(after.st_mtime * 1_000_000_000),
        )
        if (
            len(payload) != before.st_size
            or before.st_dev != after.st_dev
            or before.st_ino != after.st_ino
            or before.st_size != after.st_size
            or before_mtime != after_mtime
        ):
            raise ValueError("input changed during read")
        return payload
    finally:
        if descriptor is not None:
            os.close(descriptor)
        if directory_descriptor is not None:
            os.close(directory_descriptor)


def _validate_graph(root: object) -> None:
    pending = [root]
    visited_containers: set[int] = set()
    while pending:
        value = pending.pop()
        if isinstance(value, Mapping):
            identity = id(value)
            if identity in visited_containers:
                continue
            visited_containers.add(identity)
            if len(visited_containers) > MAX_STRUCTURE_OBJECTS:
                raise ValueError("too many containers")
            if any(not isinstance(key, str) for key in value):
                raise ValueError("non-string dictionary key")
            pending.extend(value.values())
        elif isinstance(value, Sequence) and not isinstance(
            value, (str, bytes, bytearray)
        ):
            identity = id(value)
            if identity in visited_containers:
                continue
            visited_containers.add(identity)
            if len(visited_containers) > MAX_STRUCTURE_OBJECTS:
                raise ValueError("too many containers")
            pending.extend(value)


def _preflight_structure(source: bytes) -> None:
    if source.startswith(b"bplist00"):
        if len(source) < 40:
            raise ValueError("binary plist too short")
        offset_size, reference_size, object_count, root_index, offset_start = (
            struct.unpack(">6xBBQQQ", source[-32:])
        )
        if (
            offset_size not in range(1, 9)
            or reference_size not in range(1, 9)
            or object_count < 1
            or object_count > MAX_STRUCTURE_OBJECTS
            or root_index >= object_count
            or offset_start < 8
            or offset_start + object_count * offset_size > len(source) - 32
        ):
            raise ValueError("invalid binary plist structure")
        return

    element_count = 0

    def count_element(_name: str, _attributes: dict[str, str]) -> None:
        nonlocal element_count
        element_count += 1
        if element_count > MAX_STRUCTURE_OBJECTS:
            raise ValueError("too many XML elements")

    parser = xml.parsers.expat.ParserCreate()
    parser.StartElementHandler = count_element
    parser.ExternalEntityRefHandler = lambda *_arguments: 0
    parser.Parse(source, True)


def _load_canonical(path: str) -> tuple[dict[str, object], bytes]:
    source = _read_bounded_regular_file(path)
    _preflight_structure(source)
    payload = plistlib.loads(source)
    if not isinstance(payload, dict):
        raise ValueError("root must be a dictionary")
    _validate_graph(payload)
    payload.pop("BuildMachineOSBuild", None)
    canonical = plistlib.dumps(
        payload,
        fmt=plistlib.FMT_BINARY,
        sort_keys=True,
    )
    if len(canonical) > MAX_CANONICAL_BYTES:
        raise ValueError("canonical output exceeds limit")
    return payload, canonical


def main(arguments: list[str]) -> int:
    try:
        if len(arguments) == 2 and arguments[0] == "--digest":
            _, canonical = _load_canonical(arguments[1])
            print(hashlib.sha256(canonical).hexdigest())
            return 0
        if len(arguments) == 4 and arguments[0] == "--validate-identity":
            payload, _ = _load_canonical(arguments[1])
            if (
                payload.get("CFBundleIdentifier") != arguments[2]
                or payload.get("CFBundlePackageType") != arguments[3]
            ):
                return 1
            return 0
    except (
        OSError,
        ValueError,
        TypeError,
        OverflowError,
        RecursionError,
        MemoryError,
        plistlib.InvalidFileException,
        xml.parsers.expat.ExpatError,
    ):
        return 1
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
