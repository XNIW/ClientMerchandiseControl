import 'google_address_map.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/customer_account_controller.dart';
import '../../account/domain/customer_account_failure.dart';
import '../../account/domain/customer_account_models.dart';
import '../../account/presentation/customer_account_panel.dart';
import '../../checkout/application/checkout_providers.dart';
import '../../checkout/domain/checkout_models.dart';
import '../application/delivery_context_controller.dart';
import '../application/delivery_context_providers.dart';
import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_models.dart';

class DeliveryContextScreen extends ConsumerStatefulWidget {
  const DeliveryContextScreen({super.key});

  @override
  ConsumerState<DeliveryContextScreen> createState() =>
      _DeliveryContextScreenState();
}

class _DeliveryContextScreenState extends ConsumerState<DeliveryContextScreen> {
  final _guestCommune = TextEditingController();
  final _search = TextEditingController();
  Timer? _searchDebounce;
  Future<StorefrontFulfillmentOptions>? _options;
  List<AddressSearchSuggestion> _suggestions = const [];
  bool _searching = false;
  int _scopeGeneration = 0;
  int _searchGeneration = 0;
  bool _resolvingAddress = false;
  CustomerDeliveryContext? _displayedContext;
  CustomerDeliveryMode _mode = CustomerDeliveryMode.delivery;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadOptions);
  }

  @override
  void dispose() {
    _scopeGeneration++;
    _searchGeneration++;
    _searchDebounce?.cancel();
    _guestCommune.dispose();
    _search.dispose();
    super.dispose();
  }

  void _loadOptions() {
    final shopSlug = ref.read(deliveryContextShopSlugProvider);
    if (shopSlug == null || !mounted) return;
    setState(() {
      _options = ref
          .read(checkoutRepositoryProvider)
          .loadOptions(shopSlug: shopSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryContextControllerProvider);
    final account = ref.watch(customerAccountControllerProvider);
    final selected = state.context;
    ref.listen(deliveryContextIdentityProvider, (previous, next) {
      if (previous?.subjectId != next?.subjectId) {
        _resetScope();
        _loadOptions();
      }
    });
    ref.listen(deliveryContextShopSlugProvider, (previous, next) {
      if (previous != next) {
        _resetScope();
        _loadOptions();
      }
    });
    if (!identical(selected, _displayedContext)) {
      _displayedContext = selected;
      if (selected != null) _mode = selected.mode;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deliveryContextTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SegmentedButton<CustomerDeliveryMode>(
              direction: MediaQuery.textScalerOf(context).scale(14) >= 21
                  ? Axis.vertical
                  : Axis.horizontal,
              segments: [
                ButtonSegment(
                  value: CustomerDeliveryMode.delivery,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(l10n.deliveryContextDelivery),
                ),
                ButtonSegment(
                  value: CustomerDeliveryMode.pickup,
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(l10n.deliveryContextPickup),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: state.isMutating
                  ? null
                  : (selection) => setState(() => _mode = selection.single),
            ),
            if (state.status == DeliveryContextViewStatus.offline) ...[
              const SizedBox(height: AppSpacing.md),
              _StatusBanner(
                icon: Icons.cloud_off_outlined,
                message: l10n.deliveryContextOffline,
                actionLabel: l10n.deliveryContextRetry,
                onAction: ref
                    .read(deliveryContextControllerProvider.notifier)
                    .refresh,
              ),
            ],
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _CurrentContextCard(contextValue: selected),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (account.failure != null)
              Padding(
                key: const ValueKey('delivery-account-failure'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _StatusBanner(
                  icon: Icons.error_outline,
                  message: _accountFailureMessage(l10n, account.failure!),
                ),
              ),
            if (_mode == CustomerDeliveryMode.delivery)
              _deliverySections(state, account.snapshot?.addresses ?? const [])
            else
              _pickupSection(state),
            if (state.isMutating) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                label: l10n.customerAccountLoading,
                child: const LinearProgressIndicator(),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _deliverySections(
    DeliveryContextState state,
    List<CustomerAddress> addresses,
  ) {
    final l10n = AppLocalizations.of(context);
    final searchPort = ref.watch(addressSearchPortProvider);
    final authenticated = state.authenticated;
    final recent = addresses
        .where((address) => address.lastSelectedAt != null)
        .take(3)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          key: const ValueKey('delivery-use-current-location'),
          onPressed: state.isMutating || _resolvingAddress
              ? null
              : _useCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.deliveryContextUseLocation),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.deliveryContextManualFallback,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.deliveryContextSearch,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!searchPort.configured)
          _StatusBanner(
            icon: Icons.search_off_outlined,
            message: l10n.deliveryContextSearchUnavailable,
          )
        else ...[
          SearchBar(
            key: const ValueKey('delivery-address-search'),
            controller: _search,
            hintText: l10n.deliveryContextSearchHint,
            leading: const Icon(Icons.search),
            trailing: _searching
                ? const [
                    SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ]
                : null,
            onChanged: _searchAddresses,
          ),
          Text(l10n.deliveryAddressAttribution),
          ..._suggestions.map(
            (suggestion) => ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(suggestion.displayText),
              onTap: _resolvingAddress
                  ? null
                  : () => _resolveSuggestion(suggestion),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (!authenticated) ...[
          TextField(
            key: const ValueKey('delivery-guest-commune'),
            controller: _guestCommune,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.deliveryContextGuestCommune,
            ),
          ),
          FilledButton(
            onPressed: state.isMutating
                ? null
                : () => ref
                      .read(deliveryContextControllerProvider.notifier)
                      .selectGuestCommune(commune: _guestCommune.text.trim()),
            child: Text(l10n.deliveryContextCheckArea),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.deliveryContextSignInToSave),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.deliveryContextSaved,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('delivery-address-add'),
                tooltip: l10n.deliveryContextAdd,
                onPressed: state.isMutating ? null : _addAddress,
                icon: const Icon(Icons.add_location_alt_outlined),
              ),
            ],
          ),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(l10n.customerAddressesEmptyMessage),
            )
          else
            ...addresses.map(
              (address) => _AddressChoiceTile(
                address: address,
                selected: state.context?.addressId == address.id,
                busy: state.isMutating,
                onSelect: () => ref
                    .read(deliveryContextControllerProvider.notifier)
                    .selectAddress(addressId: address.id),
                onEdit: () => _editAddress(address),
              ),
            ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.deliveryContextRecent,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: recent
                  .map(
                    (address) => ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(address.label),
                      onPressed: state.isMutating
                          ? null
                          : () => ref
                                .read(
                                  deliveryContextControllerProvider.notifier,
                                )
                                .selectAddress(addressId: address.id),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ],
    );
  }

  Widget _pickupSection(DeliveryContextState state) {
    final l10n = AppLocalizations.of(context);
    final options = _options;
    if (options == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<StorefrontFulfillmentOptions>(
      future: options,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final points = snapshot.data?.pickupPoints ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deliveryContextPickupPoints,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (points.isEmpty)
              Text(l10n.deliveryContextTemporarilyUnavailable)
            else
              ...points.map((point) {
                final select = FilledButton.tonal(
                  onPressed: state.isMutating
                      ? null
                      : () => ref
                            .read(deliveryContextControllerProvider.notifier)
                            .selectPickup(pickupPointId: point.id),
                  child: Text(
                    state.context?.pickupPointId == point.id
                        ? l10n.deliveryContextSelected
                        : l10n.deliveryContextSelect,
                  ),
                );
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) >= 21;
                final details = ListTile(
                  minVerticalPadding: AppSpacing.sm,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(point.name),
                  subtitle: Text(
                    '${point.addressLine1}\n${point.commune}, ${point.region}',
                  ),
                  isThreeLine: true,
                  trailing: largeText
                      ? null
                      : SizedBox(width: 116, child: select),
                );
                return Card(
                  child: largeText
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            details,
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: select,
                            ),
                          ],
                        )
                      : details,
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_resolvingAddress) return;
    final generation = _scopeGeneration;
    setState(() => _resolvingAddress = true);
    try {
      final l10n = AppLocalizations.of(context);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deliveryContextLocationRationaleTitle),
          content: Text(l10n.deliveryContextLocationRationale),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.customerDialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deliveryContextLocationContinue),
            ),
          ],
        ),
      );
      if (accepted != true || !_currentScope(generation)) return;
      try {
        final locationPort = ref.read(currentLocationPortProvider);
        if (!locationPort.configured) {
          _showLocationFallback();
          return;
        }
        final location = await locationPort.readOnce();
        if (!_currentScope(generation)) return;
        if (location == null) {
          _showLocationFallback();
          return;
        }
        final mapPort = ref.read(deliveryAddressMapPortProvider);
        if (!mapPort.configured &&
            (location.accuracyMeters == null ||
                location.accuracyMeters! > 250)) {
          _showLocationFallback();
          return;
        }
        final adjusted = mapPort.configured
            ? await mapPort.previewAndAdjust(location)
            : location;
        if (!_currentScope(generation)) return;
        final geocoder = ref.read(reverseGeocodingPortProvider);
        final resolved = geocoder.configured
            ? await geocoder
                  .reverse(adjusted)
                  .timeout(const Duration(seconds: 8))
            : null;
        if (!_currentScope(generation)) return;
        if (resolved == null) {
          _showLocationFallback();
          return;
        }
        await _saveResolvedAddress(
          resolved,
          mapPort.configured
              ? CustomerAddressLocationSource.mapPin
              : CustomerAddressLocationSource.currentLocation,
        );
      } on AddressMapCancelledException {
        return;
      } on AddressProviderNotConfiguredException {
        if (_currentScope(generation)) _showLocationFallback();
      } on Object {
        if (_currentScope(generation)) _showLocationFallback();
      }
    } finally {
      if (_currentScope(generation)) setState(() => _resolvingAddress = false);
    }
  }

  bool _currentScope(int generation) =>
      mounted && generation == _scopeGeneration;

  void _resetScope() {
    _scopeGeneration++;
    _searchGeneration++;
    _searchDebounce?.cancel();
    _search.clear();
    _guestCommune.clear();
    setState(() {
      _suggestions = const [];
      _searching = false;
      _resolvingAddress = false;
      _displayedContext = null;
      _mode = CustomerDeliveryMode.delivery;
      _options = null;
    });
  }

  void _searchAddresses(String value) {
    _searchDebounce?.cancel();
    final generationQuery = value.trim();
    final request = ++_searchGeneration;
    final scope = _scopeGeneration;
    setState(() {
      _searching = false;
      _suggestions = const [];
    });
    if (generationQuery.length < 3) {
      setState(() => _suggestions = const []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!_currentScope(scope) || request != _searchGeneration) return;
      setState(() => _searching = true);
      try {
        final results = await ref
            .read(addressSearchPortProvider)
            .search(generationQuery)
            .timeout(const Duration(seconds: 8));
        if (_currentScope(scope) && request == _searchGeneration) {
          setState(() => _suggestions = results.take(8).toList());
        }
      } on Object {
        if (_currentScope(scope) && request == _searchGeneration) {
          setState(() => _suggestions = const []);
        }
      } finally {
        if (_currentScope(scope) && request == _searchGeneration) {
          setState(() => _searching = false);
        }
      }
    });
  }

  Future<void> _resolveSuggestion(AddressSearchSuggestion suggestion) async {
    if (_resolvingAddress) return;
    final generation = _scopeGeneration;
    setState(() => _resolvingAddress = true);
    try {
      final resolved = await ref
          .read(addressSearchPortProvider)
          .resolve(suggestion)
          .timeout(const Duration(seconds: 8));
      if (resolved != null && _currentScope(generation)) {
        await _saveResolvedAddress(
          resolved,
          CustomerAddressLocationSource.search,
        );
      }
    } on Object {
      if (_currentScope(generation)) _showLocationFallback();
    } finally {
      if (_currentScope(generation)) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _saveResolvedAddress(
    ReverseGeocodedAddress resolved,
    CustomerAddressLocationSource source,
  ) async {
    if (!ref.read(deliveryContextControllerProvider).authenticated) {
      await ref
          .read(deliveryContextControllerProvider.notifier)
          .selectGuestCommune(commune: resolved.commune);
      return;
    }
    await _showAddressEditor(
      initial: CustomerAddressEditorInitial(
        label: AppLocalizations.of(context).deliveryContextDelivery,
        recipientName: '',
        addressLine1: resolved.addressLine1,
        addressLine2: null,
        commune: resolved.commune,
        region: resolved.region,
        postalCode: resolved.postalCode,
        countryCode: resolved.countryCode,
        deliveryInstructions: null,
        latitude: resolved.coordinate.latitude,
        longitude: resolved.coordinate.longitude,
        locationSource: source,
        locationAccuracyMeters: resolved.coordinate.accuracyMeters,
      ),
    );
  }

  Future<void> _addAddress() => _showAddressEditor();

  Future<void> _editAddress(CustomerAddress address) =>
      _showAddressEditor(address: address);

  Future<void> _showAddressEditor({
    CustomerAddress? address,
    CustomerAddressEditorInitial? initial,
  }) async {
    final generation = _scopeGeneration;
    final owner = ref.read(deliveryContextIdentityProvider)?.subjectId;
    final shop = ref.read(deliveryContextShopSlugProvider);
    bool current() =>
        _currentScope(generation) &&
        ref.read(deliveryContextIdentityProvider)?.subjectId == owner &&
        ref.read(deliveryContextShopSlugProvider) == shop;
    CustomerAddress? created;
    final saved = await showCustomerAddressEditor(
      context,
      address: address,
      initial: initial,
      onSave: (draft) async {
        const unavailable = CustomerAccountFailure(
          CustomerAccountFailureKind.unexpected,
        );
        if (!current()) return unavailable;
        final before = ref.read(customerAccountControllerProvider);
        if (before.isMutating || before.snapshot == null) return unavailable;
        final account = ref.read(customerAccountControllerProvider.notifier);
        final bool acknowledged;
        if (address == null) {
          created = await account.createAddress(draft);
          acknowledged = created != null;
        } else {
          acknowledged = await account.updateAddress(
            address.id,
            address.version,
            draft,
          );
        }
        // Un ACK owner-bound chiude l'editor anche se lo shop è cambiato.
        // Selezione e refresh successivi restano vincolati allo scope originale.
        if (acknowledged) return null;
        if (!current()) return unavailable;
        return ref.read(customerAccountControllerProvider).failure ??
            unavailable;
      },
    );
    if (saved == null || !current()) return;
    if (created case final createdAddress?) {
      await ref
          .read(deliveryContextControllerProvider.notifier)
          .selectAddress(addressId: createdAddress.id);
    } else if (address != null &&
        ref.read(deliveryContextControllerProvider).context?.addressId ==
            address.id) {
      await ref.read(deliveryContextControllerProvider.notifier).refresh();
    }
  }

  void _showLocationFallback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).deliveryContextLocationUnavailable,
        ),
      ),
    );
  }
}

