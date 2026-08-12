import '../../storefront/domain/storefront_models.dart';

const customerCartMaximumLines = 100;
const customerCartMaximumQuantity = 99;

enum CartLineStatus { available, unavailable }

enum CartLineChangeType { none, priceChanged, promotionChanged, unavailable }

enum CartQuoteStatus { indicative, confirmed }

enum CartSource { guest, account }

enum CartRemoteStatus {
  ok,
  merged,
  partial,
  revalidated,
  versionConflict,
  unavailable,
  limitReached,
}

enum CartMutationOperation { set, remove, clear }

final class CartLine {
  const CartLine({
    required this.publicationId,
    required this.publicName,
    required this.quantity,
    required this.priceClp,
    required this.snapshotPriceClp,
    required this.availability,
    required this.status,
    required this.changeType,
    required this.isGuest,
    this.compareAtPriceClp,
    this.imageUrl,
  });

  final String publicationId;
  final String publicName;
  final int quantity;
  final int priceClp;
  final int snapshotPriceClp;
  final int? compareAtPriceClp;
  final Uri? imageUrl;
  final StorefrontAvailability availability;
  final CartLineStatus status;
  final CartLineChangeType changeType;
  final bool isGuest;

  bool get isAvailable => status == CartLineStatus.available;
  bool get priceChanged => changeType == CartLineChangeType.priceChanged;
  int get lineSubtotalClp => isAvailable ? priceClp * quantity : 0;

  CartLine copyWith({
    int? quantity,
    CartLineStatus? status,
    CartLineChangeType? changeType,
    bool? isGuest,
  }) {
    return CartLine(
      publicationId: publicationId,
      publicName: publicName,
      quantity: quantity ?? this.quantity,
      priceClp: priceClp,
      snapshotPriceClp: snapshotPriceClp,
      compareAtPriceClp: compareAtPriceClp,
      imageUrl: imageUrl,
      availability: availability,
      status: status ?? this.status,
      changeType: changeType ?? this.changeType,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

final class CustomerCartSnapshot {
  CustomerCartSnapshot({
    required this.shopSlug,
    required this.version,
    required List<CartLine> items,
    required this.source,
    required this.quoteStatus,
    required this.requiresCustomerReview,
    required this.subtotalClp,
    required this.idempotent,
    this.quotedAt,
    this.quoteExpiresAt,
  }) : items = List.unmodifiable(items);

  factory CustomerCartSnapshot.empty({
    required String shopSlug,
    required CartSource source,
  }) {
    return CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: 0,
      items: const [],
      source: source,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: 0,
      idempotent: true,
    );
  }

  final String shopSlug;
  final int version;
  final List<CartLine> items;
  final CartSource source;
  final CartQuoteStatus quoteStatus;
  final bool requiresCustomerReview;
  final int subtotalClp;
  final bool idempotent;
  final DateTime? quotedAt;
  final DateTime? quoteExpiresAt;

  bool get isEmpty => items.isEmpty;
  bool get isAuthenticated => source == CartSource.account;
  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);
  int get unavailableItemCount =>
      items.where((item) => !item.isAvailable).length;

  CustomerCartSnapshot withGuestRetained(List<CartLine> retained) {
    if (retained.isEmpty) return this;
    final remoteIds = items.map((item) => item.publicationId).toSet();
    return CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: version,
      items: [
        ...items,
        ...retained
            .where((item) => !remoteIds.contains(item.publicationId))
            .map(
              (item) => item.copyWith(
                status: CartLineStatus.unavailable,
                changeType: CartLineChangeType.unavailable,
              ),
            ),
      ],
      source: source,
      quoteStatus: quoteStatus,
      requiresCustomerReview: true,
      subtotalClp: subtotalClp,
      idempotent: idempotent,
      quotedAt: quotedAt,
      quoteExpiresAt: quoteExpiresAt,
    );
  }
}

final class CartMutationRequest {
  const CartMutationRequest({
    required this.shopSlug,
    required this.operation,
    required this.expectedVersion,
    required this.idempotencyKey,
    this.publicationId,
    this.quantity,
  });

  final String shopSlug;
  final CartMutationOperation operation;
  final String? publicationId;
  final int? quantity;
  final int expectedVersion;
  final String idempotencyKey;
}

final class CartRemoteResponse {
  CartRemoteResponse({
    required this.status,
    required this.snapshot,
    List<String> rejectedPublicationIds = const [],
  }) : rejectedPublicationIds = List.unmodifiable(rejectedPublicationIds);

  final CartRemoteStatus status;
  final CustomerCartSnapshot? snapshot;
  final List<String> rejectedPublicationIds;
}
