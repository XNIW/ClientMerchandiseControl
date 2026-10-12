import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/cart/presentation/add_to_cart_button.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_failure.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/checkout/presentation/checkout_payment_screen.dart';
import 'package:client_merchandise_control/features/checkout/presentation/checkout_screen.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/client_host_visual_fonts.dart';
import '../account/customer_account_test_support.dart';
import '../reservations/reservation_hold_test_support.dart';
import 'checkout_test_support.dart';

const _other = '50000000-0000-4000-8000-000000000002';
const _next = '50000000-0000-4000-8000-000000000003';
final _identity = StateProvider<AuthenticatedCustomer?>((ref) => null);

void main() {
  setUpAll(loadClientHostVisualFonts);
  for (final mode in [CheckoutFulfillmentMode.pickup, CheckoutFulfillmentMode.delivery]) {
    testWidgets(
      'journey sintetico AddToCart pubblico, SQLite same-process, merge, '
      '${mode.name}, ACK ordine perso e prossimo edit conservato',
      (tester) async {
        final database = StorefrontCacheDatabase(NativeDatabase.memory());
        final guest = DriftGuestCartStore(database);
        final authority = _CartAuthority();
        final checkout = FakeCheckoutRepository();
        final draftStore = MemoryCheckoutDraftStore();
        var keyNumber = 0;
        String newKey() => '60000000-0000-4000-8000-'
            '${(++keyNumber).toString().padLeft(12, '0')}';
        ProviderContainer openSession() => ProviderContainer(overrides: [
          appConfigProvider.overrideWithValue(reservationTestConfig()),
          customerAccountIdentityProvider.overrideWith((ref) => ref.watch(_identity)),
          customerAccountRepositoryProvider.overrideWithValue(
            FakeCustomerAccountRepository(
              profile: CustomerProfile(
                userId: checkoutTestOwner,
                displayName: 'Cliente sintético',
                locale: 'es-CL',
                privacyConsentVersion: null,
                privacyConsentedAt: null,
                updatedAt: checkoutTestNow,
              ),
              addresses: [checkoutTestCustomerAddress()],
            ),
          ),
          guestCartStoreProvider.overrideWithValue(guest),
          customerCartRepositoryProvider.overrideWithValue(authority),
          homeControllerProvider.overrideWith(_EmptyHome.new),
          deliveryContextControllerProvider.overrideWith(TestDeliveryContextController.new),
          reservationHoldLocalStoreProvider.overrideWithValue(MemoryReservationHoldStore()),
          reservationHoldRepositoryProvider.overrideWithValue(FakeReservationHoldRepository()),
          checkoutRepositoryProvider.overrideWithValue(checkout),
          checkoutDraftStoreProvider.overrideWithValue(draftStore),
          checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
          customerIdempotencyKeyFactoryProvider.overrideWithValue(newKey),
          // CartController, CheckoutController, cart state e refresh NON sovrascritti.
        ]);
        var container = openSession();
        var router = _router(AppRoutes.catalogLocation);
        await tester.binding.setSurfaceSize(const Size(430, 932));
        try {
          await _mount(tester, container, router);
          final l10n = AppLocalizations.of(tester.element(find.byType(AddToCartButton).first));
          await _tap(tester, find.byKey(const ValueKey('add-to-cart-$checkoutTestPublication')));
          expect(find.text(l10n.cartLocalSavedNotice), findsOneWidget);
          await _tap(tester, find.byKey(const ValueKey('add-to-cart-$_other')));
          await _tap(tester, find.byKey(const ValueKey('journey-open-cart')));
          expect(find.byType(CartScreen), findsOneWidget);
          await _tap(tester, find.byKey(const ValueKey('cart-increase-$checkoutTestPublication')));
          await _tap(tester, find.byKey(const ValueKey('cart-remove-$_other')));
          var cart = container.read(cartControllerProvider).snapshot!;
          expect(cart.items.single.quantity, 2);
          expect(cart.source, CartSource.guest);

          // Chiude widget/controller, mantiene SQLite e store nello stesso processo.
          // Non è un nuovo PID, app kill, storage di device o login Google.
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          container.dispose();
          router.dispose();
          container = openSession();
          router = _router(AppRoutes.cartLocation);
          await _mount(tester, container, router);
          cart = container.read(cartControllerProvider).snapshot!;
          expect(cart.items.single.publicationId, checkoutTestPublication);
          expect(cart.items.single.quantity, 2);
          final persisted = await tester.runAsync(() => guest.read(shopSlug: 'storefront-test'));
          expect(persisted!.items.single.quantity, 2);
          await _tap(tester, find.byKey(const ValueKey('journey-public-entry')));
          await _tap(tester, find.byKey(const ValueKey('add-to-cart-$_other')));
          await _tap(tester, find.byKey(const ValueKey('journey-open-cart')));

          // Cambio identity controllato: esercita il merge production, senza OAuth.
          container.read(_identity.notifier).state = AuthenticatedCustomer.fromUntrustedIdentity(
            subjectId: checkoutTestOwner,
            email: 'customer@example.invalid',
            metadata: const {'name': 'Cliente sintético'},
          );
          await _settle(tester);
          cart = container.read(cartControllerProvider).snapshot!;
          expect(cart.source, CartSource.account);
          expect(authority.mergeCalls, 1);
          expect(cart.items.singleWhere((line) => line.publicationId == checkoutTestPublication).quantity, 2);
          expect((await tester.runAsync(() => guest.read(shopSlug: 'storefront-test')))!.items, isEmpty);
          await _tap(tester, find.byKey(const ValueKey('cart-revalidate')));
          expect(find.text(l10n.cartPriceChangedLine), findsOneWidget);
          expect(find.text(l10n.cartUnavailableLine), findsOneWidget);
          expect(container.read(cartControllerProvider).snapshot!.unavailableItemCount, 1);
          final unavailableIncrease = find.descendant(
            of: find.byKey(const ValueKey('cart-increase-$_other')),
            matching: find.byType(IconButton),
          );
          expect(tester.widget<IconButton>(unavailableIncrease).onPressed, isNull);
          await _tap(tester, find.byKey(const ValueKey('cart-remove-$_other')));
          await _tap(tester, find.byKey(const ValueKey('cart-revalidate')));
          expect(container.read(cartControllerProvider).snapshot!.subtotalClp, 2200);

          await _tap(tester, find.byKey(const ValueKey('cart-change-delivery-context')));
          expect(find.byType(DeliveryContextScreen), findsOneWidget);
          if (mode == CheckoutFulfillmentMode.delivery) {
            await _tap(tester, find.descendant(
              of: find.byType(SegmentedButton<CustomerDeliveryMode>),
              matching: find.text(l10n.deliveryContextDelivery),
            ));
          }
          await _tap(tester, find.widgetWithText(FilledButton,
            mode == CheckoutFulfillmentMode.delivery ? l10n.deliveryContextSelect : l10n.deliveryContextSelected));
          final context = container.read(deliveryContextControllerProvider).context!;
          expect(context.mode, mode == CheckoutFulfillmentMode.delivery
              ? CustomerDeliveryMode.delivery : CustomerDeliveryMode.pickup);
          if (mode == CheckoutFulfillmentMode.delivery) expect(context.addressId, checkoutTestAddress);
          await _tap(tester, find.byTooltip(MaterialLocalizations.of(tester.element(find.byType(DeliveryContextScreen))).backButtonTooltip));
          await _tap(tester, find.byKey(const ValueKey('cart-checkout')));
          expect(find.byType(CheckoutScreen), findsOneWidget);
          await _tap(tester, find.byKey(ValueKey('checkout-mode-${mode.name}')));
          await _tap(tester, find.byKey(const ValueKey('checkout-next-mode')));
          await _tap(tester, find.byKey(const ValueKey('checkout-next-destination')));
          final slot = mode == CheckoutFulfillmentMode.delivery ? checkoutTestDeliverySlot : checkoutTestPickupSlot;
          await _tap(tester, find.byKey(ValueKey('checkout-slot-$slot')));
          await _tap(tester, find.byKey(const ValueKey('checkout-next-slot')));
          final payment = mode == CheckoutFulfillmentMode.delivery
              ? CheckoutPaymentMethod.cashOnDelivery : CheckoutPaymentMethod.payAtPickup;
          await _tap(tester, find.byKey(ValueKey('checkout-payment-${payment.name}')));
          final quote = _quote(authority.snapshot(), mode, confirmed: false);
          final confirmed = _quote(authority.snapshot(), mode, confirmed: true);
          final receipt = _order(confirmed, payment);
          checkout.createOutcomes.add(checkoutTestResponse(status: CheckoutRemoteStatus.requiresReview, quote: quote));
          checkout.confirmOutcomes.add(checkoutTestResponse(status: CheckoutRemoteStatus.confirmed, quote: confirmed));
          checkout.orderOutcomes.addAll([
            const CheckoutRepositoryException(CheckoutFailureKind.timeout),
            checkoutTestOrderResponse(order: receipt, idempotent: true),
          ]);
          checkout.readOrderOutcome = checkoutTestOrderResponse(order: receipt, idempotent: true);
          checkout.beforeOrderResponse = () async {
            if (checkout.orderRequests.length == 1) {
              authority.commitOrder();
            } else {
              // Edit successivo di un altro device, prima del read post-ACK.
              authority.addNextEdit();
            }
          };
          await _tap(tester, find.byKey(const ValueKey('checkout-create-quote')));
          expect(find.byKey(const ValueKey('checkout-authoritative-total')), findsOneWidget);
          expect(checkout.createRequests.single.cartVersion, quote.cartVersion);
          expect(checkout.createRequests.single.selection.mode, mode);
          expect(checkout.createRequests.single.selection.slotId, slot);
          expect(checkout.createRequests.single.selection.deliveryContextVersion, context.version);
          expect(checkout.createRequests.single.selection.addressId,
              mode == CheckoutFulfillmentMode.delivery ? checkoutTestAddress : null);
          await _tap(tester, find.byKey(const ValueKey('checkout-confirm-quote')));
          await _tap(tester, find.byKey(const ValueKey('checkout-open-payment')));
          expect(find.byType(CheckoutPaymentScreen), findsOneWidget);
          expect(find.byKey(const ValueKey('payment-online-not-configured')), findsOneWidget);
          final readsBeforeOrder = authority.readCalls;
          await _tap(tester, find.byKey(const ValueKey('payment-confirm-order')));
          expect(authority.orderCommits, 1);
          expect(authority.quantities, isEmpty);
          expect(container.read(checkoutControllerProvider).order, isNull);
          expect(container.read(checkoutControllerProvider).pendingOperation!.kind, CheckoutPendingOperationKind.order);
          expect(draftStore.draft!.pendingOperation!.idempotencyKey, checkout.orderRequests.first.key);
          // Prima di receipt il cart locale conserva l'intent, non annuncia empty.
          expect(container.read(cartControllerProvider).snapshot!.items.single.quantity, 2);
          expect(authority.readCalls, readsBeforeOrder);
          await _tap(tester, find.byKey(const ValueKey('storefront-status-action')));
          expect(find.byKey(const ValueKey('checkout-order-receipt')), findsOneWidget);
          expect(find.text(checkoutTestOrderCode), findsOneWidget);
          expect(checkout.orderRequests, hasLength(2));
          expect(checkout.orderRequests.first, checkout.orderRequests.last);
          expect(authority.orderCommits, 1);
          expect(authority.readCalls, readsBeforeOrder + 1);
          expect(draftStore.draft!.orderId, checkoutTestOrder);
          expect(draftStore.draft!.pendingOperation, isNull);
          expect(container.read(cartControllerProvider).snapshot!.version, authority.version);
          expect(container.read(cartControllerProvider).snapshot!.items.single.publicationId, _next);

          // Back di produzione, non salto diretto a uno stato Cart precostruito.
          await _tap(tester, find.byTooltip(MaterialLocalizations.of(tester.element(find.byType(CheckoutScreen))).backButtonTooltip));
          expect(find.byType(CartScreen), findsOneWidget);
          expect(find.byKey(const ValueKey('cart-line-$checkoutTestPublication')), findsNothing);
          expect(find.byKey(const ValueKey('cart-line-$_next')), findsOneWidget);
          await _tap(tester, find.byKey(const ValueKey('cart-increase-$_next')));
          expect(authority.quantities[_next], 2);
          expect(container.read(cartControllerProvider).snapshot!.items.single.quantity, 2);
          expect(authority.clearRequests, 0);
          expect(checkout.orderRequests, hasLength(2));
          expect(receipt.items.single.quantity, 2);
          expect(receipt.items.single.publicationId, checkoutTestPublication);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          router.dispose();
          container.dispose();
          await tester.runAsync(database.close);
          await tester.binding.setSurfaceSize(null);
        }
      },
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _settle(tester);
  // Lascia trascorrere la durata pubblica del feedback; non lo rimuove artificialmente.
  final bars = find.byType(SnackBar);
  if (bars.evaluate().isNotEmpty) {
    await tester.pump(tester.widget<SnackBar>(bars.first).duration + const Duration(seconds: 1));
    await _settle(tester);
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await _settle(tester);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _mount(WidgetTester tester, ProviderContainer container, GoRouter router) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: clientHostVisualTheme(AppTheme.light()),
      locale: const Locale('es', 'CL'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await _settle(tester);
}

GoRouter _router(String initial) => GoRouter(initialLocation: initial, routes: [
  GoRoute(path: AppRoutes.catalogLocation, builder: (_, _) => const _PublicAddEntry()),
  GoRoute(path: AppRoutes.cartLocation, builder: (context, _) => Scaffold(
    appBar: AppBar(actions: [IconButton(
      key: const ValueKey('journey-public-entry'),
      onPressed: () => context.go(AppRoutes.catalogLocation),
      icon: const Icon(Icons.storefront_outlined),
    )]),
    body: const CartScreen(),
  )),
  GoRoute(path: AppRoutes.deliveryContextLocation, builder: (_, _) => const DeliveryContextScreen()),
  GoRoute(path: AppRoutes.checkoutLocation, builder: (_, _) => const CheckoutScreen()),
  GoRoute(path: AppRoutes.checkoutPaymentLocation, builder: (_, _) => const CheckoutPaymentScreen()),
]);

class _PublicAddEntry extends StatelessWidget {
  const _PublicAddEntry();
  @override
  Widget build(BuildContext context) => Scaffold(body: Column(children: [
    // Entry pubblica di produzione. Non è Catalog/Product Detail completo.
    AddToCartButton(product: _product(checkoutTestPublication)),
    AddToCartButton(product: _product(_other)),
    TextButton(key: const ValueKey('journey-open-cart'),
      onPressed: () => context.push(AppRoutes.cartLocation), child: const Text('Cart')),
  ]));
}

class _EmptyHome extends HomeController {
  @override
  HomeState build() => const HomeState.empty();
}

StorefrontProductSummary _product(String id) => StorefrontProductSummary(
  id: id,
  category: const StorefrontCategory(id: '40000000-0000-4000-8000-000000000001', slug: 'bebidas', name: 'Bebidas', sortRank: 1),
  name: id == checkoutTestPublication ? 'Café público' : id == _other ? 'Té público' : 'Compra siguiente',
  priceClp: id == checkoutTestPublication ? 1200 : 900,
  featured: false,
  sortRank: 1,
  availability: StorefrontAvailability.available,
  fulfillment: const StorefrontFulfillment(pickup: true, delivery: true, reservation: false),
  catalogVersion: 7,
  publishedAt: checkoutTestNow,
  updatedAt: checkoutTestNow,
);

final class _CartAuthority implements CustomerCartRepository {
  final quantities = <String, int>{checkoutTestPublication: 1};
  var version = 4;
  var repriced = false;
  var readCalls = 0;
  var mergeCalls = 0;
  var clearRequests = 0;
  var orderCommits = 0;

  CustomerCartSnapshot snapshot({bool validated = false}) {
    final lines = [for (final entry in quantities.entries) CartLine(
      publicationId: entry.key,
      publicName: _product(entry.key).name,
      quantity: entry.value,
      priceClp: repriced && entry.key == checkoutTestPublication ? 1100 : _product(entry.key).priceClp,
      snapshotPriceClp: _product(entry.key).priceClp,
      availability: repriced && entry.key == _other ? StorefrontAvailability.unavailable : StorefrontAvailability.available,
      status: repriced && entry.key == _other ? CartLineStatus.unavailable : CartLineStatus.available,
      changeType: repriced && entry.key == _other ? CartLineChangeType.unavailable
          : repriced && entry.key == checkoutTestPublication ? CartLineChangeType.priceChanged : CartLineChangeType.none,
      isGuest: false,
    )];
    return CustomerCartSnapshot(shopSlug: 'storefront-test', version: version,
      items: lines, source: CartSource.account,
      quoteStatus: validated ? CartQuoteStatus.confirmed : CartQuoteStatus.indicative,
      requiresCustomerReview: lines.any((line) => line.changeType != CartLineChangeType.none),
      subtotalClp: lines.fold(0, (sum, line) => sum + line.lineSubtotalClp), idempotent: false,
      quotedAt: validated ? checkoutTestNow : null,
      quoteExpiresAt: validated ? checkoutTestNow.add(const Duration(minutes: 5)) : null);
  }

  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async {
    readCalls++;
    return CartRemoteResponse(status: CartRemoteStatus.ok, snapshot: snapshot());
  }

  @override
  Future<CartRemoteResponse> mergeGuest({required String shopSlug, required List<CartLine> guestItems,
    required int expectedVersion, required String idempotencyKey}) async {
    mergeCalls++;
    for (final line in guestItems) {
      final previous = quantities[line.publicationId] ?? 0;
      quantities[line.publicationId] = previous > line.quantity ? previous : line.quantity;
    }
    version++;
    return CartRemoteResponse(status: CartRemoteStatus.merged, snapshot: snapshot());
  }

  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) async {
    if (request.expectedVersion != version) {
      return CartRemoteResponse(status: CartRemoteStatus.versionConflict, snapshot: snapshot());
    }
    switch (request.operation) {
      case CartMutationOperation.set:
        quantities[request.publicationId!] = request.quantity!;
      case CartMutationOperation.remove:
        quantities.remove(request.publicationId);
      case CartMutationOperation.clear:
        clearRequests++;
        quantities.clear();
    }
    version++;
    return CartRemoteResponse(status: CartRemoteStatus.ok, snapshot: snapshot());
  }

  @override
  Future<CartRemoteResponse> revalidate({required String shopSlug, required int expectedVersion,
    required String idempotencyKey}) async {
    repriced = true;
    version++;
    return CartRemoteResponse(status: CartRemoteStatus.revalidated, snapshot: snapshot(validated: true));
  }

  void commitOrder() {
    orderCommits++;
    quantities.clear();
    version++;
  }

  void addNextEdit() {
    quantities[_next] = 1;
    version++;
  }
}

CheckoutQuote _quote(CustomerCartSnapshot cart, CheckoutFulfillmentMode mode, {required bool confirmed}) {
  final base = checkoutTestQuoteSnapshot();
  final delivery = mode == CheckoutFulfillmentMode.delivery;
  final fee = delivery ? 2500 : 0;
  return CheckoutQuote(id: base.id, shopSlug: cart.shopSlug, cartVersion: cart.version,
    quoteVersion: confirmed ? 3 : 2,
    status: confirmed ? CheckoutQuoteStatus.confirmed : CheckoutQuoteStatus.requiresReview,
    fulfillmentMode: mode, addressId: delivery ? checkoutTestAddress : null,
    pickupPointId: delivery ? null : checkoutTestPoint, deliveryZoneId: delivery ? checkoutTestZone : null,
    slotId: delivery ? checkoutTestDeliverySlot : checkoutTestPickupSlot,
    subtotalClp: cart.subtotalClp, deliveryFeeClp: fee, totalClp: cart.subtotalClp + fee,
    items: [for (final line in cart.items) CheckoutQuoteItem(publicationId: line.publicationId,
      publicName: line.publicName, quantity: line.quantity, unitPriceClp: line.priceClp,
      compareAtPriceClp: null, lineTotalClp: line.lineSubtotalClp, promotionName: null, promotionEndsAt: null)],
    changes: const [CheckoutQuoteChange(publicationId: checkoutTestPublication,
      type: CheckoutChangeType.priceChanged, previousPriceClp: 1200, currentPriceClp: 1100)],
    requiresCustomerReview: !confirmed,
    quotedAt: base.quotedAt, expiresAt: base.expiresAt,
    confirmedAt: confirmed ? checkoutTestNow : null, serverTime: base.serverTime,
    remainingSeconds: base.remainingSeconds, idempotent: false);
}

CheckoutOrder _order(CheckoutQuote quote, CheckoutPaymentMethod method) {
  final base = checkoutTestOrderSnapshot(idempotent: true);
  final options = checkoutTestOptions();
  final slot = options.slot(quote.slotId)!;
  final address = checkoutTestCustomerAddress();
  final delivery = quote.fulfillmentMode == CheckoutFulfillmentMode.delivery;
  final point = options.pickupPoint(checkoutTestPoint)!;
  return CheckoutOrder(id: base.id, code: base.code, status: base.status, version: base.version,
    shopSlug: quote.shopSlug, fulfillmentMode: quote.fulfillmentMode,
    subtotalClp: quote.subtotalClp, deliveryFeeClp: quote.deliveryFeeClp, totalClp: quote.totalClp,
    items: quote.items,
    payment: CheckoutPayment(method: method, status: CheckoutPaymentStatus.dueAtFulfillment,
      amountClp: quote.totalClp, currencyCode: 'CLP', version: 1, failureCode: null,
      createdAt: base.placedAt, updatedAt: base.placedAt),
    placedAt: base.placedAt, serverTime: base.serverTime, idempotent: true,
    fulfillment: CheckoutOrderFulfillment(
      destinationTitle: delivery ? address.label : point.name,
      addressLine1: delivery ? address.addressLine1 : point.addressLine1,
      commune: delivery ? address.commune : point.commune,
      recipientName: delivery ? address.recipientName : null,
      recipientPhoneMasked: null,
      deliveryInstructions: delivery ? address.deliveryInstructions : null,
      slotLabel: slot.label, slotStartsAt: slot.startsAt, slotEndsAt: slot.endsAt,
    ));
}
