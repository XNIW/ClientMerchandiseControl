import 'package:client_merchandise_control/core/backend/storefront_time_zone_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accetta soltanto timezone IANA bounded dal payload atomico', () {
    expect(
      parseStorefrontTimeZoneValue('America/Santiago'),
      'America/Santiago',
    );
    expect(parseStorefrontTimeZoneValue('UTC'), 'UTC');
  });

  test('rifiuta valori ignoti, non stringa o fuori bound', () {
    for (final value in [null, 42, '', 'Mars/Olympus', 'A' * 65]) {
      expect(() => parseStorefrontTimeZoneValue(value), throwsFormatException);
    }
  });
}
