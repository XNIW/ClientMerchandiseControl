import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/delivery_context_models.dart';
import '../domain/delivery_context_repository.dart';
import 'delivery_context_providers.dart';

enum DeliveryContextViewStatus { loading, ready, offline, failure }

final class DeliveryContextState {
  const DeliveryContextState({
    required this.status,
    required this.authenticated,
    this.context,
    this.failure,
    this.isMutating = false,
    this.isFromCache = false,
  });

  final DeliveryContextViewStatus status;
  final bool authenticated;
  final CustomerDeliveryContext? context;
  final DeliveryContextFailureKind? failure;
  final bool isMutating;
  final bool isFromCache;

  DeliveryContextState copyWith({
    DeliveryContextViewStatus? status,
    CustomerDeliveryContext? context,
    bool clearContext = false,
    DeliveryContextFailureKind? failure,
    bool clearFailure = false,
    bool? isMutating,
    bool? isFromCache,
  }) {
    return DeliveryContextState(
      status: status ?? this.status,
      authenticated: authenticated,
      context: clearContext ? null : context ?? this.context,
      failure: clearFailure ? null : failure ?? this.failure,
      isMutating: isMutating ?? this.isMutating,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

final deliveryContextControllerProvider =
    NotifierProvider<DeliveryContextController, DeliveryContextState>(
      DeliveryContextController.new,
    );

class DeliveryContextController extends Notifier<DeliveryContextState> {
  String? _owner;
  String? _shopSlug;
  var _initialized = false;
  var _generation = 0;
  var _disposed = false;

  @override
  DeliveryContextState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final owner = ref.watch(deliveryContextIdentityProvider)?.subjectId;
    final shopSlug = ref.watch(deliveryContextShopSlugProvider);
    if (_initialized && _owner == owner && _shopSlug == shopSlug) return state;
    _initialized = true;
    _owner = owner;
    _shopSlug = shopSlug;
    final authenticated = owner != null;
    if (!authenticated || shopSlug == null) {
      return DeliveryContextState(
        status: DeliveryContextViewStatus.ready,
        authenticated: authenticated,
      );
    }
    final generation = ++_generation;
    scheduleMicrotask(() => _load(generation));
    return const DeliveryContextState(
      status: DeliveryContextViewStatus.loading,
      authenticated: true,
    );
  }

  Future<void> refresh() => _load(++_generation);

  Future<CustomerDeliveryContext?> previewAddress({
    String? addressId,
    String? commune,
  }) => _preview(
    mode: CustomerDeliveryMode.delivery,
    addressId: addressId,
    commune: commune,
  );

  Future<CustomerDeliveryContext?> previewPickup(String pickupPointId) =>
      _preview(mode: CustomerDeliveryMode.pickup, pickupPointId: pickupPointId);

  Future<bool> selectAddress({required String addressId}) =>
      _select(mode: CustomerDeliveryMode.delivery, addressId: addressId);

  Future<bool> selectGuestCommune({required String commune}) async {
    if (_owner != null) return false;
    final preview = await _preview(
      mode: CustomerDeliveryMode.delivery,
      commune: commune,
    );
    return preview != null;
  }

  Future<bool> selectPickup({required String pickupPointId}) =>
      _select(mode: CustomerDeliveryMode.pickup, pickupPointId: pickupPointId);

  Future<void> _load(int generation) async {
    final owner = _owner;
    final shopSlug = _shopSlug;
    if (owner == null || shopSlug == null || _disposed) return;
    try {
      final cached = await ref
          .read(deliveryContextCacheProvider)
          .read(ownerSubjectId: owner, shopSlug: shopSlug);
      if (!_current(owner, shopSlug, generation)) return;
      if (cached != null) {
        state = DeliveryContextState(
          status: DeliveryContextViewStatus.loading,
          authenticated: true,
          context: cached,
          isFromCache: true,
        );
      }
      final remote = await ref
          .read(deliveryContextRepositoryProvider)
          .read(shopSlug: shopSlug);
      if (!_current(owner, shopSlug, generation)) return;
      if (remote == null) {
        await ref
            .read(deliveryContextCacheProvider)
            .remove(ownerSubjectId: owner, shopSlug: shopSlug);
      } else {
        await ref
            .read(deliveryContextCacheProvider)
            .write(ownerSubjectId: owner, context: remote);
      }
      if (!_current(owner, shopSlug, generation)) return;
      state = DeliveryContextState(
        status: DeliveryContextViewStatus.ready,
        authenticated: true,
        context: remote,
      );
    } on DeliveryContextRepositoryException catch (error) {
      if (!_current(owner, shopSlug, generation)) return;
      final cached = state.context;
      state = DeliveryContextState(
        status:
            cached != null &&
                (error.kind == DeliveryContextFailureKind.offline ||
                    error.kind == DeliveryContextFailureKind.timeout)
            ? DeliveryContextViewStatus.offline
            : DeliveryContextViewStatus.failure,
        authenticated: true,
        context: cached,
        failure: error.kind,
        isFromCache: cached != null,
      );
    }
  }

  Future<CustomerDeliveryContext?> _preview({
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  }) async {
    final shopSlug = _shopSlug;
    if (shopSlug == null || state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final result = await ref
          .read(deliveryContextRepositoryProvider)
          .preview(
            shopSlug: shopSlug,
            mode: mode,
            addressId: addressId,
            pickupPointId: pickupPointId,
            commune: commune,
          );
      if (_shopSlug != shopSlug) return null;
      if (_owner == null) {
        state = DeliveryContextState(
          status: DeliveryContextViewStatus.ready,
          authenticated: false,
          context: result,
        );
      } else {
        state = state.copyWith(isMutating: false, clearFailure: true);
      }
      return result;
    } on DeliveryContextRepositoryException catch (error) {
      if (_shopSlug == shopSlug) {
        state = state.copyWith(
          status: DeliveryContextViewStatus.failure,
          failure: error.kind,
          isMutating: false,
        );
      }
      return null;
    }
  }

  Future<bool> _select({
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
  }) async {
    final shopSlug = _shopSlug;
    final owner = _owner;
    if (shopSlug == null || state.isMutating) return false;
    if (owner == null) {
      final preview = await _preview(
        mode: mode,
        addressId: addressId,
        pickupPointId: pickupPointId,
      );
      return preview != null;
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final selected = await ref
          .read(deliveryContextRepositoryProvider)
          .select(
            shopSlug: shopSlug,
            mode: mode,
            addressId: addressId,
            pickupPointId: pickupPointId,
            expectedVersion: state.context?.version ?? 0,
          );
      if (_owner != owner || _shopSlug != shopSlug) return false;
      await ref
          .read(deliveryContextCacheProvider)
          .write(ownerSubjectId: owner, context: selected);
      if (_owner != owner || _shopSlug != shopSlug) return false;
      state = DeliveryContextState(
        status: DeliveryContextViewStatus.ready,
        authenticated: true,
        context: selected,
      );
      return true;
    } on DeliveryContextRepositoryException catch (error) {
      if (_owner == owner && _shopSlug == shopSlug) {
        state = state.copyWith(
          status: DeliveryContextViewStatus.failure,
          failure: error.kind,
          isMutating: false,
        );
        if (error.kind == DeliveryContextFailureKind.conflict) {
          unawaited(refresh());
        }
      }
      return false;
    }
  }

  bool _current(String owner, String shopSlug, int generation) =>
      !_disposed &&
      _owner == owner &&
      _shopSlug == shopSlug &&
      generation == _generation;
}
