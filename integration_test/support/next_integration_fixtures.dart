// Dataset dichiaratamente sintetici per componenti/controller di produzione.
// Nessun dato, autenticazione, conteggio o mutazione qui prova il backend live.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/catalog/application/search_assist_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_models.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/data/supabase_storefront_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/commerce_surface_fixtures.dart';
import '../../test/support/storefront_surface_fixtures.dart';

final class Task054LongNameStorefrontFixture {
  Task054LongNameStorefrontFixture._(this.local, this.repository, this.name);

  final Task054StorefrontFixtures local;
  final SupabaseStorefrontRepository repository;
  final String name;

  static Future<Task054LongNameStorefrontFixture> create(Locale locale) async {
    final local = await Task054StorefrontFixtures.create();
    final name = switch (locale.languageCode) {
      'it' =>
        'Caffè sintetico con nome lungo e descrizione della confezione famiglia',
      'en' =>
        'Synthetic coffee with a long product name and family package description',
      'zh' => '合成咖啡测试商品长名称与家庭装包装说明用于检查紧凑布局和大字体显示',
      _ => 'Café sintético con nombre largo y descripción del envase familiar',
    };
    final repository = SupabaseStorefrontRepository(
      invoke: (function, parameters) async {
        final payload = await local.transport.call(function, parameters);
        void rename(Object? value) {
          if (value is Map<String, Object?>) {
            if ((value['id'] as String?)?.startsWith('50000000-') == true) {
              value['name'] = name;
              value['description'] = '$name. $name.';
            }
            for (final child in value.values) {
              rename(child);
            }
          } else if (value is List) {
            for (final child in value) {
              rename(child);
            }
          }
        }

        rename(payload);
        return payload;
      },
    );
    await local.cart.clear(shopSlug: 'storefront-test');
    for (final entry in <String, int>{
      task054VisualPublication: 2,
      '50000000-0000-4000-8000-000000000002': 1,
    }.entries) {
      final product = await repository.fetchProductDetail(
        shopSlug: 'storefront-test',
        publicationId: entry.key,
        cancellation: StorefrontRequestCancellation(),
      );
      await local.cart.setProduct(
        shopSlug: 'storefront-test',
        product: product,
        quantity: entry.value,
      );
    }
    return Task054LongNameStorefrontFixture._(local, repository, name);
  }

  Widget wrap(Widget child) => local.commerce.wrap(
    child,
    additionalOverrides: [
      backendReadinessRepositoryProvider.overrideWithValue(
        const Task054ReadyRepository(),
      ),
      storefrontRepositoryProvider.overrideWithValue(repository),
      storefrontCacheDatabaseProvider.overrideWithValue(local.database),
      storefrontCacheRepositoryProvider.overrideWithValue(local.cache),
      guestCartStoreProvider.overrideWithValue(local.cart),
      customerOrderIdentityProvider.overrideWithValue(null),
      searchAssistRepositoryProvider.overrideWithValue(local.search),
      searchHistoryStoreProvider.overrideWithValue(local.search),
    ],
  );

  Future<void> dispose() => local.dispose();
}

final class Task054PagedInboxFixture implements CustomerNotificationRepository {
  CustomerNotificationFailureKind? failure;
  final cursors = <CustomerNotificationCursor?>[];
  var markReadCalls = 0;
  var readAll = false;

  CustomerNotification get first => _notification('page-1-read', read: true);
  CustomerNotification get second =>
      _notification('page-2-unread', read: readAll);

  CustomerNotification _notification(String id, {required bool read}) =>
      CustomerNotification(
        id: id,
        shopSlug: 'storefront-test',
        category: CustomerNotificationCategory.order,
        event: 'order.confirmed',
        eventVersion: 1,
        titleKey: 'notification.order.confirmed.title',
        bodyKey: 'notification.order.confirmed.body',
        safeArguments: const {'orderCode': 'MC-0123456789ABCDEF0123'},
        destinationType: CustomerNotificationDestinationType.notifications,
        destinationId: null,
        createdAt: id == 'page-1-read'
            ? task054VisualNow
            : task054VisualNow.subtract(const Duration(minutes: 1)),
        readAt: read ? task054VisualNow : null,
        expiresAt: null,
      );

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    cursors.add(before);
    if (failure case final kind?) {
      throw CustomerNotificationRepositoryException(kind);
    }
    return CustomerNotificationPage(
      // Sovrapposizione intenzionale: la seconda pagina non deve duplicare first.
      items: before == null ? [first] : [first, second],
      unreadCount: readAll ? 0 : 1,
      serverTime: task054VisualNow,
      nextCursor: before == null
          ? CustomerNotificationCursor(createdAt: first.createdAt, id: first.id)
          : null,
    );
  }

  @override
  Future<DateTime> markRead(String notificationId) async {
    markReadCalls++;
    if (notificationId == second.id) readAll = true;
    return task054VisualNow;
  }

  @override
  Future<int> markAllRead(String shopSlug) async {
    readAll = true;
    return 1;
  }

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) => throw StateError('Questa fixture non simula deep link remoti');
}

final class Task054MutableReviewFixture implements CustomerReviewRepository {
  Task054MutableReviewFixture(this.delegate);

