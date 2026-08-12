import 'dart:async';

import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';

const checkoutTestOwner = '10000000-0000-4000-8000-000000000001';
const checkoutTestPublication = '50000000-0000-4000-8000-000000000001';
const checkoutTestPoint = '51000000-0000-4000-8000-000000000001';
const checkoutTestZone = '52000000-0000-4000-8000-000000000001';
const checkoutTestPickupSlot = '53000000-0000-4000-8000-000000000001';
const checkoutTestDeliverySlot = '53000000-0000-4000-8000-000000000002';
const checkoutTestQuote = '54000000-0000-4000-8000-000000000001';
const checkoutTestOrder = '57000000-0000-4000-8000-000000000001';
const checkoutTestOrderCode = 'MC-0123456789ABCDEF0123';
const checkoutTestAddress = '55000000-0000-4000-8000-000000000001';
const checkoutTestKey = '56000000-0000-4000-8000-000000000001';
final checkoutTestNow = DateTime.utc(2026, 8, 3, 3);

CustomerCartSnapshot checkoutTestCart({int version = 7}) {
  const line = CartLine(
    publicationId: checkoutTestPublication,
    publicName: 'Café público',
    quantity: 2,
    priceClp: 1200,
    snapshotPriceClp: 1200,
    compareAtPriceClp: 1500,
    availability: StorefrontAvailability.available,
    status: CartLineStatus.available,
    changeType: CartLineChangeType.none,
    isGuest: false,
  );
  return CustomerCartSnapshot(
    shopSlug: 'storefront-test',
    version: version,
    items: const [line],
    source: CartSource.account,
    quoteStatus: CartQuoteStatus.indicative,
    requiresCustomerReview: false,
    subtotalClp: 2400,
    idempotent: true,
  );
}

CustomerAddress checkoutTestCustomerAddress({
  String id = checkoutTestAddress,
  String commune = 'Santiago',
}) => CustomerAddress(
  id: id,
  label: 'Casa',
  recipientName: 'Cliente Uno',
  addressLine1: 'Avenida Uno 123',
  addressLine2: null,
  commune: commune,
  region: 'Metropolitana',
  postalCode: '8320000',
  countryCode: 'CL',
  deliveryInstructions: null,
  isDefault: true,
  updatedAt: checkoutTestNow,
);

StorefrontFulfillmentOptions checkoutTestOptions() =>
    StorefrontFulfillmentOptions(
      status: FulfillmentOptionsStatus.ok,
      shopSlug: 'storefront-test',
      currencyCode: 'CLP',
      modes: const [
        CheckoutModeOption(mode: CheckoutFulfillmentMode.pickup, enabled: true),
        CheckoutModeOption(
          mode: CheckoutFulfillmentMode.reservation,
          enabled: true,
        ),
        CheckoutModeOption(
          mode: CheckoutFulfillmentMode.delivery,
          enabled: true,
        ),
      ],
      pickupPoints: const [
        CheckoutPickupPoint(
          id: checkoutTestPoint,
          name: 'Tienda Centro',
          addressLine1: 'Avenida Uno 123',
          addressLine2: null,
          commune: 'Santiago',
          region: 'Metropolitana',
          instructions: 'Retiro en mesón',
        ),
      ],
      deliveryZones: [
        CheckoutDeliveryZone(
          id: checkoutTestZone,
          name: 'Santiago centro',
          region: 'Metropolitana',
          communes: const ['Santiago'],
          feeClp: 2500,
        ),
      ],
      slots: [
        CheckoutFulfillmentSlot(
          id: checkoutTestPickupSlot,
          mode: CheckoutFulfillmentMode.pickup,
          pickupPointId: checkoutTestPoint,
          deliveryZoneId: null,
          label: 'Hoy 16:00–18:00',
          startsAt: checkoutTestNow.add(const Duration(hours: 1)),
          endsAt: checkoutTestNow.add(const Duration(hours: 3)),
        ),
        CheckoutFulfillmentSlot(
          id: checkoutTestDeliverySlot,
          mode: CheckoutFulfillmentMode.delivery,
          pickupPointId: null,
          deliveryZoneId: checkoutTestZone,
          label: 'Mañana 10:00–12:00',
          startsAt: checkoutTestNow.add(const Duration(days: 1)),
          endsAt: checkoutTestNow.add(const Duration(days: 1, hours: 2)),
        ),
      ],
      serverTime: checkoutTestNow,
    );

