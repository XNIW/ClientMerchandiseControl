import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_device_failure.dart';
import '../domain/customer_device_models.dart';
import '../domain/customer_device_repository.dart';
import 'customer_device_providers.dart';

const _customerDeviceUnset = Object();

enum CustomerDeviceStatus { signedOut, loading, ready, offline, failure }

enum CustomerDeviceNoticeKind {
  enabled,
  denied,
  revoked,
  pendingServer,
  providerUnavailable,
  actionFailed,
}

final class CustomerDeviceState {
  const CustomerDeviceState({
    required this.status,
    required this.consentStatus,
    required this.permissionStatus,
    required this.providerAvailability,
    this.snapshot,
    this.failure,
    this.notice,
    this.isMutating = false,
    this.serverConfirmed = false,
  });

  const CustomerDeviceState.signedOut()
    : this(
        status: CustomerDeviceStatus.signedOut,
        consentStatus: CustomerDeviceConsentStatus.notRequested,
        permissionStatus: CustomerDevicePermissionStatus.notDetermined,
        providerAvailability: CustomerPushProviderAvailability.notConfigured,
      );

  const CustomerDeviceState.loading()
    : this(
        status: CustomerDeviceStatus.loading,
        consentStatus: CustomerDeviceConsentStatus.notRequested,
        permissionStatus: CustomerDevicePermissionStatus.notDetermined,
        providerAvailability: CustomerPushProviderAvailability.notConfigured,
      );

  final CustomerDeviceStatus status;
  final CustomerDeviceConsentStatus consentStatus;
  final CustomerDevicePermissionStatus permissionStatus;
  final CustomerPushProviderAvailability providerAvailability;
  final CustomerDeviceSnapshot? snapshot;
  final CustomerDeviceFailure? failure;
  final CustomerDeviceNoticeKind? notice;
  final bool isMutating;
  final bool serverConfirmed;

  bool get notificationsActive {
    return serverConfirmed &&
        consentStatus == CustomerDeviceConsentStatus.granted &&
        snapshot?.hasToken == true;
  }

  CustomerDeviceState copyWith({
    CustomerDeviceStatus? status,
    CustomerDeviceConsentStatus? consentStatus,
    CustomerDevicePermissionStatus? permissionStatus,
    CustomerPushProviderAvailability? providerAvailability,
    Object? snapshot = _customerDeviceUnset,
    Object? failure = _customerDeviceUnset,
    Object? notice = _customerDeviceUnset,
    bool? isMutating,
    bool? serverConfirmed,
  }) {
    return CustomerDeviceState(
      status: status ?? this.status,
      consentStatus: consentStatus ?? this.consentStatus,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      providerAvailability: providerAvailability ?? this.providerAvailability,
      snapshot: identical(snapshot, _customerDeviceUnset)
          ? this.snapshot
          : snapshot as CustomerDeviceSnapshot?,
      failure: identical(failure, _customerDeviceUnset)
          ? this.failure
          : failure as CustomerDeviceFailure?,
      notice: identical(notice, _customerDeviceUnset)
          ? this.notice
          : notice as CustomerDeviceNoticeKind?,
      isMutating: isMutating ?? this.isMutating,
      serverConfirmed: serverConfirmed ?? this.serverConfirmed,
    );
  }
}

final customerDeviceControllerProvider =
    NotifierProvider<CustomerDeviceController, CustomerDeviceState>(
      CustomerDeviceController.new,
    );

final class CustomerDeviceController extends Notifier<CustomerDeviceState> {
  CustomerDeviceState? _lastState;
  Future<void>? _operation;
  StreamSubscription<String>? _tokenSubscription;
  String? _subjectId;
  var _generation = 0;
  var _disposed = false;

