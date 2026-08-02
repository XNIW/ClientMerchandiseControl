import 'customer_account_models.dart';

abstract interface class CustomerAccountRepository {
  Future<CustomerAccountSnapshot> load(String expectedSubjectId);

  Future<void> saveProfile(
    String expectedSubjectId,
    CustomerProfileDraft draft, {
    required bool profileExists,
  });

  Future<void> deleteProfile(String expectedSubjectId);

  Future<void> createAddress(CustomerAddressDraft draft);

  Future<void> updateAddress(String addressId, CustomerAddressDraft draft);

  Future<void> deleteAddress(String addressId);

  Future<void> setDefaultAddress(String addressId);

  Future<void> recordPrivacyConsent({
    required String version,
    required bool accepted,
  });

  Future<CustomerDataExport> exportData();

  Future<void> requestAccountDeletion(String idempotencyKey);

  Future<void> cancelAccountDeletion(String requestId);
}
