import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:client_merchandise_control/features/account/data/secure_address_creation_journal.dart';
import 'package:client_merchandise_control/features/account/domain/address_creation_intent.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_account_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('write attende barriera durevole e propaga il mancato flush', () async {
    final barrier = Completer<void>();
    var flushStarted = false;
    final journal = SecureAddressCreationJournal(
      flush: () async {
        flushStarted = true;
        await barrier.future;
      },
    );
    var complete = false;
    final write = journal.write(
      testCustomerSubject,
      AddressCreationIntent(
        id: testAddressId,
        draft: testCustomerAddress().toDraft(),
      ),
    );
    unawaited(write.then((_) => complete = true, onError: (_) {}));
    await Future<void>.delayed(Duration.zero);
    expect(flushStarted, isTrue);
    expect(complete, isFalse);
    expect(await journal.read(testCustomerSubject), isNotNull);
    barrier.completeError(const FormatException('disk_failure'));
    await expectLater(write, throwsFormatException);
    expect(complete, isFalse);
  });

  for (final result in [true, false, null]) {
    test('barriera Android accetta soltanto commit true: $result', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        AddressCreationDurabilityBarrier.channel,
        (call) async {
          expect(call.method, 'flush');
          expect(call.arguments, isNull);
          return result;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AddressCreationDurabilityBarrier.channel,
          null,
        ),
      );
      final flush = const AddressCreationDurabilityBarrier(
        android: true,
      ).flush();
      if (result == true) {
        await flush;
      } else {
        await expectLater(flush, throwsFormatException);
      }
    });
  }

  test('canale Android assente o in errore non conferma persistenza', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      AddressCreationDurabilityBarrier.channel,
      null,
    );
    await expectLater(
      const AddressCreationDurabilityBarrier(android: true).flush(),
      throwsA(isA<MissingPluginException>()),
    );
    messenger.setMockMethodCallHandler(
      AddressCreationDurabilityBarrier.channel,
      (_) async {
        throw PlatformException(code: 'disk_failed');
      },
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        AddressCreationDurabilityBarrier.channel,
        null,
      ),
    );
    await expectLater(
      const AddressCreationDurabilityBarrier(android: true).flush(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('timeout del commit non diventa un permesso di inviare', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final pending = Completer<bool>();
    messenger.setMockMethodCallHandler(
      AddressCreationDurabilityBarrier.channel,
      (_) => pending.future,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        AddressCreationDurabilityBarrier.channel,
        null,
      ),
    );
    await expectLater(
      const AddressCreationDurabilityBarrier(
        android: true,
        timeout: Duration(milliseconds: 5),
      ).flush(),
      throwsA(isA<TimeoutException>()),
    );
    pending.complete(true);
  });

  test(
    'journal cifrato riaperto conserva intent e bozza soltanto per owner',
    () async {
      final first = SecureAddressCreationJournal();
      final intent = AddressCreationIntent(
        id: testAddressId,
        draft: testCustomerAddress().toDraft(),
      );
      await first.write(testCustomerSubject, intent);
      final restarted = SecureAddressCreationJournal();
      final restored = await restarted.read(testCustomerSubject);
      expect(restored?.id, intent.id);
      expect(restored?.matches(intent.draft), isTrue);
      expect(await restarted.read('other-owner'), isNull);
      await restarted.clear('other-owner');
      expect(await restarted.read(testCustomerSubject), isNotNull);
      await restarted.clear(testCustomerSubject);
      expect(await restarted.read(testCustomerSubject), isNull);
    },
  );

  test('journal corrotto fallisce chiuso senza perdere identità', () async {
    final journal = SecureAddressCreationJournal();
    await journal.write(
      testCustomerSubject,
      AddressCreationIntent(
        id: testAddressId,
        draft: testCustomerAddress().toDraft(),
      ),
    );
    final key = (await const FlutterSecureStorage().readAll()).keys.single;
    expect(key, isNot(contains(testCustomerSubject)));
    FlutterSecureStorage.setMockInitialValues({
      key: jsonEncode({'version': 2}),
    });
    await expectLater(journal.read(testCustomerSubject), throwsFormatException);
    expect(await const FlutterSecureStorage().read(key: key), isNotNull);
  });
}
