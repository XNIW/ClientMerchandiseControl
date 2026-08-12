import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class StorefrontDeepLinkIntent {
  const StorefrontDeepLinkIntent();
}

final class StorefrontProductDeepLink extends StorefrontDeepLinkIntent {
  const StorefrontProductDeepLink(this.publicationId);

  final String publicationId;
}

final class StorefrontCategoryDeepLink extends StorefrontDeepLinkIntent {
  const StorefrontCategoryDeepLink(this.categorySlug);

  final String categorySlug;
}

final class StorefrontOrderDeepLink extends StorefrontDeepLinkIntent {
  const StorefrontOrderDeepLink(this.orderId);

  final String orderId;
}

final class StorefrontNotificationDeepLink extends StorefrontDeepLinkIntent {
  const StorefrontNotificationDeepLink(this.routeToken);

  final String routeToken;
}

final storefrontDeepLinkCodecProvider = Provider<StorefrontDeepLinkCodec>(
  (_) => const StorefrontDeepLinkCodec(),
);

class StorefrontDeepLinkCodec {
  const StorefrontDeepLinkCodec();

  static const scheme = 'com.xniw.clientmerchandisecontrol';
  static const host = 'storefront';
  static final _shopSlug = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');
  static final _categorySlug = RegExp(r'^[a-z0-9][a-z0-9-]{1,62}$');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  Uri productUri({required String shopSlug, required String publicationId}) {
    _require(_shopSlug.hasMatch(shopSlug));
    _require(_uuid.hasMatch(publicationId));
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: [shopSlug, 'product', publicationId],
    );
  }

  Uri categoryUri({required String shopSlug, required String categorySlug}) {
    _require(_shopSlug.hasMatch(shopSlug));
    _require(_categorySlug.hasMatch(categorySlug));
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: [shopSlug, 'category', categorySlug],
    );
  }

  Uri orderUri({required String shopSlug, required String orderId}) {
    _require(_shopSlug.hasMatch(shopSlug));
    _require(_uuid.hasMatch(orderId));
    throw UnsupportedError('verified_sensitive_callback_channel_unavailable');
  }

  Uri notificationUri({required String shopSlug, required String routeToken}) {
    _require(_shopSlug.hasMatch(shopSlug));
    _require(_uuid.hasMatch(routeToken));
    throw UnsupportedError('verified_sensitive_callback_channel_unavailable');
  }

  StorefrontDeepLinkIntent? decode(Uri uri, {required String shopSlug}) {
    if (!_shopSlug.hasMatch(shopSlug) ||
        uri.scheme != scheme ||
        uri.host != host ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.length != 3 ||
        uri.pathSegments.first != shopSlug) {
      return null;
    }
    final kind = uri.pathSegments[1];
    final value = uri.pathSegments[2];
    if (kind == 'product' && _uuid.hasMatch(value)) {
      final canonical = productUri(shopSlug: shopSlug, publicationId: value);
      return uri.toString() == canonical.toString()
          ? StorefrontProductDeepLink(value)
          : null;
    }
    if (kind == 'category' && _categorySlug.hasMatch(value)) {
      final canonical = categoryUri(shopSlug: shopSlug, categorySlug: value);
      return uri.toString() == canonical.toString()
          ? StorefrontCategoryDeepLink(value)
          : null;
    }
    return null;
  }

  void _require(bool condition) {
    if (!condition) throw ArgumentError('invalid_storefront_deep_link_input');
  }
}
