import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_cache.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_cache.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_repository.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/reviews/application/customer_review_providers.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_models.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/account/customer_account_test_support.dart';
import '../features/checkout/checkout_test_support.dart';

enum Task054VisualState { loaded, empty, error, loading }

const task054VisualOrder = '84000000-0000-4000-8000-000000000001';
const task054VisualOrderItem = '85000000-0000-4000-8000-000000000001';
const task054VisualCase = '86000000-0000-4000-8000-000000000001';
const task054VisualReview = '87000000-0000-4000-8000-000000000001';
const task054VisualPublication = '50000000-0000-4000-8000-000000000001';
final task054VisualNow = DateTime.utc(2026, 9, 28, 15);

final class Task054VisualFixtures {
  Task054VisualFixtures({
    Task054VisualState state = Task054VisualState.loaded,
    this.authenticated = true,
  }) : afterSales = Task054AfterSalesRepository(state),
       reviews = Task054ReviewRepository(state),
       inbox = Task054InboxRepository(state),
       account = FakeCustomerAccountRepository(
         addresses: state == Task054VisualState.empty ? [] : null,
       ),
       delivery = Task054DeliveryRepository(state);

  final bool authenticated;
  final Task054AfterSalesRepository afterSales;
  final Task054ReviewRepository reviews;
  final Task054InboxRepository inbox;
  final FakeCustomerAccountRepository account;
  final Task054DeliveryRepository delivery;
  final notificationCache = Task054NotificationCache();
  final deliveryCache = Task054DeliveryCache();
  final checkout = FakeCheckoutRepository();

  Widget wrap(Widget child, {List<Override> additionalOverrides = const []}) {
    final identity = authenticated
        ? AuthenticatedCustomer.fromUntrustedIdentity(
            subjectId: testCustomerSubject,
            email: null,
            metadata: const {},
          )
        : null;
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: 'https://staging.example.invalid',
            supabasePublishableKey: 'sb_publishable_staging',
            authRedirectUri: AppConfig.allowedAuthRedirectUri,
            googleAuthEnabled: 'false',
            storefrontShopSlug: 'storefront-test',
          ),
        ),
        customerAccountIdentityProvider.overrideWithValue(identity),
        customerAccountRepositoryProvider.overrideWithValue(account),
        customerAfterSalesRepositoryProvider.overrideWithValue(afterSales),
        customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
          () => '88000000-0000-4000-8000-000000000001',
        ),
        customerReviewRepositoryProvider.overrideWithValue(reviews),
        customerNotificationIdentityProvider.overrideWithValue(identity),
        customerNotificationShopSlugProvider.overrideWithValue(
          'storefront-test',
        ),
        customerNotificationRepositoryProvider.overrideWithValue(inbox),
        customerNotificationCacheProvider.overrideWithValue(notificationCache),
        deliveryContextShopSlugProvider.overrideWithValue('storefront-test'),
        deliveryContextRepositoryProvider.overrideWithValue(delivery),
        deliveryContextCacheProvider.overrideWithValue(deliveryCache),
        checkoutRepositoryProvider.overrideWithValue(checkout),
        addressSearchPortProvider.overrideWithValue(
          const Task054AddressPorts(),
        ),
        reverseGeocodingPortProvider.overrideWithValue(
          const Task054AddressPorts(),
        ),
        currentLocationPortProvider.overrideWithValue(
          const Task054AddressPorts(),
        ),
        deliveryAddressMapPortProvider.overrideWithValue(
          const Task054AddressPorts(),
        ),
        ...additionalOverrides,
      ],
      child: child,
    );
  }
}

// Home widget di produzione possibili:
// const CustomerAfterSalesScreen()
// const CustomerAfterSalesScreen(caseId: task054VisualCase)
// const CustomerAfterSalesScreen(orderId: task054VisualOrder)
// const CustomerReviewsScreen()
// const CustomerNotificationInboxScreen()
// const DeliveryContextScreen()
// StorefrontProductReviewsSection(publicationId: task054VisualPublication)
// Se usi MaterialApp(home: surface) invece di router, evita submit riuscito e
// tap che chiamano context.go/push. I casi invalidi/dialog funzionano senza GoRouter.

