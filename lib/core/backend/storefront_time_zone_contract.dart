import '../formatting/shop_date_time_formatter.dart';

String parseStorefrontTimeZoneValue(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.length > 64 ||
      !ShopDateTimeFormatter.supports(value)) {
    throw const FormatException('storefront_time_zone_value');
  }
  return value;
}
