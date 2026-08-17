import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const expectedCapabilities = <String>{
  'supabaseUrlPublicKey',
  'oauth',
  'callback',
  'maps',
  'payment',
  'notifications',
  'analytics',
  'crashReporting',
  'tracking',
  'shopSlug',
  'externalCarrier',
  'loggingLevel',
};

const _environments = <String>{'development', 'staging', 'production'};
const _policies = <String>{'required', 'optional', 'forbidden'};
const expectedIosCollectedDataTypes = <String>{
  'NSPrivacyCollectedDataTypeName',
  'NSPrivacyCollectedDataTypeEmailAddress',
  'NSPrivacyCollectedDataTypePhysicalAddress',
  'NSPrivacyCollectedDataTypeUserID',
  'NSPrivacyCollectedDataTypePurchaseHistory',
  'NSPrivacyCollectedDataTypeSearchHistory',
  'NSPrivacyCollectedDataTypeOtherUserContent',
};

bool _sameStrings(Set<Object?> actual, Set<String> expected) =>
    actual.length == expected.length && actual.containsAll(expected);

final class PngInfo {
  const PngInfo({
    required this.width,
    required this.height,
    required this.hasAlpha,
  });

  final int width;
  final int height;
  final bool hasAlpha;
}

PngInfo inspectPng(Uint8List bytes) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33) throw const FormatException('invalid_png_signature');
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) {
      throw const FormatException('invalid_png_signature');
    }
  }
  if (ascii.decode(bytes.sublist(12, 16)) != 'IHDR') {
    throw const FormatException('missing_png_ihdr');
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  final colorType = bytes[25];
  var hasTransparencyChunk = false;
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = data.getUint32(offset);
    if (length > bytes.length || offset + 12 + length > bytes.length) {
      throw const FormatException('invalid_png_chunk');
    }
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    if (type == 'tRNS') hasTransparencyChunk = true;
    offset += 12 + length;
    if (type == 'IEND') break;
  }
  return PngInfo(
    width: width,
    height: height,
    hasAlpha: colorType == 4 || colorType == 6 || hasTransparencyChunk,
  );
}

void validateConfigurationMatrix(Object? value, List<String> errors) {
  if (value is! Map<String, dynamic>) {
    errors.add('configuration matrix root is not an object');
    return;
  }
  if (value.keys.toSet().difference(const {
    'schemaVersion',
    'environments',
    'capabilities',
  }).isNotEmpty) {
    errors.add('configuration matrix contains unknown root fields');
  }
  if (value['schemaVersion'] != 1) {
    errors.add('configuration matrix schemaVersion must be 1');
  }
  final environments = value['environments'];
  if (environments is! List ||
      !_sameStrings(environments.toSet(), _environments)) {
    errors.add('configuration matrix environments are incomplete');
  }
  final capabilities = value['capabilities'];
  if (capabilities is! List) {
    errors.add('configuration matrix capabilities are missing');
    return;
  }
  final seen = <String>{};
  for (final rawCapability in capabilities) {
    if (rawCapability is! Map<String, dynamic>) {
      errors.add('configuration matrix capability is not an object');
      continue;
    }
    if (rawCapability.keys.toSet().difference({
      'name',
      ..._environments,
    }).isNotEmpty) {
      errors.add('configuration matrix capability contains unknown fields');
    }
    final name = rawCapability['name'];
    if (name is! String ||
        !expectedCapabilities.contains(name) ||
        !seen.add(name)) {
      errors.add('configuration matrix has an invalid or duplicate capability');
      continue;
    }
    for (final environment in _environments) {
      final rawRule = rawCapability[environment];
      if (rawRule is! Map<String, dynamic>) {
        errors.add('$name/$environment rule is missing');
        continue;
      }
      if (rawRule.keys.toSet().difference(const {
        'policy',
        'fallback',
        'validation',
      }).isNotEmpty) {
        errors.add('$name/$environment contains unknown fields');
      }
      if (!_policies.contains(rawRule['policy'])) {
        errors.add('$name/$environment has an invalid policy');
      }
      for (final field in const ['fallback', 'validation']) {
        final content = rawRule[field];
        if (content is! String || content.trim().length < 12) {
          errors.add('$name/$environment has an invalid $field');
        }
      }
    }
  }
  if (!_sameStrings(seen, expectedCapabilities)) {
    errors.add('configuration matrix does not cover every required capability');
  }

  final serialized = jsonEncode(value);
  final secretPatterns = <RegExp>[
    RegExp(r'AIza[0-9A-Za-z_-]{20,}'),
    RegExp(r'\bsb_(?:publishable|secret)_[0-9A-Za-z_-]{8,}\b'),
    RegExp(r'\bsk_(?:live|test)_[0-9A-Za-z_-]{8,}\b'),
    RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.'),
    RegExp(r'https://[a-z0-9-]+\.supabase\.co', caseSensitive: false),
  ];
  if (secretPatterns.any((pattern) => pattern.hasMatch(serialized))) {
    errors.add('configuration matrix contains a credential-like value');
  }
}

