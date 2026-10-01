import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/application/search_assist_controller.dart';
import 'package:client_merchandise_control/features/catalog/domain/search_assist_repository.dart';
import 'package:client_merchandise_control/features/catalog/data/search_assist_data.dart';
import 'package:client_merchandise_control/features/catalog/domain/search_assist_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('submit invalida suggerimenti pendenti e spinner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _DeferredSuggestions();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.authFlowTest()),
        searchAssistRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(searchAssistControllerProvider);
    await tester.pump();
    final controller = container.read(searchAssistControllerProvider.notifier);
    controller.queryChanged('caffè');
    await tester.pump(const Duration(milliseconds: 251));
    await controller.submit('caffè');
    expect(container.read(searchAssistControllerProvider).isLoading, isFalse);
    repository.pending.complete([
      const StorefrontSearchSuggestion(
        value: 'vecchio',
        kind: StorefrontSearchSuggestionKind.product,
      ),
    ]);
    await tester.pump();
    expect(container.read(searchAssistControllerProvider).suggestions, isEmpty);
  });

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

final class _DeferredSuggestions implements SearchAssistRepository {
  final pending = Completer<List<StorefrontSearchSuggestion>>();
  @override
  Future<List<StorefrontSearchSuggestion>> suggestions({
    required String shopSlug,
    required String query,
  }) => pending.future;
}
