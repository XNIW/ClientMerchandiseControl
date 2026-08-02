import 'dart:async';

import 'package:app_links/app_links.dart';

/// Confine tecnico per i callback OAuth consegnati dal sistema operativo.
///
/// Il source apre una sola subscription verso `app_links`, la apre prima di
/// chiedere il link iniziale e convoglia link cold e warm nello stesso stream
/// broadcast. Auth e Storefront condividono questa istanza e validano namespace
/// disgiunti prima di qualunque exchange o navigazione.
abstract interface class AuthCallbackSource {
  Stream<Uri> get callbacks;

  Future<void> dispose();
}

/// Porta minima che rende `app_links` verificabile senza canali nativi nei test.
abstract interface class AppLinksGateway {
  Future<Uri?> getInitialLink();

  Stream<Uri> get uriLinkStream;
}

final class PlatformAppLinksGateway implements AppLinksGateway {
  PlatformAppLinksGateway({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}

final class AppLinksAuthCallbackSource implements AuthCallbackSource {
  AppLinksAuthCallbackSource({AppLinksGateway? gateway})
    : _gateway = gateway ?? PlatformAppLinksGateway() {
    _controller = StreamController<Uri>.broadcast(onListen: _ensureStarted);
  }

  final AppLinksGateway _gateway;
  late final StreamController<Uri> _controller;

  StreamSubscription<Uri>? _warmSubscription;
  Future<void>? _startOperation;
  bool _disposed = false;

  @override
  Stream<Uri> get callbacks => _controller.stream;

  void _ensureStarted() {
    _startOperation ??= _start();
  }

  Future<void> _start() async {
    if (_disposed) {
      return;
    }

    _warmSubscription = _gateway.uriLinkStream.listen(
      _addCallback,
      onError: _addError,
    );

    try {
      final initialCallback = await _gateway.getInitialLink();
      if (initialCallback != null) {
        _addCallback(initialCallback);
      }
    } catch (error, stackTrace) {
      _addError(error, stackTrace);
    }
  }

  void _addCallback(Uri callback) {
    if (!_disposed) {
      _controller.add(callback);
    }
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      _controller.addError(error, stackTrace);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await _warmSubscription?.cancel();
    await _controller.close();
  }
}
