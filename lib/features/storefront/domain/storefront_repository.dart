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
}
