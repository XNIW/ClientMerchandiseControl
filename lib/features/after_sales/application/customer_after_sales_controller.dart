import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
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
    this.attachmentCaseId,
    this.attachmentOrderId,
    List<CustomerAfterSalesLocalAttachment> attachments = const [],
  }) : cases = List.unmodifiable(cases), attachments = List.unmodifiable(attachments);

  factory CustomerAfterSalesState.loading() => CustomerAfterSalesState(
    isLoading: true,
    isMutating: false,
    cases: const [],
  );

  final bool isLoading;
  final bool isMutating;
  final List<CustomerAfterSalesCase> cases;
  final String? failure;
  final String? attachmentCaseId;
  final String? attachmentOrderId;
  final List<CustomerAfterSalesLocalAttachment> attachments;
  bool get hasIncompleteAttachments => attachments.any((file) => file.status != CustomerAfterSalesAttachmentStatus.confirmed);

  CustomerAfterSalesState copyWith({
    bool? isLoading,
    bool? isMutating,
    List<CustomerAfterSalesCase>? cases,
    String? failure,
    bool clearFailure = false,
    String? attachmentCaseId,
    String? attachmentOrderId,
    List<CustomerAfterSalesLocalAttachment>? attachments,
  }) {
    return CustomerAfterSalesState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      cases: cases ?? this.cases,
      failure: clearFailure ? null : failure ?? this.failure,
      attachmentCaseId: attachmentCaseId ?? this.attachmentCaseId,
      attachmentOrderId: attachmentOrderId ?? this.attachmentOrderId,
      attachments: attachments ?? this.attachments,
    );
  }
}

