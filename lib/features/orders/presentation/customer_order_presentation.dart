import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/customer_order_failure.dart';
import '../domain/customer_order_models.dart';

String customerOrderStatusLabel(
  AppLocalizations l10n,
  CustomerOrderStatus status,
) => switch (status) {
  CustomerOrderStatus.confirmed => l10n.checkoutOrderStatusConfirmed,
  CustomerOrderStatus.accepted => l10n.checkoutOrderStatusAccepted,
  CustomerOrderStatus.rejected => l10n.checkoutOrderStatusRejected,
  CustomerOrderStatus.preparing => l10n.checkoutOrderStatusPreparing,
  CustomerOrderStatus.ready => l10n.checkoutOrderStatusReady,
  CustomerOrderStatus.outForDelivery => l10n.checkoutOrderStatusOutForDelivery,
  CustomerOrderStatus.completed => l10n.checkoutOrderStatusCompleted,
  CustomerOrderStatus.cancelled => l10n.checkoutOrderStatusCancelled,
};

String customerOrderModeLabel(
  AppLocalizations l10n,
  CustomerOrderFulfillmentMode mode,
) => switch (mode) {
  CustomerOrderFulfillmentMode.pickup => l10n.checkoutModePickup,
  CustomerOrderFulfillmentMode.reservation => l10n.checkoutModeReservation,
  CustomerOrderFulfillmentMode.delivery => l10n.checkoutModeDelivery,
};

IconData customerOrderModeIcon(CustomerOrderFulfillmentMode mode) =>
    switch (mode) {
      CustomerOrderFulfillmentMode.pickup => Icons.storefront_outlined,
      CustomerOrderFulfillmentMode.reservation =>
        Icons.event_available_outlined,
      CustomerOrderFulfillmentMode.delivery => Icons.local_shipping_outlined,
    };

Color customerOrderStatusColor(
  BuildContext context,
  CustomerOrderStatus status,
) {
  final semantic = StorefrontSemanticColors.of(context);
  return switch (status) {
    CustomerOrderStatus.completed => semantic.success,
    CustomerOrderStatus.rejected ||
    CustomerOrderStatus.cancelled => Theme.of(context).colorScheme.error,
    CustomerOrderStatus.ready => semantic.success,
    CustomerOrderStatus.outForDelivery => semantic.information,
    CustomerOrderStatus.confirmed ||
    CustomerOrderStatus.accepted ||
    CustomerOrderStatus.preparing => semantic.warning,
  };
}

String customerOrderDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

String customerOrderFailureMessage(
  AppLocalizations l10n,
  CustomerOrderFailureKind? failure,
) => switch (failure) {
  CustomerOrderFailureKind.offline => l10n.ordersOffline,
  CustomerOrderFailureKind.timeout => l10n.ordersError,
  CustomerOrderFailureKind.unauthorized => l10n.ordersUnauthorized,
  CustomerOrderFailureKind.notFound => l10n.ordersNotFound,
  CustomerOrderFailureKind.notCancellable => l10n.ordersCancelNotAllowed,
  CustomerOrderFailureKind.versionConflict => l10n.ordersCancelVersionConflict,
  CustomerOrderFailureKind.idempotencyConflict ||
  CustomerOrderFailureKind.invalid ||
  CustomerOrderFailureKind.unavailable ||
  CustomerOrderFailureKind.unexpected ||
  null => l10n.ordersUnexpected,
};
