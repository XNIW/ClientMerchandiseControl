import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/domain/auth_state.dart';
import '../../customer_devices/presentation/customer_notification_panel.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'account_presentation_model.dart';
import 'customer_account_panel.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return switch (authState) {
      AuthGuest(:final canAuthenticate, :final notice) => AccountView.guest(
        onContinueWithGoogle: canAuthenticate
            ? controller.startGoogleSignIn
            : null,
        onBrowseAsGuest: () => context.go(AppRoutes.homeLocation),
        notice: notice == null ? null : _failureMessage(l10n, notice),
      ),
      AuthAuthenticating() => AccountView.status(
        title: l10n.accountSigningInTitle,
        message: l10n.accountSigningInMessage,
        isProgress: true,
        secondaryLabel: l10n.accountCancelSignIn,
        onSecondary: controller.cancelGoogleSignIn,
      ),
      AuthCancelling() => AccountView.status(
        title: l10n.accountCancellingTitle,
        message: l10n.accountCancellingMessage,
        isProgress: true,
      ),
      AuthCancelled() => AccountView.status(
        title: l10n.accountCancelledTitle,
        message: l10n.accountCancelledMessage,
        primaryLabel: l10n.accountRetry,
        onPrimary: controller.retry,
      ),
      AuthAuthenticated(:final customer) => AccountView.authenticated(
        model: _presentationModel(customer),
        onLogout: controller.signOut,
        details: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerAccountPanel(authDisplayName: customer.displayName),
            const CustomerNotificationPanel(),
          ],
        ),
      ),
      AuthSigningOut(:final customer) => AccountView.authenticated(
        model: _presentationModel(customer),
        onLogout: null,
        isSigningOut: true,
      ),
      AuthRecoverableError(:final failure) => AccountView.status(
        title: l10n.accountAuthErrorTitle,
        message: _failureMessage(l10n, failure),
        primaryLabel: failure.canRetry ? l10n.accountRetry : null,
        onPrimary: failure.canRetry ? controller.retry : null,
      ),
      AuthConfigurationError(:final failure) => AccountView.status(
        title: l10n.accountConfigurationErrorTitle,
        message: _failureMessage(l10n, failure),
      ),
    };
  }

  static AuthenticatedAccountPresentationModel _presentationModel(
    AuthenticatedCustomer customer,
  ) {
    return AuthenticatedAccountPresentationModel(
      displayName: customer.displayName,
      email: customer.email,
    );
  }
}

sealed class AccountView extends StatelessWidget {
  const AccountView._({super.key});

  const factory AccountView.guest({
    Key? key,
    VoidCallback? onContinueWithGoogle,
    VoidCallback? onBrowseAsGuest,
    String? notice,
  }) = _GuestAccountView;

  const factory AccountView.authenticated({
    Key? key,
    required AuthenticatedAccountPresentationModel model,
    required VoidCallback? onLogout,
    bool isSigningOut,
    Widget? details,
  }) = _AuthenticatedAccountView;

  const factory AccountView.status({
    Key? key,
    required String title,
    required String message,
    bool isProgress,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) = _AuthStatusAccountView;
}

final class _GuestAccountView extends AccountView {
  const _GuestAccountView({
    super.key,
    this.onContinueWithGoogle,
    this.onBrowseAsGuest,
    this.notice,
  }) : super._();

  final VoidCallback? onContinueWithGoogle;
  final VoidCallback? onBrowseAsGuest;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return _AccountSurface(
      child: _GuestAccountContent(
        onContinueWithGoogle: onContinueWithGoogle,
        onBrowseAsGuest: onBrowseAsGuest,
        notice: notice,
      ),
    );
  }
}

final class _AuthenticatedAccountView extends AccountView {
  const _AuthenticatedAccountView({
    required this.model,
    required this.onLogout,
    this.isSigningOut = false,
    this.details,
    super.key,
  }) : super._();

  final AuthenticatedAccountPresentationModel model;
  final VoidCallback? onLogout;
  final bool isSigningOut;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    return _AccountSurface(
      child: _AuthenticatedAccountContent(
        model: model,
        onLogout: onLogout,
        isSigningOut: isSigningOut,
        details: details,
      ),
    );
  }
}

final class _AuthStatusAccountView extends AccountView {
  const _AuthStatusAccountView({
    required this.title,
    required this.message,
    this.isProgress = false,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  }) : super._();

  final String title;
  final String message;
  final bool isProgress;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _AccountSurface(
      child: _AuthStatusContent(
        title: title,
        message: message,
        isProgress: isProgress,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
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
    required this.notice,
  });

  final VoidCallback? onContinueWithGoogle;
  final VoidCallback? onBrowseAsGuest;
  final String? notice;

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
        if (notice != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            liveRegion: true,
            label: notice,
            child: ExcludeSemantics(
              child: Text(
                notice!,
                key: const ValueKey('account-auth-notice'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
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
    required this.isSigningOut,
    required this.details,
  });

  final AuthenticatedAccountPresentationModel model;
  final VoidCallback? onLogout;
  final bool isSigningOut;
  final Widget? details;

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
          label: isSigningOut ? l10n.accountSigningOut : l10n.accountLogout,
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
            icon: isSigningOut
                ? const SizedBox.square(
                    dimension: AppSizes.iconStandard,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(
              isSigningOut ? l10n.accountSigningOut : l10n.accountLogout,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        ?details,
      ],
    );
  }
}

class _AuthStatusContent extends StatelessWidget {
  const _AuthStatusContent({
    required this.title,
    required this.message,
    required this.isProgress,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String message;
  final bool isProgress;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('account-auth-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          liveRegion: true,
          label: '$title. $message',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isProgress) ...[
                  const Align(
                    child: SizedBox.square(
                      key: ValueKey('account-auth-progress'),
                      dimension: AppSizes.guestAvatar,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  Icon(
                    Icons.info_outline,
                    size: AppSizes.iconEmphasis,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  title,
                  key: const ValueKey('account-auth-status-title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  key: const ValueKey('account-auth-status-message'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        if (primaryLabel != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: const ValueKey('account-auth-primary'),
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                AppSizes.minimumTouchTarget,
                AppSizes.minimumTouchTarget,
              ),
            ),
            child: Text(primaryLabel!, textAlign: TextAlign.center),
          ),
        ],
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            key: const ValueKey('account-auth-secondary'),
            onPressed: onSecondary,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                AppSizes.minimumTouchTarget,
                AppSizes.minimumTouchTarget,
              ),
            ),
            child: Text(secondaryLabel!, textAlign: TextAlign.center),
          ),
        ],
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

String _failureMessage(AppLocalizations l10n, AuthFailure failure) {
  return switch (failure.kind) {
    AuthFailureKind.offline => l10n.accountAuthOffline,
    AuthFailureKind.cancelled => l10n.accountCancelledMessage,
    AuthFailureKind.providerUnavailable => l10n.accountAuthProviderUnavailable,
    AuthFailureKind.browserLaunchFailed => l10n.accountAuthBrowserLaunchFailed,
    AuthFailureKind.invalidCallback ||
    AuthFailureKind.callbackAlreadyConsumed => l10n.accountAuthInvalidCallback,
    AuthFailureKind.sessionExpired => l10n.accountAuthSessionExpired,
    AuthFailureKind.secureStorageUnavailable =>
      l10n.accountAuthSecureStorageUnavailable,
    AuthFailureKind.configuration => l10n.accountAuthConfiguration,
    AuthFailureKind.unexpected => l10n.accountAuthUnexpected,
  };
}
