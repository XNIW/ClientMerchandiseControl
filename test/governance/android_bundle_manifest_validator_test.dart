import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _androidNamespace = 'http://schemas.android.com/apk/res/android';
const _packageName = 'com.xniw.clientmerchandisecontrol';

void main() {
  final repositoryRoot = Directory.current;

  test('accetta il manifest protobuf AAB canonico', () {
    final fixture = _writeManifestFixture(packageName: _packageName);
    addTearDown(() => fixture.parent.deleteSync(recursive: true));

    final result = Process.runSync('dart', <String>[
      '--disable-dart-dev',
      'tool/check_android_bundle_manifest.dart',
      '--manifest',
      fixture.path,
    ], workingDirectory: repositoryRoot.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('ANDROID_BUNDLE_MANIFEST_VALID'));
  });

  test('rifiuta identita AAB diversa senza esporre il valore', () {
    final unexpectedPackage = 'com.example.unapproved';
    final fixture = _writeManifestFixture(packageName: unexpectedPackage);
    addTearDown(() => fixture.parent.deleteSync(recursive: true));

    final result = Process.runSync('dart', <String>[
      '--disable-dart-dev',
      'tool/check_android_bundle_manifest.dart',
      '--manifest',
      fixture.path,
    ], workingDirectory: repositoryRoot.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('ANDROID_BUNDLE_MANIFEST_BLOCKED'));
    expect(result.stderr, isNot(contains(unexpectedPackage)));
  });

  test('rifiuta permission Android fuori allowlist', () {
    const unexpectedPermission = 'android.permission.READ_SMS';
    final fixture = _writeManifestFixture(
      packageName: _packageName,
      additionalManifestChildren: <List<int>>[
        _element(
          'uses-permission',
          attributes: <List<int>>[
            _attribute('name', unexpectedPermission, android: true),
          ],
        ),
      ],
    );
    addTearDown(() => fixture.parent.deleteSync(recursive: true));

    final result = Process.runSync('dart', <String>[
      '--disable-dart-dev',
      'tool/check_android_bundle_manifest.dart',
      '--manifest',
      fixture.path,
    ], workingDirectory: repositoryRoot.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('USES_PERMISSION_ALLOWLIST_INVALID'));
    expect(result.stderr, isNot(contains(unexpectedPermission)));
  });

  test('rifiuta alias uses-permission Android fuori allowlist', () {
    const unexpectedPermission = 'android.permission.READ_SMS';
    for (final alias in <String>[
      'uses-permission-sdk-23',
      'uses-permission-sdk-m',
    ]) {
      final fixture = _writeManifestFixture(
        packageName: _packageName,
        additionalManifestChildren: <List<int>>[
          _element(
            alias,
            attributes: <List<int>>[
              _attribute('name', unexpectedPermission, android: true),
            ],
          ),
        ],
      );
      addTearDown(() => fixture.parent.deleteSync(recursive: true));

      final result = Process.runSync('dart', <String>[
        '--disable-dart-dev',
        'tool/check_android_bundle_manifest.dart',
        '--manifest',
        fixture.path,
      ], workingDirectory: repositoryRoot.path);

      expect(result.exitCode, 1, reason: alias);
      expect(result.stderr, contains('USES_PERMISSION_ELEMENT_INVALID'));
      expect(result.stderr, isNot(contains(unexpectedPermission)));
    }
  });

  test('rifiuta component Android esportato fuori allowlist', () {
    const unexpectedComponent = 'com.example.UnsafeService';
    final fixture = _writeManifestFixture(
      packageName: _packageName,
      additionalApplicationChildren: <List<int>>[
        _element(
          'service',
          attributes: <List<int>>[
            _attribute('name', unexpectedComponent, android: true),
            _attribute('exported', 'true', android: true),
          ],
        ),
      ],
    );
    addTearDown(() => fixture.parent.deleteSync(recursive: true));

    final result = Process.runSync('dart', <String>[
      '--disable-dart-dev',
      'tool/check_android_bundle_manifest.dart',
      '--manifest',
      fixture.path,
    ], workingDirectory: repositoryRoot.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('EXPORTED_COMPONENT_ALLOWLIST_INVALID'));
    expect(result.stderr, isNot(contains(unexpectedComponent)));
  });
}