  final Task054ReviewRepository delegate;
  CustomerReview? saved;
  var submitCalls = 0;
  var updateCalls = 0;
  var failMutation = false;
  Completer<void>? mutationDelay;
  String? lastComment;
  int? lastExpectedVersion;

  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) async {
    final initial = await delegate.listMine(shopSlug: shopSlug);
    return CustomerReviewsAccount(
      items: saved == null ? [] : [saved!],
      eligible: saved == null ? initial.eligible : [],
    );
  }

  @override
  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  }) => delegate.listProduct(
    shopSlug: shopSlug,
    publicationId: publicationId,
    cursor: cursor,
    pageSize: pageSize,
  );

  Future<void> _beforeMutation(String? comment) async {
    lastComment = comment;
    await mutationDelay?.future;
    if (failMutation) throw const CustomerReviewException('unavailable');
  }

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) async {
    submitCalls++;
    await _beforeMutation(comment);
    return _save(orderItemId: orderItemId, rating: rating, comment: comment);
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
    lastExpectedVersion = expectedVersion;
    await _beforeMutation(comment);
    if (saved?.id != reviewId || saved?.version != expectedVersion) {
      throw const CustomerReviewException('version_conflict');
    }
    return _save(
      orderItemId: saved!.orderItemId,
      rating: rating,
      comment: comment,
      withdraw: withdraw,
    );
  }

  CustomerReviewMutation _save({
    required String orderItemId,
    required int rating,
    required String? comment,
    bool withdraw = false,
  }) {
    final status = withdraw
        ? CustomerReviewStatus.withdrawn
        : CustomerReviewStatus.pending;
    final version = (saved?.version ?? 0) + 1;
    saved = CustomerReview(
      id: task054VisualReview,
      orderId: task054VisualOrder,
      orderItemId: orderItemId,
      publicationId: task054VisualPublication,
      rating: rating,
      comment: comment,
      status: status,
      version: version,
      submittedAt: task054VisualNow,
      updatedAt: task054VisualNow,
    );
    return CustomerReviewMutation(
      reviewId: task054VisualReview,
      status: status,
      version: version,
    );
  }
}

final class Task054RecordedAfterSalesFixture
    implements CustomerAfterSalesRepository {
  Task054RecordedAfterSalesFixture(this.delegate);

  final Task054AfterSalesRepository delegate;
  final drafts = <CustomerAfterSalesDraft>[];
  final idempotencyKeys = <String>[];
  final uploads = <CustomerAfterSalesEvidenceInput>[];
  final evidence = <CustomerAfterSalesEvidence>[];
  bool failCreate = false;
  int? failUploadIndex;
  Completer<void>? createDelay;

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async =>
      (await delegate.list(
        shopSlug: shopSlug,
      )).map((value) => _copy(value, evidence: evidence)).toList();

  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) =>
      delegate.listOrderLines(orderId);

  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    drafts.add(draft);
    idempotencyKeys.add(idempotencyKey);
    await createDelay?.future;
    if (failCreate) throw const CustomerAfterSalesException('timeout');
    final value = _copy(
      await delegate.create(draft: draft, idempotencyKey: idempotencyKey),
      draft: draft,
    );
    delegate.createdCases = [value];
    return value;
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) => delegate.cancel(caseId: caseId, expectedVersion: expectedVersion);

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    uploads.add(input);
    if (uploads.length == failUploadIndex) {
      throw const CustomerAfterSalesException('unavailable');
    }
    final id =
        '89000000-0000-4000-8000-${uploads.length.toString().padLeft(12, '0')}';
    evidence.add(
      CustomerAfterSalesEvidence(
        id: id,
        status: 'pending_scan',
        mimeType: input.mimeType,
        createdAt: task054VisualNow,
      ),
    );
    return id;
  }

  CustomerAfterSalesCase _copy(
    CustomerAfterSalesCase value, {
    CustomerAfterSalesDraft? draft,
    List<CustomerAfterSalesEvidence>? evidence,
  }) => CustomerAfterSalesCase(
    id: value.id,
    caseCode: value.caseCode,
    orderId: value.orderId,
    type: draft?.type ?? value.type,
    status: value.status,
    reason: draft?.reason ?? value.reason,
    note: draft?.note ?? value.note,
    version: value.version,
    submittedAt: value.submittedAt,
    updatedAt: value.updatedAt,
    lines: draft == null
        ? value.lines
        : [
            for (final line in draft.lines)
              CustomerAfterSalesLine(
                id: value.lines.first.id,
                orderItemId: line.orderItemId,
                quantity: line.quantity,
                name: value.lines.first.name,
              ),
          ],
    evidence: evidence ?? value.evidence,
    timeline: value.timeline,
  );
}

/// Seam del picker: file PNG sintetici veri, nessun dialogo/permesso/compressione OS.
/// Canali verificati sulla source pinned image_picker1.2.3 e relativi plugin.
final class Task054SyntheticEvidencePicker {
  Task054SyntheticEvidencePicker() {
    directory = Directory.systemTemp.createTempSync('cmc-task054-evidence-');
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zl1sAAAAASUVORK5CYII=',
    );
    paths = List.generate(4, (index) {
      final file = File('${directory.path}/synthetic-${index + 1}.png');
      file.writeAsBytesSync(bytes);
      return file.path;
    });
  }

  late final Directory directory;
  late final List<String> paths;
  var calls = 0;
  static const _legacy = MethodChannel('plugins.flutter.io/image_picker');
  static const _channels = [
    'dev.flutter.pigeon.image_picker_android.ImagePickerApi.pickImages',
    'dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickMultiImage',
  ];

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _channels) {
      messenger.setMockMessageHandler(channel, (_) async {
        calls++;
        return const StandardMessageCodec().encodeMessage([paths]);
      });
    }
    messenger.setMockMethodCallHandler(_legacy, (call) async {
      if (call.method != 'pickMultiImage') throw MissingPluginException();
      calls++;
      return paths;
    });
  }

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _channels) {
      messenger.setMockMessageHandler(channel, null);
    }
    messenger.setMockMethodCallHandler(_legacy, null);
    directory.deleteSync(recursive: true);
  }
}
