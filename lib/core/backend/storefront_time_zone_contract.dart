import '../formatting/shop_date_time_formatter.dart';

String parseStorefrontTimeZone(
  Object? raw, {
  required String expectedShopSlug,
}) {
  if (raw is! Map) {
    throw const FormatException('storefront_time_zone_map');
  }
  final payload = raw.map((key, value) => MapEntry(key.toString(), value));
  const allowed = {
    'apiVersion',
    'status',
    'shopSlug',
    'timeZone',
    'serverTime',
  };
  if (payload.keys.any((key) => !allowed.contains(key)) ||
      payload['apiVersion'] != 'storefront-time-zone.v1') {
    throw const FormatException('storefront_time_zone_contract');
  }

  final status = payload['status'];
  final serverTime = payload['serverTime'];
  if (status is! String ||
      serverTime is! String ||
      DateTime.tryParse(serverTime) == null) {
    throw const FormatException('storefront_time_zone_status');
  }
  if (status != 'ok') {
    if (payload.keys.toSet().difference(const {
      'apiVersion',
      'status',
      'serverTime',
    }).isNotEmpty) {
      throw const FormatException('storefront_time_zone_minimal');
    }
    throw const FormatException('storefront_time_zone_unavailable');
  }
  if (payload.length != 5 || payload['shopSlug'] != expectedShopSlug) {
    throw const FormatException('storefront_time_zone_identity');
  }
  final value = payload['timeZone'];
  if (value is! String || !ShopDateTimeFormatter.supports(value)) {
    throw const FormatException('storefront_time_zone_value');
  }
  return value;
}
