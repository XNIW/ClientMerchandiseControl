import 'package:client_merchandise_control/features/orders/application/customer_reorder_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timeout e riapertura riusano la chiave fino a risposta definitiva', () {
    var sequence = 0;
    final attempt = CustomerReorderAttempt(() => 'key-${++sequence}');

    final first = attempt.begin();
    expect(attempt.begin(), first);
    expect(sequence, 1);

    attempt.complete(first);
    expect(attempt.begin(), 'key-2');
  });

  test('una risposta stale non cancella il tentativo corrente', () {
    var sequence = 0;
    final attempt = CustomerReorderAttempt(() => 'key-${++sequence}');
    final current = attempt.begin();

    attempt.complete('different-key');

    expect(attempt.begin(), current);
    expect(sequence, 1);
  });
}
