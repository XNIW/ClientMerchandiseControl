import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_controller.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_state.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_failure.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout_test_support.dart';

void main() {
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
}

ProviderContainer _container({
  required FakeCheckoutRepository repository,
  MemoryCheckoutDraftStore? store,
  Future<void> Function()? onCartRefresh,
}) {
  final cart = checkoutTestCart();
  final address = checkoutTestCustomerAddress();
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_config()),
      customerAccountIdentityProvider.overrideWithValue(_identity()),
      checkoutCartStateProvider.overrideWithValue(
        CartState(
          status: CartViewStatus.ready,
          isAuthenticated: true,
          snapshot: cart,
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

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: checkoutTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );
