import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizza nome ed email da campi dedicati bounded', () {
    final customer = AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: ' internal-subject ',
      email: ' customer@example.test ',
      metadata: const {
        'full_name': '  María   Cliente  ',
        'avatar_url': 'https://untrusted.example/avatar.png',
        'shop_id': 'must-not-authorize',
      },
    );

    expect(customer.subjectId, 'internal-subject');
    expect(customer.displayName, 'María Cliente');
    expect(customer.email, 'customer@example.test');
    expect(customer.toString(), isNot(contains('internal-subject')));
    expect(customer.toString(), isNot(contains('customer@example.test')));
    expect(customer.toString(), isNot(contains('avatar')));
  });

  test('ignora metadata HTML-like, controlli e valori eccessivi', () {
    final customers = [
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-1',
        email: 'invalid-email',
        metadata: const {'full_name': '<script>alert(1)</script>'},
      ),
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-2',
        email: 'bad\n@example.test',
        metadata: const {'name': 'Unsafe\u202eName'},
      ),
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-3',
        email: null,
        metadata: {
          'given_name': List.filled(
            AuthenticatedCustomer.maxDisplayNameRunes + 1,
            'x',
          ).join(),
        },
      ),
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-4',
        email: null,
        metadata: const {
          'full_name': 42,
          'name': <String>['not', 'text'],
        },
      ),
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-5',
        email: null,
        metadata: const {'name': 'Unsafe\u200fName'},
      ),
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: 'subject-6',
        email: null,
        metadata: const {'name': 'Unsafe\u061cName'},
      ),
    ];

    for (final customer in customers) {
      expect(customer.displayName, isNull);
      expect(customer.email, isNull);
    }
  });

  test('usa il primo nome sicuro e non campi autorizzativi', () {
    final customer = AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: 'subject',
      email: null,
      metadata: const {
        'full_name': '<unsafe>',
        'name': 'Safe Name',
        'role': 'admin',
        'shop_id': 'shop',
      },
    );

    expect(customer.displayName, 'Safe Name');
  });

  test('rifiuta subject interno nullo semanticamente o eccessivo', () {
    expect(
      () => AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: ' ',
        email: null,
        metadata: const {},
      ),
      throwsFormatException,
    );
    expect(
      () => AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: List.filled(257, 'x').join(),
        email: null,
        metadata: const {},
      ),
      throwsFormatException,
    );
  });
}
