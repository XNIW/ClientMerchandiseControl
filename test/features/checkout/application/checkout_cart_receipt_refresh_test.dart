import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_state.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout_test_support.dart';

final _identity = StateProvider<AuthenticatedCustomer>((ref) => _customer());
final _shop = StateProvider<String>((ref) => 'storefront-test');

void main() {
  for (final guestReadFails in [false, true]) {
    test('receipt confermata resta dopo refresh cart vero fallito su '
        '${guestReadFails ? 'store guest' : 'read account'}', () async {
      final guest = _ReceiptGuestStore(failSecondRead: guestReadFails);
      final cartRepository = _ReceiptCartRepository(
        failSecondRead: !guestReadFails,
      );
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(
          checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
        )
        ..confirmOutcomes.add(
          checkoutTestResponse(
            status: CheckoutRemoteStatus.confirmed,
            quote: checkoutTestQuoteSnapshot(
              status: CheckoutQuoteStatus.confirmed,
            ),
          ),
        )
        ..orderOutcomes.add(
          checkoutTestOrderResponse(order: checkoutTestOrderSnapshot()),
        );
      final store = MemoryCheckoutDraftStore();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWith((ref) => _config(ref.watch(_shop))),
          customerAccountIdentityProvider.overrideWith(
            (ref) => ref.watch(_identity),
          ),
          guestCartStoreProvider.overrideWithValue(guest),
          customerCartRepositoryProvider.overrideWithValue(cartRepository),
          checkoutAccountStateProvider.overrideWithValue(
            CustomerAccountState(
              status: CustomerAccountStatus.ready,
              snapshot: CustomerAccountSnapshot(
                profile: null,
                addresses: [checkoutTestCustomerAddress()],
                deletionRequest: null,
                loadedAt: checkoutTestNow,
              ),
            ),
          ),
          deliveryContextControllerProvider.overrideWith(
            TestDeliveryContextController.new,
          ),
          checkoutRepositoryProvider.overrideWithValue(repository),
          checkoutDraftStoreProvider.overrideWithValue(store),
          checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
          customerIdempotencyKeyFactoryProvider.overrideWithValue(
            () => checkoutTestKey,
          ),
          // checkoutCartStateProvider e checkoutCartRefreshProvider reali.
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkoutControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.selectMode(CheckoutFulfillmentMode.pickup);
      await controller.nextStep();
      await controller.selectPickupPoint(checkoutTestPoint);
      await controller.nextStep();
      await controller.selectSlot(checkoutTestPickupSlot);
      await controller.nextStep();
      await controller.selectPaymentMethod(CheckoutPaymentMethod.payAtPickup);
      await controller.createQuote();
      await controller.confirmQuote();
      await controller.createOrder();
      await Future<void>.delayed(Duration.zero);

      final cartFailure = container.read(cartControllerProvider);
      expect(cartFailure.status, CartViewStatus.failure);
      expect(cartFailure.failureKind, CartFailureKind.timeout);
      expect(guest.readCalls, 2);
      expect(cartRepository.readCalls, guestReadFails ? 1 : 2);
      final receipt = container.read(checkoutControllerProvider);
      expect(receipt.order?.id, checkoutTestOrder);
      expect(receipt.pendingOperation, isNull);
      expect(receipt.failureKind, isNull);
      expect(store.draft?.orderId, checkoutTestOrder);
      expect(repository.orderRequests, hasLength(1));

      // Il recupero del cart è una read: non produce un nuovo ordine o clear.
      await container.read(cartControllerProvider.notifier).retry();
      expect(container.read(cartControllerProvider).snapshot?.isEmpty, isTrue);
      expect(
        container.read(checkoutControllerProvider).order?.id,
        checkoutTestOrder,
      );
      expect(repository.orderRequests, hasLength(1));
      expect(cartRepository.mutationCalls, 0);
      expect(guest.clearCalls, 0);

      // La precedenza receipt non si estende a owner/shop differenti.
      if (guestReadFails) {
        container.read(_shop.notifier).state = 'storefront-other';
      } else {
        container.read(_identity.notifier).state = _customer(
          subjectId: '10000000-0000-4000-8000-000000000002',
        );
      }
      await _waitFor(container, (state) => state.order == null);
      expect(container.read(checkoutControllerProvider).order, isNull);
      expect(repository.orderRequests, hasLength(1));
    });
  }
}

Future<CheckoutState> _waitFor(
  ProviderContainer container,
  bool Function(CheckoutState state) predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final state = container.read(checkoutControllerProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw TestFailure('Stato checkout non raggiunto');
}

AuthenticatedCustomer _customer({String subjectId = checkoutTestOwner}) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subjectId,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente'},
    );

AppConfig _config(String shopSlug) => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: shopSlug,
);

final class _ReceiptCartRepository implements CustomerCartRepository {
  _ReceiptCartRepository({required this.failSecondRead});

  final bool failSecondRead;
  int readCalls = 0;
  int mutationCalls = 0;

  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async {
    readCalls++;
    if (failSecondRead && readCalls == 2) {
      throw const CartRepositoryException(CartFailureKind.timeout);
    }
    final snapshot = readCalls == 1
        ? checkoutTestCart()
        : CustomerCartSnapshot(
            shopSlug: shopSlug,
            version: 8,
            items: const [],
            source: CartSource.account,
            quoteStatus: CartQuoteStatus.indicative,
            requiresCustomerReview: false,
            subtotalClp: 0,
            idempotent: true,
          );
    return CartRemoteResponse(status: CartRemoteStatus.ok, snapshot: snapshot);
  }

  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) async {
    mutationCalls++;
    throw UnimplementedError();
  }

  @override
  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();
}

final class _ReceiptGuestStore implements GuestCartStore {
  _ReceiptGuestStore({required this.failSecondRead});

  final bool failSecondRead;
  int readCalls = 0;
  int clearCalls = 0;

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async {
    readCalls++;
    if (failSecondRead && readCalls == 2) {
      throw const CartRepositoryException(CartFailureKind.timeout);
    }
    return CustomerCartSnapshot.empty(
      shopSlug: shopSlug,
      source: CartSource.guest,
    );
  }

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async => throw UnimplementedError();

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async => throw UnimplementedError();

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async => throw UnimplementedError();

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async {
    clearCalls++;
    throw UnimplementedError();
  }

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async => throw UnimplementedError();
}
