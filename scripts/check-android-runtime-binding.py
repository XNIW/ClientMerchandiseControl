#!/usr/bin/env python3
"""Verifica il fingerprint runtime in tutte le ABI del candidato AAB."""
import argparse
from pathlib import Path
import re
import sys
import zipfile

ABIS = ('arm64-v8a', 'armeabi-v7a', 'x86_64')
MARKER = b'CMC_RELEASE_CONFIG_ATTESTATION_V1:'


def verify(path, fingerprint):
    if not re.fullmatch(r'[0-9a-f]{64}', fingerprint):
        return False
    expected = MARKER + fingerprint.encode('ascii')
    try:
        with zipfile.ZipFile(path) as archive:
            for abi in ABIS:
                name = 'base/lib/' + abi + '/libapp.so'
                if archive.namelist().count(name) != 1:
                    return False
                payload = archive.read(name)
                markers = re.findall(MARKER + rb'[0-9a-f]{64}', payload)
                if markers != [expected]:
                    return False
        return True
    except (OSError, KeyError, zipfile.BadZipFile, RuntimeError):
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aab', required=True, type=Path)
    parser.add_argument('--fingerprint', required=True)
    args = parser.parse_args()
    if not verify(args.aab, args.fingerprint):
        print('ANDROID_RELEASE_BLOCKED: RUNTIME_CONFIG_NOT_ARTIFACT_BOUND')
        return 1
    print('ANDROID_RUNTIME_BINDING PASS abis=3')
    return 0


if __name__ == '__main__':
    sys.exit(main())
