import 'dart:async';

import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sottoscrive warm prima del cold e usa un solo stream', () async {
    final gateway = _FakeAppLinksGateway();
    final source = AppLinksAuthCallbackSource(gateway: gateway);
    final received = <Uri>[];
    final subscription = source.callbacks.listen(received.add);

    final warm = Uri.parse('test.scheme://callback/?code=warm');
    final cold = Uri.parse('test.scheme://callback/?code=cold');
    gateway.emit(warm);
    gateway.completeInitial(cold);
    await Future<void>.delayed(Duration.zero);

    expect(received, [warm, cold]);
    expect(gateway.listenCount, 1);
    expect(gateway.initialCalls, 1);

    await subscription.cancel();
    await source.dispose();
  });

  test('più listener condividono una sola subscription nativa', () async {
    final gateway = _FakeAppLinksGateway()..completeInitial(null);
    final source = AppLinksAuthCallbackSource(gateway: gateway);
    final first = <Uri>[];
    final second = <Uri>[];
    final firstSubscription = source.callbacks.listen(first.add);
    final secondSubscription = source.callbacks.listen(second.add);

    final callback = Uri.parse('test.scheme://callback/?code=once');
    gateway.emit(callback);
    await Future<void>.delayed(Duration.zero);

    expect(first, [callback]);
    expect(second, [callback]);
    expect(gateway.listenCount, 1);

    await firstSubscription.cancel();
    await secondSubscription.cancel();
    await source.dispose();
  });

  test('dispose cancella il canale e ignora cold tardivo', () async {
    final gateway = _FakeAppLinksGateway();
    final source = AppLinksAuthCallbackSource(gateway: gateway);
    final received = <Uri>[];
    source.callbacks.listen(received.add);
    await Future<void>.delayed(Duration.zero);

    await source.dispose();
    gateway.completeInitial(Uri.parse('test.scheme://callback/?code=late'));
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
    expect(gateway.cancelCount, 1);
  });
}

final class _FakeAppLinksGateway implements AppLinksGateway {
  final Completer<Uri?> _initial = Completer<Uri?>();
  late final StreamController<Uri> _warm = StreamController<Uri>.broadcast(
    onListen: () => listenCount++,
    onCancel: () => cancelCount++,
  );

  int initialCalls = 0;
  int listenCount = 0;
  int cancelCount = 0;

  @override
  Future<Uri?> getInitialLink() {
    initialCalls++;
    return _initial.future;
  }

  @override
  Stream<Uri> get uriLinkStream => _warm.stream;

  void completeInitial(Uri? uri) {
    if (!_initial.isCompleted) {
      _initial.complete(uri);
    }
  }

  void emit(Uri uri) {
    _warm.add(uri);
  }
}
