import 'package:intl/intl.dart';

class ClpCurrencyFormatter {
  ClpCurrencyFormatter()
    : _formatter = NumberFormat.currency(
        locale: 'es_CL',
        symbol: r'$',
        decimalDigits: 0,
      );

  final NumberFormat _formatter;

  String format(Object? value) {
    final amount = switch (value) {
      num number => number,
      String text => _tryParse(text),
      _ => null,
    };

    if (amount == null || !amount.isFinite) {
      return '-';
    }

    final digits = _formatter
        .format(amount.abs())
        .replaceAll(r'$', '')
        .replaceAll('\u00a0', '')
        .replaceAll('\u202f', '');
    final prefix = amount.isNegative ? r'-$' : r'$';
    return '$prefix$digits';
  }

  static num? _tryParse(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return num.tryParse(normalized);
  }
}
