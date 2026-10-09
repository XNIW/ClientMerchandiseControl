#!/usr/bin/env python3
"""Verifica il callback TEST sul manifest XML effettivo dell'APK."""
import argparse
import re
import sys
import xml.etree.ElementTree as ET

ANDROID = '{http://schemas.android.com/apk/res/android}'
PACKAGE = 'com.xniw.clientmerchandisecontrol'
MAX_BYTES = 1024 * 1024


def verify(payload, host):
    if (not payload or len(payload) > MAX_BYTES or b'<!DOCTYPE' in payload.upper()
            or b'<!ENTITY' in payload.upper()
            or not re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}', host)
            or re.search(r'\.(invalid|localhost|test|example)$', host)):
        return False
    try:
        root = ET.fromstring(payload)
    except (ET.ParseError, ValueError, LookupError):
        return False
    if root.tag != 'manifest' or root.get('package') != PACKAGE:
        return False
    applications = root.findall('application')
    if len(applications) != 1:
        return False
    activities = [activity for activity in applications[0].findall('activity')
                  if activity.get(ANDROID + 'name') == PACKAGE + '.MainActivity']
    if len(activities) != 1 or activities[0].get(ANDROID + 'exported') != 'true':
        return False
    filters = [element for element in activities[0].findall('intent-filter')
               if any(data.get(ANDROID + 'scheme') == 'https'
                      for data in element.iter('data'))]
    if len(filters) != 1:
        return False
    callback = filters[0]
    if callback.attrib != {ANDROID + 'autoVerify': 'true'} or len(callback) != 4:
        return False
    data = callback.findall('data')
    actions = callback.findall('action')
    categories = callback.findall('category')
    return (len(data) == 1 and data[0].attrib == {
        ANDROID + 'scheme': 'https', ANDROID + 'host': host,
        ANDROID + 'path': '/auth-callback/',
    } and len(actions) == 1 and actions[0].attrib == {
        ANDROID + 'name': 'android.intent.action.VIEW',
    } and len(categories) == 2 and all(len(category.attrib) == 1 for category in categories)
        and {category.get(ANDROID + 'name') for category in categories} == {
            'android.intent.category.DEFAULT', 'android.intent.category.BROWSABLE',
        })


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host', required=True)
    args = parser.parse_args()
    if not verify(sys.stdin.buffer.read(MAX_BYTES + 1), args.host):
        print('ANDROID_RELEASE_BLOCKED: TEST_APK_CALLBACK_BINDING_INVALID', file=sys.stderr)
        return 1
    print('ANDROID_TEST_APK_CALLBACK_BOUND')
    return 0


if __name__ == '__main__':
    sys.exit(main())