StorefrontPaymentOptions checkoutTestPaymentOptions({
  bool payAtPickupEnabled = true,
  bool cashOnDeliveryEnabled = true,
}) => StorefrontPaymentOptions(
  status: PaymentOptionsStatus.ok,
  shopSlug: 'storefront-test',
  currencyCode: 'CLP',
  methods: [
    CheckoutPaymentOption(
      method: CheckoutPaymentMethod.payAtPickup,
      enabled: payAtPickupEnabled,
      fulfillmentModes: const [
        CheckoutFulfillmentMode.pickup,
        CheckoutFulfillmentMode.reservation,
      ],
    ),
    CheckoutPaymentOption(
      method: CheckoutPaymentMethod.cashOnDelivery,
      enabled: cashOnDeliveryEnabled,
      fulfillmentModes: const [CheckoutFulfillmentMode.delivery],
    ),
    CheckoutPaymentOption(
      method: CheckoutPaymentMethod.onlinePayment,
      enabled: false,
      fulfillmentModes: const [],
    ),
  ],
  onlineConfiguration: OnlinePaymentConfiguration.notConfigured,
  serverTime: checkoutTestNow,
);

CheckoutQuote checkoutTestQuoteSnapshot({
  CheckoutQuoteStatus status = CheckoutQuoteStatus.quoted,
  bool requiresReview = false,
  int quoteVersion = 2,
  int cartVersion = 7,
  List<CheckoutQuoteChange> changes = const [],
}) => CheckoutQuote(
  id: checkoutTestQuote,
  shopSlug: 'storefront-test',
  cartVersion: cartVersion,
  quoteVersion: quoteVersion,
  status: status,
  fulfillmentMode: CheckoutFulfillmentMode.pickup,
  addressId: null,
  pickupPointId: checkoutTestPoint,
  deliveryZoneId: null,
  slotId: checkoutTestPickupSlot,
  subtotalClp: 2400,
  deliveryFeeClp: 0,
  totalClp: 2400,
  items: const [
    CheckoutQuoteItem(
      publicationId: checkoutTestPublication,
      publicName: 'Café público',
      quantity: 2,
      unitPriceClp: 1200,
      compareAtPriceClp: 1500,
      lineTotalClp: 2400,
      promotionName: null,
      promotionEndsAt: null,
    ),
  ],
  changes: changes,
  requiresCustomerReview: requiresReview,
  quotedAt: checkoutTestNow,
  expiresAt: checkoutTestNow.add(const Duration(minutes: 5)),
  confirmedAt: status == CheckoutQuoteStatus.confirmed
      ? checkoutTestNow.add(const Duration(seconds: 20))
      : null,
  serverTime: checkoutTestNow.add(const Duration(seconds: 10)),
  remainingSeconds: 290,
  idempotent: false,
);

CheckoutRemoteResponse checkoutTestResponse({
  CheckoutRemoteStatus status = CheckoutRemoteStatus.quoted,
  CheckoutQuote? quote,
}) => CheckoutRemoteResponse(
  status: status,
  idempotent: false,
  serverTime: checkoutTestNow.add(const Duration(seconds: 10)),
  quote: quote,
);

CheckoutOrder checkoutTestOrderSnapshot({bool idempotent = false}) =>
    CheckoutOrder(
      id: checkoutTestOrder,
      code: checkoutTestOrderCode,
      status: CheckoutOrderStatus.confirmed,
      version: 1,
      shopSlug: 'storefront-test',
      fulfillmentMode: CheckoutFulfillmentMode.pickup,
      subtotalClp: 2400,
      deliveryFeeClp: 0,
      totalClp: 2400,
      items: checkoutTestQuoteSnapshot().items,
      payment: CheckoutPayment(
        method: CheckoutPaymentMethod.payAtPickup,
        status: CheckoutPaymentStatus.dueAtFulfillment,
        amountClp: 2400,
        currencyCode: 'CLP',
        version: 1,
        failureCode: null,
        createdAt: checkoutTestNow.add(const Duration(seconds: 30)),
        updatedAt: checkoutTestNow.add(const Duration(seconds: 30)),
      ),
      placedAt: checkoutTestNow.add(const Duration(seconds: 30)),
      serverTime: checkoutTestNow.add(const Duration(seconds: 30)),
      idempotent: idempotent,
    );

CheckoutOrderRemoteResponse checkoutTestOrderResponse({
  CheckoutOrderRemoteStatus status = CheckoutOrderRemoteStatus.ok,
  CheckoutOrder? order,
  bool idempotent = false,
}) => CheckoutOrderRemoteResponse(
  status: status,
  idempotent: idempotent,
  serverTime: checkoutTestNow.add(const Duration(seconds: 30)),
  order: order,
  orderId: order?.id,
);

