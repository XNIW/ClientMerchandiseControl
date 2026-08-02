import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/features/account/data/supabase_customer_account_repository.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeCustomerAccountPort port;
  late SupabaseCustomerAccountRepository repository;

  setUp(() {
    port = _FakeCustomerAccountPort();
    repository = SupabaseCustomerAccountRepository(port: port);
  });

  test('load valida owner, allow-list, default e deletion request', () async {
    final snapshot = await repository.load(subjectId);

    expect(snapshot.profile?.userId, subjectId);
    expect(snapshot.profile?.displayName, 'Cliente Uno');
    expect(snapshot.profile?.locale, 'es-CL');
    expect(snapshot.addresses, hasLength(1));
    expect(snapshot.addresses.single.isDefault, isTrue);
    expect(snapshot.deletionRequest?.status, 'requested');
  });

  test(
    'owner mismatch e consent incoerente falliscono senza dati parziali',
    () async {
      port.profile = {...port.profile!, 'user_id': secondSubjectId};
      await expectLater(
        repository.load(subjectId),
        throwsA(
          isA<CustomerAccountRepositoryException>().having(
            (error) => error.kind,
            'kind',
            CustomerAccountFailureKind.unexpected,
          ),
        ),
      );

      port.profile = {
        ..._profileRow(),
        'privacy_consent_version': 'privacy-2026.08',
        'privacy_consented_at': null,
      };
      await expectLater(
        repository.load(subjectId),
        throwsA(isA<CustomerAccountRepositoryException>()),
      );
    },
  );

  test(
    'profile save non invia owner, consent timestamp o credenziali',
    () async {
      final draft = CustomerProfileDraft(
        displayName: 'Cliente Actualizado',
        locale: 'it',
      );
      await repository.saveProfile(subjectId, draft, profileExists: true);

      expect(port.updatedProfileSubject, subjectId);
      expect(port.updatedProfile, {
        'display_name': 'Cliente Actualizado',
        'locale': 'it',
      });
      expect(
        port.updatedProfile!.keys,
        isNot(contains(anyOf('user_id', 'email', 'privacy_consented_at'))),
      );
    },
  );

  test(
    'profile scomparso durante update viene creato con default owner server',
    () async {
      port.updateProfileResult = null;
      await repository.saveProfile(
        subjectId,
        CustomerProfileDraft(displayName: null, locale: 'en'),
        profileExists: true,
      );

      expect(port.insertedProfile, {'display_name': null, 'locale': 'en'});
    },
  );

  test(
    'address CRUD usa solo campi pubblici e mai is_default/user_id',
    () async {
      final draft = _addressDraft();
      await repository.createAddress(draft);
      await repository.updateAddress(addressId, draft);
      await repository.deleteAddress(addressId);

      expect(port.insertedAddress, port.updatedAddress);
      expect(
        port.insertedAddress!.keys,
        isNot(contains(anyOf('user_id', 'is_default', 'stock', 'email'))),
      );
      expect(port.updatedAddressId, addressId);
      expect(port.deletedAddressId, addressId);
    },
  );

  test('RPC inviano payload esatto e validano apiVersion/status', () async {
    await repository.setDefaultAddress(addressId);
    expect(port.lastFunction, 'customer_set_default_address_v1');
    expect(port.lastParameters, {'p_address_id': addressId});

    await repository.recordPrivacyConsent(
      version: 'privacy-2026.08',
      accepted: true,
    );
    expect(port.lastFunction, 'customer_record_privacy_consent_v1');
    expect(port.lastParameters, {
      'p_version': 'privacy-2026.08',
      'p_accepted': true,
    });

    await repository.requestAccountDeletion(idempotencyId);
    expect(port.lastParameters, {'p_idempotency_key': idempotencyId});

    await repository.cancelAccountDeletion(deletionId);
    expect(port.lastParameters, {'p_request_id': deletionId});

    port.rpcStatus = 'not_found';
    await expectLater(
      repository.setDefaultAddress(addressId),
      throwsA(
        isA<CustomerAccountRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerAccountFailureKind.unavailable,
        ),
      ),
    );
  });

  test('export rifiuta campi server inattesi o sensibili', () async {
    final export = await repository.exportData();
    expect(export.json, isNot(contains('email')));

    port.exportPayload = {
      ...port.exportPayload,
      'email': 'customer@example.invalid',
    };
    await expectLater(
      repository.exportData(),
      throwsA(isA<CustomerAccountRepositoryException>()),
    );
  });

  test('offline e timeout sono mappati senza dettagli SDK', () async {
    port.readError = const SocketException('network secret detail');
    await expectLater(
      repository.load(subjectId),
      throwsA(
        isA<CustomerAccountRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerAccountFailureKind.offline,
        ),
      ),
    );

    port = _FakeCustomerAccountPort()..neverComplete = true;
    repository = SupabaseCustomerAccountRepository(
      port: port,
      requestTimeout: const Duration(milliseconds: 5),
    );
    await expectLater(
      repository.load(subjectId),
      throwsA(
        isA<CustomerAccountRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerAccountFailureKind.timeout,
        ),
      ),
    );
  });

  test('ID non UUID fallisce prima di invocare la porta', () async {
    await expectLater(
      repository.deleteAddress('../foreign-row'),
      throwsA(
        isA<CustomerAccountRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerAccountFailureKind.invalidInput,
        ),
      ),
    );
    expect(port.deletedAddressId, isNull);
  });
}

