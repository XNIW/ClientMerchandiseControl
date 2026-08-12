import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile draft normalizza il nome e accetta soltanto le quattro locale',
    () {
      final draft = CustomerProfileDraft(
        displayName: '  María   Pérez  ',
        locale: 'es-CL',
      );
      expect(draft.displayName, 'María Pérez');
      expect(draft.locale, 'es-CL');

      for (final locale in customerAccountSupportedLocales) {
        expect(
          () => CustomerProfileDraft(displayName: null, locale: locale),
          returnsNormally,
        );
      }
      expect(
        () => CustomerProfileDraft(displayName: 'Cliente', locale: 'fr'),
        throwsA(isA<CustomerAccountInputException>()),
      );
    },
  );

  test(
    'address draft rifiuta controllo, oversize, postal e country malevoli',
    () {
      CustomerAddressDraft valid() => CustomerAddressDraft(
        label: ' Casa ',
        recipientName: ' Cliente Uno ',
        addressLine1: ' Avenida Uno 123 ',
        addressLine2: '',
        commune: ' Santiago ',
        region: ' Metropolitana ',
        postalCode: ' 8320000 ',
        countryCode: 'cl',
        deliveryInstructions: null,
      );

      final draft = valid();
      expect(draft.label, 'Casa');
      expect(draft.countryCode, 'CL');
      expect(draft.addressLine2, isNull);

      for (final invalid in <CustomerAddressDraft Function()>[
        () => CustomerAddressDraft(
          label: 'Casa\nAtaque',
          recipientName: 'Cliente',
          addressLine1: 'Calle 1',
          addressLine2: null,
          commune: 'Santiago',
          region: 'Metropolitana',
          postalCode: null,
          countryCode: 'CL',
          deliveryInstructions: null,
        ),
        () => CustomerAddressDraft(
          label: List.filled(41, 'x').join(),
          recipientName: 'Cliente',
          addressLine1: 'Calle 1',
          addressLine2: null,
          commune: 'Santiago',
          region: 'Metropolitana',
          postalCode: null,
          countryCode: 'CL',
          deliveryInstructions: null,
        ),
        () => CustomerAddressDraft(
          label: 'Casa',
          recipientName: 'Cliente',
          addressLine1: 'Calle 1',
          addressLine2: null,
          commune: 'Santiago',
          region: 'Metropolitana',
          postalCode: '../8320000',
          countryCode: 'CL',
          deliveryInstructions: null,
        ),
        () => CustomerAddressDraft(
          label: 'Casa',
          recipientName: 'Cliente',
          addressLine1: 'Calle 1',
          addressLine2: null,
          commune: 'Santiago',
          region: 'Metropolitana',
          postalCode: null,
          countryCode: 'CHL',
          deliveryInstructions: null,
        ),
      ]) {
        expect(invalid, throwsA(isA<CustomerAccountInputException>()));
      }
    },
  );

  test('export accetta solo il contratto allow-listed customer.v1', () {
    final valid = <String, Object?>{
      'apiVersion': 'customer.v1',
      'generatedAt': '2026-08-02T18:00:00Z',
      'profile': {
        'userId': testOwnerId,
        'displayName': 'Cliente Uno',
        'locale': 'es-CL',
        'privacyConsentVersion': 'privacy-2026.08',
        'privacyConsentedAt': '2026-08-02T18:00:00Z',
        'createdAt': '2026-08-02T18:00:00Z',
        'updatedAt': '2026-08-02T18:00:00Z',
      },
      'addresses': [_validExportAddress(1)],
      'accountDeletionRequests': [
        {
          'requestId': '23000000-0000-4000-8000-000000000001',
          'status': 'requested',
          'requestedAt': '2026-08-02T18:00:00Z',
          'cancelledAt': null,
          'processedAt': null,
          'updatedAt': '2026-08-02T18:00:00Z',
        },
      ],
    };
    expect(
      CustomerDataExport.fromUntrusted(valid).json,
      contains('customer.v1'),
    );

    for (final invalid in <Map<String, Object?>>[
      {...valid, 'email': 'owner@example.invalid'},
      {...valid, 'internalMetadata': const <String, Object?>{}},
      {
        ...valid,
        'generatedAt': {'unexpected': 'nested'},
      },
      {
        ...valid,
        'profile': {
          ...(valid['profile']! as Map<String, Object?>),
          'displayName': {'unexpected': 'nested'},
        },
      },
      {
        ...valid,
        'addresses': [
          {
            'id': testAddressId,
            'label': 'Casa',
            'recipientName': 'Cliente',
            'addressLine1': 'Calle 1',
            'addressLine2': null,
            'commune': 'Santiago',
            'region': 'Metropolitana',
            'postalCode': null,
            'countryCode': 'CL',
            'deliveryInstructions': null,
            'isDefault': true,
            'createdAt': '2026-08-02T18:00:00Z',
            'updatedAt': '2026-08-02T18:00:00Z',
            'sourceProductId': 'internal',
          },
        ],
      },
    ]) {
      expect(
        () => CustomerDataExport.fromUntrusted(invalid),
        throwsFormatException,
      );
    }
  });

  test('model value, draft e lifecycle restano deterministici', () {
    final updatedAt = DateTime.utc(2026, 8, 2, 18);
    final profile = CustomerProfile(
      userId: testOwnerId,
      displayName: 'Cliente Uno',
      locale: 'it',
      privacyConsentVersion: 'privacy-2026.08',
      privacyConsentedAt: updatedAt,
      updatedAt: updatedAt,
    );
    final sameProfile = CustomerProfile(
      userId: testOwnerId,
      displayName: 'Cliente Uno',
      locale: 'it',
      privacyConsentVersion: 'privacy-2026.08',
      privacyConsentedAt: updatedAt,
      updatedAt: updatedAt,
    );
    expect(profile, sameProfile);
    expect(profile.hashCode, sameProfile.hashCode);
    expect(profile.hasPrivacyConsent, isTrue);
    expect(profile == Object(), isFalse);

    final address = CustomerAddress(
      id: testAddressId,
      label: 'Casa',
      recipientName: 'Cliente Uno',
      addressLine1: 'Avenida Uno 123',
      addressLine2: 'Depto 2',
      commune: 'Santiago',
      region: 'Metropolitana',
      postalCode: '8320000',
      countryCode: 'CL',
      deliveryInstructions: 'Conserjería',
      isDefault: true,
      updatedAt: updatedAt,
    );
    final draft = address.toDraft();
    expect(draft.label, 'Casa');
    expect(draft.addressLine2, 'Depto 2');
    expect(draft.deliveryInstructions, 'Conserjería');
    expect(address, address);
    expect(address.hashCode, address.hashCode);

    final requested = CustomerDeletionRequest(
      id: testAddressId,
      status: 'requested',
      requestedAt: updatedAt,
      cancelledAt: null,
      processedAt: null,
    );
    final processing = CustomerDeletionRequest(
      id: testAddressId,
      status: 'processing',
      requestedAt: updatedAt,
      cancelledAt: null,
      processedAt: null,
    );
    expect(requested.isActive, isTrue);
    expect(requested.canCancel, isTrue);
    expect(processing.isActive, isTrue);
    expect(processing.canCancel, isFalse);

    final sourceAddresses = [address];
    final snapshot = CustomerAccountSnapshot(
      profile: profile,
      addresses: sourceAddresses,
      deletionRequest: requested,
      loadedAt: updatedAt,
    );
    sourceAddresses.clear();
    expect(snapshot.addresses, hasLength(1));
    expect(() => snapshot.addresses.clear(), throwsUnsupportedError);
  });

  test('export applica limite dimensionale e shape esatta delle liste', () {
    final oversized = <String, Object?>{
      'apiVersion': 'customer.v1',
      'generatedAt': '2026-08-02T18:00:00Z',
      'profile': null,
      'addresses': List<Object?>.generate(
        600,
        (index) => _validExportAddress(
          index,
          instructions: List.filled(500, 'x').join(),
        ),
      ),
      'accountDeletionRequests': <Object?>[],
    };
    expect(
      () => CustomerDataExport.fromUntrusted(oversized),
      throwsFormatException,
    );
    expect(
      () => CustomerDataExport.fromUntrusted({
        'apiVersion': 'customer.v1',
        'generatedAt': '2026-08-02T18:00:00Z',
        'profile': null,
        'addresses': 'not-a-list',
        'accountDeletionRequests': <Object?>[],
      }),
      throwsFormatException,
    );
  });
}

const testAddressId = '21000000-0000-4000-8000-000000000001';
const testOwnerId = '00000000-0000-4000-8000-000000021001';

Map<String, Object?> _validExportAddress(int index, {String? instructions}) {
  return {
    'id': '22000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
    'label': 'Casa',
    'recipientName': 'Cliente Uno',
    'addressLine1': 'Avenida Uno 123',
    'addressLine2': null,
    'commune': 'Santiago',
    'region': 'Metropolitana',
    'postalCode': '8320000',
    'countryCode': 'CL',
    'deliveryInstructions': instructions,
    'isDefault': index == 1,
    'createdAt': '2026-08-02T18:00:00Z',
    'updatedAt': '2026-08-02T18:00:00Z',
  };
}
