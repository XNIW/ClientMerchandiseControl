import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_account_failure.dart';
import '../domain/customer_account_models.dart';
import '../domain/customer_account_repository.dart';
import 'customer_account_providers.dart';

const _customerStateUnset = Object();

enum CustomerAccountStatus { signedOut, loading, ready, offline, failure }

enum CustomerAccountNoticeKind {
  profileSaved,
  profileDeleted,
  addressSaved,
  addressDeleted,
  defaultAddressChanged,
  consentUpdated,
  deletionRequested,
  deletionCancelled,
  actionFailed,
}

final class CustomerAccountState {
  const CustomerAccountState({
    required this.status,
    this.snapshot,
    this.failure,
    this.isMutating = false,
    this.export,
    this.notice,
    this.noticeRevision = 0,
  });

  const CustomerAccountState.signedOut()
    : this(status: CustomerAccountStatus.signedOut);

  const CustomerAccountState.loading()
    : this(status: CustomerAccountStatus.loading);

  final CustomerAccountStatus status;
  final CustomerAccountSnapshot? snapshot;
  final CustomerAccountFailure? failure;
  final bool isMutating;
  final CustomerDataExport? export;
  final CustomerAccountNoticeKind? notice;
  final int noticeRevision;

  CustomerAccountState copyWith({
    CustomerAccountStatus? status,
    Object? snapshot = _customerStateUnset,
    Object? failure = _customerStateUnset,
    bool? isMutating,
    Object? export = _customerStateUnset,
    Object? notice = _customerStateUnset,
    int? noticeRevision,
  }) {
    return CustomerAccountState(
      status: status ?? this.status,
      snapshot: identical(snapshot, _customerStateUnset)
          ? this.snapshot
          : snapshot as CustomerAccountSnapshot?,
      failure: identical(failure, _customerStateUnset)
          ? this.failure
          : failure as CustomerAccountFailure?,
      isMutating: isMutating ?? this.isMutating,
      export: identical(export, _customerStateUnset)
          ? this.export
          : export as CustomerDataExport?,
      notice: identical(notice, _customerStateUnset)
          ? this.notice
          : notice as CustomerAccountNoticeKind?,
      noticeRevision: noticeRevision ?? this.noticeRevision,
    );
  }
}

final customerAccountControllerProvider =
    NotifierProvider<CustomerAccountController, CustomerAccountState>(
      CustomerAccountController.new,
    );

final class CustomerAccountController extends Notifier<CustomerAccountState> {
  static const privacyConsentVersion = 'privacy-2026.08';

  CustomerAccountState? _lastState;
  Future<void>? _operation;
  String? _subjectId;
  String? _pendingDeletionKey;
  var _generation = 0;
  var _disposed = false;

