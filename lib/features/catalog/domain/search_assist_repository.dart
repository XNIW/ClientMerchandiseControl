import 'search_assist_models.dart';

abstract interface class SearchAssistRepository {
  Future<List<StorefrontSearchSuggestion>> suggestions({
    required String shopSlug,
    required String query,
  });
}

abstract interface class SearchHistoryStore {
  Future<List<String>> read(String shopSlug);
  Future<void> write(String shopSlug, List<String> values);
}
