import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../domain/reservation_hold_failure.dart';
import '../domain/reservation_hold_models.dart';
import 'reservation_hold_providers.dart';

enum ReservationHoldViewStatus {
  idle,
  loading,
  active,
  expiring,
  expired,
  released,
  consumed,
  error,
}

final class ReservationHoldState {
  const ReservationHoldState({
    required this.status,
    required this.isAuthenticated,
    this.hold,
    this.failureKind,
    this.remainingSeconds = 0,
    this.hasPendingRetry = false,
  });

  const ReservationHoldState.idle({required bool isAuthenticated})
    : this(
        status: ReservationHoldViewStatus.idle,
        isAuthenticated: isAuthenticated,
      );

  final ReservationHoldViewStatus status;
  final bool isAuthenticated;
  final ReservationHoldSnapshot? hold;
  final ReservationHoldFailureKind? failureKind;
  final int remainingSeconds;
  final bool hasPendingRetry;

  bool get isBusy => status == ReservationHoldViewStatus.loading;
  bool get isActive =>
      status == ReservationHoldViewStatus.active ||
      status == ReservationHoldViewStatus.expiring;
}

final reservationHoldControllerProvider = NotifierProvider.autoDispose
    .family<ReservationHoldController, ReservationHoldState, String>(
      ReservationHoldController.new,
    );

