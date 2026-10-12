import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_state.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout_test_support.dart';

void main() {
  test('profile stesso owner mantiene ACK ordine e conclude busy', () async {
    final response = Completer<CheckoutOrderRemoteResponse>();
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
      ..orderOutcomes.add(response.future);
    final auth = _ProfileAuthRepository();
    final store = MemoryCheckoutDraftStore();
    var refreshes = 0;
    final cartState = CartState(
      status: CartViewStatus.ready,
      isAuthenticated: true,
      snapshot: checkoutTestCart(),
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.authFlowTest()),
        authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
        authCallbackSourceProvider.overrideWithValue(const _NoCallbacks()),
        checkoutCartStateProvider.overrideWithValue(cartState),
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
        checkoutCartRefreshProvider.overrideWithValue(() async => refreshes++),
        checkoutRepositoryProvider.overrideWithValue(repository),
        checkoutDraftStoreProvider.overrideWithValue(store),
        checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
        customerIdempotencyKeyFactoryProvider.overrideWithValue(
          () => checkoutTestKey,
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.dispose();
    });
    await _until(
      () =>
          container.read(checkoutControllerProvider).status ==
          CheckoutViewStatus.ready,
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
    expect(
      container.read(checkoutControllerProvider).quote!.isConfirmed,
      isTrue,
    );
    final pending = controller.createOrder();
    await _until(() => repository.orderRequests.isNotEmpty);
    expect(container.read(checkoutControllerProvider).isBusy, isTrue);

    // Cambia soltanto metadata Auth. Owner, shop, cart, indirizzi e delivery
    // restano identici: nessuna altra dependency può invalidare questa prova.
    auth.updateProfile('Nome aggiornato');
    await _until(() {
      final state = container.read(authControllerProvider);
      return state is AuthAuthenticated &&
          state.customer.displayName == 'Nome aggiornato';
    });
    expect(container.read(checkoutCartStateProvider), same(cartState));
    expect(container.read(checkoutControllerProvider).isBusy, isTrue);
    response.complete(
      checkoutTestOrderResponse(order: checkoutTestOrderSnapshot()),
    );
    await pending;

    final state = container.read(checkoutControllerProvider);
    expect(state.order?.id, checkoutTestOrder);
    expect(state.isBusy, isFalse);
    expect(state.pendingOperation, isNull);
    expect(store.draft?.orderId, checkoutTestOrder);
    expect(store.draft?.pendingOperation, isNull);
    expect(refreshes, 1);
    expect(repository.orderRequests, hasLength(1));
  });
}

Future<void> _until(bool Function() predicate) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condizione sintetica non raggiunta.');
}

final class _ProfileAuthRepository implements AuthRepository {
  final _events = StreamController<AuthSessionEvent>.broadcast();
  @override
  AuthenticatedCustomer? currentCustomer = _customer('Nome iniziale');
  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  void updateProfile(String name) {
    currentCustomer = _customer(name);
    _events.add(
      AuthSessionEvent(
        type: AuthSessionEventType.userUpdated,
        customer: currentCustomer,
      ),
    );
  }

  static AuthenticatedCustomer _customer(String name) =>
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: checkoutTestOwner,
        email: null,
        metadata: {'name': name},
      );

  @override
  Future<void> beginSignOut() async {}
  @override
  Future<void> completeSignOut() => signOutLocal();
  @override
  Future<void> signOutLocal() async {
    currentCustomer = null;
  }

  @override
  Future<void> retryPendingRemoteRevocations() async {}
  @override
  Future<void> clearPendingOAuth() async {}
  @override
  Future<bool> launchGoogleSignIn() async => true;
  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async =>
      currentCustomer!;
  Future<void> dispose() => _events.close();
}

final class _NoCallbacks implements AuthCallbackSource {
  const _NoCallbacks();
  @override
  Stream<Uri> get callbacks => const Stream<Uri>.empty();
  @override
  Future<void> dispose() async {}
}
