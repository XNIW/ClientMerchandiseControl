import 'customer_review_models.dart';

abstract interface class CustomerReviewRepository {
  Future<CustomerReviewsAccount> listMine({required String shopSlug});

  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  });

  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  });

  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  });
}

final class CustomerReviewException implements Exception {
  const CustomerReviewException(this.code);

  final String code;
}