final class Task054AfterSalesRepository
    implements CustomerAfterSalesRepository {
  Task054AfterSalesRepository(this.state);
  Task054VisualState state;
  final pendingList = Completer<List<CustomerAfterSalesCase>>();
  final pendingLines = Completer<CustomerAfterSalesOrderLines>();
  int createCalls = 0;
  int cancelCalls = 0;
  List<CustomerAfterSalesCase>? createdCases;

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async {
    if (state == Task054VisualState.error) {
      throw const CustomerAfterSalesException('unavailable');
    }
    if (state == Task054VisualState.loading) return pendingList.future;
    if (createdCases != null) return createdCases!;
    return state == Task054VisualState.empty ? [] : [task054AfterSalesCase()];
  }

  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) async {
    if (state == Task054VisualState.error) {
      throw const CustomerAfterSalesException('unavailable');
    }
    if (state == Task054VisualState.loading) return pendingLines.future;
    return CustomerAfterSalesOrderLines(
      orderId: orderId,
      shopSlug: 'storefront-test',
      items: state == Task054VisualState.empty
          ? []
          : const [
              CustomerAfterSalesOrderLine(
                orderItemId: task054VisualOrderItem,
                name: 'Producto sintético de prueba con descripción larga',
                orderedQuantity: 3,
                existingOpenQuantity: 1,
                maximumRequestQuantity: 2,
              ),
              CustomerAfterSalesOrderLine(
                orderItemId: '85000000-0000-4000-8000-000000000002',
                name: 'Producto sintético sin unidades elegibles',
                orderedQuantity: 1,
                existingOpenQuantity: 1,
                maximumRequestQuantity: 0,
              ),
            ],
      serverTime: task054VisualNow,
    );
  }

  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    createCalls++;
    if (state == Task054VisualState.error) {
      throw const CustomerAfterSalesException('unavailable');
    }
    final value = task054AfterSalesCase(note: draft.note);
    createdCases = [value];
    return value;
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) async {
    cancelCalls++;
    final value = task054AfterSalesCase(
      status: CustomerAfterSalesStatus.closed,
    );
    createdCases = [value];
    return value;
  }

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async => '89000000-0000-4000-8000-000000000001';
}

CustomerAfterSalesCase task054AfterSalesCase({
  CustomerAfterSalesStatus status = CustomerAfterSalesStatus.submitted,
  String? note = 'Nota sintética: verificar el producto recibido.',
}) => CustomerAfterSalesCase(
  id: task054VisualCase,
  caseCode: 'CS-1234567890ABCDEF',
  orderId: task054VisualOrder,
  type: CustomerAfterSalesType.returnRequest,
  status: status,
  reason: CustomerAfterSalesReason.damaged,
  note: note,
  version: 1,
  submittedAt: task054VisualNow,
  updatedAt: task054VisualNow,
  lines: const [
    CustomerAfterSalesLine(
      id: '8a000000-0000-4000-8000-000000000001',
      orderItemId: task054VisualOrderItem,
      quantity: 1,
      name: 'Producto sintético de prueba con descripción larga',
    ),
  ],
  evidence: const [],
  timeline: [
    CustomerAfterSalesEvent(
      id: '8b000000-0000-4000-8000-000000000001',
      version: 1,
      status: status,
      actorKind: 'customer',
      noteKey: 'afterSales.submitted',
      createdAt: task054VisualNow,
    ),
  ],
);