final class MemoryCheckoutDraftStore implements CheckoutDraftStore {
  CheckoutLocalDraft? draft;
  Object? saveError;
  Completer<void>? saveBarrier;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    clearCalls++;
    if (draft?.ownerSubjectId == ownerSubjectId &&
        draft?.shopSlug == shopSlug) {
      draft = null;
    }
  }

  @override
  Future<CheckoutLocalDraft?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    if (draft?.ownerSubjectId != ownerSubjectId ||
        draft?.shopSlug != shopSlug) {
      return null;
    }
    return draft;
  }

  @override
  Future<void> save(CheckoutLocalDraft draft) async {
    saveCalls++;
    if (saveError case final error?) throw error;
    await saveBarrier?.future;
    this.draft = draft;
  }
}

final class FakeCheckoutRepository implements CheckoutRepository {
  FakeCheckoutRepository({
    StorefrontFulfillmentOptions? options,
    StorefrontPaymentOptions? paymentOptions,
  }) : options = options ?? checkoutTestOptions(),
       paymentOptions = paymentOptions ?? checkoutTestPaymentOptions();

  StorefrontFulfillmentOptions options;
  StorefrontPaymentOptions paymentOptions;
  final List<Object> createOutcomes = [];
  final List<Object> confirmOutcomes = [];
  final List<Object> orderOutcomes = [];
  Object? readOutcome;
  Object? readOrderOutcome;
  final List<CheckoutQuoteCreateRequest> createRequests = [];
  final List<({String quoteId, int version, String key})> confirmRequests = [];
  final List<
    ({
      String quoteId,
      int version,
      CheckoutPaymentMethod paymentMethod,
      String key,
    })
  >
  orderRequests = [];
  int loadOptionsCalls = 0;
  int loadPaymentOptionsCalls = 0;
  int readCalls = 0;
  int readOrderCalls = 0;

  @override
  Future<CheckoutOrderRemoteResponse> createOrder({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
    required int expectedQuoteVersion,
    required CheckoutPaymentMethod paymentMethod,
    required String idempotencyKey,
  }) async {
    orderRequests.add((
      quoteId: quoteId,
      version: expectedQuoteVersion,
      paymentMethod: paymentMethod,
      key: idempotencyKey,
    ));
    return _resolveOrder(orderOutcomes);
  }

  @override
  Future<CheckoutRemoteResponse> confirmQuote({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
    required int expectedQuoteVersion,
    required String idempotencyKey,
  }) async {
    confirmRequests.add((
      quoteId: quoteId,
      version: expectedQuoteVersion,
      key: idempotencyKey,
    ));
    return _resolve(confirmOutcomes);
  }

  @override
  Future<CheckoutRemoteResponse> createQuote(
    CheckoutQuoteCreateRequest request,
  ) async {
    createRequests.add(request);
    return _resolve(createOutcomes);
  }

  @override
  Future<StorefrontFulfillmentOptions> loadOptions({
    required String shopSlug,
  }) async {
    loadOptionsCalls++;
    return options;
  }

  @override
  Future<StorefrontPaymentOptions> loadPaymentOptions({
    required String shopSlug,
  }) async {
    loadPaymentOptionsCalls++;
    return paymentOptions;
  }

  @override
  Future<CheckoutRemoteResponse> readQuote({
    required String shopSlug,
    required int cartVersion,
    required String quoteId,
  }) async {
    readCalls++;
    final outcome = readOutcome;
    if (outcome == null) {
      return checkoutTestResponse(status: CheckoutRemoteStatus.notFound);
    }
    if (outcome is CheckoutRemoteResponse) return outcome;
    if (outcome is Future<CheckoutRemoteResponse>) return outcome;
    throw outcome;
  }

  @override
  Future<CheckoutOrderRemoteResponse> readOrder({
    required String shopSlug,
    required String orderId,
  }) async {
    readOrderCalls++;
    final outcome = readOrderOutcome;
    if (outcome == null) {
      return checkoutTestOrderResponse(
        status: CheckoutOrderRemoteStatus.notFound,
      );
    }
    if (outcome is CheckoutOrderRemoteResponse) return outcome;
    if (outcome is Future<CheckoutOrderRemoteResponse>) return outcome;
    throw outcome;
  }

  Future<CheckoutRemoteResponse> _resolve(List<Object> outcomes) async {
    if (outcomes.isEmpty) {
      throw StateError('Missing checkout outcome.');
    }
    final outcome = outcomes.removeAt(0);
    if (outcome is CheckoutRemoteResponse) return outcome;
    if (outcome is Future<CheckoutRemoteResponse>) return outcome;
    throw outcome;
  }

  Future<CheckoutOrderRemoteResponse> _resolveOrder(
    List<Object> outcomes,
  ) async {
    if (outcomes.isEmpty) {
      throw StateError('Missing order outcome.');
    }
    final outcome = outcomes.removeAt(0);
    if (outcome is CheckoutOrderRemoteResponse) return outcome;
    if (outcome is Future<CheckoutOrderRemoteResponse>) return outcome;
    throw outcome;
  }
}
