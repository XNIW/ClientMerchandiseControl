import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/search_assist_models.dart';
import '../domain/search_assist_repository.dart';

abstract interface class SearchAssistPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformSearchAssistPort implements SearchAssistPort {
  PlatformSearchAssistPort(this.client);

  final SupabaseClient client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return client.rpc(function, params: parameters);
  }
}

final class SupabaseSearchAssistRepository implements SearchAssistRepository {
  SupabaseSearchAssistRepository({
    required this.port,
    this.timeout = const Duration(seconds: 8),
  });

  final SearchAssistPort port;
  final Duration timeout;

  @override
  Future<List<StorefrontSearchSuggestion>> suggestions({
    required String shopSlug,
    required String query,
  }) async {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(shopSlug) ||
        !_validQuery(query)) {
      return const [];
    }
    final raw = await port
        .invoke('storefront_search_suggestions_v1', {
          'p_shop_slug': shopSlug,
          'p_query': query,
          'p_limit': 10,
        })
        .timeout(timeout);
    if (raw is! Map) throw const FormatException('search_assist_map');
    final payload = raw.map((key, value) => MapEntry(key.toString(), value));
    const keys = {'apiVersion', 'status', 'items', 'serverTime'};
    if (payload.keys.toSet().difference(keys).isNotEmpty ||
        payload['apiVersion'] != 'storefront-search-suggestions.v1' ||
        payload['status'] != 'ok' ||
        payload['items'] is! List ||
        (payload['items'] as List).length > 10 ||
        DateTime.tryParse(payload['serverTime']?.toString() ?? '') == null) {
      throw const FormatException('search_assist_shape');
    }
    final items = (payload['items'] as List)
        .map((rawItem) {
          if (rawItem is! Map) {
            throw const FormatException('search_assist_item');
          }
          final item = rawItem.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          if (item.length != 2 ||
              !item.keys.toSet().containsAll(const {'value', 'kind'}) ||
              item['value'] is! String ||
              !_validSuggestion(item['value'] as String)) {
            throw const FormatException('search_assist_item_shape');
          }
          final kind = switch (item['kind']) {
            'product' => StorefrontSearchSuggestionKind.product,
            'category' => StorefrontSearchSuggestionKind.category,
            'brand' => StorefrontSearchSuggestionKind.brand,
            _ => throw const FormatException('search_assist_kind'),
          };
          return StorefrontSearchSuggestion(
            value: item['value'] as String,
            kind: kind,
          );
        })
        .toList(growable: false);
    if (items.map((item) => item.value.toLowerCase()).toSet().length !=
        items.length) {
      throw const FormatException('search_assist_duplicate');
    }
    return items;
  }
}

final class SharedPreferencesSearchHistoryStore implements SearchHistoryStore {
  static const _prefix = 'storefront.search_history.v1.';

  @override
  Future<List<String>> read(String shopSlug) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('$_prefix$shopSlug') ?? const [])
        .where(_validQuery)
        .take(10)
        .toList(growable: false);
  }

  @override
  Future<void> write(String shopSlug, List<String> values) async {
    final bounded = values.where(_validQuery).take(10).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_prefix$shopSlug', bounded);
  }
}

bool _validQuery(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return value == normalized &&
      value.runes.length >= 2 &&
      value.runes.length <= 80 &&
      !value.runes.any((rune) => rune < 0x20 || rune == 0x7f);
}

bool _validSuggestion(String value) =>
    value.runes.isNotEmpty &&
    value.runes.length <= 200 &&
    value == value.trim() &&
    !value.contains('<') &&
    !value.contains('>');
