import 'checkout_models.dart';

abstract interface class CheckoutRepository {
  Future<StorefrontFulfillmentOptions> loadOptions({required String shopSlug});

  Future<StorefrontPaymentOptions> loadPaymentOptions({
    required String shopSlug,
  });

  Future<CheckoutRemoteResponse> createQuote(
    CheckoutQuoteCreateRequest request,
  );

  Future<CheckoutRemoteResponse> confirmQuote({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
    required int expectedQuoteVersion,
    required String idempotencyKey,
  });

  Future<CheckoutRemoteResponse> readQuote({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
  });

  Future<CheckoutOrderRemoteResponse> createOrder({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
    required int expectedQuoteVersion,
    required CheckoutPaymentMethod paymentMethod,
    required String idempotencyKey,
  });

  Future<CheckoutOrderRemoteResponse> readOrder({
    required String shopSlug,
    required String orderId,
  });
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
