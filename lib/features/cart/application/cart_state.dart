import '../domain/cart_failure.dart';
import '../domain/cart_models.dart';

enum CartViewStatus { loading, ready, failure }

enum CartNoticeKind {
  added,
  updated,
  removed,
  cleared,
  merged,
  partialMerge,
  revalidated,
  unavailable,
  limitReached,
}

final class CartState {
  CartState({
    required this.status,
    required this.isAuthenticated,
    this.snapshot,
    this.failureKind,
    this.notice,
    this.isGlobalBusy = false,
    Set<String> busyPublicationIds = const {},
    this.hasPendingRetry = false,
  }) : busyPublicationIds = Set.unmodifiable(busyPublicationIds);

  factory CartState.loading({
    required bool isAuthenticated,
    CustomerCartSnapshot? previous,
  }) {
    return CartState(
      status: CartViewStatus.loading,
      isAuthenticated: isAuthenticated,
      snapshot: previous,
    );
  }

  factory CartState.failure({
    required bool isAuthenticated,
    required CartFailureKind failureKind,
    CustomerCartSnapshot? previous,
    bool hasPendingRetry = false,
  }) {
    return CartState(
      status: CartViewStatus.failure,
      isAuthenticated: isAuthenticated,
      snapshot: previous,
      failureKind: failureKind,
      hasPendingRetry: hasPendingRetry,
    );
  }

  final CartViewStatus status;
  final bool isAuthenticated;
  final CustomerCartSnapshot? snapshot;
  final CartFailureKind? failureKind;
  final CartNoticeKind? notice;
  final bool isGlobalBusy;
  final Set<String> busyPublicationIds;
  final bool hasPendingRetry;

  bool get hasData => snapshot != null;
  bool get isBusy => isGlobalBusy || busyPublicationIds.isNotEmpty;

  CartState copyWith({
    CartViewStatus? status,
    CustomerCartSnapshot? snapshot,
    bool preserveSnapshot = true,
    CartFailureKind? failureKind,
    bool clearFailure = false,
    CartNoticeKind? notice,
    bool clearNotice = false,
    bool? isGlobalBusy,
    Set<String>? busyPublicationIds,
    bool? hasPendingRetry,
  }) {
    return CartState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated,
      snapshot: snapshot ?? (preserveSnapshot ? this.snapshot : null),
      failureKind: clearFailure ? null : failureKind ?? this.failureKind,
      notice: clearNotice ? null : notice ?? this.notice,
      isGlobalBusy: isGlobalBusy ?? this.isGlobalBusy,
      busyPublicationIds: busyPublicationIds ?? this.busyPublicationIds,
      hasPendingRetry: hasPendingRetry ?? this.hasPendingRetry,
    );
  }
}
