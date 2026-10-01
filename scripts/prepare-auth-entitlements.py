#!/usr/bin/env python3
"""Genera soltanto gli entitlement del callback staging da define già approvati."""
import base64
import os
from pathlib import Path
import plistlib
import re
import sys


def entitlements(encoded):
    values = {}
    for item in filter(None, encoded.split(',')):
        key, value = base64.b64decode(item, validate=True).decode('utf-8').split('=', 1)
        if key in values:
            raise ValueError('duplicate_define')
        values[key] = value
    if values.get('GOOGLE_AUTH_ENABLED') != 'true':
        return {}
    host = values.get('AUTH_CALLBACK_VERIFIED_HOST', '')
    if (values.get('APP_ENV') != 'staging' or
            not re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}', host) or
            re.search(r'\.(invalid|localhost|test|example)$', host) or
            values.get('AUTH_REDIRECT_URI') != f'https://{host}/auth-callback/'):
        raise ValueError('unapproved_callback_binding')
    return {'com.apple.developer.associated-domains': [f'applinks:{host}']}


if __name__ == '__main__':
    try:
        output = Path(os.environ['SCRIPT_OUTPUT_FILE_0'])
        checking = sys.argv[1:] == ['--check']
        if sys.argv[1:] not in ([], ['--check']):
            raise ValueError('unsupported_arguments')
        if not checking:
            # Non lasciare un entitlement precedente utilizzabile dopo config invalida.
            output.unlink(missing_ok=True)
        payload = entitlements(os.environ.get('DART_DEFINES', ''))
        if checking:
            if plistlib.loads(output.read_bytes()) != payload:
                raise ValueError('stale_native_binding')
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(plistlib.dumps(payload))
    except (KeyError, ValueError, OSError):
        raise SystemExit('AUTH_NATIVE_BINDING_INVALID') from None
