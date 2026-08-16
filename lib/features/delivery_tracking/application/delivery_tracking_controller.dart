import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_delivery_tracking_repository.dart';
import '../domain/delivery_tracking_failure.dart';
import '../domain/delivery_tracking_models.dart';
import 'delivery_tracking_providers.dart';

const _deliveryTrackingUnset = Object();

enum DeliveryTrackingStatus {
  signedOut,
  idle,
  loading,
  ready,
  offline,
  failure,
}

final class DeliveryTrackingViewState {
  const DeliveryTrackingViewState({
    required this.status,
    this.orderId,
    this.snapshot,
    this.failure,
    this.isRefreshing = false,
    this.isPollingFallback = false,
    this.isForeground = true,
  });

  const DeliveryTrackingViewState.signedOut()
    : this(status: DeliveryTrackingStatus.signedOut);

  const DeliveryTrackingViewState.idle()
    : this(status: DeliveryTrackingStatus.idle);

  final DeliveryTrackingStatus status;
  final String? orderId;
  final DeliveryTrackingSnapshot? snapshot;
  final DeliveryTrackingFailureKind? failure;
  final bool isRefreshing;
  final bool isPollingFallback;
  final bool isForeground;

  DeliveryTrackingViewState copyWith({
    DeliveryTrackingStatus? status,
    Object? orderId = _deliveryTrackingUnset,
    Object? snapshot = _deliveryTrackingUnset,
    Object? failure = _deliveryTrackingUnset,
    bool? isRefreshing,
    bool? isPollingFallback,
    bool? isForeground,
  }) {
    return DeliveryTrackingViewState(
      status: status ?? this.status,
      orderId: identical(orderId, _deliveryTrackingUnset)
          ? this.orderId
          : orderId as String?,
      snapshot: identical(snapshot, _deliveryTrackingUnset)
          ? this.snapshot
          : snapshot as DeliveryTrackingSnapshot?,
      failure: identical(failure, _deliveryTrackingUnset)
          ? this.failure
          : failure as DeliveryTrackingFailureKind?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPollingFallback: isPollingFallback ?? this.isPollingFallback,
      isForeground: isForeground ?? this.isForeground,
    );
  }
}

final deliveryTrackingControllerProvider =
    NotifierProvider<DeliveryTrackingController, DeliveryTrackingViewState>(
      DeliveryTrackingController.new,
    );

