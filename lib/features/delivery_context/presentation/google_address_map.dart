import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/customer_account_providers.dart';
import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_models.dart';

final class GoogleAddressMapPort implements DeliveryAddressMapPort {
  const GoogleAddressMapPort({
    required this.navigatorKey,
    required this.enabled,
  });
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  @override
  bool get configured => enabled;

  @override
  Future<DeliveryCoordinate> previewAndAdjust(
    DeliveryCoordinate initial,
  ) async {
    final context = navigatorKey.currentContext;
    if (!enabled ||
        context == null ||
        !initial.latitude.isFinite ||
        !initial.longitude.isFinite ||
        initial.latitude.abs() > 90 ||
        initial.longitude.abs() > 180) {
      throw const AddressProviderNotConfiguredException();
    }
    final result = await showModalBottomSheet<DeliveryCoordinate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressPinSheet(initial: initial),
    );
    if (result == null) throw const AddressMapCancelledException();
    return result;
  }
}

final class AddressMapCancelledException implements Exception {
  const AddressMapCancelledException();
}

class _AddressPinSheet extends ConsumerStatefulWidget {
  const _AddressPinSheet({required this.initial});
  final DeliveryCoordinate initial;
  @override
  ConsumerState<_AddressPinSheet> createState() => _AddressPinSheetState();
}

class _AddressPinSheetState extends ConsumerState<_AddressPinSheet> {
  late DeliveryCoordinate coordinate = widget.initial;
  bool ready = false;
  bool invalidated = false;
  @override
  Widget build(BuildContext context) {
    ref.listen(customerAccountIdentityProvider, (previous, next) {
      if (previous?.subjectId != next?.subjectId && !invalidated) {
        invalidated = true;
        Navigator.of(context).pop();
      }
    });
    final l10n = AppLocalizations.of(context);
    final point = LatLng(coordinate.latitude, coordinate.longitude);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.deliveryContextPinHint),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: point, zoom: 16),
              markers: {
                Marker(
                  markerId: const MarkerId('address'),
                  position: point,
                  draggable: true,
                  onDragEnd: _move,
                ),
              },
              onTap: _move,
              onMapCreated: (_) {
                if (mounted) setState(() => ready = true);
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              indoorViewEnabled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.customerDialogCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: ready && !invalidated
                      ? () => Navigator.of(context).pop(coordinate)
                      : null,
                  child: Text(l10n.customerDialogSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _move(LatLng point) {
    if (!mounted ||
        invalidated ||
        !point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      return;
    }
    setState(
      () => coordinate = DeliveryCoordinate(
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }
}