final class ReservationHoldController
    extends AutoDisposeFamilyNotifier<ReservationHoldState, String> {
  Timer? _timer;
  Stopwatch? _serverElapsed;
  int _serverRemainingSeconds = 0;
  String? _ownerSubjectId;
  String? _shopSlug;
  var _disposed = false;
  var _generation = 0;
  Future<void>? _operation;

  @override
  ReservationHoldState build(String publicationId) {
    _disposed = false;
    ref.onDispose(_dispose);
    _timer?.cancel();
    _serverElapsed?.stop();
    _ownerSubjectId = null;
    _shopSlug = null;
    final identity = ref.watch(customerAccountIdentityProvider);
    final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
    if (identity == null) {
      return const ReservationHoldState.idle(isAuthenticated: false);
    }
    if (!isReservationHoldUuid(publicationId) ||
        shopSlug == null ||
        !isReservationHoldShopSlug(shopSlug) ||
        !isReservationHoldUuid(identity.subjectId)) {
      return const ReservationHoldState(
        status: ReservationHoldViewStatus.error,
        isAuthenticated: true,
        failureKind: ReservationHoldFailureKind.invalidInput,
      );
    }
    _ownerSubjectId = identity.subjectId;
    _shopSlug = shopSlug;
    final generation = ++_generation;
    scheduleMicrotask(() => _load(generation));
    return const ReservationHoldState(
      status: ReservationHoldViewStatus.loading,
      isAuthenticated: true,
    );
  }

  Future<void> reserve({required int quantity}) {
    return _runExclusive(() async {
      if (quantity < 1 || quantity > reservationHoldMaximumQuantity) {
        _setFailure(ReservationHoldFailureKind.invalidInput);
        return;
      }
      final context = _requireContext();
      final store = ref.read(reservationHoldLocalStoreProvider);
      final existing = await store.readEntry(
        ownerSubjectId: context.ownerSubjectId,
        shopSlug: context.shopSlug,
        publicationId: arg,
      );
      if (existing?.hold?.isActive == true &&
          existing!.quantity == quantity &&
          existing.pendingOperation == null) {
        await _syncHold(existing);
        return;
      }
      if (existing != null) {
        await ref
            .read(reservationHoldCoordinatorProvider)
            .prepareForCartMutation(
              ownerSubjectId: context.ownerSubjectId,
              shopSlug: context.shopSlug,
              publicationId: arg,
            );
      }
      final pending = ReservationHoldLocalEntry(
        ownerSubjectId: context.ownerSubjectId,
        shopSlug: context.shopSlug,
        publicationId: arg,
        quantity: quantity,
        pendingOperation: ReservationHoldPendingOperation(
          kind: ReservationHoldPendingOperationKind.create,
          idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
        ),
        updatedAt: _clock(),
      );
      await store.saveEntry(pending);
      await _executeCreate(pending);
    });
  }

  Future<void> retry() {
    return _runExclusive(() async {
      final context = _requireContext();
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (entry == null) {
        _setIdle();
        return;
      }
      final pending = entry.pendingOperation;
      if (pending?.kind == ReservationHoldPendingOperationKind.create) {
        await _executeCreate(entry);
      } else if (pending?.kind == ReservationHoldPendingOperationKind.release) {
        await _executeRelease(entry);
      } else if (entry.hold != null) {
        await _syncHold(entry);
      } else {
        await _removeEntry(entry);
        _setIdle();
      }
    });
  }

  Future<void> release() {
    return _runExclusive(() async {
      final context = _requireContext();
      final store = ref.read(reservationHoldLocalStoreProvider);
      final entry = await store.readEntry(
        ownerSubjectId: context.ownerSubjectId,
        shopSlug: context.shopSlug,
        publicationId: arg,
      );
      final hold = entry?.hold;
      if (entry == null || hold == null || hold.isTerminal) {
        if (hold != null) _applyHold(hold);
        return;
      }
      final pending = entry.copyWith(
        pendingOperation: ReservationHoldPendingOperation(
          kind: ReservationHoldPendingOperationKind.release,
          idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
        ),
        updatedAt: _clock(),
      );
      await store.saveEntry(pending);
      await _executeRelease(pending);
    });
  }

  Future<void> dismissTerminal() {
    return _runExclusive(() async {
      final context = _requireContext();
      await ref
          .read(reservationHoldLocalStoreProvider)
          .removeEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      _setIdle();
    });
  }

  Future<void> _load(int generation) async {
    try {
      final context = _requireContext();
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (!_isCurrent(generation)) return;
      if (entry == null) {
        _setIdle();
        return;
      }
      final pending = entry.pendingOperation;
      if (pending?.kind == ReservationHoldPendingOperationKind.create) {
        await _executeCreate(entry);
      } else if (pending?.kind == ReservationHoldPendingOperationKind.release) {
        await _executeRelease(entry);
      } else if (entry.hold != null) {
        await _syncHold(entry);
      } else {
        await _removeEntry(entry);
        _setIdle();
      }
    } on ReservationHoldRepositoryException catch (error) {
      _setFailure(error.kind, hasPendingRetry: true);
    } on Object {
      _setFailure(ReservationHoldFailureKind.unexpected, hasPendingRetry: true);
    }
  }

  Future<void> _executeCreate(ReservationHoldLocalEntry entry) async {
    final pending = entry.pendingOperation;
    if (pending?.kind != ReservationHoldPendingOperationKind.create) {
      _setFailure(ReservationHoldFailureKind.unexpected);
      return;
    }
    _setLoading(entry.hold);
    try {
      final response = await ref
          .read(reservationHoldRepositoryProvider)
          .create(
            shopSlug: entry.shopSlug,
            publicationId: entry.publicationId,
            quantity: entry.quantity,
            idempotencyKey: pending!.idempotencyKey,
          );
      final hold = response.hold;
      if (hold == null) {
        await _removeEntry(entry);
        _setFailure(_failureForStatus(response.status));
        return;
      }
      final resolved = _entryForHold(entry, hold);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      await _syncHold(resolved);
    } on ReservationHoldRepositoryException catch (error) {
      _setFailure(error.kind, hold: entry.hold, hasPendingRetry: true);
    } on Object {
      _setFailure(
        ReservationHoldFailureKind.unexpected,
        hold: entry.hold,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _syncHold(ReservationHoldLocalEntry entry) async {
    final hold = entry.hold;
    if (hold == null) {
      _setFailure(ReservationHoldFailureKind.unexpected);
      return;
    }
    _setLoading(hold);
    try {
      final response = await ref
          .read(reservationHoldRepositoryProvider)
          .read(holdId: hold.holdId);
      final refreshed = response.hold;
      if (refreshed == null) {
        if (response.status == ReservationHoldRemoteStatus.notFound) {
          await _removeEntry(entry);
        }
        _setFailure(_failureForStatus(response.status));
        return;
      }
      final resolved = _entryForHold(entry, refreshed);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      _applyHold(refreshed);
    } on ReservationHoldRepositoryException catch (error) {
      _setFailure(error.kind, hold: hold, hasPendingRetry: true);
    } on Object {
      _setFailure(
        ReservationHoldFailureKind.unexpected,
        hold: hold,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _executeRelease(ReservationHoldLocalEntry entry) async {
    final hold = entry.hold;
    final pending = entry.pendingOperation;
    if (hold == null ||
        pending?.kind != ReservationHoldPendingOperationKind.release) {
      _setFailure(ReservationHoldFailureKind.unexpected);
      return;
    }
    _setLoading(hold);
    try {
      final response = await ref
          .read(reservationHoldRepositoryProvider)
          .release(
            holdId: hold.holdId,
            idempotencyKey: pending!.idempotencyKey,
          );
      final resolvedHold = response.hold;
      if (resolvedHold == null) {
        if (response.status == ReservationHoldRemoteStatus.notFound) {
          await _removeEntry(entry);
        } else {
          await ref
              .read(reservationHoldLocalStoreProvider)
              .saveEntry(
                entry.copyWith(
                  clearPendingOperation: true,
                  updatedAt: _clock(),
                ),
              );
        }
        _setFailure(_failureForStatus(response.status), hold: hold);
        return;
      }
      final resolved = _entryForHold(entry, resolvedHold);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      _applyHold(resolvedHold);
    } on ReservationHoldRepositoryException catch (error) {
      _setFailure(error.kind, hold: hold, hasPendingRetry: true);
    } on Object {
      _setFailure(
        ReservationHoldFailureKind.unexpected,
        hold: hold,
        hasPendingRetry: true,
      );
    }
  }

  ReservationHoldLocalEntry _entryForHold(
    ReservationHoldLocalEntry source,
    ReservationHoldSnapshot hold,
  ) {
    final context = _requireContext();
    if (hold.shopSlug != context.shopSlug || hold.publicationId != arg) {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.unexpected,
      );
    }
    return ReservationHoldLocalEntry(
      ownerSubjectId: context.ownerSubjectId,
      shopSlug: context.shopSlug,
      publicationId: arg,
      quantity: hold.quantity,
      hold: hold,
      updatedAt: _clock(),
    );
  }

  void _applyHold(ReservationHoldSnapshot hold) {
    if (_disposed) return;
    _timer?.cancel();
    _serverElapsed?.stop();
    if (hold.status == ReservationHoldServerStatus.active) {
      _serverRemainingSeconds = hold.remainingSeconds;
      _serverElapsed = Stopwatch()..start();
      _publishCountdown(hold);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_disposed) return;
        _publishCountdown(hold);
      });
      return;
    }
    _serverRemainingSeconds = 0;
    _serverElapsed = null;
    state = ReservationHoldState(
      status: switch (hold.status) {
        ReservationHoldServerStatus.expired =>
          ReservationHoldViewStatus.expired,
        ReservationHoldServerStatus.consumed =>
          ReservationHoldViewStatus.consumed,
        ReservationHoldServerStatus.released =>
          ReservationHoldViewStatus.released,
        ReservationHoldServerStatus.active => throw StateError(
          'active hold reached terminal mapping',
        ),
      },
      isAuthenticated: true,
      hold: hold,
    );
  }

  void _publishCountdown(ReservationHoldSnapshot hold) {
    if (_disposed) return;
    final elapsed = _serverElapsed?.elapsed.inSeconds ?? 0;
    final remaining = (_serverRemainingSeconds - elapsed).clamp(0, 900);
    if (remaining == 0) {
      _timer?.cancel();
      state = ReservationHoldState(
        status: ReservationHoldViewStatus.expired,
        isAuthenticated: true,
        hold: hold,
      );
      unawaited(_syncAfterLocalExpiry(hold));
      return;
    }
    state = ReservationHoldState(
      status: remaining <= 60
          ? ReservationHoldViewStatus.expiring
          : ReservationHoldViewStatus.active,
      isAuthenticated: true,
      hold: hold,
      remainingSeconds: remaining,
    );
  }

  Future<void> _syncAfterLocalExpiry(ReservationHoldSnapshot hold) async {
    final active = _operation;
    if (active != null) {
      await active;
    }
    if (_disposed) return;
    await _runExclusive(() async {
      final context = _requireContextOrNull();
      if (context == null) return;
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (entry?.hold?.holdId == hold.holdId) {
        await _syncHold(entry!);
      }
    });
  }

  Future<void> _removeEntry(ReservationHoldLocalEntry entry) {
    return ref
        .read(reservationHoldLocalStoreProvider)
        .removeEntry(
          ownerSubjectId: entry.ownerSubjectId,
          shopSlug: entry.shopSlug,
          publicationId: entry.publicationId,
        );
  }

  ReservationHoldFailureKind _failureForStatus(
    ReservationHoldRemoteStatus status,
  ) => switch (status) {
    ReservationHoldRemoteStatus.unavailable =>
      ReservationHoldFailureKind.unavailable,
    ReservationHoldRemoteStatus.holdLimitReached =>
      ReservationHoldFailureKind.limitReached,
    ReservationHoldRemoteStatus.idempotencyConflict =>
      ReservationHoldFailureKind.conflict,
    ReservationHoldRemoteStatus.invalid =>
      ReservationHoldFailureKind.invalidInput,
    ReservationHoldRemoteStatus.notFound => ReservationHoldFailureKind.notFound,
    _ => ReservationHoldFailureKind.unexpected,
  };

  Future<void> _runExclusive(Future<void> Function() action) {
    final active = _operation;
    if (active != null) return active;
    late final Future<void> operation;
    operation =
        (() async {
          try {
            await action();
          } on ReservationHoldRepositoryException catch (error) {
            _setFailure(error.kind);
          } on Object {
            _setFailure(ReservationHoldFailureKind.unexpected);
          }
        })().whenComplete(() {
          if (identical(_operation, operation)) _operation = null;
        });
    _operation = operation;
    return operation;
  }

  void _setLoading(ReservationHoldSnapshot? hold) {
    if (_disposed) return;
    _timer?.cancel();
    state = ReservationHoldState(
      status: ReservationHoldViewStatus.loading,
      isAuthenticated: true,
      hold: hold,
    );
  }

  void _setFailure(
    ReservationHoldFailureKind kind, {
    ReservationHoldSnapshot? hold,
    bool hasPendingRetry = false,
  }) {
    if (_disposed) return;
    _timer?.cancel();
    state = ReservationHoldState(
      status: ReservationHoldViewStatus.error,
      isAuthenticated: _ownerSubjectId != null,
      hold: hold,
      failureKind: kind,
      hasPendingRetry: hasPendingRetry,
    );
  }

  void _setIdle() {
    if (_disposed) return;
    _timer?.cancel();
    state = ReservationHoldState.idle(isAuthenticated: _ownerSubjectId != null);
  }

  _ReservationContext _requireContext() {
    final context = _requireContextOrNull();
    if (context == null) {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.unauthorized,
      );
    }
    return context;
  }

  _ReservationContext? _requireContextOrNull() {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return null;
    return _ReservationContext(ownerSubjectId: owner, shopSlug: shop);
  }

  DateTime _clock() => ref.read(reservationHoldClockProvider)().toUtc();

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _serverElapsed?.stop();
  }
}

final class _ReservationContext {
  const _ReservationContext({
    required this.ownerSubjectId,
    required this.shopSlug,
  });

  final String ownerSubjectId;
  final String shopSlug;
}
