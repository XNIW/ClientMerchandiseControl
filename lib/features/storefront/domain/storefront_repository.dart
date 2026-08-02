import 'storefront_failure.dart';
import 'storefront_models.dart';

class StorefrontRequestCancellation {
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) {
      throw const StorefrontFailure(
        StorefrontFailureKind.cancelled,
        code: 'request_cancelled',
      );
    }
  }
}

abstract interface class StorefrontRepository {
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  });

  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  });

  Future<StorefrontCatalogPage> fetchCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    required StorefrontRequestCancellation cancellation,
  });
}
