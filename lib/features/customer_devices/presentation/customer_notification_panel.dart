import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_device_controller.dart';
import '../domain/customer_device_failure.dart';
import '../domain/customer_device_models.dart';

class CustomerNotificationPanel extends ConsumerWidget {
  const CustomerNotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDeviceControllerProvider);
    final controller = ref.read(customerDeviceControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    if (state.status == CustomerDeviceStatus.signedOut) {
      return const SizedBox.shrink();
    }

    final locale = _customerDeviceLocale(Localizations.localeOf(context));
    return Column(
      key: const ValueKey('customer-notifications-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: AppSizes.iconStandard,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customerNotificationsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.customerNotificationsDescription),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == CustomerDeviceStatus.loading)
          Semantics(
            container: true,
            liveRegion: true,
            label: l10n.customerNotificationsLoading,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  key: ValueKey('customer-notifications-loading'),
                ),
              ),
            ),
          )
        else ...[
          _NotificationStatus(state: state),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: [
              if (state.consentStatus == CustomerDeviceConsentStatus.granted)
                OutlinedButton.icon(
                  key: const ValueKey('customer-notifications-revoke'),
                  onPressed: state.isMutating ? null : controller.revoke,
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: Text(l10n.customerNotificationsRevoke),
                )
              else
                OutlinedButton.icon(
                  key: const ValueKey('customer-notifications-not-now'),
                  onPressed: state.isMutating
                      ? null
                      : () => controller.deny(locale),
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(l10n.customerNotificationsNotNow),
                ),
              FilledButton.icon(
                key: const ValueKey('customer-notifications-enable'),
                onPressed:
                    state.isMutating ||
                        state.providerAvailability ==
                            CustomerPushProviderAvailability.notConfigured
                    ? null
                    : () => controller.enable(locale),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l10n.customerNotificationsEnable),
              ),
              if (state.failure != null || !state.serverConfirmed)
                TextButton.icon(
                  key: const ValueKey('customer-notifications-retry'),
                  onPressed: state.isMutating
                      ? null
                      : () => controller.retry(locale),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.customerNotificationsRetry),
                ),
            ],
          ),
          if (state.isMutating) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(
              key: ValueKey('customer-notifications-progress'),
            ),
          ],
        ],
      ],
    );
  }
}

class _NotificationStatus extends StatelessWidget {
  const _NotificationStatus({required this.state});

  final CustomerDeviceState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = _statusMessage(AppLocalizations.of(context), state);
    final icon = switch (state.status) {
      CustomerDeviceStatus.offline => Icons.cloud_off_outlined,
      CustomerDeviceStatus.failure => Icons.error_outline,
      _ when state.notificationsActive => Icons.check_circle_outline,
      _ when !state.serverConfirmed => Icons.sync_problem_outlined,
      _ => Icons.info_outline,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  key: const ValueKey('customer-notifications-status'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusMessage(AppLocalizations l10n, CustomerDeviceState state) {
  if (state.status == CustomerDeviceStatus.offline) {
    return l10n.customerNotificationsOffline;
  }
  if (state.failure case final failure?) {
    return _failureMessage(l10n, failure);
  }
  if (state.providerAvailability ==
      CustomerPushProviderAvailability.notConfigured) {
    return l10n.customerNotificationsProviderUnavailable;
  }
  if (!state.serverConfirmed) {
    return l10n.customerNotificationsPending;
  }
  return switch (state.consentStatus) {
    CustomerDeviceConsentStatus.granted => l10n.customerNotificationsActive,
    CustomerDeviceConsentStatus.denied => l10n.customerNotificationsDenied,
    CustomerDeviceConsentStatus.revoked => l10n.customerNotificationsRevoked,
    CustomerDeviceConsentStatus.notRequested =>
      l10n.customerNotificationsNotRequested,
  };
}

String _failureMessage(AppLocalizations l10n, CustomerDeviceFailure failure) {
  return switch (failure.kind) {
    CustomerDeviceFailureKind.offline => l10n.customerNotificationsOffline,
    CustomerDeviceFailureKind.timeout => l10n.customerNotificationsTimeout,
    CustomerDeviceFailureKind.unauthorized =>
      l10n.customerNotificationsUnauthorized,
    CustomerDeviceFailureKind.invalidInput => l10n.customerNotificationsInvalid,
    CustomerDeviceFailureKind.conflict => l10n.customerNotificationsConflict,
    CustomerDeviceFailureKind.unavailable ||
    CustomerDeviceFailureKind.unexpected =>
      l10n.customerNotificationsUnavailable,
  };
}

String _customerDeviceLocale(Locale locale) {
  if (locale.languageCode == 'zh') {
    return 'zh-Hans';
  }
  return switch (locale.languageCode) {
    'it' => 'it',
    'en' => 'en',
    _ => 'es-CL',
  };
}
