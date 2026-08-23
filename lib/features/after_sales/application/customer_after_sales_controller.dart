import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../../orders/application/customer_order_providers.dart';
import '../data/supabase_customer_after_sales_repository.dart';
import '../domain/customer_after_sales_models.dart';
import '../domain/customer_after_sales_repository.dart';

final customerAfterSalesRepositoryProvider =
    Provider<CustomerAfterSalesRepository>((ref) {
      return SupabaseCustomerAfterSalesRepository(
        port: PlatformCustomerAfterSalesPort(Supabase.instance.client),
      );
    });

final customerAfterSalesControllerProvider =
    NotifierProvider<CustomerAfterSalesController, CustomerAfterSalesState>(
      CustomerAfterSalesController.new,
    );

final class CustomerAfterSalesState {
  CustomerAfterSalesState({
    required this.isLoading,
    required this.isMutating,
    required List<CustomerAfterSalesCase> cases,
    this.failure,
  }) : cases = List.unmodifiable(cases);

  factory CustomerAfterSalesState.loading() => CustomerAfterSalesState(
    isLoading: true,
    isMutating: false,
    cases: const [],
  );

  final bool isLoading;
  final bool isMutating;
  final List<CustomerAfterSalesCase> cases;
  final String? failure;

  CustomerAfterSalesState copyWith({
    bool? isLoading,
    bool? isMutating,
    List<CustomerAfterSalesCase>? cases,
    String? failure,
    bool clearFailure = false,
  }) {
    return CustomerAfterSalesState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      cases: cases ?? this.cases,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

final class CustomerAfterSalesController
    extends Notifier<CustomerAfterSalesState> {
  String? _contextKey;
  var _generation = 0;
  String? _pendingCreateSignature;
  String? _pendingCreateIdempotencyKey;

  @override
  CustomerAfterSalesState build() {
    final identity = ref.watch(customerAccountIdentityProvider);
    final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
    final key = '${identity?.subjectId}|$shopSlug';
    if (_contextKey != key) {
      _contextKey = key;
      _pendingCreateSignature = null;
      _pendingCreateIdempotencyKey = null;
      final generation = ++_generation;
      scheduleMicrotask(() => _load(generation));
      return CustomerAfterSalesState.loading();
    }
    return state;
  }

  Future<void> refresh() => _load(++_generation);

  Future<CustomerAfterSalesCase?> create(CustomerAfterSalesDraft draft) async {
    if (state.isMutating) return null;
    final contextFence = _captureContextFence();
    if (contextFence == null) return null;
    final signature = _createSignature(draft);
    if (_pendingCreateSignature != signature) {
      _pendingCreateSignature = signature;
      _pendingCreateIdempotencyKey = ref.read(
        customerOrderIdempotencyKeyFactoryProvider,
      )();
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final value = await ref
          .read(customerAfterSalesRepositoryProvider)
          .create(draft: draft, idempotencyKey: _pendingCreateIdempotencyKey!);
      if (!_isCurrentContext(contextFence)) return null;
      _pendingCreateSignature = null;
      _pendingCreateIdempotencyKey = null;
      state = state.copyWith(
        isMutating: false,
        cases: [value, ...state.cases.where((item) => item.id != value.id)],
      );
      return value;
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return null;
      state = state.copyWith(isMutating: false, failure: error.code);
      return null;
    }
  }

  Future<void> cancel(CustomerAfterSalesCase value) async {
    if (state.isMutating || !value.canCancel) return;
    final contextFence = _captureContextFence();
    if (contextFence == null) return;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final updated = await ref
          .read(customerAfterSalesRepositoryProvider)
          .cancel(caseId: value.id, expectedVersion: value.version);
      if (!_isCurrentContext(contextFence)) return;
      state = state.copyWith(
        isMutating: false,
        cases: state.cases
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return;
      state = state.copyWith(isMutating: false, failure: error.code);
    }
  }

  Future<bool> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    if (state.isMutating) return false;
    final contextFence = _captureContextFence();
    if (contextFence == null) return false;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      await ref
          .read(customerAfterSalesRepositoryProvider)
          .uploadEvidence(caseId: caseId, input: input);
      if (!_isCurrentContext(contextFence)) return false;
      state = state.copyWith(isMutating: false);
      return true;
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return false;
      state = state.copyWith(isMutating: false, failure: error.code);
      return false;
    }
  }

  Future<void> _load(int generation) async {
    final identity = ref.read(customerAccountIdentityProvider);
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (identity == null || shopSlug == null) {
      if (generation == _generation) {
        state = CustomerAfterSalesState(
          isLoading: false,
          isMutating: false,
          cases: const [],
        );
      }
      return;
    }
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final values = await ref
          .read(customerAfterSalesRepositoryProvider)
          .list(shopSlug: shopSlug);
      if (generation == _generation) {
        state = CustomerAfterSalesState(
          isLoading: false,
          isMutating: false,
          cases: values,
        );
      }
    } on CustomerAfterSalesException catch (error) {
      if (generation == _generation) {
        state = state.copyWith(isLoading: false, failure: error.code);
      }
    }
  }

  ({int generation, String key})? _captureContextFence() {
    final identity = ref.read(customerAccountIdentityProvider);
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (identity == null || shopSlug == null) return null;
    final key = '${identity.subjectId}|$shopSlug';
    if (key != _contextKey) return null;
    return (generation: _generation, key: key);
  }

  bool _isCurrentContext(({int generation, String key}) fence) {
    final identity = ref.read(customerAccountIdentityProvider);
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    return fence.generation == _generation &&
        fence.key == _contextKey &&
        identity != null &&
        '${identity.subjectId}|$shopSlug' == fence.key;
  }
}

String _createSignature(CustomerAfterSalesDraft draft) => [
  draft.orderId,
  draft.type.name,
  draft.reason.name,
  draft.note ?? '',
  ...draft.lines.map((line) => '${line.orderItemId}:${line.quantity}'),
].join('|');
