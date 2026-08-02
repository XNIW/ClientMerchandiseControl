import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' as platform;

import '../../../core/config/app_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../storefront/domain/storefront_models.dart';
import 'product_public_link_builder.dart';

enum ShareResultStatus { completed, dismissed, unavailable }

final class ShareResult {
  const ShareResult({required this.status, this.activity});

  final ShareResultStatus status;
  final String? activity;
}

final class ShareRequest {
  ShareRequest({
    required this.subject,
    required this.text,
    required this.publicUrl,
    required this.origin,
  }) {
    if (subject.trim().isEmpty ||
        text.trim().isEmpty ||
        !publicUrl.hasScheme ||
        !text.contains(publicUrl.toString()) ||
        origin.isEmpty ||
        !origin.left.isFinite ||
        !origin.top.isFinite ||
        !origin.width.isFinite ||
        !origin.height.isFinite) {
      throw ArgumentError('invalid_product_share_request');
    }
  }

  final String subject;
  final String text;
  final Uri publicUrl;
  final Rect origin;
}

abstract interface class ProductShareService {
  Future<ShareResult> share(ShareRequest request);
}

final class PlatformProductShareService implements ProductShareService {
  PlatformProductShareService({
    Future<platform.ShareResult> Function(platform.ShareParams)? share,
  }) : _share = share ?? platform.SharePlus.instance.share;

  final Future<platform.ShareResult> Function(platform.ShareParams) _share;

  @override
  Future<ShareResult> share(ShareRequest request) async {
    final result = await _share(
      platform.ShareParams(
        subject: request.subject,
        title: request.subject,
        text: request.text,
        sharePositionOrigin: request.origin,
      ),
    );
    return ShareResult(
      status: switch (result.status) {
        platform.ShareResultStatus.success => ShareResultStatus.completed,
        platform.ShareResultStatus.dismissed => ShareResultStatus.dismissed,
        platform.ShareResultStatus.unavailable => ShareResultStatus.unavailable,
      },
      activity: result.raw.isEmpty ? null : result.raw,
    );
  }
}

final productShareServiceProvider = Provider<ProductShareService>(
  (_) => PlatformProductShareService(),
);

class ProductShareButton extends ConsumerStatefulWidget {
  const ProductShareButton({required this.product, super.key});

  final StorefrontProductSummary product;

  @override
  ConsumerState<ProductShareButton> createState() => _ProductShareButtonState();
}

class _ProductShareButtonState extends ConsumerState<ProductShareButton> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (buttonContext) => Semantics(
        button: true,
        label: l10n.productShare,
        excludeSemantics: true,
        child: IconButton(
          key: ValueKey('share-product-${widget.product.id}'),
          tooltip: l10n.productShare,
          onPressed: _sharing ? null : () => _share(buttonContext),
          icon: const Icon(Icons.share_outlined),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
      if (shopSlug == null) {
        throw StateError('storefront_shop_unavailable');
      }
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        throw StateError('share_origin_unavailable');
      }
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final uri = ref
          .read(productPublicLinkBuilderProvider)
          .product(shopSlug: shopSlug, publicationId: widget.product.id);
      final l10n = AppLocalizations.of(context);
      await ref
          .read(productShareServiceProvider)
          .share(
            ShareRequest(
              subject: widget.product.name,
              text: l10n.productShareText(widget.product.name, uri.toString()),
              publicUrl: uri,
              origin: origin,
            ),
          );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).productShareError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
