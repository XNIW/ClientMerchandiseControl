import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/native_framework_notice.dart';

class _UnsafeException {
  @override
  String toString() => throw StateError('Non serializzare eccezioni grezze.');
}

void main() {
  test('nessuna notifica: oggetto esatto, nullo e immutabile', () {
    final recorder = NativeFrameworkNoticeRecorder();
    expect(recorder.snapshot, <String, Object?>{
      'status': 'not_observed',
      'origin': null,
      'category': null,
      'candidateAssignedAtNotice': null,
    });
    expect(() => recorder.snapshot['status'] = 'observed', throwsUnsupportedError);
  });

  final categories = <String, Object>{
    'testFailure': TestFailure('Fixture sintetica'),
    'filesystem': const FileSystemException('Fixture sintetica'),
    'flutterError': FlutterError('Fixture sintetica'),
    'assertionError': AssertionError('Fixture sintetica'),
    'other': _UnsafeException(),
  };
  for (final entry in categories.entries) {
    test('categoria finita ${entry.key}, delega identica una volta', () {
      final recorder = NativeFrameworkNoticeRecorder();
      final details = FlutterErrorDetails(exception: entry.value);
      var calls = 0;
      recorder.observeAndDelegate(
        details,
        candidateAssignedAtNotice: true,
        delegate: (value) {
          calls += 1;
          expect(identical(value, details), isTrue);
        },
      );
      expect(calls, 1);
      expect(recorder.snapshot, <String, Object?>{
        'status': 'observed',
        'origin': 'framework_notice',
        'category': entry.key,
        'candidateAssignedAtNotice': true,
      });
    });
  }

  test('prima notifica e candidato non vengono sovrascritti o aliasati', () {
    final recorder = NativeFrameworkNoticeRecorder();
    final before = recorder.snapshot;
    var calls = 0;
    void delegate(FlutterErrorDetails details) {
      calls += 1;
    }

    recorder.observeAndDelegate(
      FlutterErrorDetails(exception: TestFailure('Fixture sintetica')),
      candidateAssignedAtNotice: false,
      delegate: delegate,
    );
    final first = recorder.snapshot;
    recorder.observeAndDelegate(
      FlutterErrorDetails(exception: FlutterError('Altra fixture sintetica')),
      candidateAssignedAtNotice: true,
      delegate: delegate,
    );
    expect(calls, 2);
    expect(identical(first, recorder.snapshot), isTrue);
    expect(before['status'], 'not_observed');
    expect(first['category'], 'testFailure');
    expect(first['candidateAssignedAtNotice'], isFalse);
    expect(() => first['category'] = 'other', throwsUnsupportedError);
    final copy = Map<String, Object?>.of(first)..['category'] = 'other';
    expect(copy['category'], 'other');
    expect(first['category'], 'testFailure');
  });

  for (final observedBeforeClose in [false, true]) {
    test('chiusura idempotente, delega conservata: $observedBeforeClose', () {
      final recorder = NativeFrameworkNoticeRecorder();
      var calls = 0;
      void delegate(FlutterErrorDetails details) {
        calls += 1;
      }

      if (observedBeforeClose) {
        recorder.observeAndDelegate(
          FlutterErrorDetails(exception: TestFailure('Fixture sintetica')),
          candidateAssignedAtNotice: false,
          delegate: delegate,
        );
      }
      final before = recorder.snapshot;
      recorder.close();
      recorder.close();
      recorder.observeAndDelegate(
        FlutterErrorDetails(exception: _UnsafeException()),
        candidateAssignedAtNotice: true,
        delegate: delegate,
      );
      expect(calls, observedBeforeClose ? 2 : 1);
      expect(identical(before, recorder.snapshot), isTrue);
    });
  }

  for (final state in ['empty', 'full', 'closed']) {
    test('errore del delegate propagato identico: $state', () {
      final recorder = NativeFrameworkNoticeRecorder();
      if (state == 'full') {
        recorder.observeAndDelegate(
          FlutterErrorDetails(exception: TestFailure('Prima fixture')),
          candidateAssignedAtNotice: false,
          delegate: (_) {},
        );
      }
      if (state == 'closed') {
        recorder.close();
      }
      final details = FlutterErrorDetails(exception: _UnsafeException());
      final sentinel = Object();
      var calls = 0;
      expect(
        () => recorder.observeAndDelegate(
          details,
          candidateAssignedAtNotice: true,
          delegate: (value) {
            calls += 1;
            expect(identical(value, details), isTrue);
            throw sentinel;
          },
        ),
        throwsA(same(sentinel)),
      );
      expect(calls, 1);
      expect(
        recorder.snapshot['status'],
        state == 'closed' ? 'not_observed' : 'observed',
      );
    });
  }

  test('record privo di messaggio, stack, contesto e oggetti originali', () {
    final recorder = NativeFrameworkNoticeRecorder();
    final details = FlutterErrorDetails(
      exception: TestFailure('SYNTHETIC_RAW_MESSAGE'),
      stack: StackTrace.fromString('SYNTHETIC_RAW_STACK'),
      context: ErrorDescription('SYNTHETIC_RAW_CONTEXT'),
      library: 'SYNTHETIC_RAW_LIBRARY',
    );
    recorder.observeAndDelegate(
      details,
      candidateAssignedAtNotice: false,
      delegate: (_) {},
    );
    expect(recorder.snapshot.keys.toSet(), {
      'status',
      'origin',
      'category',
      'candidateAssignedAtNotice',
    });
    expect(jsonEncode(recorder.snapshot), isNot(contains('SYNTHETIC_RAW')));
  });
}