void validatePrivacyManifest(String content, List<String> errors) {
  final section = RegExp(
    r'<key>NSPrivacyCollectedDataTypes</key>\s*<array>([\s\S]*?)</array>\s*<key>NSPrivacyTracking</key>',
  ).firstMatch(content);
  if (section == null) {
    errors.add('iOS privacy manifest collected-data array is missing');
    return;
  }

  final dictionaries = RegExp(
    r'<dict>([\s\S]*?)</dict>',
  ).allMatches(section.group(1)!).map((match) => match.group(1)!).toList();
  final declared = <String>{};
  for (final dictionary in dictionaries) {
    final type = RegExp(
      r'<key>NSPrivacyCollectedDataType</key>\s*<string>([^<]+)</string>',
    ).firstMatch(dictionary)?.group(1);
    if (type == null || !declared.add(type)) {
      errors.add('iOS privacy manifest has an invalid or duplicate data type');
      continue;
    }
    if (!RegExp(
      r'<key>NSPrivacyCollectedDataTypeLinked</key>\s*<true\s*/>',
    ).hasMatch(dictionary)) {
      errors.add('$type must be linked to the user');
    }
    if (!RegExp(
      r'<key>NSPrivacyCollectedDataTypeTracking</key>\s*<false\s*/>',
    ).hasMatch(dictionary)) {
      errors.add('$type must fail closed for tracking');
    }
    if (!RegExp(
      r'<key>NSPrivacyCollectedDataTypePurposes</key>\s*<array>\s*<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>\s*</array>',
    ).hasMatch(dictionary)) {
      errors.add('$type must declare only App Functionality');
    }
  }

  if (!_sameStrings(declared.cast<Object?>(), expectedIosCollectedDataTypes)) {
    errors.add('iOS privacy manifest collected-data types are incomplete');
  }
}