String _accountFailureMessage(
  AppLocalizations l10n,
  CustomerAccountFailure failure,
) => switch (failure.kind) {
  CustomerAccountFailureKind.offline => l10n.customerAccountOffline,
  CustomerAccountFailureKind.unauthorized => l10n.customerAccountUnauthorized,
  CustomerAccountFailureKind.invalidInput => l10n.customerAccountInvalid,
  CustomerAccountFailureKind.conflict => l10n.customerAccountConflict,
  CustomerAccountFailureKind.timeout => l10n.customerAccountTimeout,
  CustomerAccountFailureKind.unavailable => l10n.customerAccountUnavailable,
  CustomerAccountFailureKind.unexpected => l10n.customerAccountUnexpected,
};

class _CurrentContextCard extends StatelessWidget {
  const _CurrentContextCard({required this.contextValue});

  final CustomerDeliveryContext contextValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fee = contextValue.estimatedFeeClp;
    final slotStart = contextValue.earliestSlotStartsAt;
    final slotEnd = contextValue.earliestSlotEndsAt;
    final status = switch (contextValue.serviceabilityStatus) {
      DeliveryServiceabilityStatus.serviceable =>
        l10n.deliveryContextServiceable,
      DeliveryServiceabilityStatus.unsupported =>
        l10n.deliveryContextUnsupported,
      DeliveryServiceabilityStatus.invalid => l10n.deliveryContextInvalid,
      DeliveryServiceabilityStatus.temporarilyUnavailable =>
        l10n.deliveryContextTemporarilyUnavailable,
    };
    final formatter = ClpCurrencyFormatter();
    final slot = slotStart == null || slotEnd == null
        ? null
        : '${MaterialLocalizations.of(context).formatShortDate(slotStart.toLocal())} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(slotStart.toLocal()))}'
              '–${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(slotEnd.toLocal()))}';
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deliveryContextCurrent,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    contextValue.isCheckoutReady
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(status)),
                ],
              ),
              if (fee != null)
                Text(l10n.deliveryContextEstimatedFee(formatter.format(fee))),
              if (slot != null) Text(l10n.deliveryContextEarliestSlot(slot)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressChoiceTile extends StatelessWidget {
  const _AddressChoiceTile({
    required this.address,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onEdit,
  });

  final CustomerAddress address;
  final bool selected;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.location_on_outlined,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${address.label} · ${address.commune}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(address.addressLine1),
                      if (address.recipientPhoneE164 != null)
                        Text(_maskedPhone(address.recipientPhoneE164!)),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: AppSizes.minimumTouchTarget,
                    height: AppSizes.minimumTouchTarget,
                  ),
                  tooltip: l10n.customerAddressEdit,
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : onSelect,
                  child: Text(
                    selected
                        ? l10n.deliveryContextSelected
                        : l10n.deliveryContextSelect,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _maskedPhone(String value) {
  final suffix = value.length <= 4 ? value : value.substring(value.length - 4);
  return '•••• $suffix';
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
            if (onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
          ],
        ),
      ),
    );
  }
}
