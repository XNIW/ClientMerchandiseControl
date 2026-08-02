import 'dart:async';

import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_repository.dart';

const testCustomerSubject = '00000000-0000-4000-8000-000000021001';
const testAddressId = '21000000-0000-4000-8000-000000000001';
const testDeletionId = '21000000-0000-4000-8000-000000000099';
final testTimestamp = DateTime.utc(2026, 8, 2, 18);

CustomerProfile testCustomerProfile({
  String? displayName = 'Cliente Uno',
  String locale = 'es-CL',
  bool consented = false,
}) {
  return CustomerProfile(
    userId: testCustomerSubject,
    displayName: displayName,
    locale: locale,
    privacyConsentVersion: consented ? 'privacy-2026.08' : null,
    privacyConsentedAt: consented ? testTimestamp : null,
    updatedAt: testTimestamp,
  );
}

CustomerAddress testCustomerAddress({
  String id = testAddressId,
  String label = 'Casa',
  bool isDefault = true,
}) {
  return CustomerAddress(
    id: id,
    label: label,
    recipientName: 'Cliente Uno',
    addressLine1: 'Avenida Uno 123',
    addressLine2: null,
    commune: 'Santiago',
    region: 'Metropolitana',
    postalCode: '8320000',
    countryCode: 'CL',
    deliveryInstructions: null,
    isDefault: isDefault,
    updatedAt: testTimestamp,
  );
}

final class FakeCustomerAccountRepository implements CustomerAccountRepository {
  FakeCustomerAccountRepository({
    CustomerProfile? profile,
    List<CustomerAddress>? addresses,
    this.deletionRequest,
  }) : profile = profile ?? testCustomerProfile(),
       addresses = List<CustomerAddress>.of(
         addresses ?? [testCustomerAddress()],
       );

  CustomerProfile? profile;
  List<CustomerAddress> addresses;
  CustomerDeletionRequest? deletionRequest;
  Object? loadError;
  Object? mutationError;
  Completer<void>? loadBarrier;
  Completer<void>? deletionBarrier;
  String? subjectId;
  int loadCalls = 0;
  int saveProfileCalls = 0;
  int createAddressCalls = 0;
  int requestDeletionCalls = 0;
  final List<String> deletionKeys = [];

  @override
  Future<CustomerAccountSnapshot> load(String expectedSubjectId) async {
    loadCalls++;
    subjectId = expectedSubjectId;
    await loadBarrier?.future;
    if (loadError case final error?) {
      throw error;
    }
    return CustomerAccountSnapshot(
      profile: profile,
      addresses: addresses,
      deletionRequest: deletionRequest,
      loadedAt: testTimestamp,
    );
  }

  @override
  Future<void> saveProfile(
    String expectedSubjectId,
    CustomerProfileDraft draft, {
    required bool profileExists,
  }) async {
    _throwMutationIfNeeded();
    saveProfileCalls++;
    profile = CustomerProfile(
      userId: expectedSubjectId,
      displayName: draft.displayName,
      locale: draft.locale,
      privacyConsentVersion: profile?.privacyConsentVersion,
      privacyConsentedAt: profile?.privacyConsentedAt,
      updatedAt: testTimestamp.add(Duration(seconds: saveProfileCalls)),
    );
  }

  @override
  Future<void> deleteProfile(String expectedSubjectId) async {
    _throwMutationIfNeeded();
    profile = null;
  }

  @override
  Future<void> createAddress(CustomerAddressDraft draft) async {
    _throwMutationIfNeeded();
    createAddressCalls++;
    addresses = [
      ...addresses,
      _addressFromDraft(
        '22000000-0000-4000-8000-${createAddressCalls.toString().padLeft(12, '0')}',
        draft,
      ),
    ];
  }

  @override
  Future<void> updateAddress(
    String addressId,
    CustomerAddressDraft draft,
  ) async {
    _throwMutationIfNeeded();
    addresses = [
      for (final address in addresses)
        if (address.id == addressId)
          _addressFromDraft(addressId, draft, isDefault: address.isDefault)
        else
          address,
    ];
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    _throwMutationIfNeeded();
    addresses = addresses
        .where((address) => address.id != addressId)
        .toList(growable: false);
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    _throwMutationIfNeeded();
    addresses = [
      for (final address in addresses)
        CustomerAddress(
          id: address.id,
          label: address.label,
          recipientName: address.recipientName,
          addressLine1: address.addressLine1,
          addressLine2: address.addressLine2,
          commune: address.commune,
          region: address.region,
          postalCode: address.postalCode,
          countryCode: address.countryCode,
          deliveryInstructions: address.deliveryInstructions,
          isDefault: address.id == addressId,
          updatedAt: testTimestamp,
        ),
    ];
  }

  @override
  Future<void> recordPrivacyConsent({
    required String version,
    required bool accepted,
  }) async {
    _throwMutationIfNeeded();
    final current = profile ?? testCustomerProfile(displayName: null);
    profile = CustomerProfile(
      userId: current.userId,
      displayName: current.displayName,
      locale: current.locale,
      privacyConsentVersion: accepted ? version : null,
      privacyConsentedAt: accepted ? testTimestamp : null,
      updatedAt: testTimestamp,
    );
  }

  @override
  Future<CustomerDataExport> exportData() async {
    _throwMutationIfNeeded();
    return CustomerDataExport.fromUntrusted({
      'apiVersion': 'customer.v1',
      'generatedAt': testTimestamp.toIso8601String(),
      'profile': profile == null
          ? null
          : {
              'userId': profile!.userId,
              'displayName': profile!.displayName,
              'locale': profile!.locale,
              'privacyConsentVersion': profile!.privacyConsentVersion,
              'privacyConsentedAt': profile!.privacyConsentedAt
                  ?.toIso8601String(),
              'createdAt': testTimestamp.toIso8601String(),
              'updatedAt': profile!.updatedAt.toIso8601String(),
            },
      'addresses': <Object?>[],
      'accountDeletionRequests': <Object?>[],
    });
  }

  @override
  Future<void> requestAccountDeletion(String idempotencyKey) async {
    _throwMutationIfNeeded();
    requestDeletionCalls++;
    deletionKeys.add(idempotencyKey);
    await deletionBarrier?.future;
    deletionRequest = CustomerDeletionRequest(
      id: testDeletionId,
      status: 'requested',
      requestedAt: testTimestamp,
      cancelledAt: null,
      processedAt: null,
    );
  }

  @override
  Future<void> cancelAccountDeletion(String requestId) async {
    _throwMutationIfNeeded();
    deletionRequest = CustomerDeletionRequest(
      id: requestId,
      status: 'cancelled',
      requestedAt: testTimestamp,
      cancelledAt: testTimestamp,
      processedAt: null,
    );
  }

  void _throwMutationIfNeeded() {
    if (mutationError case final error?) {
      throw error;
    }
  }
}

CustomerAddress _addressFromDraft(
  String id,
  CustomerAddressDraft draft, {
  bool isDefault = false,
}) {
  return CustomerAddress(
    id: id,
    label: draft.label,
    recipientName: draft.recipientName,
    addressLine1: draft.addressLine1,
    addressLine2: draft.addressLine2,
    commune: draft.commune,
    region: draft.region,
    postalCode: draft.postalCode,
    countryCode: draft.countryCode,
    deliveryInstructions: draft.deliveryInstructions,
    isDefault: isDefault,
    updatedAt: testTimestamp,
  );
}

CustomerAccountRepositoryException offlineCustomerFailure() {
  return const CustomerAccountRepositoryException(
    CustomerAccountFailureKind.offline,
  );
}
