import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final repositoryRoot = Directory.current.path;

  test('iOS release source uses canonical identity and Release archive', () {
    final project = File(
      '$repositoryRoot/ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final scheme = File(
      '$repositoryRoot/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    ).readAsStringSync();

    expect(
      project,
      contains(
        'PRODUCT_BUNDLE_IDENTIFIER = com.xniw.clientmerchandisecontrol;',
      ),
    );
    expect(project, contains('CURRENT_PROJECT_VERSION = 1;'));
    expect(project, contains('DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'));
    expect(scheme, contains('buildForArchiving = "YES"'));
    expect(scheme, contains('buildConfiguration = "Release"'));
  });

  test('production-like configuration remains public and fail-closed', () {
    final values =
        jsonDecode(
              File(
                '$repositoryRoot/config/app_config.production.release.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final releaseConfig = File(
      '$repositoryRoot/ios/Flutter/Release.xcconfig',
    ).readAsStringSync();

    expect(values['APP_ENV'], 'production');
    expect(values['GOOGLE_AUTH_ENABLED'], 'false');
    expect(values['DELIVERY_MAPS_ENABLED'], 'false');
    expect(values['DELIVERY_MAPS_NATIVE_CONFIGURED'], 'false');
    expect(values, isNot(contains('SUPABASE_URL')));
    expect(values, isNot(contains('SUPABASE_PUBLISHABLE_KEY')));
    expect(values, isNot(contains('AUTH_REDIRECT_URI')));
    expect(values, isNot(contains('STOREFRONT_SHOP_SLUG')));
    expect(releaseConfig, contains('IOS_GOOGLE_MAPS_API_KEY=NOT_CONFIGURED'));
  });

  test('native callback is bounded and provider deep linking is disabled', () {
    final info = File(
      '$repositoryRoot/ios/Runner/Info.plist',
    ).readAsStringSync();
    final entitlements = Directory('$repositoryRoot/ios/Runner')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.entitlements'));

    expect(
      info,
      contains('<string>com.xniw.clientmerchandisecontrol</string>'),
    );
    expect(info, contains('<key>FlutterDeepLinkingEnabled</key>'));
    expect(info, contains('<false/>'));
    expect(entitlements, isEmpty);
  });

  test('release validator binds app archive dSYM privacy and security', () {
    final validator = File(
      '$repositoryRoot/scripts/check-ios-release.sh',
    ).readAsStringSync();

    expect(validator, contains('ARTIFACT_BUNDLE_IDENTIFIER_MISMATCH'));
    expect(validator, contains('APP_PRIVACY_MANIFEST_MISMATCH'));
    expect(validator, contains('DEPENDENCY_PRIVACY_MANIFEST_MISSING'));
    expect(validator, contains('ARCHIVE_DSYM_UUID_MISMATCH'));
    expect(validator, contains('APP_ARCHIVE_BUNDLE_MISMATCH'));
    expect(validator, contains('APP_EXECUTABLE_NAME_INVALID'));
    expect(validator, contains('ARTIFACT_SIGNATURE_INVALID'));
    expect(validator, contains('SIGNED_ENTITLEMENT_SET_INVALID'));
    expect(
      validator,
      contains(r'${cmc_ios_release_app}/Frameworks/App.framework/App'),
    );
    expect(validator, contains('MAPS_ARTIFACT_NOT_FAIL_CLOSED'));
    expect(validator, contains('check-client-security.sh'));
    expect(validator, isNot(contains('/Users/')));
  });

  test('TestFlight gate validates distribution identity and profile', () {
    final validator = File(
      '$repositoryRoot/scripts/check-ios-release.sh',
    ).readAsStringSync();

    for (final boundary in <String>[
      'TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE',
      'TESTFLIGHT_PROVISIONING_PROFILE_MISSING',
      'APPLE_DISTRIBUTION_CERTIFICATE_REQUIRED',
      'SIGNING_FINGERPRINT_MISMATCH',
      'PROVISIONING_TEAM_MISMATCH',
      'APP_STORE_PROVISIONING_PROFILE_REQUIRED',
      'SIGNED_APPLICATION_IDENTIFIER_MISMATCH',
      'DEVELOPMENT_PROVISIONING_PROFILE_REJECTED',
      'APP_STORE_CONNECT_API_KEY_INVALID',
      'TESTFLIGHT_RUNTIME_CONFIG_MISSING',
      'TESTFLIGHT_RUNTIME_CONFIG_NOT_ARTIFACT_BOUND',
      'IOS_TESTFLIGHT_UPLOAD_INPUTS_VALIDATED',
    ]) {
      expect(validator, contains(boundary), reason: boundary);
    }
  });

  test('CI builds and validates an unsigned Release archive', () {
    final workflow = File(
      '$repositoryRoot/.github/workflows/ci.yml',
    ).readAsStringSync();
    expect(() => _validateIosReleaseJob(workflow), returnsNormally);
  });

  test(
    'CI release evidence cannot be satisfied by comments outside the job',
    () {
      const workflow = '''
jobs:
  quality:
    runs-on: ubuntu-latest
# ios-release:
# iOS release candidate
# flutter build ios --release --no-codesign
# xcodebuild archive
# check-ios-release.sh
# CODE_SIGNING_ALLOWED=NO
''';

      expect(
        () => _validateIosReleaseJob(workflow),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('CI release gate rejects source-only or duplicate jobs', () {
    const sourceOnly = '''
jobs:
  ios-release:
    name: iOS release candidate
    runs-on: macos-latest
    steps:
      - run: bash scripts/check-ios-release.sh --source-only
''';
    expect(
      () => _validateIosReleaseJob(sourceOnly),
      throwsA(isA<StateError>()),
    );

    final workflow = File(
      '$repositoryRoot/.github/workflows/ci.yml',
    ).readAsStringSync();
    final duplicate = '$workflow\n  ios-release:\n    runs-on: macos-latest\n';
    expect(() => _validateIosReleaseJob(duplicate), throwsA(isA<StateError>()));
  });

  test('CI release gate rejects sentinel strings in a no-op step', () {
    const workflow = '''
jobs:
  ios-release:
    name: iOS release candidate
    runs-on: macos-latest
    timeout-minutes: 45
    steps:
      - name: No-op release evidence
        run: |
          : "bash scripts/check-ios-release.sh --source-only"
          : "flutter build ios --release --no-codesign --dart-define-from-file=config/app_config.production.release.json"
          : "xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/ios/archive/Runner.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO"
          : "bash scripts/check-ios-release.sh --app build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app --archive build/ios/archive/Runner.xcarchive"
          : "bash scripts/test-ios-release-validator.sh --archive build/ios/archive/Runner.xcarchive"
''';

    expect(() => _validateIosReleaseJob(workflow), throwsA(isA<StateError>()));
  });

  test('CI release gate rejects workflow job and step execution overrides', () {
    final workflow = File(
      '$repositoryRoot/.github/workflows/ci.yml',
    ).readAsStringSync();
    const candidateStep = '      - name: Validate iOS release candidate\n';
    expect(workflow, contains(candidateStep));

    final mutations = <String>[
      workflow.replaceFirst(
        '    timeout-minutes: 45\n',
        '    timeout-minutes: 45\n    if: false\n',
      ),
      workflow.replaceFirst(candidateStep, '$candidateStep        if: false\n'),
      workflow.replaceFirst(
        candidateStep,
        '$candidateStep        continue-on-error: true\n',
      ),
      workflow.replaceFirst(
        candidateStep,
        '$candidateStep        shell: python\n',
      ),
      workflow.replaceFirst(
        'jobs:\n',
        'defaults:\n  run:\n    shell: echo {0}\njobs:\n',
      ),
      workflow.replaceFirst(
        'jobs:\n',
        'defaults:\n  run:\n    working-directory: .\njobs:\n',
      ),
      workflow.replaceFirst(
        'env:\n  FLUTTER_VERSION: 3.44.8\n',
        'env:\n  FLUTTER_VERSION: 3.44.8\n  BASH_ENV: .github/noop.sh\n',
      ),
      workflow.replaceFirst(
        'env:\n  FLUTTER_VERSION: 3.44.8\n',
        'env:\n  FLUTTER_VERSION: 3.44.8\n  ENV: .github/noop.sh\n',
      ),
      workflow.replaceFirst(
        '      - name: Validate iOS release source\n',
        '      - name: Poison release environment\n'
            '        run: echo BASH_ENV=.github/noop.sh >> "\$GITHUB_ENV"\n'
            '      - name: Validate iOS release source\n',
      ),
      workflow.replaceFirst(
        '  pull_request:\n    branches:\n      - main\n',
        '',
      ),
    ];

    for (final mutation in mutations) {
      expect(
        () => _validateIosReleaseJob(mutation),
        throwsA(isA<StateError>()),
      );
    }
  });
}

void _validateIosReleaseJob(String workflow) {
  final Object? document;
  try {
    document = loadYaml(workflow);
  } on YamlException catch (error) {
    throw StateError('workflow YAML invalid: $error');
  }
  if (document is! YamlMap || document['jobs'] is! YamlMap) {
    throw StateError('workflow jobs missing');
  }
  const allowedWorkflowKeys = <String>{
    'name',
    'on',
    'concurrency',
    'permissions',
    'env',
    'jobs',
  };
  final workflowKeys = document.keys.map((key) => key.toString()).toSet();
  final workflowEnv = document['env'];
  if (workflowKeys.length != allowedWorkflowKeys.length ||
      !workflowKeys.containsAll(allowedWorkflowKeys) ||
      workflowEnv is! YamlMap ||
      workflowEnv.length != 1 ||
      workflowEnv['FLUTTER_VERSION'] != '3.44.8') {
    throw StateError('workflow execution boundary invalid');
  }
  final triggers = document['on'];
  final permissions = document['permissions'];
  final concurrency = document['concurrency'];
  if (document['name'] != 'CI' ||
      triggers is! YamlMap ||
      !_hasExactKeys(triggers, const <String>{
        'pull_request',
        'push',
        'workflow_dispatch',
      }) ||
      !_isMainBranchTrigger(triggers['pull_request']) ||
      !_isMainBranchTrigger(triggers['push']) ||
      triggers['workflow_dispatch'] != null ||
      permissions is! YamlMap ||
      !_hasExactKeys(permissions, const <String>{'contents'}) ||
      permissions['contents'] != 'read' ||
      concurrency is! YamlMap ||
      !_hasExactKeys(concurrency, const <String>{
        'group',
        'cancel-in-progress',
      }) ||
      concurrency['group'] != r'ci-${{ github.workflow }}-${{ github.ref }}' ||
      concurrency['cancel-in-progress'] != true) {
    throw StateError('workflow trigger or permission boundary invalid');
  }
  final jobs = document['jobs'] as YamlMap;
  if (!jobs.containsKey('ios-release') || jobs['ios-release'] is! YamlMap) {
    throw StateError('ios-release job missing');
  }
  final job = jobs['ios-release'] as YamlMap;
  const allowedJobKeys = <String>{
    'name',
    'runs-on',
    'timeout-minutes',
    'steps',
  };
  final jobKeys = job.keys.map((key) => key.toString()).toSet();
  if (job['name'] != 'iOS release candidate' ||
      job['runs-on'] != 'macos-latest' ||
      job['timeout-minutes'] != 45 ||
      job['steps'] is! YamlList ||
      jobKeys.length != allowedJobKeys.length ||
      !jobKeys.containsAll(allowedJobKeys)) {
    throw StateError('ios-release job metadata invalid');
  }

  final rawSteps = job['steps'] as YamlList;
  final steps = rawSteps.whereType<YamlMap>().toList();
  if (rawSteps.length != 9 || steps.length != 9) {
    throw StateError('ios-release step set invalid');
  }
  _requireStep(
    steps[0],
    name: 'Checkout',
    keys: const <String>{'name', 'uses'},
    uses: 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1',
  );
  _requireStep(
    steps[1],
    name: 'Set up Flutter',
    keys: const <String>{'name', 'uses', 'with'},
    uses: 'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
  );
  final flutterWith = steps[1]['with'];
  if (flutterWith is! YamlMap ||
      !_hasExactKeys(flutterWith, const <String>{
        'flutter-version',
        'channel',
      }) ||
      flutterWith['flutter-version'] != r'${{ env.FLUTTER_VERSION }}' ||
      flutterWith['channel'] != 'stable') {
    throw StateError('iOS Flutter setup invalid');
  }
  _requireStep(
    steps[2],
    name: 'Validate Flutter toolchain',
    keys: const <String>{'name', 'run'},
    run: 'bash scripts/resolve-flutter.sh',
  );
  _requireStep(
    steps[3],
    name: 'Resolve dependencies',
    keys: const <String>{'name', 'run'},
    run: 'flutter pub get --enforce-lockfile',
  );
  const required = <String, String>{
    'Validate iOS release source':
        'bash scripts/check-ios-release.sh --source-only',
    'Build production-like unsigned iOS app':
        'flutter build ios --release --no-codesign '
        '--dart-define-from-file=config/app_config.production.release.json',
    'Archive production-like unsigned iOS app':
        'xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner '
        '-configuration Release -destination \'generic/platform=iOS\' '
        '-archivePath build/ios/archive/Runner.xcarchive '
        'CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO '
        'COMPILER_INDEX_STORE_ENABLE=NO',
    'Validate iOS release candidate':
        'bash scripts/check-ios-release.sh '
        '--app build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app '
        '--archive build/ios/archive/Runner.xcarchive '
        '--reference-app build/ios/iphoneos/Runner.app',
    'Validate iOS adversarial release boundaries':
        'bash scripts/test-ios-release-validator.sh '
        '--archive build/ios/archive/Runner.xcarchive '
        '--reference-app build/ios/iphoneos/Runner.app',
  };

  for (final indexed in required.entries.indexed) {
    _requireStep(
      steps[indexed.$1 + 4],
      name: indexed.$2.key,
      keys: const <String>{'name', 'run'},
      run: indexed.$2.value,
    );
  }
}

bool _hasExactKeys(YamlMap map, Set<String> expected) {
  final keys = map.keys.map((key) => key.toString()).toSet();
  return keys.length == expected.length && keys.containsAll(expected);
}

bool _isMainBranchTrigger(Object? value) {
  if (value is! YamlMap || !_hasExactKeys(value, const <String>{'branches'})) {
    return false;
  }
  final branches = value['branches'];
  return branches is YamlList &&
      branches.length == 1 &&
      branches.single == 'main';
}

void _requireStep(
  YamlMap step, {
  required String name,
  required Set<String> keys,
  String? run,
  String? uses,
}) {
  if (!_hasExactKeys(step, keys) ||
      step['name'] != name ||
      (run != null && _normalizeCommand(step['run']) != run) ||
      (uses != null && step['uses'] != uses)) {
    throw StateError('iOS release step invalid: $name');
  }
}

String _normalizeCommand(Object? value) {
  if (value is! String) {
    return '';
  }
  return value.trim().split(RegExp(r'\s+')).join(' ');
}
