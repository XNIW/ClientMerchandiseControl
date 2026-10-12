import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';
import 'package:client_merchandise_control/core/observability/observability_providers.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_state.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_failure.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout_test_support.dart';
import '../../../support/collecting_observability.dart';

void main() {
  test('telemetry checkout espone solo step e outcome enumerati', () async {
    final observability = CollectingObservabilityPort();
    final container = _container(
      repository: FakeCheckoutRepository(),
      observability: observability,
    );
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );

    await _reachReview(container);

    final events = observability.events
        .where((event) => event.name == ObservabilityEventName.checkoutStep)
        .toList();
    expect(events, isNotEmpty);
    expect(events.last.attributes['step'], CheckoutTelemetryStep.review.name);
    final payload = events
        .map((event) => event.toSafeMap(environment: 'staging'))
        .toList()
        .toString();
    expect(payload, isNot(contains('Cliente Uno')));
    expect(payload, isNot(contains('Avenida Uno 123')));
    expect(payload, isNot(contains(checkoutTestPoint)));
    expect(payload, isNot(contains(checkoutTestPickupSlot)));
    expect(payload, isNot(contains(checkoutTestPublication)));
  });

  test(
    'percorre i cinque step e conserva una selezione server-validabile',
    () async {
      final repository = FakeCheckoutRepository();
      final store = MemoryCheckoutDraftStore();
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);

      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachReview(container);

      final state = container.read(checkoutControllerProvider);
      expect(state.step, CheckoutStep.review);
      expect(state.selection.mode, CheckoutFulfillmentMode.pickup);
      expect(state.selection.pickupPointId, checkoutTestPoint);
      expect(state.selection.slotId, checkoutTestPickupSlot);
      expect(state.selection.paymentMethod, CheckoutPaymentMethod.payAtPickup);
      expect(store.draft?.step, CheckoutStep.review);
    },
  );

  test('timeout ambiguo riusa chiave e versione al retry', () async {
    final repository = FakeCheckoutRepository()
      ..createOutcomes.addAll([
        const CheckoutRepositoryException(CheckoutFailureKind.timeout),
        checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
      ]);
    final store = MemoryCheckoutDraftStore();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    await _reachReview(container);

    await container.read(checkoutControllerProvider.notifier).createQuote();
    var state = container.read(checkoutControllerProvider);
    expect(state.failureKind, CheckoutFailureKind.timeout);
    expect(state.hasPendingRetry, isTrue);
    expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);

    await container.read(checkoutControllerProvider.notifier).retry();
    state = container.read(checkoutControllerProvider);
    expect(state.step, CheckoutStep.confirmation);
    expect(state.quote?.id, checkoutTestQuote);
    expect(state.hasPendingRetry, isFalse);
    expect(repository.createRequests, hasLength(2));
    expect(
      repository.createRequests
          .map((request) => request.idempotencyKey)
          .toSet(),
      {checkoutTestKey},
    );
    expect(
      repository.createRequests.map((request) => request.cartVersion),
      everyElement(7),
    );
  });

  test('doppio tap con richiesta attiva esegue una sola create', () async {
    final barrier = Completer<CheckoutRemoteResponse>();
    final repository = FakeCheckoutRepository()
      ..createOutcomes.add(barrier.future);
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    await _reachReview(container);

    final controller = container.read(checkoutControllerProvider.notifier);
    final first = controller.createQuote();
    final second = controller.createQuote();
    await Future<void>.delayed(Duration.zero);

    expect(repository.createRequests, hasLength(1));
    expect(container.read(checkoutControllerProvider).isBusy, isTrue);
    barrier.complete(checkoutTestResponse(quote: checkoutTestQuoteSnapshot()));
    await Future.wait([first, second]);
    expect(repository.createRequests, hasLength(1));
    expect(container.read(checkoutControllerProvider).isBusy, isFalse);
  });

  test(
    'variazione prezzo richiede conferma esplicita e conferma idempotente',
    () async {
      const change = CheckoutQuoteChange(
        publicationId: checkoutTestPublication,
        type: CheckoutChangeType.priceChanged,
        previousPriceClp: 1300,
        currentPriceClp: 1200,
      );
      final changedQuote = checkoutTestQuoteSnapshot(
        status: CheckoutQuoteStatus.requiresReview,
        requiresReview: true,
        changes: const [change],
      );
      final confirmedQuote = checkoutTestQuoteSnapshot(
        status: CheckoutQuoteStatus.confirmed,
      );
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(
          checkoutTestResponse(
            status: CheckoutRemoteStatus.requiresReview,
            quote: changedQuote,
          ),
        )
        ..confirmOutcomes.add(
          checkoutTestResponse(
            status: CheckoutRemoteStatus.confirmed,
            quote: confirmedQuote,
          ),
        );
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachReview(container);

      await container.read(checkoutControllerProvider.notifier).createQuote();
      var state = container.read(checkoutControllerProvider);
      expect(state.quote?.requiresCustomerReview, isTrue);
      expect(state.notice, CheckoutNoticeKind.quoteChanged);

      await container.read(checkoutControllerProvider.notifier).confirmQuote();
      state = container.read(checkoutControllerProvider);
      expect(state.isConfirmed, isTrue);
      expect(state.notice, CheckoutNoticeKind.confirmed);
      expect(repository.confirmRequests.single.quoteId, checkoutTestQuote);
      expect(repository.confirmRequests.single.version, 2);
      expect(repository.confirmRequests.single.key, checkoutTestKey);
    },
  );

  test(
    'ordine autorevole salva receipt e aggiorna il carrello solo dopo success',
    () async {
      var refreshCalls = 0;
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
      final container = _container(
        repository: repository,
        store: store,
        onCartRefresh: () async => refreshCalls++,
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachConfirmedQuote(container);

      expect(refreshCalls, 0);
      await container.read(checkoutControllerProvider.notifier).createOrder();

      final state = container.read(checkoutControllerProvider);
      expect(state.order?.id, checkoutTestOrder);
      expect(state.order?.code, checkoutTestOrderCode);
      expect(state.notice, CheckoutNoticeKind.orderConfirmed);
      expect(state.pendingOperation, isNull);
      expect(store.draft?.orderId, checkoutTestOrder);
      expect(refreshCalls, 1);
      expect(repository.orderRequests.single.quoteId, checkoutTestQuote);
      expect(repository.orderRequests.single.version, 2);
      expect(
        repository.orderRequests.single.paymentMethod,
        CheckoutPaymentMethod.payAtPickup,
      );
      expect(repository.orderRequests.single.key, checkoutTestKey);
    },
  );

  test(
    'throw telemetry dopo ordine non altera receipt o refresh carrello',
    () async {
      var refreshCalls = 0;
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
      final container = _container(
        repository: repository,
        store: store,
        onCartRefresh: () async => refreshCalls++,
        observability: ThrowingObservabilityPort(
          onlyFor: ObservabilityEventName.orderCreated,
        ),
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachConfirmedQuote(container);

      await expectLater(
        container.read(checkoutControllerProvider.notifier).createOrder(),
        completes,
      );

      expect(
        container.read(checkoutControllerProvider).order?.id,
        checkoutTestOrder,
      );
      expect(store.draft?.orderId, checkoutTestOrder);
      expect(refreshCalls, 1);
      expect(repository.orderRequests, hasLength(1));
    },
  );

  test(
    'timeout ordine conserva intent e retrya stessa key senza svuotare prima',
    () async {
      var refreshCalls = 0;
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
        ..orderOutcomes.addAll([
          const CheckoutRepositoryException(CheckoutFailureKind.timeout),
          checkoutTestOrderResponse(
            order: checkoutTestOrderSnapshot(idempotent: true),
            idempotent: true,
          ),
        ]);
      final store = MemoryCheckoutDraftStore();
      final container = _container(
        repository: repository,
        store: store,
        onCartRefresh: () async => refreshCalls++,
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachConfirmedQuote(container);

      await container.read(checkoutControllerProvider.notifier).createOrder();
      var state = container.read(checkoutControllerProvider);
      expect(state.failureKind, CheckoutFailureKind.timeout);
      expect(state.pendingOperation?.kind, CheckoutPendingOperationKind.order);
      expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      expect(refreshCalls, 0);

      await container.read(checkoutControllerProvider.notifier).retry();
      state = container.read(checkoutControllerProvider);
      expect(state.order?.id, checkoutTestOrder);
      expect(refreshCalls, 1);
      expect(repository.orderRequests, hasLength(2));
      expect(repository.orderRequests.map((request) => request.key).toSet(), {
        checkoutTestKey,
      });
      expect(
        repository.orderRequests
            .map((request) => request.paymentMethod)
            .toSet(),
        {CheckoutPaymentMethod.payAtPickup},
      );
    },
  );

  test('ordine ambiguo non viene sostituito da Back, selezioni, quote o restart', () async {
    final repository = FakeCheckoutRepository()
      ..createOutcomes.add(checkoutTestResponse(quote: checkoutTestQuoteSnapshot()))
      ..confirmOutcomes.add(checkoutTestResponse(status: CheckoutRemoteStatus.confirmed,
          quote: checkoutTestQuoteSnapshot(status: CheckoutQuoteStatus.confirmed)))
      ..orderOutcomes.addAll([const CheckoutRepositoryException(CheckoutFailureKind.timeout),
          checkoutTestOrderResponse(order: checkoutTestOrderSnapshot(idempotent: true), idempotent: true)]);
    final store = MemoryCheckoutDraftStore();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    await _waitFor(container, (state) => state.status == CheckoutViewStatus.ready);
    await _reachConfirmedQuote(container);
    final controller = container.read(checkoutControllerProvider.notifier);
    await controller.createOrder();
    final pending = store.draft!.pendingOperation!;
    await controller.previousStep();
    await controller.selectMode(CheckoutFulfillmentMode.delivery);
    await controller.selectSlot(checkoutTestPickupSlot);
    await controller.createQuote();
    await controller.confirmQuote();
    await controller.restart();
    expect(store.draft!.pendingOperation, same(pending));
    expect(container.read(checkoutControllerProvider).pendingOperation, same(pending));
    expect(container.read(checkoutControllerProvider).step, CheckoutStep.confirmation);
    expect(repository.createRequests, hasLength(1));
    expect(repository.confirmRequests, hasLength(1));
    expect(repository.orderRequests, hasLength(1));
    await controller.retry();
    expect(repository.orderRequests, hasLength(2));
    expect(repository.orderRequests.map((request) => request.key).toSet(), {pending.idempotencyKey});
    expect(store.draft!.orderId, checkoutTestOrder);
  });

  for (final emptyCart in [false, true]) {
    test('recreate container dopo ACK ordine perso riconcilia cart '
        '${emptyCart ? 'vuoto' : 'nuovo non vuoto'} con stessa key', () async {
      final store = MemoryCheckoutDraftStore();
      final firstRepository = FakeCheckoutRepository()
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
          const CheckoutRepositoryException(CheckoutFailureKind.timeout),
        );
      final first = _container(repository: firstRepository, store: store);
      try {
        await _waitFor(
          first,
          (state) => state.status == CheckoutViewStatus.ready,
        );
        await _reachConfirmedQuote(first);
        await first.read(checkoutControllerProvider.notifier).createOrder();
        expect(
          store.draft?.pendingOperation?.kind,
          CheckoutPendingOperationKind.order,
        );
        expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      } finally {
        first.dispose();
      }

      var cartRefreshes = 0;
      final replay = FakeCheckoutRepository()
        ..orderOutcomes.add(
          checkoutTestOrderResponse(
            order: checkoutTestOrderSnapshot(idempotent: true),
            idempotent: true,
          ),
        );
      // La quote non è più leggibile: il server l'ha consumata al commit.
      // Il cart nuovo rappresenta una successiva aggiunta da un altro device.
      final restored = _container(
        repository: replay,
        store: store,
        cart: emptyCart ? _emptyAccountCart() : _accountCartAtVersion(9),
        onCartRefresh: () async => cartRefreshes++,
      );
      addTearDown(restored.dispose);
      final state = await _waitFor(
        restored,
        (state) => state.status == CheckoutViewStatus.ready && !state.isBusy,
      );
      expect(state.order?.id, checkoutTestOrder);
      expect(replay.orderRequests, hasLength(1));
      expect(replay.orderRequests.single.quoteId, checkoutTestQuote);
      expect(replay.orderRequests.single.version, 2);
      expect(
        replay.orderRequests.single.paymentMethod,
        CheckoutPaymentMethod.payAtPickup,
      );
      expect(replay.orderRequests.single.key, checkoutTestKey);
      expect(replay.createRequests, isEmpty);
      expect(replay.readCalls, 0);
      expect(store.draft?.orderId, checkoutTestOrder);
      expect(store.draft?.pendingOperation, isNull);
      expect(cartRefreshes, 1);
    });
  }

  test(
    'replay ordine con cart nuovo mantiene intent se secondo ACK va perso',
    () async {
      final store = MemoryCheckoutDraftStore()
        ..draft = CheckoutLocalDraft(
          ownerSubjectId: checkoutTestOwner,
          shopSlug: 'storefront-test',
          step: CheckoutStep.confirmation,
          selection: const CheckoutSelection(
            mode: CheckoutFulfillmentMode.pickup,
            pickupPointId: checkoutTestPoint,
            slotId: checkoutTestPickupSlot,
            paymentMethod: CheckoutPaymentMethod.payAtPickup,
          ),
          quoteId: checkoutTestQuote,
          pendingOperation: const CheckoutPendingOperation(
            kind: CheckoutPendingOperationKind.order,
            idempotencyKey: checkoutTestKey,
            cartVersion: 7,
            quoteId: checkoutTestQuote,
            expectedQuoteVersion: 2,
            paymentMethod: CheckoutPaymentMethod.payAtPickup,
          ),
          updatedAt: checkoutTestNow,
        );
      final repository = FakeCheckoutRepository()
        ..orderOutcomes.addAll([
          const CheckoutRepositoryException(CheckoutFailureKind.timeout),
          checkoutTestOrderResponse(
            order: checkoutTestOrderSnapshot(idempotent: true),
            idempotent: true,
          ),
        ]);
      final container = _container(
        repository: repository,
        store: store,
        cart: _accountCartAtVersion(9),
      );
      addTearDown(container.dispose);
      final recovery = await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready && !state.isBusy,
      );
      expect(recovery.failureKind, CheckoutFailureKind.timeout);
      expect(recovery.pendingOperation?.idempotencyKey, checkoutTestKey);
      expect(store.draft?.pendingOperation?.idempotencyKey, checkoutTestKey);
      expect(repository.readCalls, 0);
      await container.read(checkoutControllerProvider.notifier).retry();
      expect(
        container.read(checkoutControllerProvider).order?.id,
        checkoutTestOrder,
      );
      expect(repository.orderRequests, hasLength(2));
      expect(
        repository.orderRequests.map((request) => request.key),
        everyElement(checkoutTestKey),
      );
      expect(repository.createRequests, isEmpty);
    },
  );

  test(
    'receipt owner-scoped si ripristina anche con carrello remoto vuoto',
    () async {
      final store = MemoryCheckoutDraftStore()
        ..draft = CheckoutLocalDraft(
          ownerSubjectId: checkoutTestOwner,
          shopSlug: 'storefront-test',
          step: CheckoutStep.confirmation,
          selection: const CheckoutSelection(
            mode: CheckoutFulfillmentMode.pickup,
            pickupPointId: checkoutTestPoint,
            slotId: checkoutTestPickupSlot,
            paymentMethod: CheckoutPaymentMethod.payAtPickup,
          ),
          quoteId: checkoutTestQuote,
          orderId: checkoutTestOrder,
          updatedAt: checkoutTestNow,
        );
      final repository = FakeCheckoutRepository()
        ..readOrderOutcome = checkoutTestOrderResponse(
          order: checkoutTestOrderSnapshot(idempotent: true),
          idempotent: true,
        );
      final container = _container(
        repository: repository,
        store: store,
        cart: _emptyAccountCart(),
      );
      addTearDown(container.dispose);

      final restored = await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready && state.hasOrder,
      );
      expect(restored.order?.code, checkoutTestOrderCode);
      expect(restored.notice, CheckoutNoticeKind.restored);
      expect(repository.readOrderCalls, 1);
    },
  );

  test(
    'riavvio ripristina intent pending e retry non duplica identità',
    () async {
      final store = MemoryCheckoutDraftStore()
        ..draft = CheckoutLocalDraft(
          ownerSubjectId: checkoutTestOwner,
          shopSlug: 'storefront-test',
          step: CheckoutStep.review,
          selection: const CheckoutSelection(
            mode: CheckoutFulfillmentMode.pickup,
            pickupPointId: checkoutTestPoint,
            slotId: checkoutTestPickupSlot,
            paymentMethod: CheckoutPaymentMethod.payAtPickup,
          ),
          pendingOperation: const CheckoutPendingOperation(
            kind: CheckoutPendingOperationKind.create,
            idempotencyKey: checkoutTestKey,
            cartVersion: 7,
          ),
          updatedAt: checkoutTestNow,
        );
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(
          checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
        );
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);

      final restored = await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      expect(restored.step, CheckoutStep.review);
      expect(restored.notice, CheckoutNoticeKind.restored);
      expect(restored.pendingOperation?.idempotencyKey, checkoutTestKey);

      await container.read(checkoutControllerProvider.notifier).retry();
      expect(repository.createRequests.single.idempotencyKey, checkoutTestKey);
      expect(
        container.read(checkoutControllerProvider).quote?.id,
        checkoutTestQuote,
      );
    },
  );

  test(
    'restore not-found rimuove confirm stale e mostra errore reale',
    () async {
      final store = MemoryCheckoutDraftStore()
        ..draft = CheckoutLocalDraft(
          ownerSubjectId: checkoutTestOwner,
          shopSlug: 'storefront-test',
          step: CheckoutStep.confirmation,
          selection: const CheckoutSelection(
            mode: CheckoutFulfillmentMode.pickup,
            pickupPointId: checkoutTestPoint,
            slotId: checkoutTestPickupSlot,
            paymentMethod: CheckoutPaymentMethod.payAtPickup,
          ),
          quoteId: checkoutTestQuote,
          pendingOperation: const CheckoutPendingOperation(
            kind: CheckoutPendingOperationKind.confirm,
            idempotencyKey: checkoutTestKey,
            cartVersion: 7,
            quoteId: checkoutTestQuote,
            expectedQuoteVersion: 2,
          ),
          updatedAt: checkoutTestNow,
        );
      final repository = FakeCheckoutRepository()
        ..readOutcome = checkoutTestResponse(
          status: CheckoutRemoteStatus.notFound,
        );
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);

      final restored = await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      expect(restored.failureKind, CheckoutFailureKind.notFound);
      expect(restored.step, CheckoutStep.review);
      expect(restored.quote, isNull);
      expect(restored.pendingOperation, isNull);
      expect(store.draft?.pendingOperation, isNull);
    },
  );

  test(
    'version conflict libera pending e richiede refresh del carrello',
    () async {
      var refreshCalls = 0;
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(
          checkoutTestResponse(
            status: CheckoutRemoteStatus.cartVersionConflict,
          ),
        );
      final container = _container(
        repository: repository,
        onCartRefresh: () async => refreshCalls++,
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachReview(container);

      await container.read(checkoutControllerProvider.notifier).createQuote();
      final state = container.read(checkoutControllerProvider);
      expect(state.failureKind, CheckoutFailureKind.staleCart);
      expect(state.pendingOperation, isNull);
      expect(refreshCalls, 1);
    },
  );

  test(
    'metodo pagamento è vincolato alla modalità e online resta disabilitato',
    () async {
      final repository = FakeCheckoutRepository();
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.selectMode(CheckoutFulfillmentMode.delivery);
      await controller.nextStep();
      await controller.selectAddress(checkoutTestAddress);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await controller.nextStep();
      await controller.selectSlot(checkoutTestDeliverySlot);
      await controller.nextStep();

      await controller.selectPaymentMethod(CheckoutPaymentMethod.payAtPickup);
      await controller.selectPaymentMethod(CheckoutPaymentMethod.onlinePayment);
      expect(
        container.read(checkoutControllerProvider).selection.paymentMethod,
        isNull,
      );

      await controller.selectPaymentMethod(
        CheckoutPaymentMethod.cashOnDelivery,
      );
      expect(
        container.read(checkoutControllerProvider).selection.paymentMethod,
        CheckoutPaymentMethod.cashOnDelivery,
      );
    },
  );

  test(
    'errore server metodo pagamento libera intent senza creare ordine',
    () async {
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
          checkoutTestOrderResponse(
            status: CheckoutOrderRemoteStatus.paymentMethodUnavailable,
          ),
        );
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachConfirmedQuote(container);

      await container.read(checkoutControllerProvider.notifier).createOrder();

      final state = container.read(checkoutControllerProvider);
      expect(state.failureKind, CheckoutFailureKind.paymentUnavailable);
      expect(state.pendingOperation, isNull);
      expect(state.order, isNull);
    },
  );

  test('fallimento persistenza impedisce ogni chiamata remota', () async {
    final repository = FakeCheckoutRepository();
    final store = MemoryCheckoutDraftStore();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    store.saveError = StateError('disk unavailable');

    await container
        .read(checkoutControllerProvider.notifier)
        .selectMode(CheckoutFulfillmentMode.pickup);

    expect(
      container.read(checkoutControllerProvider).failureKind,
      CheckoutFailureKind.unexpected,
    );
    expect(repository.createRequests, isEmpty);
  });

  test(
    'logout durante create scarta risposta e non persiste la quote',
    () async {
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _identity(),
      );
      final response = Completer<CheckoutRemoteResponse>();
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(response.future);
      final store = MemoryCheckoutDraftStore();
      final container = _container(
        repository: repository,
        store: store,
        identityProvider: identity,
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachReview(container);

      final operation = container
          .read(checkoutControllerProvider.notifier)
          .createQuote();
      await _waitFor(container, (_) => repository.createRequests.isNotEmpty);
      container.read(identity.notifier).state = null;
      await Future<void>.delayed(Duration.zero);
      final savesBeforeCompletion = store.saveCalls;

      response.complete(
        checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
      );
      await operation;

      expect(container.read(checkoutControllerProvider).quote, isNull);
      expect(store.saveCalls, savesBeforeCompletion);
      expect(store.draft?.quoteId, isNull);
    },
  );

  test('login B durante create non riceve stato o draft di A', () async {
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _identity(),
    );
    final response = Completer<CheckoutRemoteResponse>();
    final repository = FakeCheckoutRepository()
      ..createOutcomes.add(response.future);
    final store = MemoryCheckoutDraftStore();
    final container = _container(
      repository: repository,
      store: store,
      identityProvider: identity,
    );
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    await _reachReview(container);

    final operation = container
        .read(checkoutControllerProvider.notifier)
        .createQuote();
    await _waitFor(container, (_) => repository.createRequests.isNotEmpty);
    container.read(identity.notifier).state = _identity(
      subjectId: '10000000-0000-4000-8000-000000000002',
    );
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    final savesBeforeCompletion = store.saveCalls;

    response.complete(checkoutTestResponse(quote: checkoutTestQuoteSnapshot()));
    await operation;

    expect(container.read(checkoutControllerProvider).quote, isNull);
    expect(store.saveCalls, savesBeforeCompletion);
    expect(store.draft?.ownerSubjectId, '10000000-0000-4000-8000-000000000002');
    expect(store.draft?.quoteId, isNull);
  });

  test('cambio account durante save blocca RPC e publish stale', () async {
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _identity(),
    );
    final repository = FakeCheckoutRepository();
    final store = MemoryCheckoutDraftStore();
    final container = _container(
      repository: repository,
      store: store,
      identityProvider: identity,
    );
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CheckoutViewStatus.ready,
    );
    await _reachReview(container);
    store.saveBarrier = Completer<void>();

    final operation = container
        .read(checkoutControllerProvider.notifier)
        .createQuote();
    await Future<void>.delayed(Duration.zero);
    container.read(identity.notifier).state = null;
    await Future<void>.delayed(Duration.zero);
    store.saveBarrier!.complete();
    await operation;

    expect(repository.createRequests, isEmpty);
    expect(container.read(checkoutControllerProvider).quote, isNull);
  });

  test(
    'dispose durante create impedisce completion e side effect tardivi',
    () async {
      final response = Completer<CheckoutRemoteResponse>();
      final repository = FakeCheckoutRepository()
        ..createOutcomes.add(response.future);
      final store = MemoryCheckoutDraftStore();
      final container = _container(repository: repository, store: store);
      await _waitFor(
        container,
        (state) => state.status == CheckoutViewStatus.ready,
      );
      await _reachReview(container);

      final operation = container
          .read(checkoutControllerProvider.notifier)
          .createQuote();
      await _waitFor(container, (_) => repository.createRequests.isNotEmpty);
      final savesBeforeCompletion = store.saveCalls;
      container.dispose();
      response.complete(
        checkoutTestResponse(quote: checkoutTestQuoteSnapshot()),
      );
      await operation;

      expect(store.saveCalls, savesBeforeCompletion);
    },
  );
}

