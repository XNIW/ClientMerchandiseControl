enum StorefrontSearchSuggestionKind { product, category, brand }

final class StorefrontSearchSuggestion {
  const StorefrontSearchSuggestion({required this.value, required this.kind});

  final String value;
  final StorefrontSearchSuggestionKind kind;
}

final class SearchAssistState {
  const SearchAssistState({
    this.history = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.query = '',
  });

  final List<String> history;
  final List<StorefrontSearchSuggestion> suggestions;
  final bool isLoading;
  final String query;

  SearchAssistState copyWith({
    List<String>? history,
    List<StorefrontSearchSuggestion>? suggestions,
    bool? isLoading,
    String? query,
  }) => SearchAssistState(
    history: history ?? this.history,
    suggestions: suggestions ?? this.suggestions,
    isLoading: isLoading ?? this.isLoading,
    query: query ?? this.query,
  );
}