final class Task054ReviewRepository implements CustomerReviewRepository {
  Task054ReviewRepository(this.state);
  Task054VisualState state;
  final pendingMine = Completer<CustomerReviewsAccount>();
  final pendingProduct = Completer<StorefrontProductReviews>();
  int submitCalls = 0;
  int updateCalls = 0;
  bool failMutation = false;

  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) async {
    if (state == Task054VisualState.error) {
      throw const CustomerReviewException('unavailable');
    }
    if (state == Task054VisualState.loading) return pendingMine.future;
    return CustomerReviewsAccount(
      eligible: state == Task054VisualState.empty
          ? []
          : const [
              CustomerReviewEligibleLine(
                orderId: task054VisualOrder,
                orderItemId: '85000000-0000-4000-8000-000000000002',
                publicationId: task054VisualPublication,
                name: 'Producto sintético de prueba con descripción larga',
              ),
            ],
      items: state == Task054VisualState.empty
          ? []
          : [
              CustomerReview(
                id: task054VisualReview,
                orderId: task054VisualOrder,
                orderItemId: task054VisualOrderItem,
                publicationId: task054VisualPublication,
                rating: 5,
                comment:
                    'Comentario sintético para verificar lectura y edición.',
                status: CustomerReviewStatus.published,
                version: 1,
                submittedAt: task054VisualNow,
                updatedAt: task054VisualNow,
              ),
            ],
    );
  }

  @override
  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  }) async {
    if (state == Task054VisualState.error) {
      throw const CustomerReviewException('unavailable');
    }
    if (state == Task054VisualState.loading) return pendingProduct.future;
    final empty = state == Task054VisualState.empty;
    return StorefrontProductReviews(
      averageRating: empty ? 0 : 4.5,
      publishedCount: empty ? 0 : 24,
      distribution: empty ? const {} : const {1: 0, 2: 0, 3: 0, 4: 12, 5: 12},
      items: empty
          ? []
          : [
              StorefrontProductReview(
                id: task054VisualReview,
                rating: 5,
                comment:
                    'Comentario sintético para verificar lectura y compra verificada.',
                createdAt: task054VisualNow,
                verifiedPurchase: true,
              ),
            ],
      nextCursor: null,
      serverTime: task054VisualNow,
    );
  }

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) async {
    submitCalls++;
    if (failMutation) throw const CustomerReviewException('unavailable');
    return const CustomerReviewMutation(
      reviewId: task054VisualReview,
      status: CustomerReviewStatus.pending,
      version: 1,
    );
  }

  @override
  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  }) async {
    updateCalls++;
    if (failMutation) throw const CustomerReviewException('unavailable');
    return CustomerReviewMutation(
      reviewId: reviewId,
      status: withdraw
          ? CustomerReviewStatus.withdrawn
          : CustomerReviewStatus.pending,
      version: expectedVersion + 1,
    );
  }
}

final class Task054InboxRepository implements CustomerNotificationRepository {
  Task054InboxRepository(this.state);
  Task054VisualState state;
  final pending = Completer<CustomerNotificationPage>();
  int markAllCalls = 0;
  bool read = false;

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    if (state == Task054VisualState.error) {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.unavailable,
      );
    }
    if (state == Task054VisualState.loading) return pending.future;
    final categories = category == null
        ? CustomerNotificationCategory.values
        : [category];
    final items = state == Task054VisualState.empty
        ? <CustomerNotification>[]
        : categories
              .map(
                (value) => CustomerNotification(
                  id: 'notification-${value.name}',
                  shopSlug: shopSlug,
                  category: value,
                  event: 'order.confirmed',
                  eventVersion: 1,
                  titleKey: 'notification.order.confirmed.title',
                  bodyKey: 'notification.order.confirmed.body',
                  safeArguments: const {'orderCode': 'MC-0123456789ABCDEF0123'},
                  // Evita una destinazione mock se il writer tappa questa fixture.
                  destinationType:
                      CustomerNotificationDestinationType.notifications,
                  destinationId: null,
                  createdAt: task054VisualNow,
                  readAt: read ? task054VisualNow : null,
                  expiresAt: null,
                ),
              )
              .toList();
    return CustomerNotificationPage(
      items: items,
      unreadCount: items.where((item) => item.isUnread).length,
      serverTime: task054VisualNow,
      nextCursor: null,
    );
  }

  @override
  Future<DateTime> markRead(String notificationId) async => task054VisualNow;

  @override
  Future<int> markAllRead(String shopSlug) async {
    markAllCalls++;
    read = true;
    return CustomerNotificationCategory.values.length;
  }

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) async => const CustomerNotificationCartDestination(
    event: CustomerNotificationEvent.confirmed,
    eventVersion: 1,
  );
}

