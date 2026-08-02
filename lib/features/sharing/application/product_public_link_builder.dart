import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deep_links/application/storefront_deep_link.dart';

final productPublicLinkBuilderProvider = Provider<ProductPublicLinkBuilder>(
  (ref) => ProductPublicLinkBuilder(ref.watch(storefrontDeepLinkCodecProvider)),
);

final class ProductPublicLinkBuilder {
  const ProductPublicLinkBuilder(this._codec);

  final StorefrontDeepLinkCodec _codec;

  Uri product({required String shopSlug, required String publicationId}) =>
      _codec.productUri(shopSlug: shopSlug, publicationId: publicationId);
}
