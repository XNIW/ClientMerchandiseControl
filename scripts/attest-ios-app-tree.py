#!/usr/bin/env python3
"""Calcola un digest exact-content bounded di un bundle iOS."""

from __future__ import annotations

import hashlib
import os
import stat
import sys
from typing import Optional


MAX_FILES = 4_096
MAX_FILE_BYTES = 134_217_728
MAX_TOTAL_BYTES = 536_870_912


def _stable_times(value: os.stat_result) -> tuple[int, int]:
    return (
        getattr(value, "st_mtime_ns", int(value.st_mtime * 1_000_000_000)),
        getattr(value, "st_ctime_ns", int(value.st_ctime * 1_000_000_000)),
    )


def _read_regular(
    directory: int,
    name: str,
    remaining_total: int,
) -> tuple[os.stat_result, bytes]:
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
            or before.st_size < 0
            or before.st_size > MAX_FILE_BYTES
            or before.st_size > remaining_total
        ):
            raise ValueError("invalid file")
        digest = hashlib.sha256()
        remaining = MAX_FILE_BYTES + 1
        length = 0
        while remaining > 0:
            chunk = os.read(descriptor, min(65_536, remaining))
            if not chunk:
                break
            digest.update(chunk)
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
        return before, digest.digest()
    finally:
        if descriptor is not None:
            os.close(descriptor)


def _walk(
    directory: int,
    relative: str,
    records: list[tuple[bytes, int, int, bytes]],
    budget: list[int],
) -> None:
    before = os.fstat(directory)
    names: list[str] = []
    with os.scandir(directory) as iterator:
        for entry in iterator:
            names.append(entry.name)
            budget[0] += 1
            if budget[0] > MAX_FILES:
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
            try:
                _walk(child, child_relative, records, budget)
            finally:
                os.close(child)
        elif stat.S_ISREG(metadata.st_mode):
            stable, digest = _read_regular(
                directory,
                name,
                MAX_TOTAL_BYTES - budget[1],
            )
            budget[1] += stable.st_size
            records.append(
                (
                    child_relative.encode("utf-8"),
                    stable.st_mode & 0o7777,
                    stable.st_size,
                    digest,
                )
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


def attest(path: str) -> str:
    if (
        not os.path.isabs(path)
        or os.path.normpath(path) != path
        or os.path.islink(path)
        or not hasattr(os, "O_DIRECTORY")
        or not hasattr(os, "O_NOFOLLOW")
        or not hasattr(os, "O_NONBLOCK")
    ):
        raise ValueError("non-canonical root")
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        records: list[tuple[bytes, int, int, bytes]] = []
        budget = [0, 0]
        _walk(descriptor, "", records, budget)
    finally:
        os.close(descriptor)
    output = hashlib.sha256()
    for relative, mode, length, digest in sorted(records):
        output.update(relative)
        output.update(b"\0")
        output.update(f"{mode:o}".encode("ascii"))
        output.update(b"\0")
        output.update(str(length).encode("ascii"))
        output.update(b"\0")
        output.update(digest.hex().encode("ascii"))
        output.update(b"\0")
    return output.hexdigest()


def main(arguments: list[str]) -> int:
    if len(arguments) != 1:
        return 1
    try:
        print(attest(arguments[0]))
    except (OSError, UnicodeError, ValueError, OverflowError, MemoryError):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