ProviderContainer _container({
  required FakeCheckoutRepository repository,
  MemoryCheckoutDraftStore? store,
  Future<void> Function()? onCartRefresh,
  CustomerCartSnapshot? cart,
  StateProvider<AuthenticatedCustomer?>? identityProvider,
  ObservabilityPort? observability,
}) {
  final currentCart = cart ?? checkoutTestCart();
  final address = checkoutTestCustomerAddress();
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_config()),
      customerAccountIdentityProvider.overrideWith((ref) {
        final provider = identityProvider;
        return provider == null ? _identity() : ref.watch(provider);
      }),
      checkoutCartStateProvider.overrideWithValue(
        CartState(
          status: CartViewStatus.ready,
          isAuthenticated: true,
          snapshot: currentCart,
        ),
      ),
      checkoutAccountStateProvider.overrideWithValue(
        CustomerAccountState(
          status: CustomerAccountStatus.ready,
          snapshot: CustomerAccountSnapshot(
            profile: null,
            addresses: [address],
            deletionRequest: null,
            loadedAt: checkoutTestNow,
          ),
        ),
      ),
      deliveryContextControllerProvider.overrideWith(
        TestDeliveryContextController.new,
      ),
      checkoutCartRefreshProvider.overrideWithValue(
        onCartRefresh ?? () async {},
      ),
      checkoutRepositoryProvider.overrideWithValue(repository),
      checkoutDraftStoreProvider.overrideWithValue(
        store ?? MemoryCheckoutDraftStore(),
      ),
      checkoutClockProvider.overrideWithValue(() => checkoutTestNow),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        () => checkoutTestKey,
      ),
      if (observability != null)
        observabilityProvider.overrideWithValue(observability),
    ],
  );
}

