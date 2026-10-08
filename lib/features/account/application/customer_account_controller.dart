import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_account_failure.dart';
import '../domain/address_creation_intent.dart';
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
    this.pendingAddressDraft,
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
  final CustomerAddressDraft? pendingAddressDraft;

  CustomerAccountState copyWith({
    CustomerAccountStatus? status,
    Object? snapshot = _customerStateUnset,
    Object? failure = _customerStateUnset,
    bool? isMutating,
    Object? export = _customerStateUnset,
    Object? notice = _customerStateUnset,
    int? noticeRevision,
    Object? pendingAddressDraft = _customerStateUnset,
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
      pendingAddressDraft: identical(pendingAddressDraft, _customerStateUnset)
          ? this.pendingAddressDraft
          : pendingAddressDraft as CustomerAddressDraft?,
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
  String? _shopSlug;
  AddressCreationIntent? _pendingIntent;
  Future<CustomerAddress?>? _addressOperation;
  CustomerAddressDraft? _activeAddressDraft;
  int? _activeAddressGeneration;
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
    final shopSlug = identity == null
        ? null
        : ref.watch(customerAccountShopSlugProvider);
    if (identity == null) {
      _generation++;
      _subjectId = null;
      _pendingIntent = null;
      _pendingDeletionKey = null;
      final signedOut = const CustomerAccountState.signedOut();
      _lastState = signedOut;
      return signedOut;
    }
    if (_subjectId == identity.subjectId &&
        _shopSlug == shopSlug &&
        _lastState != null) {
      return _lastState!;
    }
    _subjectId = identity.subjectId;
    _shopSlug = shopSlug;
    _pendingIntent = null;
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

  Future<CustomerAddress?> createAddress(CustomerAddressDraft draft) {
    final active = _addressOperation;
    if (active != null) {
      final same =
          _activeAddressGeneration == _generation &&
          AddressCreationIntent(
            id: '',
            draft: _activeAddressDraft!,
          ).matches(draft);
      return same ? active : Future.value();
    }
    if (_operation != null) return Future.value();
    final owner = _subjectId;
    final generation = _generation;
    if (owner == null || _lastState?.snapshot == null) return Future.value();
    _activeAddressDraft = draft;
    _activeAddressGeneration = generation;
    late final Future<CustomerAddress?> operation;
    operation = _createAddress(draft, owner, generation).whenComplete(() {
      if (identical(_addressOperation, operation)) {
        _addressOperation = null;
        _activeAddressDraft = null;
        _activeAddressGeneration = null;
      }
    });
    _addressOperation = operation;
    return operation;
  }

  Future<CustomerAddress?> _createAddress(
    CustomerAddressDraft draft,
    String owner,
    int generation,
  ) async {
    CustomerAddress? acknowledged;
    await _serialize(() async {
      if (!_isCurrent(owner, generation)) return;
      final repository = ref.read(customerAccountRepositoryProvider);
      final journal = repository.addressCreationJournal;
      final current = _lastState!;
      _publish(current.copyWith(isMutating: true, failure: null, notice: null));
      var ambiguous = false;
      var hadPending = false;
      try {
        var intent = await journal.read(owner);
        if (!_isCurrent(owner, generation)) return;
        if (intent != null) {
          hadPending = true;
          _pendingIntent = intent;
          ambiguous = true;
          // Una modifica non cambia identità e non può generare un duplicato.
          // Prima si verifica il contenuto originale; poi si modifica il canonico.
          if (!intent.matches(draft)) {
            _publish(
              current.copyWith(
                isMutating: false,
                failure: const CustomerAccountFailure(
                  CustomerAccountFailureKind.conflict,
                  isUncertain: true,
                ),
                notice: CustomerAccountNoticeKind.actionFailed,
                noticeRevision: current.noticeRevision + 1,
              ),
            );
            return;
          }
          // Un precedente flush fallito può aver aggiornato solo la memoria.
          // Conferma di nuovo su disco lo stesso payload prima di qualsiasi RPC.
          await journal.write(owner, intent);
          if (!_isCurrent(owner, generation)) return;
          acknowledged = await repository.reconcileAddressCreation(intent.id);
          if (!_isCurrent(owner, generation)) return;
        } else {
          intent = AddressCreationIntent(
            id: ref.read(customerIdempotencyKeyFactoryProvider)(),
            draft: draft,
          );
          // Deve riuscire prima di inviare qualunque scrittura remota.
          await journal.write(owner, intent);
          if (!_isCurrent(owner, generation)) return;
          _pendingIntent = intent;
        }
        if (acknowledged == null) {
          ambiguous = true;
          acknowledged = await repository.createAddress(
            intent.draft,
            intentId: intent.id,
          );
        }
        // Un ACK vecchio non conferma né chiude l'editor di un nuovo scope.
        if (!_isCurrent(owner, generation)) return;
        ambiguous = false;
        await journal.clear(owner);
        if (!_isCurrent(owner, generation)) return;
        _pendingIntent = null;
        final snapshot = await repository.load(owner);
        if (!_isCurrent(owner, generation)) return;
        _publish(
          CustomerAccountState(
            status: CustomerAccountStatus.ready,
            snapshot: snapshot,
            notice: CustomerAccountNoticeKind.addressSaved,
            noticeRevision: current.noticeRevision + 1,
          ),
        );
      } on Object catch (error) {
        if (!_isCurrent(owner, generation)) return;
        final failure = _failureFrom(error);
        final rejected =
            error is CustomerAccountRepositoryException &&
            error.creationRejected;
        if (acknowledged == null &&
            ((rejected && !hadPending) ||
                (error is CustomerAccountRepositoryException &&
                    error.creationDeleted))) {
          try {
            await journal.clear(owner);
            _pendingIntent = null;
            ambiguous = false;
          } on Object {
            /* Conserva il journal se la rimozione non riesce. */
          }
        }
        if (!_isCurrent(owner, generation)) return;
        _publish(
          (_lastState ?? current).copyWith(
            isMutating: false,
            failure: CustomerAccountFailure(
              failure.kind,
              isUncertain:
                  acknowledged == null && (ambiguous || _pendingIntent != null),
            ),
            notice: CustomerAccountNoticeKind.actionFailed,
            noticeRevision: current.noticeRevision + 1,
          ),
        );
      }
    });
    return _isCurrent(owner, generation) ? acknowledged : null;
  }

  /// Conferma la scrittura nella stessa sessione, anche se il refresh fallisce.
  Future<bool> updateAddress(
    String addressId,
    int expectedVersion,
    CustomerAddressDraft draft,
  ) async {
    final subjectId = _subjectId;
    final generation = _generation;
    var acknowledged = false;
    await _mutate((repository, _) async {
      await repository.updateAddress(
        addressId,
        draft,
        expectedVersion: expectedVersion,
      );
      acknowledged = true;
    }, CustomerAccountNoticeKind.addressSaved);
    return acknowledged &&
        subjectId != null &&
        _isCurrent(subjectId, generation);
  }

  Future<void> deleteAddress(String addressId, [int expectedVersion = 1]) {
    return _mutate(
      (repository, _) =>
          repository.deleteAddress(addressId, expectedVersion: expectedVersion),
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
      final generation = _generation;
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
        if (!_isCurrent(subjectId, generation)) {
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
        _publishMutationFailure(error, subjectId, generation);
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
        final intent = await repository.addressCreationJournal.read(subjectId);
        if (!_isCurrent(subjectId, generation)) return;
        _pendingIntent = intent;
        final snapshot = await repository.load(subjectId);
        if (!_isCurrent(subjectId, generation)) {
          return;
        }
        _publish(
          CustomerAccountState(
            status: CustomerAccountStatus.ready,
            snapshot: snapshot,
            failure: _pendingIntent == null
                ? null
                : const CustomerAccountFailure(
                    CustomerAccountFailureKind.unavailable,
                    isUncertain: true,
                  ),
            notice: _pendingIntent == null
                ? null
                : CustomerAccountNoticeKind.actionFailed,
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
      final generation = _generation;
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
        if (!_isCurrent(subjectId, generation)) return;
        final snapshot = await repository.load(subjectId);
        if (!_isCurrent(subjectId, generation)) {
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
        _publishMutationFailure(error, subjectId, generation);
      }
    });
  }

  void _publishMutationFailure(Object error, String subjectId, int generation) {
    if (!_isCurrent(subjectId, generation)) {
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
    final scoped = next.copyWith(pendingAddressDraft: _pendingIntent?.draft);
    _lastState = scoped;
    state = scoped;
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
