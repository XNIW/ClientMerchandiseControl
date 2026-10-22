#!/usr/bin/env python3
"""Verifica il grant iOS TEST e il callback dell'app già firmata."""
import argparse
from pathlib import Path
import plistlib
import re
import sys

KEY = 'com.apple.developer.associated-domains'


def verify(entitlements, profile, host):
    if (not re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}', host)
            or re.search(r'\.(invalid|localhost|test|example)$', host)):
        return False
    expected = ['applinks:' + host]
    if not isinstance(entitlements, dict) or entitlements.get(KEY) != expected:
        return False
    grants = profile.get('Entitlements') if isinstance(profile, dict) else None
    if not isinstance(grants, dict):
        return False
    return grants.get(KEY) in (expected, ['*'], '*')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--entitlements', required=True, type=Path)
    parser.add_argument('--profile', required=True, type=Path)
    parser.add_argument('--host', required=True)
    args = parser.parse_args()
    try:
        entitlements = plistlib.loads(args.entitlements.read_bytes())
        profile = plistlib.loads(args.profile.read_bytes())
        valid = verify(entitlements, profile, args.host)
    except (OSError, ValueError, plistlib.InvalidFileException):
        valid = False
    if not valid:
        print('IOS_RELEASE_BLOCKED: TEST_CALLBACK_BINDING_INVALID', file=sys.stderr)
        return 1
    print('IOS_TEST_NATIVE_CALLBACK_BINDING_VALIDATED')
    return 0


if __name__ == '__main__':
    sys.exit(main())
