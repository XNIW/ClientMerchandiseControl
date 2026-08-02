import 'dart:convert';

import 'package:http/http.dart' as http;

final class StorefrontRpcResponseException implements Exception {
  const StorefrontRpcResponseException({
    required this.statusCode,
    required this.code,
  });

  final int statusCode;
  final String code;
}

final class HttpStorefrontRpcInvoker {
  factory HttpStorefrontRpcInvoker({
    required Uri origin,
    required String publishableKey,
    required http.Client client,
  }) => HttpStorefrontRpcInvoker._(origin, publishableKey, client);

  HttpStorefrontRpcInvoker._(this._origin, this._publishableKey, this._client);

  static final _functionName = RegExp(r'^storefront_[a-z0-9_]+_v1$');
  static const _maximumResponseBytes = 2 * 1024 * 1024;

  final Uri _origin;
  final String _publishableKey;
  final http.Client _client;

  Future<Object?> call(String function, Map<String, Object?> parameters) async {
    if (!_functionName.hasMatch(function)) {
      throw const FormatException('invalid_storefront_rpc_function');
    }
    final response = await _client.post(
      _origin.resolve('/rest/v1/rpc/$function'),
      headers: {
        'accept': 'application/json',
        'apikey': _publishableKey,
        'authorization': 'Bearer $_publishableKey',
        'content-type': 'application/json',
      },
      body: jsonEncode(parameters),
    );
    if (response.bodyBytes.length > _maximumResponseBytes) {
      throw const FormatException('storefront_rpc_response_too_large');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StorefrontRpcResponseException(
        statusCode: response.statusCode,
        code: _errorCode(response.bodyBytes),
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _errorCode(List<int> bodyBytes) {
    try {
      final payload = jsonDecode(utf8.decode(bodyBytes));
      if (payload case {'code': final String code}) {
        return code.length <= 80 ? code : 'remote_error';
      }
    } on Object {
      // Error bodies are deliberately reduced to a non-sensitive code.
    }
    return 'remote_error';
  }
}
