import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

abstract final class ShopDateTimeFormatter {
  static var _initialized = false;

  static bool supports(String value) {
    if (value.isEmpty || value.runes.length > 64 || value.trim() != value) {
      return false;
    }
    _initialize();
    try {
      time_zone.getLocation(_databaseName(value));
      return true;
    } on time_zone.LocationNotFoundException {
      return false;
    }
  }

  static String format(
    BuildContext context,
    DateTime value, {
    required String timeZone,
  }) {
    _initialize();
    final location = time_zone.getLocation(_databaseName(timeZone));
    final zoned = time_zone.TZDateTime.from(value.toUtc(), location);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateTime = DateFormat.yMMMd(locale).add_Hm().format(zoned);
    return '$dateTime · $timeZone';
  }

  static DateTime inTimeZone(DateTime value, {required String timeZone}) {
    _initialize();
    return time_zone.TZDateTime.from(
      value.toUtc(),
      time_zone.getLocation(_databaseName(timeZone)),
    );
  }

  static String _databaseName(String value) =>
      value == 'UTC' ? 'Etc/UTC' : value;

  static void _initialize() {
    if (_initialized) return;
    time_zone_data.initializeTimeZones();
    _initialized = true;
  }
}
