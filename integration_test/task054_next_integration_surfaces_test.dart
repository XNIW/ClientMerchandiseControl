// UI/controller produzione con fixture dichiarate: nessuna prova staging,
// tastiera di sistema, screen reader, provider o persistenza dopo kill/restart.
import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/address_creation_intent.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
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
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/delivery_tracking/delivery_tracking_test_support.dart';
import '../test/features/account/customer_account_test_support.dart';
import '../test/features/orders/customer_order_test_support.dart';
import '../test/support/commerce_surface_fixtures.dart';
import '../test/support/storefront_surface_fixtures.dart';
import 'support/next_integration_fixtures.dart';
import 'support/visual_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'address editor focus compatto200% rende recuperabili errori immediati e differiti',
    (tester) async {
      final fixture = Task054VisualFixtures();
      await tester.pumpWidget(
        fixture.wrap(
          _app(
            const Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: CustomerAccountPanel(
                    authDisplayName: 'Cliente sintético',
                  ),
                ),
              ),
            ),
            compact: true,
          ),
        ),
      );
      try {
        await tester.pumpAndSettle();
        final edit = find.byKey(
          const ValueKey('customer-address-edit-$testAddressId'),
        );
        await _reveal(tester, edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        final line1 = find.byKey(
          const ValueKey('customer-address-field-line1'),
        );
        const draft = 'Calle borrador conservado 456';
        await _reveal(tester, line1);
        await tester.enterText(line1, draft);
        fixture.account.mutationError =
            const CustomerAccountRepositoryException(
              CustomerAccountFailureKind.unavailable,
            );
        final submit = find.byKey(const ValueKey('customer-address-submit'));
        final editable = find.descendant(
          of: line1,
          matching: find.byType(EditableText),
        );
        await tester.showKeyboard(line1);
        await _expectAddressKeyboardReady(tester, editable);
        await _reveal(tester, submit);
        await _expectAddressKeyboardReady(tester, editable);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsOneWidget,
        );
        expect(tester.widget<TextFormField>(line1).controller!.text, draft);
        final l10n = AppLocalizations.of(tester.element(line1));
        expect(
          find.byKey(const ValueKey('customer-address-save-failure')),
          findsOneWidget,
        );
        expect(find.text(l10n.customerAccountUnavailable), findsWidgets);
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        expect(fixture.account.addressUpdates.single.expectedVersion, 1);
        await _expectAddressRecoveryReachable(tester);
        await Scrollable.ensureVisible(tester.element(editable), alignment: 0);
        await tester.pumpAndSettle();
        expect(editable.hitTestable(), findsOneWidget);
        await tester.tap(editable);
        await tester.showKeyboard(line1);
        await _expectAddressKeyboardReady(tester, editable);
        final input = tester.widget<EditableText>(editable);
        expect(input.focusNode.hasFocus, isTrue);
        expect(input.readOnly, isFalse);
        await _expectAddressRecoveryReachable(tester);
        await captureVisual(tester, 'address-editor-focus-compact200');
        // Il frame OS permette di verificare l'IME prima del retry differito;
        // le metriche Flutter non sostituiscono l'ispezione dei pixel OS.
        final delayed = Completer<void>();
        fixture.account.addressMutationBarrier = delayed;
        await _reveal(tester, submit);
        await _expectAddressKeyboardReady(tester, editable);
        await tester.tap(submit);
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byKey(const ValueKey('customer-address-saving')),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        expect(tester.widget<TextFormField>(line1).controller!.text, draft);
        delayed.complete();
        await tester.pumpAndSettle();
        await _expectAddressRecoveryReachable(tester);
        expect(tester.widget<TextFormField>(line1).controller!.text, draft);
        expect(fixture.account.addressUpdates, hasLength(2));
        fixture.account.mutationError = null;
        fixture.account.addressMutationBarrier = null;
        await _reveal(tester, submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        expect(fixture.account.addresses.single.addressLine1, draft);
        expect(fixture.account.addressUpdates, hasLength(3));
        expect(
          fixture.account.addressUpdates.every(
            (attempt) =>
                attempt.addressId == testAddressId &&
                attempt.expectedVersion == 1 &&
                attempt.draft.addressLine1 == draft,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await _unmount(tester);
      }
    },
  );

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'journal illeggibile compatto200% recupera senza cancellare ${locale.toLanguageTag()} ${brightness.name}',
        (tester) async {
          final fixture = Task054VisualFixtures();
          final draft = testCustomerAddress(
            label: 'Borrador sintético',
          ).toDraft();
          final intent = AddressCreationIntent(
            id: '21000000-0000-4000-8000-000000000888',
            draft: draft,
          );
          fixture.account.addressCreationJournal
            ..intents[testCustomerSubject] = intent
            ..readError = StateError('temporarily_unreadable');
          await tester.pumpWidget(
            fixture.wrap(
              _app(
                const Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: CustomerAccountPanel(
                        authDisplayName: 'Cliente sintético',
                      ),
                    ),
                  ),
                ),
                compact: true,
                locale: locale,
                brightness: brightness,
              ),
            ),
          );
          try {
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('customer-account-ready')),
              findsOneWidget,
            );
            final add = find.byKey(const ValueKey('customer-address-add'));
            expect(tester.widget<IconButton>(add).onPressed, isNull);
            final warning = find.byKey(
              const ValueKey('customer-address-journal-unavailable'),
            );
            final l10n = AppLocalizations.of(tester.element(warning));
            expect(
              find.text(l10n.customerAddressJournalUnavailable),
              findsOneWidget,
            );
            await _reveal(tester, warning);
            final retry = find.byKey(
              const ValueKey('customer-address-journal-retry'),
            );
            await _reveal(tester, retry);
            expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
            expect(fixture.account.addressCreationJournal.clearCalls, 0);
            expect(fixture.account.createAddressAttempts, 0);
            await captureVisual(
              tester,
              'address-journal-unavailable-compact200-${locale.toLanguageTag()}-${brightness.name}',
            );
            fixture.account.addressCreationJournal.readError = null;
            await tester.tap(retry);
            await tester.pumpAndSettle();
            expect(warning, findsNothing);
            await _reveal(tester, add);
            await tester.tap(add);
            await tester.pumpAndSettle();
            final line1 = find.byKey(
              const ValueKey('customer-address-field-line1'),
            );
            expect(
              tester.widget<TextFormField>(line1).controller!.text,
              draft.addressLine1,
            );
            expect(tester.widget<TextFormField>(line1).enabled, isFalse);
            expect(
              fixture
                  .account
                  .addressCreationJournal
                  .intents[testCustomerSubject],
              same(intent),
            );
            expect(fixture.account.addressCreationJournal.clearCalls, 0);
            expect(tester.takeException(), isNull);
          } finally {
            await _unmount(tester);
          }
        },
      );

      testWidgets(
        'address create compatto200% esito incerto ${locale.toLanguageTag()} ${brightness.name}',
        (tester) async {
          final fixture = Task054VisualFixtures();
          await tester.pumpWidget(
            fixture.wrap(
              _app(
                const Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: CustomerAccountPanel(
                        authDisplayName: 'Cliente sintético',
                      ),
                    ),
                  ),
                ),
                compact: true,
                locale: locale,
                brightness: brightness,
              ),
            ),
          );
          try {
            await tester.pumpAndSettle();
            final add = find.byKey(const ValueKey('customer-address-add'));
            await _reveal(tester, add);
            await tester.tap(add);
            await tester.pumpAndSettle();
            const draft = 'Calle intento incierto 789';
            for (final entry in {
              'label': 'Casa sintética',
              'recipient': 'Cliente sintético',
              'line1': draft,
              'commune': 'Santiago',
              'region': 'Metropolitana',
              'country': 'CL',
            }.entries) {
              final field = find.byKey(
                ValueKey('customer-address-field-${entry.key}'),
              );
              await _reveal(tester, field);
              await tester.enterText(field, entry.value);
            }
            final line1 = find.byKey(
              const ValueKey('customer-address-field-line1'),
            );
            final editable = find.descendant(
              of: line1,
              matching: find.byType(EditableText),
            );
            await _reveal(tester, line1);
            await tester.showKeyboard(line1);
            await _expectAddressKeyboardReady(tester, editable);
            fixture.account.addressResponseError =
                const CustomerAccountRepositoryException(
                  CustomerAccountFailureKind.unavailable,
                );
            final submit = find.byKey(
              const ValueKey('customer-address-submit'),
            );
            await _reveal(tester, submit);
            await _expectAddressKeyboardReady(tester, editable);
            await tester.tap(submit);
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(tester.element(line1));
            expect(find.text(l10n.customerAddressUnknown), findsWidgets);
            expect(find.text(l10n.customerAddressVerify), findsOneWidget);
            expect(find.text(l10n.customerAddressCloseEditor), findsOneWidget);
            expect(tester.widget<TextFormField>(line1).enabled, isFalse);
            expect(tester.widget<TextFormField>(line1).controller!.text, draft);
            await _expectAddressRecoveryReachable(tester);
            expect(fixture.account.createAddressCalls, 1);
            expect(fixture.account.createAddressAttempts, 1);
            await captureVisual(
              tester,
              'address-create-unknown-compact200-${locale.toLanguageTag()}-${brightness.name}',
            );
            if (brightness == Brightness.dark) {
              await tester.tap(
                find.byKey(const ValueKey('customer-address-cancel')),
              );
              await tester.pumpAndSettle();
              await _reveal(tester, add);
              await tester.tap(add);
              await tester.pumpAndSettle();
              expect(
                tester.widget<TextFormField>(line1).controller!.text,
                draft,
              );
              expect(tester.widget<TextFormField>(line1).enabled, isFalse);
              await _expectAddressRecoveryReachable(tester);
            }
            // In light verifica nella route ancora aperta; in dark prova anche
            // chiusura e riapertura, sempre sullo stesso intent per ogni lingua.
            await _reveal(tester, submit);
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('customer-address-dialog')),
              findsNothing,
            );
            expect(fixture.account.createAddressCalls, 1);
            expect(fixture.account.createAddressAttempts, 1);
            expect(fixture.account.reconcileCalls, 1);
            expect(
              fixture.account.addresses.where(
                (item) => item.addressLine1 == draft,
              ),
              hasLength(1),
            );
            expect(tester.takeException(), isNull);
          } finally {
            await _unmount(tester);
          }
        },
      );
    }
  }

  testWidgets(
    'search field focus compatto200% conserva query e retry dopo errore',
    (tester) async {
      final fixture = await Task054LongNameStorefrontFixture.create(
        const Locale('es', 'CL'),
      );
      await tester.pumpWidget(
        fixture.wrap(
          _app(
            const Scaffold(body: SafeArea(child: CatalogScreen())),
            compact: true,
          ),
        ),
      );
      try {
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('catalog-search'));
        final container = ProviderScope.containerOf(tester.element(search));
        fixture.local.transport.state = Task054StorefrontState.error;
        const query = 'consulta sintética';
        await _reveal(tester, search);
        await tester.enterText(search, query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(
          container.read(catalogControllerProvider).status,
          CatalogLoadStatus.unavailable,
        );
        expect(container.read(catalogControllerProvider).searchQuery, query);
        expect(tester.widget<SearchBar>(search).controller!.text, query);
        expect(fixture.local.transport.calls, contains('storefront_search_v1'));
        final retry = find.byKey(const ValueKey('catalog-retry-action'));
        await _reveal(tester, retry);
        expect(retry.hitTestable(), findsOneWidget);
        expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
        final clear = find.byKey(const ValueKey('catalog-search-clear'));
        expect(tester.widget<IconButton>(clear).onPressed, isNotNull);
        await _reveal(tester, search);
        await tester.tap(search);
        await tester.showKeyboard(search);
        final input = tester.widget<EditableText>(
          find.descendant(of: search, matching: find.byType(EditableText)),
        );
        expect(input.focusNode.hasFocus, isTrue);
        expect(input.readOnly, isFalse);
        await captureVisual(tester, 'search-field-focus-compact200');
        fixture.local.transport.state = Task054StorefrontState.loaded;
        await _reveal(tester, retry);
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(
          container.read(catalogControllerProvider).status,
          CatalogLoadStatus.empty,
        );
        expect(container.read(catalogControllerProvider).searchQuery, query);
        expect(tester.widget<SearchBar>(search).controller!.text, query);
        expect(tester.takeException(), isNull);
      } finally {
        await _unmount(tester);
        await fixture.dispose();
      }
    },
  );

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
            if (surface.key == 'product') {
              final fulfillment = find.byKey(
                const ValueKey('product-detail-fulfillment'),
              );
              final l10n = AppLocalizations.of(
                tester.element(find.byType(ProductDetailScreen)),
              );
              final pickup = find.descendant(
                of: fulfillment,
                matching: find.text(l10n.productDetailPickup),
              );
              final delivery = find.descendant(
                of: fulfillment,
                matching: find.text(l10n.productDetailDelivery),
              );
              // Il centro del Wrap può cadere nello spazio fra le due righe.
              // Raggiunge una label reale, poi rende visibile l'intero gruppo.
              await _reveal(tester, pickup);
              await Scrollable.ensureVisible(
                tester.element(fulfillment),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              final viewport = tester.getRect(
                find.byWidget(
                  Scrollable.of(tester.element(fulfillment)).widget,
                ),
              );
              final badges = tester.getRect(fulfillment);
              expect(viewport.intersect(badges), badges);
              expect(pickup.hitTestable(), findsOneWidget);
              expect(delivery.hitTestable(), findsOneWidget);
              await captureVisual(
                tester,
                'product-fulfillment-compact200-${locale.toLanguageTag()}',
              );
              final increase = find.byKey(
                const ValueKey('product-quantity-increase'),
              );
              final add = find.byKey(
                const ValueKey('add-to-cart-$task054VisualPublication'),
              );
              expect(increase.hitTestable(), findsOneWidget);
              await tester.tap(increase);
              await tester.pumpAndSettle();
              expect(add.hitTestable(), findsOneWidget);
              expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
              await tester.tap(add);
              await tester.pumpAndSettle();
              expect(
                (await fixture.local.cart.read(
                  shopSlug: 'storefront-test',
                )).items.first.quantity,
                4,
              );
            }
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
      await tester.showKeyboard(field);
      await _reveal(tester, field);
      expect(field.hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await captureVisual(tester, 'review-comment-focus-compact200');
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

  for (final partialUploadFailure in [false, true]) {
    testWidgets(
      partialUploadFailure
          ? 'assistenza upload parziale conserva caso e mostra errore'
          : 'assistenza submit busy timeout retry max3allegati dettaglio',
      (tester) async {
        final fixture = Task054VisualFixtures();
        fixture.afterSales.createdCases = [];
        final repository = Task054RecordedAfterSalesFixture(fixture.afterSales)
          ..failCreate = !partialUploadFailure
          ..failUploadIndex = partialUploadFailure ? 2 : null;
        final picker = Task054SyntheticEvidencePicker()..install();
        final router = GoRouter(
          initialLocation: AppRoutes.afterSalesCreateLocation(
            task054VisualOrder,
          ),
          routes: [
            GoRoute(
              path: AppRoutes.afterSalesBaseLocation,
              builder: (context, state) => CustomerAfterSalesScreen(
                orderId: state.uri.queryParameters['orderId'],
              ),
            ),
            GoRoute(
              path: AppRoutes.afterSalesPattern,
              builder: (context, state) => CustomerAfterSalesScreen(
                caseId: state.pathParameters['caseId'],
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          fixture.wrap(
            MaterialApp.router(
              theme: AppTheme.light(),
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
            additionalOverrides: [
              customerAfterSalesRepositoryProvider.overrideWithValue(
                repository,
              ),
            ],
          ),
        );
        try {
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(CustomerAfterSalesScreen)),
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(CustomerAfterSalesScreen)),
          );
          final eligible = find.byType(Checkbox).first;
          expect(
            tester.widget<Checkbox>(find.byType(Checkbox).last).onChanged,
            isNull,
          );
          await _reveal(tester, eligible);
          await tester.tap(eligible);
          await tester.pumpAndSettle();
          final quantity = find.byType(DropdownButton<int>);
          await _reveal(tester, quantity);
          await tester.tap(quantity);
          await tester.pumpAndSettle();
          await tester.tap(find.text('2').last);
          await tester.pumpAndSettle();
          final note = find.byType(TextField);
          await _reveal(tester, note);
          const text =
              'Nota sintética conservada con cantidad y tres archivos al reintentar.';
          await tester.enterText(note, text);
          await tester.pumpAndSettle();
          final editable = tester.widget<EditableText>(
            find.byType(EditableText),
          );
          expect(editable.focusNode.hasFocus, isTrue);
          if (!partialUploadFailure) {
            await captureVisual(tester, 'assistance-note-focus');
          }
          editable.focusNode.unfocus();
          await tester.pumpAndSettle();
          expect(editable.focusNode.hasFocus, isFalse);
          expect(editable.controller.text, text);
          final attach = find.byKey(
            const ValueKey('after-sales-evidence-picker'),
          );
          await _reveal(tester, attach);
          await tester.tap(attach);
          await tester.pumpAndSettle();
          expect(picker.calls, 1);
          expect(find.text(l10n.afterSalesEvidenceSelected(3)), findsOneWidget);
          expect(find.text(l10n.afterSalesEvidenceSelected(4)), findsNothing);
          if (!partialUploadFailure) {
            await captureVisual(
              tester,
              'assistance-selected3-fixture-attachments',
            );
          }
          final submit = find.byKey(const ValueKey('after-sales-submit'));
          await _reveal(tester, submit);
          if (!partialUploadFailure) {
            repository.createDelay = Completer<void>();
          }
          await tester.tap(submit);
          await tester.pump();
          if (!partialUploadFailure) {
            expect(
              container.read(customerAfterSalesControllerProvider).isMutating,
              isTrue,
            );
            expect(tester.widget<FilledButton>(submit).onPressed, isNull);
            expect(tester.widget<OutlinedButton>(attach).onPressed, isNull);
            expect(tester.widget<TextField>(note).enabled, isFalse);
            expect(repository.drafts.single.lines.single.quantity, 2);
            await captureVisual(tester, 'assistance-submit-busy');
            repository.createDelay!.complete();
            await tester.pumpAndSettle();
            expect(
              container.read(customerAfterSalesControllerProvider).failure,
              'timeout',
            );
            expect(tester.widget<TextField>(note).controller!.text, text);
            expect(tester.widget<DropdownButton<int>>(quantity).value, 2);
            expect(
              find.text(l10n.afterSalesEvidenceSelected(3)),
              findsOneWidget,
            );
            expect(find.text(l10n.afterSalesFailure), findsOneWidget);
            expect(repository.uploads, isEmpty);
            await captureVisual(
              tester,
              'assistance-submit-timeout-draft-preserved',
            );
            await _waitForFailureNotice(tester);
            repository.failCreate = false;
            repository.createDelay = null;
            await _reveal(tester, submit);
            await tester.tap(submit);
          }
          await tester.pumpAndSettle();
          expect(repository.uploads, hasLength(3));
          expect(
            repository.uploads.every(
              (input) =>
                  input.extension == 'png' &&
                  input.mimeType == 'image/png' &&
                  input.bytes.isNotEmpty,
            ),
            isTrue,
          );
          expect(repository.drafts.last.note, text);
          expect(repository.drafts.last.lines.single.quantity, 2);
          expect(
            repository.drafts.last.lines.single.orderItemId,
            task054VisualOrderItem,
          );
          if (!partialUploadFailure) {
            expect(repository.idempotencyKeys, hasLength(2));
            expect(repository.idempotencyKeys.toSet(), hasLength(1));
          } else {
            expect(repository.drafts, hasLength(1));
            expect(
              find.text(l10n.afterSalesEvidenceUploadFailure),
              findsOneWidget,
            );
          }
          expect(
            find.byKey(const ValueKey('after-sales-submit')),
            findsNothing,
          );
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.afterSalesLocation(task054VisualCase),
          );
          final created = container
              .read(customerAfterSalesControllerProvider)
              .cases
              .single;
          expect(created.note, text);
          expect(created.lines.single.quantity, 2);
          expect(created.evidence, hasLength(partialUploadFailure ? 2 : 3));
          expect(fixture.afterSales.createCalls, 1);
          if (partialUploadFailure) {
            await captureVisual(
              tester,
              'assistance-evidence-partial-upload-failure',
            );
          }
          await _reveal(tester, find.text(created.caseCode));
          await captureVisual(
            tester,
            partialUploadFailure
                ? 'assistance-partial-evidence-detail'
                : 'assistance-submitted-detail',
          );
          if (!partialUploadFailure) {
            await _reveal(tester, find.text(l10n.afterSalesEvidence));
            expect(find.text('pending_scan'), findsNWidgets(3));
            await captureVisual(
              tester,
              'assistance-submitted3-evidence-detail',
            );
          }
          expect(tester.takeException(), isNull);
        } finally {
          if (repository.createDelay case final delay?
              when !delay.isCompleted) {
            delay.complete();
          }
          await _unmount(tester);
          router.dispose();
          picker.dispose();
        }
      },
    );
  }

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
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
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
  await tester.pumpAndSettle();
  // Un reflow successivo al primo scroll può smontare un elemento della lista.
  for (var attempt = 0; attempt < 2; attempt++) {
    if (finder.evaluate().isEmpty) {
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      // Un drag dal centro può finire nello scroll interno del campo testo.
      for (
        var scrolls = 0;
        scrolls < 50 && finder.evaluate().isEmpty;
        scrolls++
      ) {
        final next = (position.pixels + 160).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if (next == position.pixels) break;
        position.jumpTo(next);
        await tester.pumpAndSettle();
      }
      expect(
        finder,
        findsOneWidget,
        reason: 'Il controllo deve essere montato nella lista esterna.',
      );
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    if (finder.hitTestable().evaluate().isNotEmpty) return;
  }
  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: 'Il controllo deve essere raggiungibile dopo il reflow.',
  );
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

Future<void> _expectAddressKeyboardReady(
  WidgetTester tester,
  Finder editable,
) async {
  expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  if (!visualCaptureEnabled || !(Platform.isAndroid || Platform.isIOS)) return;
  var previousInset = -1.0;
  var stableSamples = 0;
  for (var attempt = 0; attempt < 20; attempt++) {
    final inset = tester.view.viewInsets.bottom;
    stableSamples = inset > 0 && (inset - previousInset).abs() < 0.5
        ? stableSamples + 1
        : 0;
    if (stableSamples >= 2) return;
    previousInset = inset;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    stableSamples,
    greaterThanOrEqualTo(2),
    reason: 'La richiesta parte solo con tastiera di sistema già aperta.',
  );
}

Future<void> _expectAddressRecoveryReachable(WidgetTester tester) async {
  // Un cliente può scorrere per leggere: controlliamo il messaggio completo e
  // ciascuna azione raggiungibile, senza imporre che siano visibili insieme.
  for (final key in [
    'customer-address-save-failure',
    'customer-address-submit',
    'customer-address-cancel',
  ]) {
    final target = find.byKey(ValueKey(key));
    expect(target, findsOneWidget);
    await _reveal(tester, target);
    final compact = tester.getRect(
      find.byKey(const ValueKey('task054-compact-viewport')),
    );
    final ratio = tester.view.devicePixelRatio;
    final unobscured = compact.intersect(
      Rect.fromLTWH(
        0,
        0,
        tester.view.physicalSize.width / ratio,
        (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
            ratio,
      ),
    );
    final rect = tester.getRect(target);
    expect(rect.left, greaterThanOrEqualTo(unobscured.left));
    expect(rect.right, lessThanOrEqualTo(unobscured.right));
    final longMessage =
        key == 'customer-address-save-failure' &&
        rect.height > unobscured.height;
    if (longMessage) {
      await Scrollable.ensureVisible(tester.element(target), alignment: 0);
      await tester.pumpAndSettle();
      expect(tester.getRect(target).top, greaterThanOrEqualTo(unobscured.top));
      expect(tester.getRect(target).top, lessThan(unobscured.bottom));
      await Scrollable.ensureVisible(tester.element(target), alignment: 1);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(target).bottom,
        lessThanOrEqualTo(unobscured.bottom),
      );
      expect(tester.getRect(target).bottom, greaterThan(unobscured.top));
    } else {
      expect(rect.top, greaterThanOrEqualTo(unobscured.top));
      expect(
        rect.bottom,
        lessThanOrEqualTo(unobscured.bottom),
        reason:
            '$key deve essere raggiungibile senza essere coperto dalla tastiera.',
      );
    }
    if (!longMessage) expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  }
}

Future<void> _waitForFailureNotice(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    // Attende la durata della notifica reale: il precedente errore non deve
    // coprire la CTA edit né contaminare una cattura del successivo successo.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}