File _writeManifestFixture({
  required String packageName,
  List<List<int>> additionalManifestChildren = const <List<int>>[],
  List<List<int>> additionalApplicationChildren = const <List<int>>[],
}) {
  final directory = Directory.systemTemp.createTempSync(
    'cmc-android-bundle-manifest.',
  );
  final manifest = _element(
    'manifest',
    attributes: <List<int>>[
      _attribute('package', packageName),
      _attribute('versionName', '0.1.0', android: true),
      _attribute('versionCode', '1', android: true),
    ],
    children: <List<int>>[
      _element(
        'uses-sdk',
        attributes: <List<int>>[
          _attribute('minSdkVersion', '24', android: true),
          _attribute('targetSdkVersion', '36', android: true),
        ],
      ),
      _element(
        'uses-permission',
        attributes: <List<int>>[
          _attribute('name', 'android.permission.INTERNET', android: true),
        ],
      ),
      _element(
        'uses-permission',
        attributes: <List<int>>[
          _attribute(
            'name',
            'android.permission.ACCESS_NETWORK_STATE',
            android: true,
          ),
        ],
      ),
      _element(
        'permission',
        attributes: <List<int>>[
          _attribute(
            'name',
            '$_packageName.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
            android: true,
          ),
          _attribute('protectionLevel', 'signature', android: true),
        ],
      ),
      _element(
        'uses-permission',
        attributes: <List<int>>[
          _attribute(
            'name',
            '$_packageName.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
            android: true,
          ),
        ],
      ),
      ...additionalManifestChildren,
      _element(
        'application',
        attributes: <List<int>>[
          _attribute('allowBackup', 'false', android: true),
          _attribute('usesCleartextTraffic', 'false', android: true),
          _attribute(
            'networkSecurityConfig',
            '@xml/network_security_config',
            android: true,
          ),
        ],
        children: <List<int>>[
          _element(
            'meta-data',
            attributes: <List<int>>[
              _attribute(
                'name',
                'com.google.android.geo.API_KEY',
                android: true,
              ),
              _attribute('value', 'NOT_CONFIGURED', android: true),
            ],
          ),
          _element(
            'activity',
            attributes: <List<int>>[
              _attribute('name', '$_packageName.MainActivity', android: true),
              _attribute('exported', 'true', android: true),
            ],
            children: <List<int>>[
              _element(
                'intent-filter',
                children: <List<int>>[
                  _element(
                    'data',
                    attributes: <List<int>>[
                      _attribute('scheme', _packageName, android: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _element(
            'receiver',
            attributes: <List<int>>[
              _attribute(
                'name',
                'androidx.profileinstaller.ProfileInstallReceiver',
                android: true,
              ),
              _attribute('exported', 'true', android: true),
              _attribute(
                'permission',
                'android.permission.DUMP',
                android: true,
              ),
            ],
          ),
          ...additionalApplicationChildren,
        ],
      ),
    ],
  );
  final file = File('${directory.path}/AndroidManifest.xml');
  file.writeAsBytesSync(_fieldBytes(1, manifest));
  return file;
}

List<int> _element(
  String name, {
  List<List<int>> attributes = const <List<int>>[],
  List<List<int>> children = const <List<int>>[],
}) {
  return <int>[
    ..._fieldString(3, name),
    for (final attribute in attributes) ..._fieldBytes(4, attribute),
    for (final child in children) ..._fieldBytes(5, _fieldBytes(1, child)),
  ];
}

List<int> _attribute(String name, String value, {bool android = false}) {
  return <int>[
    if (android) ..._fieldString(1, _androidNamespace),
    ..._fieldString(2, name),
    ..._fieldString(3, value),
  ];
}

List<int> _fieldString(int number, String value) =>
    _fieldBytes(number, utf8.encode(value));

List<int> _fieldBytes(int number, List<int> value) => <int>[
  ..._varint((number << 3) | 2),
  ..._varint(value.length),
  ...value,
];

List<int> _varint(int value) {
  final bytes = <int>[];
  var remaining = value;
  do {
    var byte = remaining & 0x7f;
    remaining >>= 7;
    if (remaining != 0) {
      byte |= 0x80;
    }
    bytes.add(byte);
  } while (remaining != 0);
  return bytes;
}
