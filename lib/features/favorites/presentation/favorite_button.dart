import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/favorites_controller.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.publicationId, super.key});

  final String publicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = favorites.maybeWhen(
      data: (entries) =>
          entries.any((entry) => entry.publicationId == publicationId),
      orElse: () => false,
    );
    final label = isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd;
    return IconButton(
      key: ValueKey('favorite-product-$publicationId'),
      tooltip: label,
      onPressed: favorites.hasError || favorites.isLoading
          ? null
          : () => _toggle(context, ref),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      final isFavorite = await ref
          .read(favoritesControllerProvider.notifier)
          .toggle(publicationId);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? l10n.favoriteAdded : l10n.favoriteRemoved),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).favoritesErrorMessage),
        ),
      );
    }
  }
}