final class CustomerAfterSalesController
    extends Notifier<CustomerAfterSalesState> {
  String? _contextKey;
  var _generation = 0;
  var _disposed = false;
  var _operationBusy = false;
  String? _pendingCreateSignature;
  String? _pendingCreateIdempotencyKey;

  @override
  CustomerAfterSalesState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    if (ref.exists(authControllerProvider)) {
      ref.listen(authControllerProvider, (previous, next) {
        String? owner(AuthState? value) => switch (value) { AuthAuthenticated(:final customer) => customer.subjectId, _ => null };
        if (owner(previous) != owner(next)) {
          ++_generation;
          _contextKey = null;
          _operationBusy = false;
          _pendingCreateSignature = null;
          _pendingCreateIdempotencyKey = null;
          state = CustomerAfterSalesState.loading();
          ref.invalidateSelf();
        }
      });
    }
    final identity = ref.watch(customerAccountIdentityProvider);
    final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
    final key = '${identity?.subjectId}|$shopSlug';
    if (_contextKey != key) {
      _contextKey = key;
      _operationBusy = false;
      _pendingCreateSignature = null;
      _pendingCreateIdempotencyKey = null;
      final generation = ++_generation;
      scheduleMicrotask(() => _load(generation));
      return CustomerAfterSalesState.loading();
    }
    return state;
  }

  Future<void> refresh() async {
    if (_operationBusy) return;
    await _load(++_generation);
  }

  Future<CustomerAfterSalesCase?> create(CustomerAfterSalesDraft draft) async {
    if (_operationBusy) return null;
    final contextFence = _captureContextFence();
    if (contextFence == null) return null;
    _operationBusy = true;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      return await _createCase(draft, contextFence);
    } finally {
      if (_isCurrentContext(contextFence)) {
        _operationBusy = false;
        state = state.copyWith(isMutating: false);
      }
    }
  }

  Future<CustomerAfterSalesCase?> _createCase(CustomerAfterSalesDraft draft, ({int generation, String key}) contextFence) async {
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
        isMutating: true,
        cases: [value, ...state.cases.where((item) => item.id != value.id)],
      );
      return value;
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return null;
      state = state.copyWith(isMutating: true, failure: error.code);
      return null;
    }
  }

  Future<void> cancel(CustomerAfterSalesCase value) async {
    if (_operationBusy || !value.canCancel) return;
    final contextFence = _captureContextFence();
    if (contextFence == null) return;
    _operationBusy = true;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final updated = await ref
          .read(customerAfterSalesRepositoryProvider)
          .cancel(caseId: value.id, expectedVersion: value.version);
      if (!_isCurrentContext(contextFence)) return;
      _operationBusy = false;
      state = state.copyWith(
        isMutating: false,
        cases: state.cases
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return;
      _operationBusy = false;
      state = state.copyWith(isMutating: false, failure: error.code);
    }
  }

  Future<bool> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    if (_operationBusy) return false;
    final contextFence = _captureContextFence();
    if (contextFence == null) return false;
    _operationBusy = true;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      await ref
          .read(customerAfterSalesRepositoryProvider)
          .uploadEvidence(caseId: caseId, input: input);
      if (!_isCurrentContext(contextFence)) return false;
      _operationBusy = false;
      state = state.copyWith(isMutating: false);
      return true;
    } on CustomerAfterSalesException catch (error) {
      if (!_isCurrentContext(contextFence)) return false;
      _operationBusy = false;
      state = state.copyWith(isMutating: false, failure: error.code);
      return false;
    }
  }

  bool Function()? captureOperationContext() {
    final fence = _captureContextFence();
    return fence == null ? null : () => _isCurrentContext(fence);
  }

  Future<CustomerAfterSalesCase?> submitWithEvidence({
    required CustomerAfterSalesDraft draft,
    required List<CustomerAfterSalesLocalAttachment> attachments,
    required bool Function() canContinue,
  }) async {
    if (_operationBusy) return null;
    final fence = _captureContextFence();
    if (fence == null || !canContinue()) return null;
    _operationBusy = true;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      var value = state.attachmentOrderId == draft.orderId
          ? state.cases.where((item) => item.id == state.attachmentCaseId).firstOrNull : null;
      value ??= await _createCase(draft, fence);
      if (value == null || !_isCurrentContext(fence)) return null;
      // caseId viene conservato prima di leggere qualunque file locale.
      if (state.attachmentCaseId != value.id) {
        state = state.copyWith(attachmentCaseId: value.id, attachmentOrderId: draft.orderId, attachments: attachments);
      }
      if (!canContinue()) return value;
      await _completeAttachments(value.id, fence, canContinue);
      return _isCurrentContext(fence) ? value : null;
    } finally {
      if (_isCurrentContext(fence)) {
        _operationBusy = false;
        state = state.copyWith(isMutating: false);
      }
    }
  }

  void selectAttachments(String caseId, List<CustomerAfterSalesLocalAttachment> values, {int? replaceIndex}) {
    if (_operationBusy || _captureContextFence() == null) return;
    if (state.attachmentCaseId != caseId) {
      state = state.copyWith(attachmentCaseId: caseId, attachments: values.take(3).toList());
      return;
    }
    final attachments = state.attachments.toList();
    if (replaceIndex != null && replaceIndex < attachments.length && values.isNotEmpty) {
      final old = attachments[replaceIndex];
      if (old.status != CustomerAfterSalesAttachmentStatus.fileUnavailable && old.status != CustomerAfterSalesAttachmentStatus.ready) return;
      attachments[replaceIndex] = values.first;
    } else {
      attachments.addAll(values.take(3 - attachments.length));
    }
    state = state.copyWith(attachments: attachments);
  }

  Future<void> completeAttachments(String caseId, bool Function() canContinue) async {
    if (_operationBusy || state.attachmentCaseId != caseId) return;
    final fence = _captureContextFence();
    if (fence == null || !canContinue()) return;
    _operationBusy = true;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      await _completeAttachments(caseId, fence, canContinue);
    } finally {
      if (_isCurrentContext(fence)) {
        _operationBusy = false;
        state = state.copyWith(isMutating: false);
      }
    }
  }

  Future<void> _completeAttachments(String caseId, ({int generation, String key}) fence, bool Function() canContinue) async {
    bool current() => _isCurrentContext(fence) && canContinue();
    for (final file in state.attachments.toList()) {
      if (!current()) return;
      if (file.status == CustomerAfterSalesAttachmentStatus.confirmed) continue;
      if (file.input == null) {
        file.status = CustomerAfterSalesAttachmentStatus.reading;
        state = state.copyWith();
        try {
          final bytes = await file.readBytes();
          if (!current()) return;
          file.input = CustomerAfterSalesEvidenceInput(bytes: bytes, extension: file.extension, mimeType: file.mimeType, ownerId: ref.read(customerAccountIdentityProvider)?.subjectId,
            // Fence contesto durevole; il retry può avvenire su un'altra route.
            canContinue: () => _isCurrentContext(fence));
        } on Object {
          if (!current()) return;
          file.status = CustomerAfterSalesAttachmentStatus.fileUnavailable;
          state = state.copyWith();
          continue;
        }
      }
      file.input!.canContinue = current;
      file.status = CustomerAfterSalesAttachmentStatus.uploading;
      state = state.copyWith();
      try {
        file.evidenceId = await ref.read(customerAfterSalesRepositoryProvider).uploadEvidence(caseId: caseId, input: file.input!);
        if (!_isCurrentContext(fence)) return;
        file.status = CustomerAfterSalesAttachmentStatus.confirmed;
      } on CustomerAfterSalesException catch (error) {
        if (!_isCurrentContext(fence)) return;
        file.status = error.code == 'evidence_ambiguous' || error.code == 'timeout' || error.code == 'offline'
            ? CustomerAfterSalesAttachmentStatus.ambiguous : CustomerAfterSalesAttachmentStatus.failed;
      } on Object {
        if (!_isCurrentContext(fence)) return;
        file.status = CustomerAfterSalesAttachmentStatus.ambiguous;
      }
      state = state.copyWith();
    }
  }

  Future<void> _load(int generation) async {
    if (_disposed || generation != _generation) return;
    final identity = ref.read(customerAccountIdentityProvider);
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (identity == null || shopSlug == null) {
      if (!_disposed && generation == _generation) {
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
      if (!_disposed && generation == _generation) {
        state = state.copyWith(isLoading: false, cases: values);
      }
    } on CustomerAfterSalesException catch (error) {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(isLoading: false, failure: error.code);
      }
    }
  }

  ({int generation, String key})? _captureContextFence() {
    if (_disposed) return null;
    final identity = ref.read(customerAccountIdentityProvider);
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (identity == null || shopSlug == null) return null;
    final key = '${identity.subjectId}|$shopSlug';
    if (key != _contextKey) return null;
    return (generation: _generation, key: key);
  }

  bool _isCurrentContext(({int generation, String key}) fence) {
    if (_disposed || fence.generation != _generation) return false;
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
