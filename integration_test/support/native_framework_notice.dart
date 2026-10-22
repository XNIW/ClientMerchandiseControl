// Diagnostica della sola fixture: non decide l'esito del test nativo.
import 'dart:io' show FileSystemException;

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter_test/flutter_test.dart' show TestFailure;

enum _NoticeCategory {
  testFailure,
  filesystem,
  flutterError,
  assertionError,
  other,
}

class NativeFrameworkNoticeRecorder {
  static const _notObserved = <String, Object?>{
    'status': 'not_observed',
    'origin': null,
    'category': null,
    'candidateAssignedAtNotice': null,
  };

  Map<String, Object?>? _firstNotice;
  bool _closed = false;

  Map<String, Object?> get snapshot => _firstNotice ?? _notObserved;

  void close() {
    _closed = true;
  }

  void observeAndDelegate(
    FlutterErrorDetails details, {
    required bool candidateAssignedAtNotice,
    required void Function(FlutterErrorDetails) delegate,
  }) {
    if (!_closed && _firstNotice == null) {
      final error = details.exception;
      // FlutterError implementa AssertionError: il caso specifico viene prima.
      final category = error is TestFailure
          ? _NoticeCategory.testFailure
          : error is FileSystemException
          ? _NoticeCategory.filesystem
          : error is FlutterError
          ? _NoticeCategory.flutterError
          : error is AssertionError
          ? _NoticeCategory.assertionError
          : _NoticeCategory.other;
      _firstNotice = Map<String, Object?>.unmodifiable({
        'status': 'observed',
        'origin': 'framework_notice',
        'category': category.name,
        'candidateAssignedAtNotice': candidateAssignedAtNotice,
      });
    }
    // Anche con latch pieno/chiuso: stessa chiamata e stessa propagazione SDK.
    delegate(details);
  }
}
