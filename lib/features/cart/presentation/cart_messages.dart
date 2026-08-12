import '../../../l10n/generated/app_localizations.dart';
import '../application/cart_state.dart';
import '../domain/cart_failure.dart';

String cartFailureMessage(AppLocalizations l10n, CartFailureKind kind) {
  return switch (kind) {
    CartFailureKind.offline => l10n.cartOfflineError,
    CartFailureKind.timeout => l10n.cartTimeoutError,
    CartFailureKind.unauthorized => l10n.cartUnauthorizedError,
    CartFailureKind.invalidInput => l10n.cartInvalidError,
    CartFailureKind.conflict => l10n.cartConflictError,
    CartFailureKind.limitReached => l10n.cartLimitReached,
    CartFailureKind.unavailable => l10n.cartProductUnavailable,
    CartFailureKind.unexpected => l10n.cartUnavailableError,
  };
}

String cartNoticeMessage(AppLocalizations l10n, CartNoticeKind kind) {
  return switch (kind) {
    CartNoticeKind.added => l10n.cartAddedNotice,
    CartNoticeKind.updated => l10n.cartUpdatedNotice,
    CartNoticeKind.removed => l10n.cartRemovedNotice,
    CartNoticeKind.cleared => l10n.cartClearedNotice,
    CartNoticeKind.merged => l10n.cartMergedNotice,
    CartNoticeKind.partialMerge => l10n.cartPartialMergeNotice,
    CartNoticeKind.revalidated => l10n.cartRevalidatedNotice,
    CartNoticeKind.unavailable => l10n.cartProductUnavailable,
    CartNoticeKind.limitReached => l10n.cartLimitReached,
  };
}
