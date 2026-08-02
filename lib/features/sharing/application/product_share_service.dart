import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../deep_links/application/storefront_deep_link.dart';
import '../../storefront/domain/storefront_models.dart';

abstract interface class ProductShareService {
  Future<void> share({
    required String subject,
    required String text,
    required Rect origin,
  });
}

final class PlatformProductShareService implements ProductShareService {
  PlatformProductShareService({
    Future<ShareResult> Function(ShareParams)? share,
  }) : _share = share ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams) _share;

  @override
  Future<void> share({
    required String subject,
    required String text,
    required Rect origin,
  }) async {
    await _share(
      ShareParams(subject: subject, text: text, sharePositionOrigin: origin),
    );
  }
}

final productShareServiceProvider = Provider<ProductShareService>(
  (_) => PlatformProductShareService(),
);

class ProductShareButton extends ConsumerWidget {
  const ProductShareButton({required this.product, super.key});

  final StorefrontProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (buttonContext) => IconButton(
        key: ValueKey('share-product-${product.id}'),
        tooltip: l10n.productShare,
        onPressed: () => _share(buttonContext, ref),
        icon: const Icon(Icons.share_outlined),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (shopSlug == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final codec = ref.read(storefrontDeepLinkCodecProvider);
    final uri = codec.productUri(shopSlug: shopSlug, publicationId: product.id);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(productShareServiceProvider)
          .share(
            subject: product.name,
            text: l10n.productShareText(product.name, uri.toString()),
            origin: origin,
          );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.productShareError)));
      }
    }
  }
}
