enum CustomerReviewStatus { pending, published, rejected, withdrawn }

final class CustomerReview {
  const CustomerReview({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.publicationId,
    required this.rating,
    required this.comment,
    required this.status,
    required this.version,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final String orderId;
  final String orderItemId;
  final String publicationId;
  final int rating;
  final String? comment;
  final CustomerReviewStatus status;
  final int version;
  final DateTime submittedAt;
  final DateTime updatedAt;
}

final class CustomerReviewEligibleLine {
  const CustomerReviewEligibleLine({
    required this.orderId,
    required this.orderItemId,
    required this.publicationId,
    required this.name,
  });

  final String orderId;
  final String orderItemId;
  final String publicationId;
  final String name;
}

final class CustomerReviewsAccount {
  CustomerReviewsAccount({
    required List<CustomerReview> items,
    required List<CustomerReviewEligibleLine> eligible,
  }) : items = List.unmodifiable(items),
       eligible = List.unmodifiable(eligible);

  final List<CustomerReview> items;
  final List<CustomerReviewEligibleLine> eligible;
}

final class StorefrontProductReview {
  const StorefrontProductReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.verifiedPurchase,
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final bool verifiedPurchase;
}

final class StorefrontProductReviews {
  StorefrontProductReviews({
    required this.averageRating,
    required this.publishedCount,
    required Map<int, int> distribution,
    required List<StorefrontProductReview> items,
    required this.serverTime,
  }) : distribution = Map.unmodifiable(distribution),
       items = List.unmodifiable(items);

  final double averageRating;
  final int publishedCount;
  final Map<int, int> distribution;
  final List<StorefrontProductReview> items;
  final DateTime serverTime;
}

final class CustomerReviewMutation {
  const CustomerReviewMutation({
    required this.reviewId,
    required this.status,
    required this.version,
  });

  final String reviewId;
  final CustomerReviewStatus status;
  final int version;
}
