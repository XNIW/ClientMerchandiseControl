import '../../storefront/domain/storefront_models.dart';
import 'cart_models.dart';

abstract interface class GuestCartStore {
  Future<CustomerCartSnapshot> read({required String shopSlug});

  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  });

  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  });

  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  });

  Future<CustomerCartSnapshot> clear({required String shopSlug});

  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  });
}

abstract interface class CustomerCartRepository {
  Future<CartRemoteResponse> read({required String shopSlug});

  Future<CartRemoteResponse> mutate(CartMutationRequest request);

  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  });
}
