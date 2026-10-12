import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_state.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/customer_session_route_fixture.dart';
import '../checkout_test_support.dart';

// AuthController e CheckoutController sono reali; repository/callback sintetici.
// Questi test non certificano sessioni, ordini o riavvii native del backend TEST.
void main() {
  for (final boundary in ['ownerB', 'ownerA-B-A', 'ownerA-B-A-ready', 'shop']) {
    test('ACK ordine non attraversa $boundary prima del rebuild checkout', () async {
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
      final rig = _rig(repository);
      addTearDown(() async {
        rig.container.dispose();
        await rig.auth.dispose();
      });
      await _until(
        () => rig.container.read(checkoutControllerProvider).status ==
            CheckoutViewStatus.ready,
      );
      final controller = rig.container.read(checkoutControllerProvider.notifier);
      await _reachConfirmedQuote(rig.container);
      final pending = controller.createOrder();
      await _until(() => repository.orderRequests.isNotEmpty);
      final savesBeforeBoundary = rig.store.saveCalls;
      expect(rig.store.draft?.ownerSubjectId, routeFixtureOwnerA);
      expect(rig.store.draft?.pendingOperation?.kind,
          CheckoutPendingOperationKind.order);

      // Il caso ready isola Auth senza l'invalidazione dovuta al cart loading.
      // Non leggere Checkout fra il confine e la completion tardiva.
      if (boundary != 'ownerA-B-A-ready') {
        rig.container.read(rig.cart.notifier).state =
          CartState.loading(isAuthenticated: true);
      }
      switch (boundary) {
        case 'ownerB':
          rig.auth.signIn(routeFixtureOwnerB);
          await _until(() => _owner(rig.container) == routeFixtureOwnerB);
        case 'ownerA-B-A' || 'ownerA-B-A-ready':
          rig.auth.signIn(routeFixtureOwnerB);
          rig.auth.signIn(routeFixtureOwnerA);
          await Future<void>.delayed(Duration.zero);
          expect(_owner(rig.container), routeFixtureOwnerA);
        case 'shop':
          rig.container.read(rig.config.notifier).state = AppConfig.authFlowTest(
            storefrontShopSlug: 'storefront-other',
          );
      }
      response.complete(checkoutTestOrderResponse(
        order: checkoutTestOrderSnapshot(),
      ));
      await pending;

      // Il server può aver committato A: il suo journal resta per una successiva
      // riconciliazione autorizzata, senza publish o refresh sotto un altro scope.
      expect(rig.store.saveCalls, savesBeforeBoundary);
      expect(rig.store.draft?.orderId, isNull);
      expect(rig.store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      expect(rig.refreshCount(), 0);
      expect(repository.orderRequests, hasLength(1));
      expect(rig.container.read(checkoutControllerProvider).order, isNull);
    });
  }
}

String? _owner(ProviderContainer container) =>
    switch (container.read(authControllerProvider)) {
      AuthAuthenticated(:final customer) => customer.subjectId,
      _ => null,
    };

({
  ProviderContainer container,
  RouteFixtureAuthRepository auth,
  MemoryCheckoutDraftStore store,
  StateProvider<CartState> cart,
  StateProvider<AppConfig> config,
  int Function() refreshCount,
}) _rig(FakeCheckoutRepository repository) {
  final auth = RouteFixtureAuthRepository();
  final store = MemoryCheckoutDraftStore();
  final config = StateProvider<AppConfig>((ref) => AppConfig.authFlowTest());
  final cart = StateProvider<CartState>((ref) => CartState(
    status: CartViewStatus.ready,
    isAuthenticated: true,
    snapshot: checkoutTestCart(),
  ));
  var refreshes = 0;
  final container = ProviderContainer(overrides: [
    appConfigProvider.overrideWith((ref) => ref.watch(config)),
    authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
    authCallbackSourceProvider.overrideWithValue(const _NoCallbacks()),
    checkoutCartStateProvider.overrideWith((ref) => ref.watch(cart)),
    checkoutAccountStateProvider.overrideWithValue(CustomerAccountState(
      status: CustomerAccountStatus.ready,
      snapshot: CustomerAccountSnapshot(
        profile: null,
        addresses: [checkoutTestCustomerAddress()],
        deletionRequest: null,
        loadedAt: checkoutTestNow,
      ),
    )),
    deliveryContextControllerProvider.overrideWith(
      TestDeliveryContextController.new,
    ),
    checkoutCartRefreshProvider.overrideWithValue(() async => refreshes++),
    checkoutRepositoryProvider.overrideWithValue(repository),
    checkoutDraftStoreProvider.overrideWithValue(store),
    checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
    customerIdempotencyKeyFactoryProvider.overrideWithValue(() => checkoutTestKey),
  ]);
  return (
    container: container,
    auth: auth,
    store: store,
    cart: cart,
    config: config,
    refreshCount: () => refreshes,
  );
}

Future<void> _reachConfirmedQuote(ProviderContainer container) async {
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
  expect(container.read(checkoutControllerProvider).quote?.isConfirmed, isTrue);
}

Future<void> _until(bool Function() predicate) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condizione sintetica non raggiunta.');
}

final class _NoCallbacks implements AuthCallbackSource {
  const _NoCallbacks();
  @override
  Stream<Uri> get callbacks => const Stream<Uri>.empty();
  @override
  Future<void> dispose() async {}
}
