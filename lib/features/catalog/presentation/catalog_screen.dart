import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../core/backend/backend_readiness_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'catalog_presentation_state.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref
        .watch(backendReadinessControllerProvider)
        .catalogPresentationState;
    final retry = ref.read(backendReadinessControllerProvider.notifier).retry;

    return StorefrontPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CatalogControls(l10n: l10n),
          const SizedBox(height: AppSpacing.xl),
          _CatalogStateSurface(state: state, l10n: l10n, onRetry: retry),
        ],
      ),
    );
  }
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              textField: true,
              enabled: false,
              label: l10n.catalogSearchLabel,
              hint: l10n.catalogSearchHint,
              child: ExcludeSemantics(
                child: SearchBar(
                  key: const ValueKey('catalog-search'),
                  enabled: false,
                  leading: const Icon(Icons.search),
                  hintText: l10n.catalogSearchHint,
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minimumTouchTarget,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _UnavailableControl(
                  key: const ValueKey('catalog-filter'),
                  icon: Icons.tune,
                  label: l10n.catalogFilterLabel,
                ),
                _UnavailableControl(
                  key: const ValueKey('catalog-sort'),
                  icon: Icons.swap_vert,
                  label: l10n.catalogSortLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.catalogControlsUnavailable,
              key: const ValueKey('catalog-controls-explanation'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableControl extends StatelessWidget {
  const _UnavailableControl({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minimumTouchTarget),
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _CatalogStateSurface extends StatelessWidget {
  const _CatalogStateSurface({
    required this.state,
    required this.l10n,
    required this.onRetry,
  });

  final CatalogPresentationState state;
  final AppLocalizations l10n;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final presentation = switch (state) {
      CatalogPresentationState.connecting => (
        key: 'catalog-connecting',
        icon: Icons.cloud_sync_outlined,
        title: l10n.catalogConnectingTitle,
        message: l10n.catalogConnectingMessage,
        retryable: false,
      ),
      CatalogPresentationState.empty => (
        key: 'catalog-empty',
        icon: Icons.inventory_2_outlined,
        title: l10n.catalogEmptyTitle,
        message: l10n.catalogEmptyMessage,
        retryable: false,
      ),
      CatalogPresentationState.offline => (
        key: 'catalog-offline',
        icon: Icons.cloud_off_outlined,
        title: l10n.catalogOfflineTitle,
        message: l10n.catalogOfflineMessage,
        retryable: true,
      ),
      CatalogPresentationState.unavailable => (
        key: 'catalog-unavailable',
        icon: Icons.cloud_queue_outlined,
        title: l10n.catalogUnavailableTitle,
        message: l10n.catalogUnavailableMessage,
        retryable: false,
      ),
      CatalogPresentationState.retry => (
        key: 'catalog-retry',
        icon: Icons.error_outline,
        title: l10n.catalogRetryTitle,
        message: l10n.catalogRetryMessage,
        retryable: true,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: state != CatalogPresentationState.empty,
      child: Card(
        key: ValueKey(presentation.key),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: state == CatalogPresentationState.connecting
                      ? const SizedBox.square(
                          dimension: AppSizes.iconEmphasis,
                          child: CircularProgressIndicator(
                            key: ValueKey('catalog-progress'),
                            strokeWidth: AppSizes.progressIndicatorStroke,
                          ),
                        )
                      : Icon(
                          presentation.icon,
                          size: AppSizes.iconEmphasis,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  presentation.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                presentation.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (presentation.retryable) ...[
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    key: const ValueKey('catalog-retry-action'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.backendRetry),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