  @override
  CustomerDeviceState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      unawaited(_tokenSubscription?.cancel());
      _tokenSubscription = null;
    });
    final identity = ref.watch(customerDeviceIdentityProvider);
    if (identity == null) {
      _subjectId = null;
      unawaited(_tokenSubscription?.cancel());
      _tokenSubscription = null;
      final signedOut = const CustomerDeviceState.signedOut();
      _lastState = signedOut;
      return signedOut;
    }
    if (_subjectId == identity.subjectId && _lastState != null) {
      return _lastState!;
    }
    _subjectId = identity.subjectId;
    unawaited(_tokenSubscription?.cancel());
    _tokenSubscription = null;
    final loading = const CustomerDeviceState.loading();
    _lastState = loading;
    final generation = ++_generation;
    scheduleMicrotask(() => _loadAfterActiveOperation(generation));
    return loading;
  }

  Future<void> refresh() {
    final active = _operation;
    if (active != null) {
      return active;
    }
    return _serialize(() => _load(++_generation));
  }

  Future<void> enable(String locale) {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      final provider = ref.read(customerPushTokenProvider);
      final capability = await provider.requestAuthorization();
      if (!_isCurrent(subjectId)) {
        return;
      }
      if (capability.availability ==
          CustomerPushProviderAvailability.notConfigured) {
        _publish(
          (_lastState ?? const CustomerDeviceState.loading()).copyWith(
            status: CustomerDeviceStatus.ready,
            providerAvailability: capability.availability,
            permissionStatus: capability.permission,
            notice: CustomerDeviceNoticeKind.providerUnavailable,
            isMutating: false,
          ),
        );
        return;
      }
      final consent =
          capability.permission == CustomerDevicePermissionStatus.authorized ||
              capability.permission ==
                  CustomerDevicePermissionStatus.provisional
          ? CustomerDeviceConsentStatus.granted
          : CustomerDeviceConsentStatus.denied;
      await _register(
        subjectId: subjectId,
        locale: locale,
        consent: consent,
        permission: capability.permission,
        token: consent == CustomerDeviceConsentStatus.granted
            ? capability.token
            : null,
        notice: consent == CustomerDeviceConsentStatus.granted
            ? CustomerDeviceNoticeKind.enabled
            : CustomerDeviceNoticeKind.denied,
      );
    });
  }

  Future<void> deny(String locale) {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      final capability = await ref
          .read(customerPushTokenProvider)
          .currentCapability();
      await _register(
        subjectId: subjectId,
        locale: locale,
        consent: CustomerDeviceConsentStatus.denied,
        permission: capability.permission,
        token: null,
        notice: CustomerDeviceNoticeKind.denied,
      );
    });
  }

  Future<void> revoke() {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      try {
        await ref.read(customerPushTokenProvider).revokeLocalToken();
      } on Object {
        // La revoca server resta necessaria anche se il provider locale fallisce.
      }
      final store = ref.read(customerDeviceLocalStoreProvider);
      final record = await store.loadOrCreate();
      final key =
          _matchingPendingKey(
            record,
            subjectId,
            CustomerDevicePendingOperationKind.revoke,
          ) ??
          ref.read(customerDeviceUuidFactoryProvider)();
      final pending = record.copyWith(
        decisionOwnerSubjectId: subjectId,
        consentStatus: CustomerDeviceConsentStatus.revoked,
        pendingOperation: CustomerDevicePendingOperation(
          kind: CustomerDevicePendingOperationKind.revoke,
          ownerSubjectId: subjectId,
          idempotencyKey: key,
        ),
      );
      await store.save(pending);
      _publishPending(
        consent: CustomerDeviceConsentStatus.revoked,
        permission:
            _lastState?.permissionStatus ??
            CustomerDevicePermissionStatus.notDetermined,
      );
      try {
        final snapshot = await ref
            .read(customerDeviceRepositoryProvider)
            .revoke(installationId: record.installationId, idempotencyKey: key);
        if (!_isCurrent(subjectId)) {
          return;
        }
        await store.save(pending.copyWith(clearPendingOperation: true));
        _publish(
          CustomerDeviceState(
            status: CustomerDeviceStatus.ready,
            consentStatus: CustomerDeviceConsentStatus.revoked,
            permissionStatus:
                snapshot?.permissionStatus ??
                (_lastState?.permissionStatus ??
                    CustomerDevicePermissionStatus.notDetermined),
            providerAvailability:
                _lastState?.providerAvailability ??
                CustomerPushProviderAvailability.notConfigured,
            snapshot: snapshot,
            notice: CustomerDeviceNoticeKind.revoked,
            serverConfirmed: true,
          ),
        );
      } on Object catch (error) {
        _publishOperationFailure(error, subjectId);
      }
    });
  }

  Future<void> retry(String locale) {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      final store = ref.read(customerDeviceLocalStoreProvider);
      final record = await store.loadOrCreate();
      final pending = record.pendingOperation;
      if (pending == null || pending.ownerSubjectId != subjectId) {
        await _load(++_generation);
        return;
      }
      if (pending.kind == CustomerDevicePendingOperationKind.revoke) {
        await _retryRevoke(subjectId, record, pending);
        return;
      }
      final capability = await ref
          .read(customerPushTokenProvider)
          .currentCapability();
      final consent = record.consentFor(subjectId);
      if (consent == CustomerDeviceConsentStatus.granted &&
          (capability.availability !=
                  CustomerPushProviderAvailability.configured ||
              capability.token == null)) {
        _publish(
          (_lastState ?? const CustomerDeviceState.loading()).copyWith(
            status: CustomerDeviceStatus.ready,
            failure: const CustomerDeviceFailure(
              CustomerDeviceFailureKind.unavailable,
            ),
            notice: CustomerDeviceNoticeKind.pendingServer,
            isMutating: false,
            serverConfirmed: false,
          ),
        );
        return;
      }
      await _registerWithKey(
        subjectId: subjectId,
        record: record,
        locale: locale,
        consent: consent,
        permission: capability.permission,
        token: consent == CustomerDeviceConsentStatus.granted
            ? capability.token
            : null,
        key: pending.idempotencyKey,
        notice: consent == CustomerDeviceConsentStatus.denied
            ? CustomerDeviceNoticeKind.denied
            : CustomerDeviceNoticeKind.enabled,
      );
    });
  }

  Future<void> _loadAfterActiveOperation(int generation) async {
    final active = _operation;
    if (active != null) {
      await active;
    }
    if (_disposed || _subjectId == null || _generation != generation) {
      return;
    }
    await _serialize(() => _load(generation));
  }

  Future<void> _load(int generation) async {
    final subjectId = _subjectId;
    if (subjectId == null || !isCustomerDeviceUuid(subjectId)) {
      _publish(
        const CustomerDeviceState(
          status: CustomerDeviceStatus.failure,
          consentStatus: CustomerDeviceConsentStatus.notRequested,
          permissionStatus: CustomerDevicePermissionStatus.notDetermined,
          providerAvailability: CustomerPushProviderAvailability.notConfigured,
          failure: CustomerDeviceFailure(
            CustomerDeviceFailureKind.unauthorized,
          ),
        ),
      );
      return;
    }
    try {
      final provider = ref.read(customerPushTokenProvider);
      final results = await Future.wait<Object?>([
        ref.read(customerDeviceLocalStoreProvider).loadOrCreate(),
        provider.currentCapability(),
      ]);
      final record = results[0]! as CustomerDeviceLocalRecord;
      final capability = results[1]! as CustomerPushCapability;
      if (!_isCurrent(subjectId) || generation != _generation) {
        return;
      }
      _listenForTokenChanges(provider);
      final pending = record.pendingOperation;
      final ownedPending = pending?.ownerSubjectId == subjectId
          ? pending
          : null;
      if (ownedPending != null &&
          ownedPending.kind == CustomerDevicePendingOperationKind.revoke) {
        await _retryRevoke(subjectId, record, ownedPending);
        return;
      }
      final snapshot = await ref
          .read(customerDeviceRepositoryProvider)
          .status(record.installationId);
      if (!_isCurrent(subjectId) || generation != _generation) {
        return;
      }
      final localConsent = record.consentFor(subjectId);
      final consent = snapshot?.consentStatus ?? localConsent;
      if (snapshot != null && ownedPending == null) {
        await ref
            .read(customerDeviceLocalStoreProvider)
            .save(
              record.copyWith(
                decisionOwnerSubjectId: subjectId,
                consentStatus: snapshot.consentStatus,
                clearPendingOperation: true,
              ),
            );
      }
      _publish(
        CustomerDeviceState(
          status: CustomerDeviceStatus.ready,
          consentStatus: consent,
          permissionStatus: snapshot?.permissionStatus ?? capability.permission,
          providerAvailability: capability.availability,
          snapshot: snapshot,
          notice: ownedPending == null
              ? null
              : CustomerDeviceNoticeKind.pendingServer,
          serverConfirmed: ownedPending == null,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(subjectId) || generation != _generation) {
        return;
      }
      _publishOperationFailure(error, subjectId);
    }
  }

  Future<void> _register({
    required String subjectId,
    required String locale,
    required CustomerDeviceConsentStatus consent,
    required CustomerDevicePermissionStatus permission,
    required String? token,
    required CustomerDeviceNoticeKind notice,
  }) async {
    final store = ref.read(customerDeviceLocalStoreProvider);
    final record = await store.loadOrCreate();
    final key =
        _matchingPendingKey(
          record,
          subjectId,
          CustomerDevicePendingOperationKind.register,
        ) ??
        ref.read(customerDeviceUuidFactoryProvider)();
    await _registerWithKey(
      subjectId: subjectId,
      record: record,
      locale: locale,
      consent: consent,
      permission: permission,
      token: token,
      key: key,
      notice: notice,
    );
  }

  Future<void> _registerWithKey({
    required String subjectId,
    required CustomerDeviceLocalRecord record,
    required String locale,
    required CustomerDeviceConsentStatus consent,
    required CustomerDevicePermissionStatus permission,
    required String? token,
    required String key,
    required CustomerDeviceNoticeKind notice,
  }) async {
    final store = ref.read(customerDeviceLocalStoreProvider);
    final pending = record.copyWith(
      decisionOwnerSubjectId: subjectId,
      consentStatus: consent,
      pendingOperation: CustomerDevicePendingOperation(
        kind: CustomerDevicePendingOperationKind.register,
        ownerSubjectId: subjectId,
        idempotencyKey: key,
      ),
    );
    await store.save(pending);
    _publishPending(consent: consent, permission: permission);
    if (consent == CustomerDeviceConsentStatus.granted && token == null) {
      _publishOperationFailure(
        const CustomerDeviceRepositoryException(
          CustomerDeviceFailureKind.unavailable,
        ),
        subjectId,
      );
      return;
    }
    try {
      final snapshot = await ref
          .read(customerDeviceRepositoryProvider)
          .register(
            CustomerDeviceRegistrationRequest(
              installationId: record.installationId,
              platform: ref.read(customerPushTokenProvider).platform,
              locale: locale,
              consentStatus: consent,
              permissionStatus: permission,
              pushToken: token,
              idempotencyKey: key,
            ),
          );
      if (!_isCurrent(subjectId)) {
        return;
      }
      await store.save(pending.copyWith(clearPendingOperation: true));
      _publish(
        CustomerDeviceState(
          status: CustomerDeviceStatus.ready,
          consentStatus: snapshot.consentStatus,
          permissionStatus: snapshot.permissionStatus,
          providerAvailability:
              _lastState?.providerAvailability ??
              CustomerPushProviderAvailability.configured,
          snapshot: snapshot,
          notice: notice,
          serverConfirmed: true,
        ),
      );
    } on Object catch (error) {
      _publishOperationFailure(error, subjectId);
    }
  }

  Future<void> _retryRevoke(
    String subjectId,
    CustomerDeviceLocalRecord record,
    CustomerDevicePendingOperation pending,
  ) async {
    _publishPending(
      consent: CustomerDeviceConsentStatus.revoked,
      permission:
          _lastState?.permissionStatus ??
          CustomerDevicePermissionStatus.notDetermined,
    );
    try {
      final snapshot = await ref
          .read(customerDeviceRepositoryProvider)
          .revoke(
            installationId: record.installationId,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrent(subjectId)) {
        return;
      }
      await ref
          .read(customerDeviceLocalStoreProvider)
          .save(
            record.copyWith(
              decisionOwnerSubjectId: subjectId,
              consentStatus: CustomerDeviceConsentStatus.revoked,
              clearPendingOperation: true,
            ),
          );
      _publish(
        CustomerDeviceState(
          status: CustomerDeviceStatus.ready,
          consentStatus: CustomerDeviceConsentStatus.revoked,
          permissionStatus:
              snapshot?.permissionStatus ??
              CustomerDevicePermissionStatus.notDetermined,
          providerAvailability:
              _lastState?.providerAvailability ??
              CustomerPushProviderAvailability.notConfigured,
          snapshot: snapshot,
          notice: CustomerDeviceNoticeKind.revoked,
          serverConfirmed: true,
        ),
      );
    } on Object catch (error) {
      _publishOperationFailure(error, subjectId);
    }
  }

  void _listenForTokenChanges(CustomerPushTokenProvider provider) {
    _tokenSubscription ??= provider.tokenChanges.listen(
      (token) => unawaited(_refreshToken(token)),
      onError: (_, _) {},
    );
  }

  Future<void> _refreshToken(String token) {
    return _serialize(() async {
      final subjectId = _subjectId;
      if (subjectId == null) {
        return;
      }
      final store = ref.read(customerDeviceLocalStoreProvider);
      final record = await store.loadOrCreate();
      if (record.consentFor(subjectId) != CustomerDeviceConsentStatus.granted) {
        return;
      }
      final capability = await ref
          .read(customerPushTokenProvider)
          .currentCapability();
      if (capability.availability !=
              CustomerPushProviderAvailability.configured ||
          (capability.permission != CustomerDevicePermissionStatus.authorized &&
              capability.permission !=
                  CustomerDevicePermissionStatus.provisional)) {
        return;
      }
      await _registerWithKey(
        subjectId: subjectId,
        record: record,
        locale: _lastState?.snapshot?.locale ?? 'es-CL',
        consent: CustomerDeviceConsentStatus.granted,
        permission: capability.permission,
        token: token,
        key: ref.read(customerDeviceUuidFactoryProvider)(),
        notice: CustomerDeviceNoticeKind.enabled,
      );
    });
  }

  void _publishPending({
    required CustomerDeviceConsentStatus consent,
    required CustomerDevicePermissionStatus permission,
  }) {
    _publish(
      (_lastState ?? const CustomerDeviceState.loading()).copyWith(
        status: CustomerDeviceStatus.ready,
        consentStatus: consent,
        permissionStatus: permission,
        notice: CustomerDeviceNoticeKind.pendingServer,
        isMutating: true,
        serverConfirmed: false,
      ),
    );
  }

  void _publishOperationFailure(Object error, String subjectId) {
    if (!_isCurrent(subjectId)) {
      return;
    }
    final failure = switch (error) {
      CustomerDeviceRepositoryException(:final kind) => CustomerDeviceFailure(
        kind,
      ),
      FormatException() => const CustomerDeviceFailure(
        CustomerDeviceFailureKind.invalidInput,
      ),
      _ => const CustomerDeviceFailure(CustomerDeviceFailureKind.unavailable),
    };
    _publish(
      (_lastState ?? const CustomerDeviceState.loading()).copyWith(
        status: failure.kind == CustomerDeviceFailureKind.offline
            ? CustomerDeviceStatus.offline
            : CustomerDeviceStatus.failure,
        failure: failure,
        notice: CustomerDeviceNoticeKind.actionFailed,
        isMutating: false,
        serverConfirmed: false,
      ),
    );
  }

  Future<void> _serialize(Future<void> Function() action) {
    final active = _operation;
    if (active != null) {
      return active;
    }
    Future<void> guardedAction() async {
      try {
        await action();
      } on Object catch (error) {
        final subjectId = _subjectId;
        if (subjectId != null) {
          _publishOperationFailure(error, subjectId);
        }
      }
    }

    late final Future<void> operation;
    operation = guardedAction().whenComplete(() {
      if (identical(_operation, operation)) {
        _operation = null;
      }
    });
    _operation = operation;
    return operation;
  }

  bool _isCurrent(String subjectId) {
    return !_disposed && _subjectId == subjectId;
  }

  void _publish(CustomerDeviceState next) {
    if (_disposed) {
      return;
    }
    _lastState = next;
    state = next;
  }
}

String? _matchingPendingKey(
  CustomerDeviceLocalRecord record,
  String subjectId,
  CustomerDevicePendingOperationKind kind,
) {
  final pending = record.pendingOperation;
  return pending?.ownerSubjectId == subjectId && pending?.kind == kind
      ? pending?.idempotencyKey
      : null;
}
