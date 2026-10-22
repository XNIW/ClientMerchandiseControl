import 'dart:convert';

import 'customer_account_models.dart';

/// Una sola creazione non riconciliata per account. Lo shop limita la UI, non
/// l'identità server: gli indirizzi appartengono globalmente all'account.
final class AddressCreationIntent {
  const AddressCreationIntent({required this.id, required this.draft});

  final String id;
  final CustomerAddressDraft draft;

  bool matches(CustomerAddressDraft other) =>
      jsonEncode(addressDraftPayload(draft)) ==
      jsonEncode(addressDraftPayload(other));
}

abstract interface class AddressCreationJournal {
  Future<AddressCreationIntent?> read(String owner);
  Future<void> write(String owner, AddressCreationIntent intent);
  Future<void> clear(String owner);
}

Map<String, Object?> addressDraftPayload(CustomerAddressDraft draft) => {
  'label': draft.label,
  'recipientName': draft.recipientName,
  'recipientPhoneE164': draft.recipientPhoneE164,
  'addressLine1': draft.addressLine1,
  'addressLine2': draft.addressLine2,
  'commune': draft.commune,
  'region': draft.region,
  'postalCode': draft.postalCode,
  'countryCode': draft.countryCode,
  'deliveryInstructions': draft.deliveryInstructions,
  'latitude': draft.latitude,
  'longitude': draft.longitude,
  'locationSource': switch (draft.locationSource) {
    CustomerAddressLocationSource.currentLocation => 'current_location',
    CustomerAddressLocationSource.mapPin => 'map_pin',
    _ => draft.locationSource.name,
  },
  'locationAccuracyMeters': draft.locationAccuracyMeters,
  'isDefault': draft.isDefault,
};

CustomerAddressDraft addressDraftFromPayload(Map<String, dynamic> payload) =>
    CustomerAddressDraft(
      label: payload['label'] as String,
      recipientName: payload['recipientName'] as String,
      recipientPhoneE164: payload['recipientPhoneE164'] as String?,
      addressLine1: payload['addressLine1'] as String,
      addressLine2: payload['addressLine2'] as String?,
      commune: payload['commune'] as String,
      region: payload['region'] as String,
      postalCode: payload['postalCode'] as String?,
      countryCode: payload['countryCode'] as String,
      deliveryInstructions: payload['deliveryInstructions'] as String?,
      latitude: (payload['latitude'] as num?)?.toDouble(),
      longitude: (payload['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters: (payload['locationAccuracyMeters'] as num?)
          ?.toDouble(),
      locationSource: switch (payload['locationSource']) {
        'manual' => CustomerAddressLocationSource.manual,
        'search' => CustomerAddressLocationSource.search,
        'current_location' => CustomerAddressLocationSource.currentLocation,
        'map_pin' => CustomerAddressLocationSource.mapPin,
        _ => throw const FormatException('address_intent_source'),
      },
      isDefault: payload['isDefault'] as bool,
    );
