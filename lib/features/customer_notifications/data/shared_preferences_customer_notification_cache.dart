import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/customer_notification_cache.dart';
import '../domain/customer_notification_models.dart';

final class SharedPreferencesCustomerNotificationCache
    implements CustomerNotificationCache {
  static const _prefix = 'cmc.customer-notification-cache.v1';

  @override
  Future<List<CustomerNotification>> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    final key = _key(ownerSubjectId, shopSlug);
    try {
      final preferences = SharedPreferencesAsync();
      final raw = await preferences.getString(key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['ownerSubjectId'] != ownerSubjectId ||
          decoded['shopSlug'] != shopSlug ||
          decoded['items'] is! List) {
        throw const FormatException('notification_cache_envelope');
      }
      final items = (decoded['items'] as List)
          .take(100)
          .map((item) => _decodeItem(item, shopSlug))
          .toList(growable: false);
      return items;
    } on Object {
      try {
        await SharedPreferencesAsync().remove(key);
      } on Object {
        // The inbox cache is best-effort and must never block live data.
      }
      return const [];
    }
  }

  @override
  Future<void> write({
    required String ownerSubjectId,
    required String shopSlug,
    required List<CustomerNotification> items,
  }) async {
    try {
      final bounded = items.take(100).map(_encodeItem).toList(growable: false);
      await SharedPreferencesAsync().setString(
        _key(ownerSubjectId, shopSlug),
        jsonEncode({
          'ownerSubjectId': ownerSubjectId,
          'shopSlug': shopSlug,
          'items': bounded,
        }),
      );
    } on Object {
      // Persistence is read-only assistance, never an authorization boundary.
    }
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    try {
      await SharedPreferencesAsync().remove(_key(ownerSubjectId, shopSlug));
    } on Object {
      // Account-switch cleanup also clears observable memory in the controller.
    }
  }

  static String _key(String owner, String shop) => '$_prefix:$owner:$shop';

  static Map<String, Object?> _encodeItem(CustomerNotification item) => {
    'id': item.id,
    'shopSlug': item.shopSlug,
    'category': item.category.name,
    'event': item.event,
    'eventVersion': item.eventVersion,
    'titleKey': item.titleKey,
    'bodyKey': item.bodyKey,
    'safeArguments': item.safeArguments,
    'destinationType': item.destinationType.name,
    'destinationId': item.destinationId,
    'createdAt': item.createdAt.toIso8601String(),
    'readAt': item.readAt?.toIso8601String(),
    'expiresAt': item.expiresAt?.toIso8601String(),
  };

  static CustomerNotification _decodeItem(Object? raw, String shopSlug) {
    if (raw is! Map) throw const FormatException('notification_cache_item');
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final id = map['id'];
    final eventVersion = map['eventVersion'];
    final safeRaw = map['safeArguments'];
    if (id is! String ||
        map['shopSlug'] != shopSlug ||
        eventVersion is! int ||
        eventVersion < 1 ||
        safeRaw is! Map) {
      throw const FormatException('notification_cache_identity');
    }
    final safe = safeRaw.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
    return CustomerNotification(
      id: id,
      shopSlug: shopSlug,
      category: CustomerNotificationCategory.values.byName(
        map['category'] as String,
      ),
      event: map['event'] as String,
      eventVersion: eventVersion,
      titleKey: map['titleKey'] as String,
      bodyKey: map['bodyKey'] as String,
      safeArguments: safe,
      destinationType: CustomerNotificationDestinationType.values.byName(
        map['destinationType'] as String,
      ),
      destinationId: map['destinationId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(),
      readAt: _date(map['readAt']),
      expiresAt: _date(map['expiresAt']),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;
}
