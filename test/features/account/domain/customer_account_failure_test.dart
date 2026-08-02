import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo failure recuperabili espongono retry', () {
    for (final kind in const {
      CustomerAccountFailureKind.offline,
      CustomerAccountFailureKind.timeout,
      CustomerAccountFailureKind.unavailable,
      CustomerAccountFailureKind.unexpected,
    }) {
      expect(CustomerAccountFailure(kind).canRetry, isTrue, reason: kind.name);
    }
    for (final kind in const {
      CustomerAccountFailureKind.unauthorized,
      CustomerAccountFailureKind.invalidInput,
      CustomerAccountFailureKind.conflict,
    }) {
      expect(CustomerAccountFailure(kind).canRetry, isFalse, reason: kind.name);
    }
  });

  test('exception repository espone soltanto il codice sanitizzato', () {
    const error = CustomerAccountRepositoryException(
      CustomerAccountFailureKind.conflict,
    );
    expect(error.toString(), 'CustomerAccountRepositoryException(conflict)');
  });
}
