import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Never fail(String code) {
  stderr.writeln('IOS_RUNTIME_CONFIG_BLOCKED: $code');
  exit(1);
}

void main(List<String> arguments) {
  if (arguments.length != 2 || arguments[0] != '--config') {
    fail('USAGE');
  }

  final file = File(arguments[1]);
  if (!file.existsSync() || FileSystemEntity.isLinkSync(file.path)) {
    fail('FILE_NOT_REGULAR');
  }

  final bytes = file.readAsBytesSync();
  if (bytes.isEmpty || bytes.length > 65536) {
    fail('FILE_SIZE_INVALID');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
  } on FormatException {
    fail('JSON_INVALID');
  }
  if (decoded is! Map<String, dynamic>) {
    fail('JSON_OBJECT_REQUIRED');
  }
  final values = decoded;

  const requiredKeys = <String>{
    'APP_ENV',
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'AUTH_REDIRECT_URI',
    'GOOGLE_AUTH_ENABLED',
    'STOREFRONT_SHOP_SLUG',
    'DELIVERY_MAPS_ENABLED',
    'DELIVERY_MAPS_NATIVE_CONFIGURED',
  };
  if (values.keys.toSet().difference(requiredKeys).isNotEmpty ||
      requiredKeys.difference(values.keys.toSet()).isNotEmpty) {
    fail('KEY_SET_INVALID');
  }
  if (values.values.any((value) => value is! String)) {
    fail('STRING_VALUES_REQUIRED');
  }

  String value(String key) => (values[key]! as String).trim();
  if (value('APP_ENV') != 'production') {
    fail('ENVIRONMENT_INVALID');
  }
  if (value('GOOGLE_AUTH_ENABLED') != 'false' ||
      value('DELIVERY_MAPS_ENABLED') != 'false' ||
      value('DELIVERY_MAPS_NATIVE_CONFIGURED') != 'false') {
    fail('CAPABILITY_STATE_INVALID');
  }

  final backend = Uri.tryParse(value('SUPABASE_URL'));
  if (backend == null ||
      backend.scheme != 'https' ||
      !backend.hasAuthority ||
      backend.host.isEmpty ||
      backend.userInfo.isNotEmpty ||
      backend.hasQuery ||
      backend.hasFragment ||
      (backend.path.isNotEmpty && backend.path != '/')) {
    fail('BACKEND_ORIGIN_INVALID');
  }
  if (!_isPublishableKey(value('SUPABASE_PUBLISHABLE_KEY'))) {
    fail('PUBLISHABLE_KEY_INVALID');
  }
  if (value('AUTH_REDIRECT_URI') !=
      'https://clientmerchandisecontrol.invalid/auth-callback/') {
    fail('AUTH_REDIRECT_INVALID');
  }
  if (!RegExp(
    r'^[a-z0-9][a-z0-9-]{2,62}$',
  ).hasMatch(value('STOREFRONT_SHOP_SLUG'))) {
    fail('SHOP_SLUG_INVALID');
  }

  stdout.writeln(sha256.convert(bytes));
}

bool _isPublishableKey(String value) {
  if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(value)) {
    return true;
  }
  final segments = value.split('.');
  if (segments.length != 3 || segments.any((segment) => segment.isEmpty)) {
    return false;
  }
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
    );
    return payload is Map<String, dynamic> &&
        payload['role'] == 'anon' &&
        base64Url.decode(base64Url.normalize(segments[2])).isNotEmpty;
  } on FormatException {
    return false;
  }
}
