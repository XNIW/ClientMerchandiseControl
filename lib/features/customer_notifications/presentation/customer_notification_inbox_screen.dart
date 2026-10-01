import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_notification_inbox_controller.dart';
import '../domain/customer_notification_models.dart';

class CustomerNotificationInboxScreen extends ConsumerWidget {
  const CustomerNotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(customerNotificationInboxControllerProvider);
    final controller = ref.read(
      customerNotificationInboxControllerProvider.notifier,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          TextButton(
            key: const ValueKey('notifications-mark-all-read'),
            onPressed: state.unreadCount == 0 || state.isMutating
                ? null
                : controller.markAllRead,
            child: Text(l10n.notificationsMarkAllRead),
          ),
        ],
      ),
      body: switch (state.status) {
        CustomerNotificationInboxStatus.signedOut => StorefrontEmptyState(
          icon: Icons.lock_outline,
          title: l10n.checkoutAuthTitle,
          message: l10n.checkoutAuthMessage,
        ),
        CustomerNotificationInboxStatus.loading when state.items.isEmpty =>
          const Center(child: CircularProgressIndicator()),
        CustomerNotificationInboxStatus.failure when state.items.isEmpty =>
          StorefrontEmptyState(
            icon: Icons.cloud_off_outlined,
            title: l10n.notificationsTitle,
            message: l10n.customerAccountUnavailable,
            actionLabel: l10n.deliveryContextRetry,
            onAction: controller.refresh,
          ),
        _ => _InboxBody(state: state),
      },
    );
  }
}

class _InboxBody extends ConsumerWidget {
  const _InboxBody({required this.state});

  final CustomerNotificationInboxState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(
      customerNotificationInboxControllerProvider.notifier,
    );
    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<CustomerNotificationCategory?>(
              segments: [
                ButtonSegment(value: null, label: Text(l10n.notificationsAll)),
                ButtonSegment(
                  value: CustomerNotificationCategory.order,
                  label: Text(l10n.notificationsOrders),
                ),
                ButtonSegment(
                  value: CustomerNotificationCategory.payment,
                  label: Text(l10n.notificationsPayments),
                ),
                ButtonSegment(
                  value: CustomerNotificationCategory.afterSales,
                  label: Text(l10n.notificationsSupport),
                ),
              ],
              selected: {state.category},
              onSelectionChanged: (selection) =>
                  controller.selectCategory(selection.single),
            ),
          ),
          CheckboxListTile(
            key: const ValueKey('notifications-unread-only'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.notificationsUnreadOnly),
            value: state.unreadOnly,
            onChanged: (value) => controller.selectUnreadOnly(value ?? false),
          ),
          if (state.status == CustomerNotificationInboxStatus.offline) ...[
            const SizedBox(height: AppSpacing.md),
            StorefrontStatusBanner(
              message: l10n.notificationsOffline,
              icon: Icons.cloud_off_outlined,
              actionLabel: l10n.deliveryContextRetry,
              onAction: controller.refresh,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (state.visibleItems.isEmpty)
            StorefrontEmptyState(
              icon: Icons.notifications_none_outlined,
              title: l10n.notificationsEmptyTitle,
              message: l10n.notificationsEmptyMessage,
            )
          else
            ...state.visibleItems.map(
              (item) => _NotificationTile(
                item: item,
                onTap: () => _openNotification(context, ref, item),
              ),
            ),
          if (state.hasMore) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const ValueKey('notifications-load-more'),
              onPressed: state.isLoadingMore ? null : controller.loadMore,
              child: state.isLoadingMore
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.notificationsLoadMore),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    CustomerNotification item,
  ) async {
    await ref
        .read(customerNotificationInboxControllerProvider.notifier)
        .markRead(item.id);
    if (!context.mounted) return;
    switch (item.destinationType) {
      case CustomerNotificationDestinationType.order:
        context.push(AppRoutes.orderLocation(item.destinationId!));
      case CustomerNotificationDestinationType.afterSales:
        context.push(AppRoutes.afterSalesLocation(item.destinationId));
      case CustomerNotificationDestinationType.product:
        context.push(AppRoutes.productLocation(item.destinationId!));
      case CustomerNotificationDestinationType.notifications:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final CustomerNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, body, icon) = switch (item.category) {
      CustomerNotificationCategory.order => (
        l10n.notificationOrderTitle,
        l10n.notificationOrderBody,
        Icons.receipt_long_outlined,
      ),
      CustomerNotificationCategory.payment => (
        l10n.notificationPaymentTitle,
        l10n.notificationPaymentBody,
        Icons.payments_outlined,
      ),
      CustomerNotificationCategory.afterSales => (
        l10n.notificationSupportTitle,
        l10n.notificationSupportBody,
        Icons.support_agent_outlined,
      ),
      CustomerNotificationCategory.system => (
        l10n.notificationSystemTitle,
        l10n.notificationSystemBody,
        Icons.info_outline,
      ),
    };
    final safeCode =
        item.safeArguments['orderCode'] ?? item.safeArguments['caseCode'];
    final date = item.createdAt.toLocal();
    final dateLabel =
        '${MaterialLocalizations.of(context).formatShortDate(date)} · '
        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    return Card(
      key: ValueKey('notification-${item.id}'),
      color: item.isUnread
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        minTileHeight: AppSizes.minimumTouchTarget,
        leading: Badge(isLabelVisible: item.isUnread, child: Icon(icon)),
        title: Text(title),
        subtitle: Text([body, ?safeCode, dateLabel].join('\n')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
