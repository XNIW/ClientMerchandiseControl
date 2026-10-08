import 'customer_account_models.dart';
import 'address_creation_intent.dart';

abstract interface class CustomerAccountRepository {
  Future<CustomerAccountSnapshot> load(String expectedSubjectId);

  Future<void> saveProfile(
    String expectedSubjectId,
    CustomerProfileDraft draft, {
    required bool profileExists,
  });

  Future<void> deleteProfile(String expectedSubjectId);

  AddressCreationJournal get addressCreationJournal;

  Future<CustomerAddress> createAddress(
    CustomerAddressDraft draft, {
    required String intentId,
  });

  /// Null indica nessun commit osservato. Non autorizza un nuovo intent.
  Future<CustomerAddress?> reconcileAddressCreation(String intentId);

  Future<void> updateAddress(
    String addressId,
    CustomerAddressDraft draft, {
    int expectedVersion = 1,
  });

  Future<void> deleteAddress(String addressId, {int expectedVersion = 1});

  Future<void> setDefaultAddress(String addressId);

  Future<void> recordPrivacyConsent({
    required String version,
    required bool accepted,
  });

  Future<CustomerDataExport> exportData();

  Future<void> requestAccountDeletion(String idempotencyKey);

  Future<void> cancelAccountDeletion(String requestId);
}
