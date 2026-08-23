final class CustomerReorderAttempt {
  CustomerReorderAttempt(this._createKey);

  final String Function() _createKey;
  String? _pendingKey;

  String begin() => _pendingKey ??= _createKey();

  void complete(String key) {
    if (_pendingKey == key) _pendingKey = null;
  }
}
