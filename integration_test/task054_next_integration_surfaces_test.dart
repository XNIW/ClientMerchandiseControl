// UI/controller produzione con fixture dichiarate: nessuna prova staging,
// tastiera di sistema, screen reader, provider o persistenza dopo kill/restart.
import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/delivery_live_map.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/presentation/order_detail_screen.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/product_detail/presentation/product_detail_screen.dart';
import 'package:client_merchandise_control/features/reviews/application/customer_review_providers.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/delivery_tracking/delivery_tracking_test_support.dart';
import '../test/features/orders/customer_order_test_support.dart';
import '../test/support/commerce_surface_fixtures.dart';
import 'support/next_integration_fixtures.dart';
import 'support/visual_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final surface in <String, Widget>{
      'home': const Scaffold(body: SafeArea(child: HomeScreen())),
      'catalog': const Scaffold(body: SafeArea(child: CatalogScreen())),
      'product': const ProductDetailScreen(
        publicationId: task054VisualPublication,
      ),
      'cart': const Scaffold(body: SafeArea(child: CartScreen())),
    }.entries) {
      testWidgets(
        '${surface.key} compatto200% nomi lunghi ${locale.toLanguageTag()}',
        (tester) async {
          final fixture = await Task054LongNameStorefrontFixture.create(locale);
          try {
            await tester.pumpWidget(
              fixture.wrap(_app(surface.value, locale: locale, compact: true)),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getSize(
                find.byKey(const ValueKey('task054-compact-viewport')),
              ),
              const Size(320, 568),
            );
            final container = ProviderScope.containerOf(
              tester.element(
                find.byType(
                  <String, Type>{
                    'home': HomeScreen,
                    'catalog': CatalogScreen,
                    'product': ProductDetailScreen,
                    'cart': CartScreen,
                  }[surface.key]!,
                ),
              ),
            );
            switch (surface.key) {
              case 'home':
                expect(
                  container
                      .read(homeControllerProvider)
                      .data!
                      .featured
                      .first
                      .name,
                  fixture.name,
                );
                await _reveal(
                  tester,
                  find.byKey(const ValueKey('home-promotion-spotlight')),
                );
              case 'catalog':
                expect(
                  container.read(catalogControllerProvider).items.first.name,
                  fixture.name,
                );
                await _reveal(
                  tester,
                  find.byKey(
                    const ValueKey('catalog-product-$task054VisualPublication'),
                  ),
                );
              case 'product':
                expect(
                  container
                      .read(
                        productDetailControllerProvider(
                          task054VisualPublication,
                        ),
                      )
                      .product!
                      .name,
                  fixture.name,
                );
                await _reveal(
                  tester,
                  find.byKey(const ValueKey('product-detail-name')),
                );
              case 'cart':
                final increase = find.byKey(
                  const ValueKey('cart-increase-$task054VisualPublication'),
                );
                await _reveal(tester, increase);
                await tester.tap(increase);
                await tester.pumpAndSettle();
                final snapshot = container
                    .read(cartControllerProvider)
                    .snapshot!;
                expect(snapshot.items.first.publicName, fixture.name);
                expect(snapshot.items.first.quantity, 3);
                // Il dato nasce e cambia nello store Drift reale, in DB memory:
                // questa verifica non dichiara durevolezza dopo kill/restart.
                expect(
                  (await fixture.local.cart.read(
                    shopSlug: 'storefront-test',
                  )).items.first.quantity,
                  3,
                );
            }
            expect(find.text(fixture.name), findsWidgets);
            await captureVisual(
              tester,
              '${surface.key}-compact200-long-${locale.toLanguageTag()}',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: 'Viewport320×568 e reflow200%',
            );
          } finally {
            await _unmount(tester);
            await fixture.dispose();
          }
        },
      );
    }
  }

  testWidgets('inbox non lette parziale raggiunge pagina2 e deduplica', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final repository = Task054PagedInboxFixture();
    await tester.pumpWidget(
      fixture.wrap(
        _app(const CustomerNotificationInboxScreen(), compact: true),
        additionalOverrides: [
          customerNotificationRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    try {
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      expect(
        container.read(customerNotificationInboxControllerProvider).unreadCount,
        1,
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('notifications-unread-only')),
      );
      await tester.tap(find.byKey(const ValueKey('notifications-unread-only')));
      await tester.pumpAndSettle();
      final partial = container.read(
        customerNotificationInboxControllerProvider,
      );
      expect(partial.unreadOnly, isTrue);
      expect(partial.visibleItems, isEmpty);
      expect(partial.hasMore, isTrue);
      expect(
        find.byKey(const ValueKey('notifications-filter-empty')),
        findsOneWidget,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      expect(find.text(l10n.notificationsEmptyTitle), findsNothing);
      final more = find.byKey(const ValueKey('notifications-load-more'));
      await _reveal(tester, more);
      await captureVisual(tester, 'inbox-unread-partial-compact200');
      await tester.tap(more);
      await tester.pumpAndSettle();
      final loaded = container.read(
        customerNotificationInboxControllerProvider,
      );
      expect(repository.cursors.map((cursor) => cursor?.id), [
        null,
        repository.first.id,
      ]);
      expect(loaded.items.map((item) => item.id), [
        repository.first.id,
        repository.second.id,
      ]);
      expect(loaded.visibleItems.single.id, repository.second.id);
      expect(loaded.unreadCount, 1);
      expect(loaded.hasMore, isFalse);
      final unread = find.byKey(
        ValueKey('notification-${repository.second.id}'),
      );
      await _reveal(tester, unread);
      await captureVisual(tester, 'inbox-page2-unread-compact200');
      await tester.tap(unread);
      await tester.pumpAndSettle();
      expect(repository.markReadCalls, 1);
      expect(
        container.read(customerNotificationInboxControllerProvider).unreadCount,
        0,
      );
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .visibleItems,
        isEmpty,
      );
      expect(fixture.notificationCache.items, hasLength(2));
      expect(
        fixture.notificationCache.items.every((item) => !item.isUnread),
        isTrue,
      );
      await captureVisual(tester, 'inbox-page2-read-empty-compact200');
      expect(tester.takeException(), isNull);
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets('inbox offline conserva cache e auth scaduta la elimina', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final repository = Task054PagedInboxFixture()
      ..failure = CustomerNotificationFailureKind.offline;
    fixture.notificationCache.items = [repository.second];
    await tester.pumpWidget(
      fixture.wrap(
        _app(const CustomerNotificationInboxScreen()),
        additionalOverrides: [
          customerNotificationRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    try {
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      final offline = container.read(
        customerNotificationInboxControllerProvider,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      expect(offline.status, CustomerNotificationInboxStatus.offline);
      expect(offline.isFromCache, isTrue);
      expect(offline.items.single.id, repository.second.id);
      expect(find.text(l10n.notificationsOffline), findsOneWidget);
      expect(
        find.byKey(ValueKey('notification-${repository.second.id}')),
        findsOneWidget,
      );
      await captureVisual(tester, 'inbox-offline-cache');
      repository.failure = CustomerNotificationFailureKind.unauthorized;
      await tester.tap(find.text(l10n.deliveryContextRetry));
      await tester.pumpAndSettle();
      final expired = container.read(
        customerNotificationInboxControllerProvider,
      );
      expect(expired.status, CustomerNotificationInboxStatus.failure);
      expect(expired.failure, CustomerNotificationFailureKind.unauthorized);
      expect(expired.items, isEmpty);
      expect(expired.unreadCount, 0);
      expect(expired.isFromCache, isFalse);
      expect(fixture.notificationCache.items, isEmpty);
      expect(
        find.byKey(ValueKey('notification-${repository.second.id}')),
        findsNothing,
      );
      expect(find.text(l10n.customerAccountUnavailable), findsOneWidget);
      await captureVisual(tester, 'inbox-auth-expired-purged');
      expect(tester.takeException(), isNull);
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets('recensione submit busy failure retry edit conserva commento', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final repository = Task054MutableReviewFixture(fixture.reviews)
      ..failMutation = true;
    await tester.pumpWidget(
      fixture.wrap(
        _app(const CustomerReviewsScreen(), compact: true),
        additionalOverrides: [
          customerReviewRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    try {
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerReviewsScreen)),
      );
      await _reveal(tester, find.text(l10n.reviewsLeave));
      await tester.tap(find.text(l10n.reviewsLeave));
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      const comment =
          'Comentario sintético conservado después de un error de envío.';
      await tester.enterText(field, comment);
      final submit = find.byKey(const ValueKey('review-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      repository.mutationDelay = Completer<void>();
      await tester.tap(submit);
      await tester.pump();
      expect(repository.submitCalls, 1);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.widget<TextField>(field).enabled, isFalse);
      await captureVisual(tester, 'review-submit-busy-compact200');
      repository.mutationDelay!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, comment);
      expect(repository.saved, isNull);
      expect(find.text(l10n.reviewsFailure), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await captureVisual(
        tester,
        'review-submit-failure-comment-preserved-compact200',
      );
      repository.failMutation = false;
      repository.mutationDelay = null;
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repository.submitCalls, 2);
      expect(repository.lastComment, comment);
      expect(repository.saved!.comment, comment);
      expect(repository.saved!.version, 1);
      expect(repository.saved!.rating, 5);
      expect(find.byType(AlertDialog), findsNothing);
      await _waitForFailureNotice(tester);
      await tester.tap(find.text(l10n.reviewsMine));
      await tester.pumpAndSettle();
      expect(find.textContaining(comment), findsOneWidget);
      await captureVisual(tester, 'review-submitted-readback-compact200');
      final edit = find.byTooltip(l10n.reviewsEdit);
      await _reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, comment);
      const edited =
          'Comentario sintético editado sin perder el texto en el retry.';
      await tester.enterText(field, edited);
      repository.failMutation = true;
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repository.updateCalls, 1);
      expect(repository.saved!.version, 1);
      expect(tester.widget<TextField>(field).controller!.text, edited);
      await captureVisual(
        tester,
        'review-edit-failure-comment-preserved-compact200',
      );
      repository.failMutation = false;
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repository.updateCalls, 2);
      expect(repository.lastExpectedVersion, 1);
      expect(repository.saved!.version, 2);
      expect(find.byType(AlertDialog), findsNothing);
      await _waitForFailureNotice(tester);
      expect(find.textContaining(edited), findsOneWidget);
      await captureVisual(tester, 'review-edited-readback-compact200');
      await _reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Bozza sintetica da annullare');
      final cancelLabel = MaterialLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      ).cancelButtonLabel;
      final cancel = find.text(cancelLabel);
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.updateCalls, 2);
      expect(repository.saved!.comment, edited);
      expect(repository.saved!.version, 2);
      expect(find.textContaining(edited), findsOneWidget);
      await captureVisual(tester, 'review-edit-cancel-readback-compact200');
      expect(tester.takeException(), isNull);
    } finally {
      if (repository.mutationDelay case final delay? when !delay.isCompleted) {
        delay.complete();
      }
      await _unmount(tester);
    }
  });

  testWidgets('tracking provider OFF conserva ordine fresh e stale testuali', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final orders = FakeCustomerOrderRepository()
      ..detailOutcomes.add(
        orderTestDetail(
          status: CustomerOrderStatus.outForDelivery,
          version: 2,
          fulfillmentMode: CustomerOrderFulfillmentMode.delivery,
        ),
      );
    final tracking = FakeDeliveryTrackingRepository()
      ..snapshot = trackingLiveSnapshot(orderId: orderTestOrder);
    var mapFactories = 0;
    final identity = AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: orderTestOwner,
      email: null,
      metadata: const {},
    );
    await tester.pumpWidget(
      fixture.wrap(
        _app(const OrderDetailScreen(orderId: orderTestOrder)),
        additionalOverrides: [
          customerOrderIdentityProvider.overrideWithValue(identity),
          customerOrderShopSlugProvider.overrideWithValue(orderTestShop),
          customerOrderRepositoryProvider.overrideWithValue(orders),
          customerOrderCacheStoreProvider.overrideWithValue(
            MemoryCustomerOrderCacheStore(),
          ),
          customerOrderClockProvider.overrideWithValue(() => orderTestNow),
          deliveryTrackingRepositoryProvider.overrideWithValue(tracking),
          deliveryTrackingCacheProvider.overrideWithValue(
            MemoryDeliveryTrackingCache(),
          ),
          deliveryTrackingClockProvider.overrideWithValue(
            () => trackingTestNow,
          ),
          deliveryTrackingPollIntervalProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
          deliveryMapConfigurationProvider.overrideWithValue(
            const DeliveryMapConfiguration(
              enabled: false,
              nativeConfigurationPresent: false,
            ),
          ),
          deliveryMapAdapterFactoryProvider.overrideWithValue(() {
            mapFactories++;
            return FakeDeliveryMapAdapter();
          }),
        ],
      ),
    );
    try {
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OrderDetailScreen)),
      );
      await _reveal(tester, find.text(l10n.deliveryTrackingFresh));
      expect(tracking.loadCalls, 1);
      expect(tracking.watchCalls, 1);
      expect(
        find.byKey(const ValueKey('delivery-tracking-card')),
        findsOneWidget,
      );
      expect(mapFactories, 0);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      await captureVisual(tester, 'tracking-provider-off-fresh-text');
      tracking.stream.add(
        trackingLiveSnapshot(
          orderId: orderTestOrder,
          version: 5,
          freshness: 'stale',
        ),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, find.text(l10n.deliveryTrackingStale));
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
      expect(
        find.byKey(const ValueKey('order-detail-timeline')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(find.textContaining('-33.446'), findsNothing);
      expect(find.textContaining('-70.655'), findsNothing);
      expect(mapFactories, 0);
      await captureVisual(tester, 'tracking-provider-off-stale-text');
      expect(tester.takeException(), isNull);
    } finally {
      await _unmount(tester);
      await tracking.stream.close();
    }
  });
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('es', 'CL'),
  bool compact = false,
}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: !compact
      ? null
      : (context, child) => Center(
          child: SizedBox(
            key: const ValueKey('task054-compact-viewport'),
            width: 320,
            height: 568,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(320, 568),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
          ),
        ),
  home: home,
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

Future<void> _waitForFailureNotice(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    // Attende la durata della notifica reale: il precedente errore non deve
    // coprire la CTA edit né contaminare una cattura del successivo successo.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}