final class Task054NotificationCache implements CustomerNotificationCache {
  List<CustomerNotification> items = [];
  @override
  Future<List<CustomerNotification>> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async => items;
  @override
  Future<void> write({
    required String ownerSubjectId,
    required String shopSlug,
    required List<CustomerNotification> items,
  }) async {
    this.items = items;
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    items = [];
  }
}

final class Task054DeliveryRepository implements DeliveryContextRepository {
  Task054DeliveryRepository(this.state);
  Task054VisualState state;
  CustomerDeliveryContext? selected;
  final pending = Completer<CustomerDeliveryContext?>();
  @override
  Future<CustomerDeliveryContext?> read({required String shopSlug}) async {
    if (state == Task054VisualState.error) {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unavailable,
      );
    }
    if (state == Task054VisualState.loading) return pending.future;
    // Nessun contesto selezionato di partenza: apre Delivery e l'editor indirizzo.
    return selected;
  }

  @override
  Future<CustomerDeliveryContext> preview({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  }) async => _context(shopSlug, mode, addressId, pickupPointId);
  @override
  Future<CustomerDeliveryContext> select({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    required int expectedVersion,
    String? addressId,
    String? pickupPointId,
  }) async {
    selected = _context(shopSlug, mode, addressId, pickupPointId);
    return selected!;
  }

  CustomerDeliveryContext _context(
    String shopSlug,
    CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
  ) => CustomerDeliveryContext(
    ownerUserId: testCustomerSubject,
    shopSlug: shopSlug,
    mode: mode,
    addressId: addressId,
    pickupPointId: pickupPointId,
    pickupPointName: mode == CustomerDeliveryMode.pickup
        ? 'Tienda sintética'
        : null,
    serviceabilityStatus: DeliveryServiceabilityStatus.serviceable,
    deliveryZoneId: checkoutTestZone,
    deliveryZoneName: 'Zona sintética',
    estimatedFeeClp: mode == CustomerDeliveryMode.pickup ? 0 : 2500,
    earliestSlotStartsAt: task054VisualNow.add(const Duration(days: 1)),
    earliestSlotEndsAt: task054VisualNow.add(const Duration(days: 1, hours: 2)),
    version: 1,
    selectedAt: task054VisualNow,
    serverTime: task054VisualNow,
  );
}

final class Task054DeliveryCache implements DeliveryContextCacheStore {
  CustomerDeliveryContext? value;
  @override
  Future<CustomerDeliveryContext?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async => value;
  @override
  Future<void> write({
    required String ownerSubjectId,
    required CustomerDeliveryContext context,
  }) async {
    value = context;
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    value = null;
  }
}

final class Task054AddressPorts
    implements
        AddressSearchPort,
        ReverseGeocodingPort,
        CurrentLocationPort,
        DeliveryAddressMapPort {
  const Task054AddressPorts();
  @override
  bool get configured => false;
  @override
  Future<List<AddressSearchSuggestion>> search(String query) async => [];
  @override
  Future<ReverseGeocodedAddress?> resolve(
    AddressSearchSuggestion suggestion,
  ) async => null;
  @override
  Future<ReverseGeocodedAddress?> reverse(
    DeliveryCoordinate coordinate,
  ) async => null;
  @override
  Future<DeliveryCoordinate?> readOnce() async => null;
  @override
  Future<DeliveryCoordinate> previewAndAdjust(
    DeliveryCoordinate initial,
  ) async => initial;
}
