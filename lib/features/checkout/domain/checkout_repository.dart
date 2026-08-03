import 'checkout_models.dart';

abstract interface class CheckoutRepository {
  Future<StorefrontFulfillmentOptions> loadOptions({required String shopSlug});

  Future<CheckoutRemoteResponse> createQuote(
    CheckoutQuoteCreateRequest request,
  );

  Future<CheckoutRemoteResponse> confirmQuote({
    required String quoteId,
    required int expectedQuoteVersion,
    required String idempotencyKey,
  });

  Future<CheckoutRemoteResponse> readQuote({required String quoteId});
}

abstract interface class CheckoutDraftStore {
  Future<CheckoutLocalDraft?> read({
    required String ownerSubjectId,
    required String shopSlug,
  });

  Future<void> save(CheckoutLocalDraft draft);

  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  });
}
