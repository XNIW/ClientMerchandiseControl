import '../data/shared_preferences_customer_device_store.dart';
import '../domain/customer_device_models.dart';
import '../domain/customer_device_repository.dart';

final class CustomerDeviceSignOutCoordinator {
  factory CustomerDeviceSignOutCoordinator({
    required CustomerDeviceRepository repository,
    required CustomerDeviceLocalStore localStore,
    required CustomerPushTokenProvider pushTokenProvider,
    required CustomerDeviceUuidFactory uuidFactory,
  }) {
    return CustomerDeviceSignOutCoordinator._(
      repository,
      localStore,
      pushTokenProvider,
      uuidFactory,
    );
  }

  CustomerDeviceSignOutCoordinator._(
    this._repository,
    this._localStore,
    this._pushTokenProvider,
    this._uuidFactory,
  );

  final CustomerDeviceRepository _repository;
  final CustomerDeviceLocalStore _localStore;
  final CustomerPushTokenProvider _pushTokenProvider;
  final CustomerDeviceUuidFactory _uuidFactory;
  Future<void>? _active;

  Future<void> prepareForSignOut(String ownerSubjectId) {
    final active = _active;
    if (active != null) {
      return active;
    }
    late final Future<void> operation;
    operation = _run(ownerSubjectId).whenComplete(() {
      if (identical(_active, operation)) {
        _active = null;
      }
    });
    _active = operation;
    return operation;
  }

  Future<void> _run(String ownerSubjectId) async {
    try {
      await _pushTokenProvider.revokeLocalToken();
    } on Object {
      // Continua con la revoca server-side, che è il confine autorevole.
    }
    try {
      if (!isCustomerDeviceUuid(ownerSubjectId)) {
        return;
      }
      final record = await _localStore.loadOrCreate();
      final existing = record.pendingOperation;
      final key =
          existing?.kind == CustomerDevicePendingOperationKind.revoke &&
              existing?.ownerSubjectId == ownerSubjectId
          ? existing!.idempotencyKey
          : _uuidFactory();
      final pending = record.copyWith(
        decisionOwnerSubjectId: ownerSubjectId,
        consentStatus: CustomerDeviceConsentStatus.revoked,
        pendingOperation: CustomerDevicePendingOperation(
          kind: CustomerDevicePendingOperationKind.revoke,
          ownerSubjectId: ownerSubjectId,
          idempotencyKey: key,
        ),
      );
      await _localStore.save(pending);
      await _repository.revoke(
        installationId: record.installationId,
        idempotencyKey: key,
      );
      await _localStore.save(pending.copyWith(clearPendingOperation: true));
    } on Object {
      // Il record pending consente un retry al prossimo accesso dello stesso owner.
    }
  }
}
