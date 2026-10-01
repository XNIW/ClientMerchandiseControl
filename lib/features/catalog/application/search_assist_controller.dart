import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../data/search_assist_data.dart';
import '../domain/search_assist_models.dart';
import '../domain/search_assist_repository.dart';

final searchAssistRepositoryProvider = Provider<SearchAssistRepository>((ref) {
  return SupabaseSearchAssistRepository(
    port: PlatformSearchAssistPort(Supabase.instance.client),
  );
});

final searchHistoryStoreProvider = Provider<SearchHistoryStore>((ref) {
  return SharedPreferencesSearchHistoryStore();
});

final searchAssistControllerProvider =
    NotifierProvider<SearchAssistController, SearchAssistState>(
      SearchAssistController.new,
    );

final class SearchAssistController extends Notifier<SearchAssistState> {
  Timer? _debounce;
  var _requestGeneration = 0;
  String? _shopSlug;

  @override
  SearchAssistState build() {
    final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
    if (_shopSlug != shopSlug) {
      _shopSlug = shopSlug;
      final generation = ++_requestGeneration;
      scheduleMicrotask(() => _loadHistory(shopSlug, generation));
    }
    ref.onDispose(() {
      _debounce?.cancel();
      _requestGeneration++;
    });
    return const SearchAssistState();
  }

  void queryChanged(String raw) {
    final query = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    _debounce?.cancel();
    final generation = ++_requestGeneration;
    if (query.runes.length < 2 || query.runes.length > 80) {
      state = state.copyWith(
        query: query,
        suggestions: const [],
        isLoading: false,
      );
      return;
    }
    state = state.copyWith(query: query, isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final shopSlug = _shopSlug;
      if (shopSlug == null) return;
      try {
        final items = await ref
            .read(searchAssistRepositoryProvider)
            .suggestions(shopSlug: shopSlug, query: query);
        if (generation == _requestGeneration) {
          state = state.copyWith(suggestions: items, isLoading: false);
        }
      } on Object {
        if (generation == _requestGeneration) {
          state = state.copyWith(suggestions: const [], isLoading: false);
        }
      }
    });
  }

  Future<void> submit(String raw) async {
    _debounce?.cancel();
    _requestGeneration++;
    state = state.copyWith(isLoading: false, suggestions: const []);
    final query = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.runes.length < 2 || query.runes.length > 80) return;
    final shopSlug = _shopSlug;
    if (shopSlug == null) return;
    final history = [
      query,
      ...state.history.where(
        (value) => value.toLowerCase() != query.toLowerCase(),
      ),
    ].take(10).toList(growable: false);
    state = state.copyWith(
      history: history,
      suggestions: const [],
      query: query,
    );
    await ref.read(searchHistoryStoreProvider).write(shopSlug, history);
  }

  Future<void> remove(String query) async {
    final shopSlug = _shopSlug;
    if (shopSlug == null) return;
    final history = state.history.where((value) => value != query).toList();
    state = state.copyWith(history: history);
    await ref.read(searchHistoryStoreProvider).write(shopSlug, history);
  }

  Future<void> clear() async {
    final shopSlug = _shopSlug;
    if (shopSlug == null) return;
    state = state.copyWith(history: const []);
    await ref.read(searchHistoryStoreProvider).write(shopSlug, const []);
  }

  Future<void> _loadHistory(String? shopSlug, int generation) async {
    if (shopSlug == null) return;
    final values = await ref.read(searchHistoryStoreProvider).read(shopSlug);
    if (generation == _requestGeneration) {
      state = state.copyWith(history: values);
    }
  }
}
