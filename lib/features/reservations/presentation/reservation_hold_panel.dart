import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/reservation_hold_controller.dart';
import '../domain/reservation_hold_failure.dart';

class ReservationHoldPanel extends ConsumerWidget {
  const ReservationHoldPanel({
    required this.publicationId,
    required this.quantity,
    required this.canCreate,
    this.compact = false,
    super.key,
  });

  final String publicationId;
  final int quantity;
  final bool canCreate;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationHoldControllerProvider(publicationId));
    final notifier = ref.read(
      reservationHoldControllerProvider(publicationId).notifier,
    );
    final l10n = AppLocalizations.of(context);

    if (!canCreate &&
        state.hold == null &&
        !state.hasPendingRetry &&
        (state.status == ReservationHoldViewStatus.idle ||
            state.status == ReservationHoldViewStatus.loading ||
            state.status == ReservationHoldViewStatus.error)) {
      return const SizedBox.shrink();
    }

    final content = switch (state.status) {
      ReservationHoldViewStatus.idle =>
        state.isAuthenticated
            ? _ReservationAction(
                key: const ValueKey('reservation-hold-create'),
                label: l10n.reservationHoldCreateAction(quantity),
                icon: Icons.timer_outlined,
                onPressed: canCreate
                    ? () => unawaited(notifier.reserve(quantity: quantity))
                    : null,
              )
            : _ReservationAction(
                key: const ValueKey('reservation-hold-sign-in'),
                label: l10n.reservationHoldSignInAction,
                icon: Icons.login,
                onPressed: canCreate
                    ? () => context.go(AppRoutes.accountLocation)
                    : null,
              ),
      ReservationHoldViewStatus.loading => _ReservationMessage(
        key: const ValueKey('reservation-hold-loading'),
        icon: Icons.sync,
        message: l10n.reservationHoldLoading,
        progress: true,
      ),
      ReservationHoldViewStatus.active ||
      ReservationHoldViewStatus.expiring => _ReservationActive(
        state: state,
        onRelease: () => unawaited(notifier.release()),
      ),
      ReservationHoldViewStatus.expired => _ReservationTerminal(
        key: const ValueKey('reservation-hold-expired'),
        icon: Icons.timer_off_outlined,
        message: l10n.reservationHoldExpired,
        onDismiss: notifier.dismissTerminal,
      ),
      ReservationHoldViewStatus.released => _ReservationTerminal(
        key: const ValueKey('reservation-hold-released'),
        icon: Icons.event_available_outlined,
        message: l10n.reservationHoldReleased,
        onDismiss: notifier.dismissTerminal,
      ),
      ReservationHoldViewStatus.consumed => _ReservationTerminal(
        key: const ValueKey('reservation-hold-consumed'),
        icon: Icons.check_circle_outline,
        message: l10n.reservationHoldConsumed,
        onDismiss: notifier.dismissTerminal,
      ),
      ReservationHoldViewStatus.error => _ReservationError(
        state: state,
        canCreate: canCreate,
        quantity: quantity,
        onRetry: () => unawaited(notifier.retry()),
        onCreate: () => unawaited(notifier.reserve(quantity: quantity)),
      ),
    };

    if (compact) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.surface),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: content,
      ),
    );
  }
}

class _ReservationAction extends StatelessWidget {
  const _ReservationAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
      ),
    ),
  );
}

class _ReservationMessage extends StatelessWidget {
  const _ReservationMessage({
    required this.icon,
    required this.message,
    this.progress = false,
    super.key,
  });

  final IconData icon;
  final String message;
  final bool progress;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: message,
    excludeSemantics: true,
    child: Row(
      children: [
        if (progress)
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _ReservationActive extends StatelessWidget {
  const _ReservationActive({required this.state, required this.onRelease});

  final ReservationHoldState state;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expiring = state.status == ReservationHoldViewStatus.expiring;
    final title = expiring
        ? l10n.reservationHoldExpiring
        : l10n.reservationHoldActive;
    final remaining = l10n.reservationHoldRemaining(
      _formatRemaining(state.remainingSeconds),
    );
    final colors = StorefrontSemanticColors.of(context);
    final background = expiring
        ? colors.warningContainer
        : colors.successContainer;
    final foreground = expiring
        ? colors.onWarningContainer
        : colors.onSuccessContainer;
    return Semantics(
      key: const ValueKey('reservation-hold-active'),
      container: true,
      liveRegion: expiring,
      label: '$title. $remaining',
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.surface),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.xs,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      remaining,
                      key: const ValueKey('reservation-hold-remaining'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: l10n.reservationHoldReleaseAction,
                onTap: onRelease,
                excludeSemantics: true,
                child: IconButton(
                  key: const ValueKey('reservation-hold-release'),
                  tooltip: l10n.reservationHoldReleaseAction,
                  onPressed: onRelease,
                  icon: Icon(Icons.close, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationTerminal extends StatelessWidget {
  const _ReservationTerminal({
    required this.icon,
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final IconData icon;
  final String message;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      explicitChildNodes: true,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          Semantics(
            button: true,
            label: l10n.reservationHoldDismissAction,
            onTap: () => unawaited(onDismiss()),
            excludeSemantics: true,
            child: IconButton(
              key: const ValueKey('reservation-hold-dismiss'),
              tooltip: l10n.reservationHoldDismissAction,
              onPressed: () => unawaited(onDismiss()),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationError extends StatelessWidget {
  const _ReservationError({
    required this.state,
    required this.canCreate,
    required this.quantity,
    required this.onRetry,
    required this.onCreate,
  });

  final ReservationHoldState state;
  final bool canCreate;
  final int quantity;
  final VoidCallback onRetry;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = _failureMessage(
      l10n,
      state.failureKind ?? ReservationHoldFailureKind.unexpected,
    );
    final retry = state.hasPendingRetry || state.hold != null;
    return Semantics(
      key: const ValueKey('reservation-hold-error'),
      container: true,
      liveRegion: true,
      label: [
        message,
        if (state.hasPendingRetry) l10n.reservationHoldPendingRetry,
      ].join(' '),
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReservationMessage(
            icon: Icons.warning_amber_outlined,
            message: message,
          ),
          if (state.hasPendingRetry) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.reservationHoldPendingRetry,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            key: const ValueKey('reservation-hold-retry'),
            onPressed: retry
                ? onRetry
                : canCreate
                ? onCreate
                : null,
            icon: const Icon(Icons.refresh),
            label: Text(
              retry
                  ? l10n.reservationHoldRetryAction
                  : l10n.reservationHoldCreateAction(quantity),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _failureMessage(
  AppLocalizations l10n,
  ReservationHoldFailureKind kind,
) => switch (kind) {
  ReservationHoldFailureKind.offline => l10n.reservationHoldOfflineError,
  ReservationHoldFailureKind.timeout => l10n.reservationHoldTimeoutError,
  ReservationHoldFailureKind.unauthorized =>
    l10n.reservationHoldUnauthorizedError,
  ReservationHoldFailureKind.invalidInput => l10n.reservationHoldInvalidError,
  ReservationHoldFailureKind.conflict => l10n.reservationHoldConflictError,
  ReservationHoldFailureKind.unavailable =>
    l10n.reservationHoldUnavailableError,
  ReservationHoldFailureKind.limitReached => l10n.reservationHoldLimitError,
  ReservationHoldFailureKind.notFound => l10n.reservationHoldNotFoundError,
  ReservationHoldFailureKind.unexpected => l10n.reservationHoldUnexpectedError,
};
