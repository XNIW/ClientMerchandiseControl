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
    return _runExclusive((context) async {
      if (quantity < 1 || quantity > reservationHoldMaximumQuantity) {
        _setFailure(ReservationHoldFailureKind.invalidInput);
        return;
      }
      final store = ref.read(reservationHoldLocalStoreProvider);
      final existing = await store.readEntry(
        ownerSubjectId: context.ownerSubjectId,
        shopSlug: context.shopSlug,
        publicationId: arg,
      );
      if (!_isCurrentContext(context)) return;
      if (existing?.hold?.isActive == true &&
          existing!.quantity == quantity &&
          existing.pendingOperation == null) {
        await _syncHold(existing, context);
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
        if (!_isCurrentContext(context)) return;
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
      if (!_isCurrentContext(context)) return;
      await _executeCreate(pending, context);
    });
  }

  Future<void> retry() {
    return _runExclusive((context) async {
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (!_isCurrentContext(context)) return;
      if (entry == null) {
        _setIdle();
        return;
      }
      final pending = entry.pendingOperation;
      if (pending?.kind == ReservationHoldPendingOperationKind.create) {
        await _executeCreate(entry, context);
      } else if (pending?.kind == ReservationHoldPendingOperationKind.release) {
        await _executeRelease(entry, context);
      } else if (entry.hold != null) {
        await _syncHold(entry, context);
      } else {
        await _removeEntry(entry);
        _setIdle();
      }
    });
  }

  Future<void> release() {
    return _runExclusive((context) async {
      final store = ref.read(reservationHoldLocalStoreProvider);
      final entry = await store.readEntry(
        ownerSubjectId: context.ownerSubjectId,
        shopSlug: context.shopSlug,
        publicationId: arg,
      );
      if (!_isCurrentContext(context)) return;
      final hold = entry?.hold;
      if (entry == null || hold == null || hold.isTerminal) {
        if (hold != null) _applyHold(hold, context);
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
      if (!_isCurrentContext(context)) return;
      await _executeRelease(pending, context);
    });
  }

  Future<void> dismissTerminal() {
    return _runExclusive((context) async {
      await ref
          .read(reservationHoldLocalStoreProvider)
          .removeEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (!_isCurrentContext(context)) return;
      _setIdle();
    });
  }

  Future<void> _load(int generation) async {
    final context = _requireContextOrNull();
    if (context == null || context.generation != generation) return;
    try {
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (!_isCurrentContext(context)) return;
      if (entry == null) {
        _setIdle();
        return;
      }
      final pending = entry.pendingOperation;
      if (pending?.kind == ReservationHoldPendingOperationKind.create) {
        await _executeCreate(entry, context);
      } else if (pending?.kind == ReservationHoldPendingOperationKind.release) {
        await _executeRelease(entry, context);
      } else if (entry.hold != null) {
        await _syncHold(entry, context);
      } else {
        await _removeEntry(entry);
        if (!_isCurrentContext(context)) return;
        _setIdle();
      }
    } on ReservationHoldRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(error.kind, hasPendingRetry: true);
    } on Object {
      if (!_isCurrentContext(context)) return;
      _setFailure(ReservationHoldFailureKind.unexpected, hasPendingRetry: true);
    }
  }

  Future<void> _executeCreate(
    ReservationHoldLocalEntry entry,
    _ReservationContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
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
      if (!_isCurrentContext(context)) return;
      final hold = response.hold;
      if (hold == null) {
        await _removeEntry(entry);
        if (!_isCurrentContext(context)) return;
        _setFailure(_failureForStatus(response.status));
        return;
      }
      final resolved = _entryForHold(entry, hold, context);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      if (!_isCurrentContext(context)) return;
      await _syncHold(resolved, context);
    } on ReservationHoldRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(error.kind, hold: entry.hold, hasPendingRetry: true);
    } on Object {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        ReservationHoldFailureKind.unexpected,
        hold: entry.hold,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _syncHold(
    ReservationHoldLocalEntry entry,
    _ReservationContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
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
      if (!_isCurrentContext(context)) return;
      final refreshed = response.hold;
      if (refreshed == null) {
        if (response.status == ReservationHoldRemoteStatus.notFound) {
          await _removeEntry(entry);
        }
        if (!_isCurrentContext(context)) return;
        _setFailure(_failureForStatus(response.status));
        return;
      }
      final resolved = _entryForHold(entry, refreshed, context);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      if (!_isCurrentContext(context)) return;
      _applyHold(refreshed, context);
    } on ReservationHoldRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(error.kind, hold: hold, hasPendingRetry: true);
    } on Object {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        ReservationHoldFailureKind.unexpected,
        hold: hold,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _executeRelease(
    ReservationHoldLocalEntry entry,
    _ReservationContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
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
      if (!_isCurrentContext(context)) return;
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
        if (!_isCurrentContext(context)) return;
        _setFailure(_failureForStatus(response.status), hold: hold);
        return;
      }
      final resolved = _entryForHold(entry, resolvedHold, context);
      await ref.read(reservationHoldLocalStoreProvider).saveEntry(resolved);
      if (!_isCurrentContext(context)) return;
      _applyHold(resolvedHold, context);
    } on ReservationHoldRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(error.kind, hold: hold, hasPendingRetry: true);
    } on Object {
      if (!_isCurrentContext(context)) return;
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
    _ReservationContext context,
  ) {
    if (!_isCurrentContext(context) ||
        source.ownerSubjectId != context.ownerSubjectId ||
        source.shopSlug != context.shopSlug ||
        source.publicationId != arg ||
        hold.shopSlug != context.shopSlug ||
        hold.publicationId != arg) {
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

  void _applyHold(ReservationHoldSnapshot hold, _ReservationContext context) {
    if (!_isCurrentContext(context)) return;
    _timer?.cancel();
    _serverElapsed?.stop();
    if (hold.status == ReservationHoldServerStatus.active) {
      _serverRemainingSeconds = hold.remainingSeconds;
      _serverElapsed = Stopwatch()..start();
      _publishCountdown(hold);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_isCurrentContext(context)) return;
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
    await _runExclusive((context) async {
      final entry = await ref
          .read(reservationHoldLocalStoreProvider)
          .readEntry(
            ownerSubjectId: context.ownerSubjectId,
            shopSlug: context.shopSlug,
            publicationId: arg,
          );
      if (!_isCurrentContext(context)) return;
      if (entry?.hold?.holdId == hold.holdId) {
        await _syncHold(entry!, context);
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

  Future<void> _runExclusive(
    Future<void> Function(_ReservationContext context) action,
  ) {
    final active = _operation;
    if (active != null) return active;
    final context = _requireContextOrNull();
    if (context == null) return Future<void>.value();
    late final Future<void> operation;
    operation =
        (() async {
          try {
            if (_isCurrentContext(context)) await action(context);
          } on ReservationHoldRepositoryException catch (error) {
            if (_isCurrentContext(context)) _setFailure(error.kind);
          } on Object {
            if (_isCurrentContext(context)) {
              _setFailure(ReservationHoldFailureKind.unexpected);
            }
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

  _ReservationContext? _requireContextOrNull() {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return null;
    return _ReservationContext(
      ownerSubjectId: owner,
      shopSlug: shop,
      generation: _generation,
    );
  }

  DateTime _clock() => ref.read(reservationHoldClockProvider)().toUtc();

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  bool _isCurrentContext(_ReservationContext context) {
    return _isCurrent(context.generation) &&
        _ownerSubjectId == context.ownerSubjectId &&
        _shopSlug == context.shopSlug;
  }

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
    required this.generation,
  });

  final String ownerSubjectId;
  final String shopSlug;
  final int generation;
}