Future<void> _reachReview(ProviderContainer container) async {
  final controller = container.read(checkoutControllerProvider.notifier);
  await controller.selectMode(CheckoutFulfillmentMode.pickup);
  await controller.nextStep();
  await controller.selectPickupPoint(checkoutTestPoint);
  await controller.nextStep();
  await controller.selectSlot(checkoutTestPickupSlot);
  await controller.nextStep();
  await controller.selectPaymentMethod(CheckoutPaymentMethod.payAtPickup);
}

Future<void> _reachConfirmedQuote(ProviderContainer container) async {
  await _reachReview(container);
  final controller = container.read(checkoutControllerProvider.notifier);
  await controller.createQuote();
  await controller.confirmQuote();
}

CustomerCartSnapshot _accountCartAtVersion(int version) {
  final original = checkoutTestCart();
  return CustomerCartSnapshot(
    shopSlug: original.shopSlug,
    version: version,
    items: original.items,
    source: CartSource.account,
    quoteStatus: original.quoteStatus,
    requiresCustomerReview: original.requiresCustomerReview,
    subtotalClp: original.subtotalClp,
    idempotent: original.idempotent,
  );
}

CustomerCartSnapshot _emptyAccountCart() => CustomerCartSnapshot(
  shopSlug: 'storefront-test',
  version: 8,
  items: const [],
  source: CartSource.account,
  quoteStatus: CartQuoteStatus.indicative,
  requiresCustomerReview: false,
  subtotalClp: 0,
  idempotent: true,
);

Future<CheckoutState> _waitFor(
  ProviderContainer container,
  bool Function(CheckoutState state) predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final state = container.read(checkoutControllerProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw TestFailure(
    'Checkout state non raggiunto: '
    '${container.read(checkoutControllerProvider).status}',
  );
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);

AuthenticatedCustomer _identity({String subjectId = checkoutTestOwner}) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subjectId,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );
