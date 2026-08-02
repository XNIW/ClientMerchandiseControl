import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'storefront_status_banner.dart';

class StorefrontCacheStatus extends StatelessWidget {
  const StorefrontCacheStatus({
    required this.cachedAt,
    required this.isStale,
    required this.isRefreshing,
    this.compact = false,
    super.key,
  });

  final DateTime cachedAt;
  final bool isStale;
  final bool isRefreshing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timestamp = DateFormat.yMd(
      locale,
    ).add_Hm().format(cachedAt.toLocal());
    final freshness = isStale
        ? l10n.storefrontCacheStale(timestamp)
        : l10n.storefrontCacheFresh(timestamp);
    final message = isRefreshing
        ? '$freshness ${l10n.storefrontCacheRefreshing}'
        : freshness;
    return StorefrontStatusBanner(
      key: const ValueKey('storefront-cache-status'),
      message: message,
      icon: isRefreshing
          ? Icons.sync_outlined
          : isStale
          ? Icons.history_outlined
          : Icons.offline_pin_outlined,
      compact: compact,
    );
  }
}
