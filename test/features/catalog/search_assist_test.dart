import 'package:client_merchandise_control/features/catalog/data/search_assist_data.dart';
import 'package:client_merchandise_control/features/catalog/domain/search_assist_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('cronologia resta locale, shop-scoped e bounded a dieci', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesSearchHistoryStore();
    await store.write(
      'storefront-test',
      List.generate(12, (index) => 'ricerca $index'),
    );

    expect(await store.read('storefront-test'), hasLength(10));
    expect(await store.read('other-shop'), isEmpty);
  });

  test(
    'suggerimenti sono pubblicati, tipizzati e senza query identitaria',
    () async {
      final port = _Port();
      final items = await SupabaseSearchAssistRepository(
        port: port,
      ).suggestions(shopSlug: 'storefront-test', query: 'cafè');

      expect(items.single.kind, StorefrontSearchSuggestionKind.product);
      expect(port.parameters, {
        'p_shop_slug': 'storefront-test',
        'p_query': 'cafè',
        'p_limit': 10,
      });
      expect(port.parameters, isNot(contains(anyOf('userId', 'ownerUserId'))));
    },
  );
}

final class _Port implements SearchAssistPort {
  Map<String, Object?>? parameters;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.parameters = parameters;
    return {
      'apiVersion': 'storefront-search-suggestions.v1',
      'status': 'ok',
      'items': [
        {'value': 'Caffè pubblicato', 'kind': 'product'},
      ],
      'serverTime': '2026-08-23T12:00:00Z',
    };
  }
}
