import 'dart:async';

import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_cache.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout/checkout_test_support.dart';

void main() {
  late ProviderContainer container;
  late _Repository repository;
  late _Cache cache;
  final identity = StateProvider<AuthenticatedCustomer?>(
    (ref) => AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: checkoutTestOwner,
      email: null,
      metadata: const {},
    ),
  );

  setUp(() async {
    repository = _Repository();
    cache = _Cache();
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWith(
          (ref) => ref.watch(identity),
        ),
        deliveryContextShopSlugProvider.overrideWithValue('storefront-test'),
        deliveryContextRepositoryProvider.overrideWithValue(repository),
        deliveryContextCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    container.listen(deliveryContextControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'preview completata dopo logout non pubblica il contesto owner al guest',
    () async {
      final request = Completer<CustomerDeliveryContext>();
      repository.pendingPreview = request.future;
      final operation = container
          .read(deliveryContextControllerProvider.notifier)
          .previewAddress(addressId: checkoutTestAddress);
      container.read(identity.notifier).state = null;
      expect(
        container.read(deliveryContextControllerProvider).authenticated,
        isFalse,
      );
      request.complete(checkoutTestDeliveryContext());
      expect(await operation, isNull);
      expect(container.read(deliveryContextControllerProvider).context, isNull);
    },
  );

  test(
    'risposta dopo switch A-B-A non sovrascrive una sessione nuova',
    () async {
      final original = container.read(identity);
      final request = Completer<CustomerDeliveryContext>();
      repository.pendingSelect = request.future;
      final operation = container
          .read(deliveryContextControllerProvider.notifier)
          .selectPickup(pickupPointId: checkoutTestPoint);
      container.read(identity.notifier).state = null;
      container.read(deliveryContextControllerProvider);
      container.read(identity.notifier).state = original;
      container.read(deliveryContextControllerProvider);
      await Future<void>.delayed(Duration.zero);
      request.complete(checkoutTestPickupContext());
      expect(await operation, isFalse);
      expect(
        container.read(deliveryContextControllerProvider).context?.mode,
        CustomerDeliveryMode.delivery,
      );
    },
  );

  test(
    'refresh con autorizzazione revocata elimina il contesto in cache e UI',
    () async {
      repository.readFailure = const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unauthorized,
      );
      await container
          .read(deliveryContextControllerProvider.notifier)
          .refresh();
      final state = container.read(deliveryContextControllerProvider);
      expect(state.status, DeliveryContextViewStatus.failure);
      expect(state.context, isNull);
      expect(cache.value, isNull);
    },
  );

  for (final readFirst in [false, true]) {
    test(
      'preview non annulla lettura iniziale, readFirst=$readFirst',
      () async {
        final read = Completer<CustomerDeliveryContext?>();
        final preview = Completer<CustomerDeliveryContext>();
        repository.pendingRead = read.future;
        repository.pendingPreview = preview.future;
        final controller = container.read(
          deliveryContextControllerProvider.notifier,
        );
        final refresh = controller.refresh();
        await Future<void>.delayed(Duration.zero);
        final operation = controller.previewAddress(
          addressId: checkoutTestAddress,
        );
        if (readFirst) {
          read.complete(checkoutTestDeliveryContext());
          await refresh;
          expect(
            container.read(deliveryContextControllerProvider).isMutating,
            isTrue,
          );
        }
        preview.complete(checkoutTestDeliveryContext());
        expect(await operation, isNotNull);
        if (!readFirst) {
          read.complete(checkoutTestDeliveryContext());
          await refresh;
        }
        expect(
          container.read(deliveryContextControllerProvider).status,
          DeliveryContextViewStatus.ready,
        );
        expect(
          container.read(deliveryContextControllerProvider).isMutating,
          isFalse,
        );
      },
    );
  }

  test(
    'revoca resta visibile anche se il purge della cache fallisce',
    () async {
      cache.failRemove = true;
      repository.readFailure = const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unauthorized,
      );
      await container
          .read(deliveryContextControllerProvider.notifier)
          .refresh();
      final state = container.read(deliveryContextControllerProvider);
      expect(state.context, isNull);
      expect(state.failure, DeliveryContextFailureKind.unauthorized);
    },
  );

  test(
    'preview risolta dopo dispose non accede a ref o stato distrutti',
    () async {
      final request = Completer<CustomerDeliveryContext>();
      repository.pendingPreview = request.future;
      final operation = container
          .read(deliveryContextControllerProvider.notifier)
          .previewAddress(addressId: checkoutTestAddress);
      container.dispose();
      request.complete(checkoutTestDeliveryContext());
      expect(await operation, isNull);
    },
  );
}

class _Cache implements DeliveryContextCacheStore {
  CustomerDeliveryContext? value;
  bool failRemove = false;
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
    if (failRemove) throw StateError("cache write failed");
    value = null;
  }
}

class _Repository implements DeliveryContextRepository {
  Future<CustomerDeliveryContext?>? pendingRead;
  Future<CustomerDeliveryContext>? pendingPreview;
  Future<CustomerDeliveryContext>? pendingSelect;
  DeliveryContextRepositoryException? readFailure;
  @override
  Future<CustomerDeliveryContext?> read({required String shopSlug}) async {
    if (readFailure != null) throw readFailure!;
    return pendingRead ?? checkoutTestDeliveryContext();
  }

  @override
  Future<CustomerDeliveryContext> preview({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  }) async => pendingPreview ?? checkoutTestDeliveryContext();
  @override
  Future<CustomerDeliveryContext> select({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    required int expectedVersion,
    String? addressId,
    String? pickupPointId,
  }) async => pendingSelect ?? checkoutTestPickupContext();
}