final class _FakeCustomerAccountPort implements CustomerAccountPort {
  Map<String, Object?>? profile = _profileRow();
  Object? updateProfileResult = _profileRow();
  Object? readError;
  bool neverComplete = false;
  String rpcStatus = 'ok';
  String? lastFunction;
  Map<String, Object?>? lastParameters;
  String? updatedProfileSubject;
  Map<String, Object?>? updatedProfile;
  Map<String, Object?>? insertedProfile;
  Map<String, Object?>? insertedAddress;
  String? updatedAddressId;
  Map<String, Object?>? updatedAddress;
  String? deletedAddressId;
  Map<String, Object?> exportPayload = _exportPayload();

  Future<Object?> _read(Object? value) async {
    if (readError case final error?) {
      throw error;
    }
    if (neverComplete) {
      return Completer<Object?>().future;
    }
    return value;
  }

  @override
  Future<Object?> readProfile() => _read(profile);

  @override
  Future<Object?> readAddresses() => _read([_addressRow()]);

  @override
  Future<Object?> readDeletionRequests() => _read([_deletionRow()]);

  @override
  Future<Object?> insertProfile(Map<String, Object?> values) async {
    insertedProfile = values;
    return _profileRow();
  }

  @override
  Future<Object?> updateProfile(
    String expectedSubjectId,
    Map<String, Object?> values,
  ) async {
    updatedProfileSubject = expectedSubjectId;
    updatedProfile = values;
    return updateProfileResult;
  }

  @override
  Future<void> deleteProfile(String expectedSubjectId) async {}

  @override
  Future<void> insertAddress(Map<String, Object?> values) async {
    insertedAddress = values;
  }

  @override
  Future<void> updateAddress(
    String addressId,
    Map<String, Object?> values,
  ) async {
    updatedAddressId = addressId;
    updatedAddress = values;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    deletedAddressId = addressId;
  }

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    lastFunction = function;
    lastParameters = parameters;
    if (function == 'customer_data_export_v1') {
      return exportPayload;
    }
    final status = rpcStatus != 'ok'
        ? rpcStatus
        : switch (function) {
            'customer_request_account_deletion_v1' => 'requested',
            'customer_cancel_account_deletion_v1' => 'cancelled',
            _ => 'ok',
          };
    return {'apiVersion': 'customer.v1', 'status': status};
  }
}

Map<String, Object?> _profileRow() => {
  'user_id': subjectId,
  'display_name': 'Cliente Uno',
  'locale': 'es-CL',
  'privacy_consent_version': null,
  'privacy_consented_at': null,
  'updated_at': timestamp,
};

Map<String, Object?> _addressRow() => {
  'id': addressId,
  'label': 'Casa',
  'recipient_name': 'Cliente Uno',
  'address_line_1': 'Avenida Uno 123',
  'address_line_2': null,
  'commune': 'Santiago',
  'region': 'Metropolitana',
  'postal_code': '8320000',
  'country_code': 'CL',
  'delivery_instructions': null,
  'is_default': true,
  'updated_at': timestamp,
};

Map<String, Object?> _deletionRow() => {
  'id': deletionId,
  'status': 'requested',
  'requested_at': timestamp,
  'cancelled_at': null,
  'processed_at': null,
};

Map<String, Object?> _exportPayload() => {
  'apiVersion': 'customer.v1',
  'generatedAt': timestamp,
  'profile': null,
  'addresses': <Object?>[],
  'accountDeletionRequests': <Object?>[],
};

CustomerAddressDraft _addressDraft() => CustomerAddressDraft(
  label: 'Casa',
  recipientName: 'Cliente Uno',
  addressLine1: 'Avenida Uno 123',
  addressLine2: null,
  commune: 'Santiago',
  region: 'Metropolitana',
  postalCode: '8320000',
  countryCode: 'CL',
  deliveryInstructions: null,
);

const subjectId = '00000000-0000-4000-8000-000000021001';
const secondSubjectId = '00000000-0000-4000-8000-000000021002';
const addressId = '21000000-0000-4000-8000-000000000001';
const deletionId = '21000000-0000-4000-8000-000000000002';
const idempotencyId = '21000000-0000-4000-8000-000000000003';
const timestamp = '2026-08-02T18:00:00Z';
