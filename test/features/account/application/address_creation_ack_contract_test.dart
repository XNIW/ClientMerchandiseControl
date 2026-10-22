import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/data/supabase_customer_account_repository.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = '00000000-0000-4000-8000-000000021001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final malformed in ['id', 'label']) {
    test('ACK malformato $malformed conserva intento durevole al retry', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final port = _CommittedPort(malformed);
      final repository = SupabaseCustomerAccountRepository(port: port);
      var keys = 0;
      final container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(
            AuthenticatedCustomer.fromUntrustedIdentity(
              subjectId: owner,
              email: 'review@example.invalid',
              metadata: const {},
            ),
          ),
          customerAccountShopSlugProvider.overrideWithValue('test-shop'),
          customerAccountRepositoryProvider.overrideWithValue(repository),
          customerIdempotencyKeyFactoryProvider.overrideWithValue(
            () =>
                '21000000-0000-4000-8000-${(++keys).toString().padLeft(12, '0')}',
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(customerAccountControllerProvider);
      for (
        var i = 0;
        i < 50 &&
            container.read(customerAccountControllerProvider).status !=
                CustomerAccountStatus.ready;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(
        container.read(customerAccountControllerProvider).status,
        CustomerAccountStatus.ready,
      );
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final draft = CustomerAddressDraft(
        label: 'Casa',
        recipientName: 'Cliente Test',
        addressLine1: 'Via Uno 123',
        commune: 'Santiago',
        region: 'Metropolitana',
        countryCode: 'CL',
        addressLine2: null,
        postalCode: null,
        deliveryInstructions: null,
      );
      final first = await controller.createAddress(draft);
      expect(first, isNull);
      final pending = await repository.addressCreationJournal.read(owner);
      final firstFailure = container
          .read(customerAccountControllerProvider)
          .failure;
      port.corruptResponse = false;
      final retry = await controller.createAddress(draft);
      expect(retry, isNotNull);
      expect(
        port.rows,
        hasLength(1),
        reason:
            'A response parse failure after a real committed port operation must never allocate a second intent',
      );
      expect(pending, isNotNull);
      expect(firstFailure?.isUncertain, isTrue);
    });
  }
}

class _CommittedPort implements CustomerAccountPort {
  _CommittedPort(this.malformed);
  final String malformed;
  bool corruptResponse = true;
  final rows = <String, Map<String, Object?>>{};
  int reconciles = 0;
  @override
  Future<Object?> readProfile() async => null;
  @override
  Future<Object?> readDeletionRequests() async => <Object>[];
  @override
  Future<Object?> readAddresses() async => {
    'apiVersion': 'customer-address.v2',
    'status': 'ok',
    'items': rows.values.toList(),
  };
  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    final intent = parameters['p_intent_id']! as String;
    if (function == 'customer_address_create_reconcile_v3') {
      reconciles++;
      return {
        'apiVersion': 'customer-address.v3',
        'status': rows.containsKey(intent) ? 'ok' : 'not_found',
        if (rows.containsKey(intent)) 'address': rows[intent],
      };
    }
    if (function != 'customer_address_create_v3') {
      throw StateError('unexpected RPC');
    }
    rows.putIfAbsent(
      intent,
      () => {
        ...(parameters['p_payload']! as Map<String, Object?>),
        'id':
            '22000000-0000-4000-8000-${(rows.length + 1).toString().padLeft(12, '0')}',
        'isDefault': false,
        'version': 1,
        'validatedAt': null,
        'updatedAt': '2026-10-08T12:00:00Z',
        'lastSelectedAt': null,
      },
    );
    final returned = Map<String, Object?>.from(rows[intent]!);
    if (corruptResponse) {
      returned[malformed] = malformed == 'id' ? 'invalid-address-id' : 'x' * 41;
    }
    return {
      'apiVersion': 'customer-address.v3',
      'status': 'ok',
      'address': returned,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
