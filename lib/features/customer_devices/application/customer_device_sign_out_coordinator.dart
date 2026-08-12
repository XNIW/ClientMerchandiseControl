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
      final generatedKey = _uuidFactory();
      final pending = await _localStore.update((record) {
        final existing = record.pendingOperations
            .where(
              (operation) =>
                  operation.kind == CustomerDevicePendingOperationKind.revoke &&
                  operation.ownerSubjectId == ownerSubjectId,
            )
            .firstOrNull;
        return record
            .queueRevocation(
              CustomerDevicePendingOperation(
                kind: CustomerDevicePendingOperationKind.revoke,
                ownerSubjectId: ownerSubjectId,
                idempotencyKey: existing?.idempotencyKey ?? generatedKey,
              ),
            )
            .copyWith(
              decisionOwnerSubjectId: ownerSubjectId,
              consentStatus: CustomerDeviceConsentStatus.revoked,
            );
      });
      final operation = pending.pendingOperations.firstWhere(
        (candidate) =>
            candidate.kind == CustomerDevicePendingOperationKind.revoke &&
            candidate.ownerSubjectId == ownerSubjectId,
      );
      await _repository.revoke(
        installationId: pending.installationId,
        idempotencyKey: operation.idempotencyKey,
      );
      await _localStore.update(
        (current) => current.completePending(operation.idempotencyKey),
      );
    } on Object {
      // Il record pending consente un retry al prossimo accesso dello stesso owner.
    }
  }
}
