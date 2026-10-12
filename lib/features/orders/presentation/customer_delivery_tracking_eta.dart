import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../delivery_tracking/application/delivery_tracking_providers.dart';
import '../../delivery_tracking/domain/delivery_tracking_models.dart';
import 'customer_order_presentation.dart';

/// Qualifica soltanto la finestra fornita dal server, senza calcolare una ETA.
class CustomerDeliveryTrackingEta extends ConsumerStatefulWidget {
  const CustomerDeliveryTrackingEta({
    required this.snapshot,
    required this.timeZone,
    required this.orderTerminal,
    this.isForeground = true,
    super.key,
  });

  final DeliveryTrackingSnapshot snapshot;
  final String timeZone;
  final bool orderTerminal;
  final bool isForeground;

  @override
  ConsumerState<CustomerDeliveryTrackingEta> createState() =>
      _CustomerDeliveryTrackingEtaState();
}

class _CustomerDeliveryTrackingEtaState
    extends ConsumerState<CustomerDeliveryTrackingEta> {
  Timer? _expiry;
  late DateTime _now;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _now = ref.read(deliveryTrackingClockProvider)();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.of(context) && ModalRoute.of(context)?.isCurrent != false;
    _resetDeadline();
  }

  @override
  void didUpdateWidget(covariant CustomerDeliveryTrackingEta oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetDeadline();
  }

  void _resetDeadline() {
    _expiry?.cancel();
    _expiry = null;
    _now = ref.read(deliveryTrackingClockProvider)();
    final end = widget.snapshot.etaEndsAt;
    if (!_visible || !widget.isForeground ||
        widget.orderTerminal || widget.snapshot.isTerminal || end == null) return;
    final remaining = end.difference(_now);
    if (remaining <= Duration.zero) return;
    _expiry = Timer(remaining, () {
      if (!mounted) return;
      setState(_resetDeadline);
    });
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderTerminal || widget.snapshot.isTerminal) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final start = widget.snapshot.etaStartsAt;
    final end = widget.snapshot.etaEndsAt;
    final label = start == null || end == null
        ? l10n.deliveryTrackingEtaUnavailable
        : !end.isAfter(_now)
        ? l10n.deliveryTrackingEtaExpired
        : l10n.deliveryTrackingWindow(
            customerOrderDate(context, start, timeZone: widget.timeZone),
            customerOrderDate(context, end, timeZone: widget.timeZone),
          );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Semantics(
        key: const ValueKey('delivery-tracking-eta'),
        liveRegion: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