final class DeliveryTrackingController
    extends Notifier<DeliveryTrackingViewState> {
  StreamSubscription<DeliveryTrackingSnapshot>? _subscription;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _freshnessTimer;
  String? _subjectId;
  String? _shopSlug;
  String? _orderId;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _disposed = false;
  var _foreground = true;
  var _routeVisible = true;
  Future<void> _snapshotCommitTail = Future<void>.value();

  @override
  DeliveryTrackingViewState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      unawaited(_stopRuntime());
    });
    final identity = ref.watch(deliveryTrackingIdentityProvider);
    final shopSlug = ref.watch(deliveryTrackingShopSlugProvider);
    if (identity == null || shopSlug == null) {
      final previousSubject = _subjectId;
      _subjectId = null;
      _shopSlug = null;
      _orderId = null;
      final generation = ++_generation;
      scheduleMicrotask(() async {
        await _stopRuntime();
        if (previousSubject != null) {
          await _clearCacheAfterSnapshots(previousSubject);
        }
        if (!_disposed && generation == _generation) {
          state = const DeliveryTrackingViewState.signedOut();
        }
      });
      return const DeliveryTrackingViewState.signedOut();
    }
    if (_subjectId != identity.subjectId || _shopSlug != shopSlug) {
      final previousSubject = _subjectId;
      _subjectId = identity.subjectId;
      _shopSlug = shopSlug;
      _orderId = null;
      final generation = ++_generation;
      scheduleMicrotask(() async {
        await _stopRuntime();
        if (previousSubject != null && previousSubject != identity.subjectId) {
          await _clearCacheAfterSnapshots(previousSubject);
        }
        if (!_disposed && generation == _generation) {
          state = const DeliveryTrackingViewState.idle();
        }
      });
      return const DeliveryTrackingViewState.idle();
    }
    return stateOrNull ?? const DeliveryTrackingViewState.idle();
  }

  Future<void> open(String orderId, {bool forceRefresh = false}) async {
    final subjectId = _subjectId;
    final shopSlug = _shopSlug;
    if (subjectId == null || shopSlug == null) return;
    final generation = ++_generation;
    _orderId = orderId;
    await _stopRuntime();
    if (!_isCurrent(generation, orderId)) return;
    state = DeliveryTrackingViewState(
      status: DeliveryTrackingStatus.loading,
      orderId: orderId,
      isRefreshing: true,
      isForeground: _foreground,
    );

    if (!forceRefresh) {
      final cached = await ref
          .read(deliveryTrackingCacheProvider)
          .read(
            ownerSubjectId: subjectId,
            shopSlug: shopSlug,
            orderId: orderId,
          );
      if (!_isCurrent(generation, orderId)) return;
      if (cached != null) {
        state = state.copyWith(
          status: DeliveryTrackingStatus.offline,
          snapshot: _freshnessAdjusted(cached),
          isRefreshing: true,
        );
      }
    }
    await _load(generation, orderId);
    if (_isCurrent(generation, orderId) &&
        _runtimeAllowed &&
        state.snapshot?.isTerminal != true) {
      _startRuntime(generation, orderId);
    }
  }

  Future<void> refresh() async {
    final orderId = _orderId;
    if (orderId == null) return;
    state = state.copyWith(isRefreshing: true, failure: null);
    await _load(_generation, orderId);
  }

  Future<void> close({bool clearCache = false}) async {
    final subjectId = _subjectId;
    _generation++;
    _orderId = null;
    await _stopRuntime();
    if (clearCache && subjectId != null) {
      await _clearCacheAfterSnapshots(subjectId);
    }
    if (!_disposed) {
      state = _subjectId == null
          ? const DeliveryTrackingViewState.signedOut()
          : const DeliveryTrackingViewState.idle();
    }
  }

  Future<void> setForeground(bool foreground) async {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (!_disposed) state = state.copyWith(isForeground: foreground);
    final orderId = _orderId;
    if (!foreground || orderId == null) {
      await _stopRuntime();
      return;
    }
    final generation = _generation;
    await _load(generation, orderId);
    if (_isCurrent(generation, orderId) &&
        _runtimeAllowed &&
        state.snapshot?.isTerminal != true) {
      _startRuntime(generation, orderId);
    }
  }

  Future<void> setRouteVisible(bool visible) async {
    if (_routeVisible == visible) return;
    _routeVisible = visible;
    final orderId = _orderId;
    if (!visible || orderId == null) {
      await _stopRuntime();
      return;
    }
    if (!_foreground) return;
    final generation = _generation;
    await _load(generation, orderId);
    if (_isCurrent(generation, orderId) &&
        _runtimeAllowed &&
        state.snapshot?.isTerminal != true) {
      _startRuntime(generation, orderId);
    }
  }

  Future<void> _load(int generation, String orderId) async {
    _expireCurrentFreshness();
    final subjectId = _subjectId;
    final shopSlug = _shopSlug;
    if (subjectId == null || shopSlug == null) return;
    try {
      final snapshot = await ref
          .read(deliveryTrackingRepositoryProvider)
          .load(shopSlug: shopSlug, orderId: orderId);
      if (!_isCurrent(generation, orderId)) return;
      if (snapshot.orderId != orderId) {
        throw const DeliveryTrackingRepositoryException(
          DeliveryTrackingFailureKind.invalid,
        );
      }
      await _commitSnapshot(
        generation,
        orderId,
        snapshot,
        subjectId: subjectId,
        shopSlug: shopSlug,
      );
    } on Object catch (error) {
      if (!_isCurrent(generation, orderId)) return;
      final failure = _failure(error);
      if (failure == DeliveryTrackingFailureKind.unauthorized) {
        _generation++;
        _orderId = null;
        await _stopRuntime();
        await _clearCacheAfterSnapshots(subjectId);
        if (!_disposed && _subjectId == subjectId && _shopSlug == shopSlug) {
          state = DeliveryTrackingViewState(
            status: DeliveryTrackingStatus.failure,
            failure: DeliveryTrackingFailureKind.unauthorized,
            isForeground: _foreground,
          );
        }
        return;
      }
      final hasSnapshot = state.snapshot != null;
      state = state.copyWith(
        status:
            hasSnapshot &&
                (failure == DeliveryTrackingFailureKind.offline ||
                    failure == DeliveryTrackingFailureKind.timeout)
            ? DeliveryTrackingStatus.offline
            : DeliveryTrackingStatus.failure,
        failure: failure,
        isRefreshing: false,
        isPollingFallback: state.isPollingFallback,
      );
    }
  }

  void _startRuntime(int generation, String orderId) {
    if (!_isCurrent(generation, orderId) || !_runtimeAllowed) return;
    _subscribe(generation, orderId);
    if (state.failure == DeliveryTrackingFailureKind.offline ||
        state.failure == DeliveryTrackingFailureKind.timeout ||
        state.failure == DeliveryTrackingFailureKind.unavailable) {
      _startPollingFallback(generation, orderId);
    }
  }

  void _subscribe(int generation, String orderId) {
    unawaited(_subscription?.cancel());
    _subscription = ref
        .read(deliveryTrackingRepositoryProvider)
        .watch(orderId: orderId)
        .listen(
          (snapshot) async {
            if (!_isCurrent(generation, orderId)) return;
            if (snapshot.orderId != orderId) return;
            _markRealtimeHealthy();
            final subjectId = _subjectId;
            final shopSlug = _shopSlug;
            if (subjectId == null || shopSlug == null) return;
            await _commitSnapshot(
              generation,
              orderId,
              snapshot,
              subjectId: subjectId,
              shopSlug: shopSlug,
              realtimeHealthy: true,
            );
          },
          onError: (Object _) {
            if (!_isCurrent(generation, orderId)) return;
            _startPollingFallback(generation, orderId);
            _scheduleReconnect(generation, orderId);
          },
          onDone: () {
            if (!_isCurrent(generation, orderId)) return;
            _startPollingFallback(generation, orderId);
            _scheduleReconnect(generation, orderId);
          },
        );
  }

  void _startPollingFallback(int generation, String orderId) {
    if (!_isCurrent(generation, orderId) || !_runtimeAllowed) return;
    if (!state.isPollingFallback) {
      state = state.copyWith(isPollingFallback: true);
    }
    if (_pollTimer != null) return;
    unawaited(_load(generation, orderId));
    _pollTimer = Timer.periodic(
      ref.read(deliveryTrackingPollIntervalProvider),
      (_) => unawaited(_load(generation, orderId)),
    );
  }

  void _markRealtimeHealthy() {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (state.isPollingFallback) {
      state = state.copyWith(isPollingFallback: false);
    }
  }

  void _scheduleReconnect(int generation, String orderId) {
    _reconnectTimer?.cancel();
    final base = ref.read(deliveryTrackingReconnectBaseProvider);
    final exponent = _reconnectAttempt.clamp(0, 4);
    final factor = 1 << exponent;
    _reconnectAttempt++;
    final milliseconds = (base.inMilliseconds * factor).clamp(1, 30000);
    _reconnectTimer = Timer(Duration(milliseconds: milliseconds), () {
      if (_isCurrent(generation, orderId) && _runtimeAllowed) {
        _subscribe(generation, orderId);
      }
    });
  }

  Future<void> _accept(
    DeliveryTrackingSnapshot snapshot, {
    required String subjectId,
    required String shopSlug,
  }) async {
    try {
      await ref
          .read(deliveryTrackingCacheProvider)
          .save(
            ownerSubjectId: subjectId,
            shopSlug: shopSlug,
            snapshot: snapshot,
          );
    } on Object {
      // Il cache failure non deve interrompere lo snapshot server-authoritative.
    }
  }

  Future<bool> _commitSnapshot(
    int generation,
    String orderId,
    DeliveryTrackingSnapshot snapshot, {
    required String subjectId,
    required String shopSlug,
    bool realtimeHealthy = false,
  }) async {
    final previous = _snapshotCommitTail;
    final turn = Completer<void>();
    _snapshotCommitTail = turn.future;
    await previous;
    try {
      if (!_isCurrent(generation, orderId)) return false;
      final current = state.snapshot;
      if (current != null &&
          !isNewerDeliveryTrackingSnapshot(current, snapshot)) {
        state = state.copyWith(
          isRefreshing: false,
          failure: null,
          isPollingFallback: realtimeHealthy ? false : state.isPollingFallback,
        );
        return false;
      }
      await _accept(snapshot, subjectId: subjectId, shopSlug: shopSlug);
      if (!_isCurrent(generation, orderId)) return false;
      state = state.copyWith(
        status: DeliveryTrackingStatus.ready,
        snapshot: _freshnessAdjusted(snapshot),
        failure: null,
        isRefreshing: false,
        isPollingFallback: realtimeHealthy ? false : state.isPollingFallback,
      );
      _scheduleFreshnessExpiry(generation, orderId, state.snapshot!);
      if (snapshot.isTerminal) await _stopRuntime();
      return true;
    } finally {
      turn.complete();
    }
  }

  Future<void> _clearCacheAfterSnapshots(String subjectId) async {
    final previous = _snapshotCommitTail;
    final turn = Completer<void>();
    _snapshotCommitTail = turn.future;
    await previous;
    try {
      await ref
          .read(deliveryTrackingCacheProvider)
          .clear(ownerSubjectId: subjectId);
    } finally {
      turn.complete();
    }
  }

  DeliveryTrackingSnapshot _freshnessAdjusted(
    DeliveryTrackingSnapshot snapshot,
  ) {
    final receivedAt = snapshot.receivedAt;
    if (snapshot.freshness == DeliveryTrackingFreshness.fresh &&
        receivedAt != null &&
        ref.read(deliveryTrackingClockProvider)().difference(receivedAt) >
            ref.read(deliveryTrackingFreshnessThresholdProvider)) {
      return snapshot.copyWith(freshness: DeliveryTrackingFreshness.stale);
    }
    return snapshot;
  }

  void _expireCurrentFreshness() {
    final current = state.snapshot;
    if (current == null) return;
    final adjusted = _freshnessAdjusted(current);
    if (adjusted.freshness != current.freshness) {
      state = state.copyWith(snapshot: adjusted);
    }
  }

  void _scheduleFreshnessExpiry(
    int generation,
    String orderId,
    DeliveryTrackingSnapshot snapshot,
  ) {
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    final receivedAt = snapshot.receivedAt;
    if (snapshot.freshness != DeliveryTrackingFreshness.fresh ||
        receivedAt == null) {
      return;
    }
    final deadline = receivedAt.add(
      ref.read(deliveryTrackingFreshnessThresholdProvider),
    );
    final delay = deadline.difference(
      ref.read(deliveryTrackingClockProvider)(),
    );
    if (delay <= Duration.zero) {
      _expireCurrentFreshness();
      return;
    }
    _freshnessTimer = Timer(delay, () {
      if (!_isCurrent(generation, orderId)) return;
      _expireCurrentFreshness();
    });
  }

  Future<void> _stopRuntime() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) await subscription.cancel();
  }

  bool _isCurrent(int generation, String orderId) =>
      !_disposed &&
      generation == _generation &&
      orderId == _orderId &&
      _subjectId != null &&
      _shopSlug != null;

  bool get _runtimeAllowed => _foreground && _routeVisible;

  DeliveryTrackingFailureKind _failure(Object error) => switch (error) {
    DeliveryTrackingRepositoryException(:final kind) => kind,
    DeliveryTrackingRealtimeException() =>
      DeliveryTrackingFailureKind.unavailable,
    _ => DeliveryTrackingFailureKind.unexpected,
  };
}