  @override
  CustomerAccountState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final identity = ref.watch(customerAccountIdentityProvider);
    if (identity == null) {
      _subjectId = null;
      _pendingDeletionKey = null;
      final signedOut = const CustomerAccountState.signedOut();
      _lastState = signedOut;
      return signedOut;
    }
    if (_subjectId == identity.subjectId && _lastState != null) {
      return _lastState!;
    }
    _subjectId = identity.subjectId;
    _pendingDeletionKey = null;
    final loading = const CustomerAccountState.loading();
    _lastState = loading;
    final generation = ++_generation;
    scheduleMicrotask(() => _loadAfterActiveOperation(generation));
    return loading;
  }

  Future<void> retry() => _restartLoad();

  Future<void> refresh() => _restartLoad(preserveData: true);

  Future<void> saveProfile(CustomerProfileDraft draft) {
    final snapshot = _lastState?.snapshot;
    return _mutate(
      (repository, subjectId) => repository.saveProfile(
        subjectId,
        draft,
        profileExists: snapshot?.profile != null,
      ),
      CustomerAccountNoticeKind.profileSaved,
    );
  }

  Future<void> deleteProfile() {
    return _mutate(
      (repository, subjectId) => repository.deleteProfile(subjectId),
      CustomerAccountNoticeKind.profileDeleted,
    );
  }

  Future<void> createAddress(CustomerAddressDraft draft) {
    return _mutate(
      (repository, _) => repository.createAddress(draft),
      CustomerAccountNoticeKind.addressSaved,
    );
  }

  Future<void> updateAddress(String addressId, CustomerAddressDraft draft) {
    return _mutate(
      (repository, _) => repository.updateAddress(addressId, draft),
      CustomerAccountNoticeKind.addressSaved,
    );
  }

  Future<void> deleteAddress(String addressId) {
    return _mutate(
      (repository, _) => repository.deleteAddress(addressId),
      CustomerAccountNoticeKind.addressDeleted,
    );
  }

  Future<void> setDefaultAddress(String addressId) {
    return _mutate(
      (repository, _) => repository.setDefaultAddress(addressId),
      CustomerAccountNoticeKind.defaultAddressChanged,
    );
  }

  Future<void> recordPrivacyConsent(bool accepted) {
    return _mutate(
      (repository, _) => repository.recordPrivacyConsent(
        version: accepted ? privacyConsentVersion : '',
        accepted: accepted,
      ),
      CustomerAccountNoticeKind.consentUpdated,
    );
  }

  Future<void> requestAccountDeletion() {
    _pendingDeletionKey ??= ref.read(customerIdempotencyKeyFactoryProvider)();
    final key = _pendingDeletionKey!;
    return _mutate(
      (repository, _) => repository.requestAccountDeletion(key),
      CustomerAccountNoticeKind.deletionRequested,
      afterSuccess: () => _pendingDeletionKey = null,
    );
  }

  Future<void> cancelAccountDeletion(String requestId) {
    return _mutate(
      (repository, _) => repository.cancelAccountDeletion(requestId),
      CustomerAccountNoticeKind.deletionCancelled,
      afterSuccess: () => _pendingDeletionKey = null,
    );
  }

  Future<void> exportData() {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      _publish(
        (_lastState ?? const CustomerAccountState.loading()).copyWith(
          isMutating: true,
          failure: null,
          export: null,
        ),
      );
      try {
        final repository = ref.read(customerAccountRepositoryProvider);
        final export = await repository.exportData();
        if (_subjectId != subjectId || _disposed) {
          return;
        }
        _publish(
          (_lastState ?? const CustomerAccountState.loading()).copyWith(
            status: CustomerAccountStatus.ready,
            isMutating: false,
            failure: null,
            export: export,
          ),
        );
      } on Object catch (error) {
        _publishMutationFailure(error, subjectId);
      }
    });
  }

  void clearExport() {
    final current = _lastState;
    if (current != null && current.export != null) {
      _publish(current.copyWith(export: null));
    }
  }

  Future<void> _restartLoad({bool preserveData = false}) {
    final active = _operation;
    if (active != null) {
      return active;
    }
    return _startLoad(++_generation, preserveData: preserveData);
  }

  Future<void> _loadAfterActiveOperation(int generation) async {
    final active = _operation;
    if (active != null) {
      await active;
    }
    if (_disposed || _subjectId == null || _generation != generation) {
      return;
    }
    await _startLoad(generation);
  }

  Future<void> _startLoad(int generation, {bool preserveData = false}) {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      final previous = _lastState?.snapshot;
      _publish(
        preserveData && previous != null
            ? _lastState!.copyWith(isMutating: true, failure: null)
            : const CustomerAccountState.loading(),
      );
      try {
        final repository = ref.read(customerAccountRepositoryProvider);
        final snapshot = await repository.load(subjectId);
        if (!_isCurrent(subjectId, generation)) {
          return;
        }
        _publish(
          CustomerAccountState(
            status: CustomerAccountStatus.ready,
            snapshot: snapshot,
          ),
        );
      } on Object catch (error) {
        if (!_isCurrent(subjectId, generation)) {
          return;
        }
        final failure = _failureFrom(error);
        _publish(
          CustomerAccountState(
            status: failure.kind == CustomerAccountFailureKind.offline
                ? CustomerAccountStatus.offline
                : CustomerAccountStatus.failure,
            snapshot: previous,
            failure: failure,
          ),
        );
      }
    });
  }

  Future<void> _mutate(
    Future<void> Function(
      CustomerAccountRepository repository,
      String subjectId,
    )
    action,
    CustomerAccountNoticeKind successNotice, {
    void Function()? afterSuccess,
  }) {
    return _serialize(() async {
      final subjectId = _subjectId;
      final current = _lastState;
      if (subjectId == null || current?.snapshot == null) {
        return;
      }
      _publish(
        current!.copyWith(
          isMutating: true,
          failure: null,
          notice: null,
          export: null,
        ),
      );
      try {
        final repository = ref.read(customerAccountRepositoryProvider);
        await action(repository, subjectId);
        final snapshot = await repository.load(subjectId);
        if (_subjectId != subjectId || _disposed) {
          return;
        }
        afterSuccess?.call();
        _publish(
          CustomerAccountState(
            status: CustomerAccountStatus.ready,
            snapshot: snapshot,
            notice: successNotice,
            noticeRevision: current.noticeRevision + 1,
          ),
        );
      } on Object catch (error) {
        _publishMutationFailure(error, subjectId);
      }
    });
  }

  void _publishMutationFailure(Object error, String subjectId) {
    if (_subjectId != subjectId || _disposed) {
      return;
    }
    final current = _lastState ?? const CustomerAccountState.loading();
    _publish(
      current.copyWith(
        status: current.snapshot == null
            ? CustomerAccountStatus.failure
            : CustomerAccountStatus.ready,
        isMutating: false,
        failure: _failureFrom(error),
        notice: CustomerAccountNoticeKind.actionFailed,
        noticeRevision: current.noticeRevision + 1,
      ),
    );
  }

  Future<void> _serialize(Future<void> Function() action) {
    final active = _operation;
    if (active != null) {
      return active;
    }
    late final Future<void> operation;
    operation = action().whenComplete(() {
      if (identical(_operation, operation)) {
        _operation = null;
      }
    });
    _operation = operation;
    return operation;
  }

  bool _isCurrent(String subjectId, int generation) {
    return !_disposed && _subjectId == subjectId && _generation == generation;
  }

  void _publish(CustomerAccountState next) {
    if (_disposed) {
      return;
    }
    _lastState = next;
    state = next;
  }
}

CustomerAccountFailure _failureFrom(Object error) {
  return switch (error) {
    CustomerAccountRepositoryException(:final kind) => CustomerAccountFailure(
      kind,
    ),
    CustomerAccountInputException() => const CustomerAccountFailure(
      CustomerAccountFailureKind.invalidInput,
    ),
    _ => const CustomerAccountFailure(CustomerAccountFailureKind.unavailable),
  };
}
