import 'package:client_merchandise_control/core/backend/storefront_time_zone_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final serverTime = DateTime.utc(2026, 8, 16, 12).toIso8601String();

  test('accetta soltanto timezone IANA bounded per lo shop atteso', () {
    expect(
      parseStorefrontTimeZone({
        'apiVersion': 'storefront-time-zone.v1',
        'status': 'ok',
        'shopSlug': 'storefront-test',
        'timeZone': 'America/Santiago',
        'serverTime': serverTime,
      }, expectedShopSlug: 'storefront-test'),
      'America/Santiago',
    );
    expect(
      parseStorefrontTimeZone({
        'apiVersion': 'storefront-time-zone.v1',
        'status': 'ok',
        'shopSlug': 'storefront-test',
        'timeZone': 'UTC',
        'serverTime': serverTime,
      }, expectedShopSlug: 'storefront-test'),
      'UTC',
    );
  });

  test('rifiuta zona ignota, identità diversa e campi interni', () {
    final base = <String, Object?>{
      'apiVersion': 'storefront-time-zone.v1',
      'status': 'ok',
      'shopSlug': 'storefront-test',
      'timeZone': 'America/Santiago',
      'serverTime': serverTime,
    };
    for (final payload in [
      {...base, 'timeZone': 'Mars/Olympus'},
      {...base, 'shopSlug': 'other-shop'},
      {...base, 'databaseUrl': 'postgres://internal.invalid'},
      {...base}..remove('serverTime'),
    ]) {
      expect(
        () => parseStorefrontTimeZone(
          payload,
          expectedShopSlug: 'storefront-test',
        ),
        throwsFormatException,
      );
    }
  });

  test('gli errori remoti restano minimali e fail-closed', () {
    expect(
      () => parseStorefrontTimeZone({
        'apiVersion': 'storefront-time-zone.v1',
        'status': 'unavailable',
        'serverTime': serverTime,
      }, expectedShopSlug: 'storefront-test'),
      throwsFormatException,
    );
    expect(
      () => parseStorefrontTimeZone({
        'apiVersion': 'storefront-time-zone.v1',
        'status': 'unavailable',
        'shopSlug': 'storefront-test',
        'serverTime': serverTime,
      }, expectedShopSlug: 'storefront-test'),
      throwsFormatException,
    );
  });
}
