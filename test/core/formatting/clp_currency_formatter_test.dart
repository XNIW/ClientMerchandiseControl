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
    expect(formatter.format(-47100), r'-$47.100');
  });

  test('gestisce zero e valori molto grandi in modo deterministico', () {
    expect(formatter.format(0), r'$0');
    expect(formatter.format(999999999), r'$999.999.999');
  });

  test('determina il segno dopo l’arrotondamento ai pesos interi', () {
    expect(formatter.format(-0.4), r'$0');
    expect(formatter.format('-0,4'), r'$0');
    expect(formatter.format(0.4), r'$0');
    expect(formatter.format(-0.5), r'-$1');
  });

  test('gestisce stringhe numeriche, null, non finiti e input non valido', () {
    expect(formatter.format('47100'), r'$47.100');
    expect(formatter.format(null), '-');
    expect(formatter.format(double.infinity), '-');
    expect(formatter.format(double.nan), '-');
    expect(formatter.format('non-numero'), '-');
  });
}