Future<List<String>> validateRepository(Directory root) async {
  final errors = <String>[];
  File file(String relativePath) => File('${root.path}/$relativePath');

  void requireText(String relativePath, Iterable<String> tokens) {
    final target = file(relativePath);
    if (!target.existsSync()) {
      errors.add('$relativePath is missing');
      return;
    }
    final content = target.readAsStringSync();
    for (final token in tokens) {
      if (!content.contains(token)) errors.add('$relativePath misses $token');
    }
  }

  void requirePng(
    String relativePath,
    int expectedWidth,
    int expectedHeight, {
    bool opaque = false,
  }) {
    final target = file(relativePath);
    if (!target.existsSync()) {
      errors.add('$relativePath is missing');
      return;
    }
    try {
      final info = inspectPng(target.readAsBytesSync());
      if (info.width != expectedWidth || info.height != expectedHeight) {
        errors.add(
          '$relativePath is ${info.width}x${info.height}, expected '
          '${expectedWidth}x$expectedHeight',
        );
      }
      if (opaque && info.hasAlpha) errors.add('$relativePath is not opaque');
    } on FormatException catch (error) {
      errors.add('$relativePath is invalid: ${error.message}');
    }
  }

  requirePng('assets/release/app-icon-master.png', 1024, 1024, opaque: true);
  requirePng('assets/release/google-play-icon-512.png', 512, 512, opaque: true);
  for (final entry in const {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  }.entries) {
    requirePng(
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      entry.value,
      entry.value,
      opaque: true,
    );
  }
  requireText('android/app/src/main/AndroidManifest.xml', const [
    'android:icon="@mipmap/ic_launcher"',
    'android:allowBackup="false"',
    'android.permission.INTERNET',
  ]);
  requireText(
    'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    const ['@color/storefront_brand_teal', '@drawable/ic_launcher_foreground'],
  );
  requireText(
    'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
    const ['@drawable/ic_launcher_monochrome'],
  );
  requireText('android/app/src/main/res/values-v31/styles.xml', const [
    'android:windowSplashScreenBackground',
    'android:windowSplashScreenAnimatedIcon',
  ]);

  final manifest = file('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync() &&
      manifest.readAsStringSync().contains('android.permission.ACCESS_')) {
    errors.add('Android manifest unexpectedly requests a location permission');
  }

  final iconContents = file(
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
  );
  if (!iconContents.existsSync()) {
    errors.add('iOS AppIcon Contents.json is missing');
  } else {
    final decoded = jsonDecode(iconContents.readAsStringSync());
    final images = decoded is Map<String, dynamic> ? decoded['images'] : null;
    if (images is! List || images.length != 19) {
      errors.add('iOS AppIcon must declare exactly 19 required images');
    } else {
      for (final rawImage in images) {
        if (rawImage is! Map<String, dynamic>) {
          errors.add('iOS AppIcon contains an invalid entry');
          continue;
        }
        final name = rawImage['filename'];
        final size = rawImage['size'];
        final scale = rawImage['scale'];
        if (name is! String || size is! String || scale is! String) {
          errors.add('iOS AppIcon entry is incomplete');
          continue;
        }
        final points = double.tryParse(size.split('x').first);
        final multiplier = int.tryParse(scale.replaceAll('x', ''));
        if (points == null || multiplier == null) {
          errors.add('iOS AppIcon entry has invalid dimensions');
          continue;
        }
        final pixels = (points * multiplier).round();
        requirePng(
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/$name',
          pixels,
          pixels,
          opaque: true,
        );
      }
    }
  }
  requireText(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json',
    const ['LaunchMark.svg', 'preserves-vector-representation'],
  );
  requireText(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchMark.svg',
    const ['width="168"', 'height="168"', '#FFFDF8', '#BFD9D3'],
  );
  final privacyManifest = file('ios/Runner/PrivacyInfo.xcprivacy');
  if (!privacyManifest.existsSync()) {
    errors.add('ios/Runner/PrivacyInfo.xcprivacy is missing');
  } else {
    final content = privacyManifest.readAsStringSync();
    requireText('ios/Runner/PrivacyInfo.xcprivacy', const [
      'NSPrivacyAccessedAPITypes',
      'NSPrivacyCollectedDataTypes',
      'NSPrivacyTracking',
      '<false/>',
    ]);
    validatePrivacyManifest(content, errors);
  }
  requireText('ios/Runner.xcodeproj/project.pbxproj', const [
    'PrivacyInfo.xcprivacy',
    'PrivacyInfo.xcprivacy in Resources',
    'PRODUCT_BUNDLE_IDENTIFIER = com.xniw.clientmerchandisecontrol;',
  ]);
  requireText('ios/Runner/Info.plist', const [
    '<string>Client Merchandise Control</string>',
    r'<string>$(FLUTTER_BUILD_NAME)</string>',
    r'<string>$(FLUTTER_BUILD_NUMBER)</string>',
  ]);
  requireText('android/app/build.gradle.kts', const [
    'applicationId = "com.xniw.clientmerchandisecontrol"',
    'versionCode = flutter.versionCode',
    'versionName = flutter.versionName',
  ]);
  requireText('pubspec.yaml', const ['version: 0.1.0+1']);

  final matrix = file('config/release_configuration_matrix.json');
  if (!matrix.existsSync()) {
    errors.add('configuration matrix is missing');
  } else {
    try {
      validateConfigurationMatrix(
        jsonDecode(matrix.readAsStringSync()),
        errors,
      );
    } on FormatException {
      errors.add('configuration matrix is not valid JSON');
    }
  }

  for (final document in const [
    'docs/releases/RELEASE-CONFIGURATION-MATRIX.md',
    'docs/releases/STORE-LISTING-METADATA.md',
    'docs/releases/STORE-PRIVACY-DATA-EVIDENCE.md',
    'docs/releases/PRIVACY-LEGAL-ACTIVATION.md',
    'docs/releases/OPEN-SOURCE-AND-MAPS-ATTRIBUTION.md',
    'docs/releases/DEPENDENCY-AND-DEBT-AUDIT.md',
  ]) {
    requireText(document, const []);
  }
  for (final ownerDocument in const [
    'docs/releases/STORE-LISTING-METADATA.md',
    'docs/releases/STORE-PRIVACY-DATA-EVIDENCE.md',
    'docs/releases/PRIVACY-LEGAL-ACTIVATION.md',
  ]) {
    requireText(ownerDocument, const ['NEEDS_OWNER_VALUE']);
  }

  return errors;
}

Future<void> main(List<String> arguments) async {
  final root = arguments.isEmpty
      ? Directory.current
      : Directory(arguments.single);
  final errors = await validateRepository(root);
  if (errors.isNotEmpty) {
    stderr.writeln('RELEASE_METADATA_INVALID (${errors.length})');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'RELEASE_METADATA_READY: 12 capabilities x 3 environments; '
    'Android/iOS identity, opaque icons, launch assets, privacy manifest and '
    'owner-value templates validated.',
  );
}
