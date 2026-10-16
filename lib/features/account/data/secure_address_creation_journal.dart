import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/address_creation_intent.dart';

/// Bozza cifrata e limitata. Nessuna scadenza automatica: perdere un intent
/// ancora ambiguo permetterebbe una seconda creazione. Si rimuove solo all'ACK
/// oppure dopo un rifiuto definitivo. Nessun contenuto viene scritto nei log.
final class SecureAddressCreationJournal implements AddressCreationJournal {
  SecureAddressCreationJournal({
    FlutterSecureStorage? storage,
    Future<void> Function()? flush,
  }) : _flush = flush ?? const AddressCreationDurabilityBarrier().flush,
       _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(
               resetOnError: false,
               migrateOnAlgorithmChange: true,
               migrateWithBackup: false,
               keyCipherAlgorithm:
                   KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
               storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
               storageNamespace: 'cmc_address_creation_v1',
             ),
             iOptions: IOSOptions(
               accountName:
                   'com.xniw.clientmerchandisecontrol.address-creation.v1',
               accessibility: KeychainAccessibility.first_unlock_this_device,
               synchronizable: false,
             ),
           );

  final FlutterSecureStorage _storage;
  final Future<void> Function() _flush;
  static const maximumBytes = 16384;

  // Il plugin può registrare la chiave in caso di errore: nessun owner raw.
  String _key(String owner) =>
      'cmc.address-creation.v1.${sha256.convert(utf8.encode('cmc.address-creation.v1:$owner'))}';

  @override
  Future<AddressCreationIntent?> read(String owner) async {
    final encoded = await _storage.read(key: _key(owner));
    if (encoded == null) return null;
    // Corruzione/storage indisponibile falliscono chiusi: mai cancellare il
    // journal per poi inviare alla cieca una creazione con nuova identità.
    if (utf8.encode(encoded).length > maximumBytes) {
      throw const FormatException('address_intent_size');
    }
    final root = jsonDecode(encoded) as Map<String, dynamic>;
    if (root['version'] != 1 || root['owner'] != owner) {
      throw const FormatException('address_intent_owner');
    }
    final id = root['id'] as String;
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id)) {
      throw const FormatException('address_intent_id');
    }
    return AddressCreationIntent(
      id: id,
      draft: addressDraftFromPayload(root['draft'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> write(String owner, AddressCreationIntent intent) async {
    final encoded = jsonEncode({
      'version': 1,
      'owner': owner,
      'id': intent.id,
      'draft': addressDraftPayload(intent.draft),
    });
    if (utf8.encode(encoded).length > maximumBytes) {
      throw const FormatException('address_intent_size');
    }
    await _storage.write(key: _key(owner), value: encoded);
    await _flush();
  }

  @override
  Future<void> clear(String owner) async {
    await _storage.delete(key: _key(owner));
    await _flush();
  }
}

/// SharedPreferences.apply del plugin aggiorna la memoria prima del disco.
/// Android deve confermare commit; errori, timeout e canale assente falliscono
/// chiusi. Keychain su iOS completa già la scrittura prima del risultato.
final class AddressCreationDurabilityBarrier {
  const AddressCreationDurabilityBarrier({
    this.android,
    this.timeout = const Duration(seconds: 5),
  });

  final bool? android;
  final Duration timeout;
  static const channel = MethodChannel(
    'com.xniw.clientmerchandisecontrol/address_creation_durability',
  );

  Future<void> flush() async {
    if (!(android ?? Platform.isAndroid)) return;
    final persisted = await channel
        .invokeMethod<bool>('flush')
        .timeout(timeout);
    if (persisted != true) {
      throw const FormatException('address_intent_not_durable');
    }
  }
}
