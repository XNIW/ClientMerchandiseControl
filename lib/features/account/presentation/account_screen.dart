import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'account_presentation_model.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountView.guest();
  }
}

sealed class AccountView extends StatelessWidget {
  const AccountView._({super.key});

  const factory AccountView.guest({
    Key? key,
    VoidCallback? onContinueWithGoogle,
    VoidCallback? onBrowseAsGuest,
  }) = _GuestAccountView;

  const factory AccountView.authenticated({
    Key? key,
    required AuthenticatedAccountPresentationModel model,
    required VoidCallback onLogout,
  }) = _AuthenticatedAccountView;
}

final class _GuestAccountView extends AccountView {
  const _GuestAccountView({
    super.key,
    this.onContinueWithGoogle,
    this.onBrowseAsGuest,
  }) : super._();

  final VoidCallback? onContinueWithGoogle;
  final VoidCallback? onBrowseAsGuest;

  @override
  Widget build(BuildContext context) {
    return _AccountSurface(
      child: _GuestAccountContent(
        onContinueWithGoogle: onContinueWithGoogle,
        onBrowseAsGuest: onBrowseAsGuest,
      ),
    );
  }
}

final class _AuthenticatedAccountView extends AccountView {
  const _AuthenticatedAccountView({
    required this.model,
    required this.onLogout,
    super.key,
  }) : super._();

  final AuthenticatedAccountPresentationModel model;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _AccountSurface(
      child: _AuthenticatedAccountContent(model: model, onLogout: onLogout),
    );
  }
}

class _AccountSurface extends StatelessWidget {
  const _AccountSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StorefrontPage(
      maxWidth: AppSizes.accountContentMaxWidth,
      child: Card(
        key: const ValueKey('account-card'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}

class _GuestAccountContent extends StatelessWidget {
  const _GuestAccountContent({
    required this.onContinueWithGoogle,
    required this.onBrowseAsGuest,
  });

  final VoidCallback? onContinueWithGoogle;
  final VoidCallback? onBrowseAsGuest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const SizedBox.square(
                key: ValueKey('account-guest-avatar'),
                dimension: AppSizes.guestAvatar,
                child: Icon(Icons.person_outline, size: AppSizes.iconEmphasis),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.accountGuestTitle,
            key: const ValueKey('account-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.accountGuestBenefit,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        _AccountButtonSemantics(
          label: l10n.accountContinueWithGoogle,
          onTap: onContinueWithGoogle,
          child: FilledButton(
            key: const ValueKey('account-google-button'),
            onPressed: onContinueWithGoogle,
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                AppSizes.minimumTouchTarget,
                AppSizes.minimumTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: AppSizes.iconStandard),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.accountContinueWithGoogle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onContinueWithGoogle == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.accountGoogleComingSoon,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (onBrowseAsGuest != null) ...[
          const SizedBox(height: AppSpacing.md),
          _AccountButtonSemantics(
            label: l10n.accountBrowseAsGuest,
            onTap: onBrowseAsGuest,
            child: OutlinedButton(
              key: const ValueKey('account-browse-button'),
              onPressed: onBrowseAsGuest,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  AppSizes.minimumTouchTarget,
                  AppSizes.minimumTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                l10n.accountBrowseAsGuest,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthenticatedAccountContent extends StatelessWidget {
  const _AuthenticatedAccountContent({
    required this.model,
    required this.onLogout,
  });

  final AuthenticatedAccountPresentationModel model;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayName = _normalizedOrFallback(
      model.displayName,
      l10n.accountNameFallback,
    );
    final email = _normalizedOrFallback(model.email, l10n.accountEmailFallback);
    final semanticColors = StorefrontSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.accountAuthenticatedTitle,
            key: const ValueKey('account-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Align(
          child: _AccountAvatar(
            bytes: model.avatarBytes,
            semanticLabel: l10n.accountAvatarLabel(displayName),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          displayName,
          key: const ValueKey('account-display-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          email,
          key: const ValueKey('account-email'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          container: true,
          label: l10n.accountSessionActive,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: semanticColors.successContainer,
                borderRadius: BorderRadius.circular(AppRadii.surface),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  key: const ValueKey('account-session-status'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: semanticColors.onSuccessContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        l10n.accountSessionActive,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: semanticColors.onSuccessContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _AccountButtonSemantics(
          label: l10n.accountLogout,
          onTap: onLogout,
          child: OutlinedButton.icon(
            key: const ValueKey('account-logout-button'),
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                AppSizes.minimumTouchTarget,
                AppSizes.minimumTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: Text(l10n.accountLogout, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.bytes, required this.semanticLabel});

  static const _decodedDimension = 192;

  final Uint8List? bytes;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      colorScheme: Theme.of(context).colorScheme,
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ClipOval(
          child: SizedBox.square(
            dimension: AppSizes.accountAvatar,
            child: bytes == null
                ? fallback
                : Image.memory(
                    bytes!,
                    key: const ValueKey('account-avatar-image'),
                    fit: BoxFit.cover,
                    cacheWidth: _decodedDimension,
                    cacheHeight: _decodedDimension,
                    errorBuilder: (context, error, stackTrace) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('account-avatar-fallback'),
      color: colorScheme.secondaryContainer,
      child: Icon(
        Icons.person,
        size: AppSizes.iconEmphasis,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}

class _AccountButtonSemantics extends StatelessWidget {
  const _AccountButtonSemantics({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(child: child),
    );
  }
}

String _normalizedOrFallback(String? value, String fallback) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}
