import 'package:client_merchandise_control/core/formatting/clp_currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClpCurrencyFormatter formatter;

  setUp(() {
    formatter = ClpCurrencyFormatter();
  });

  test('formatta 47100 come CLP senza decimali', () {
    expect(formatter.format(47100), r'$47.100');
  });

  test('gestisce valori negativi', () {
    final result = formatter.format(-47100);

    expect(result, contains(r'$'));
    expect(result, contains('47.100'));
    expect(result, contains('-'));
  });

  test('gestisce stringhe numeriche, null e input non valido', () {
    expect(formatter.format('47100'), r'$47.100');
    expect(formatter.format(null), '-');
    expect(formatter.format('non-numero'), '-');
  });
}
