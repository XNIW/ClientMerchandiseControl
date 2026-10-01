import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_models.dart';

/// Solo endpoint HTTPS esplicitamente approvati; nessun servizio pubblico implicito.
final class AddressProviderConfiguration {
  const AddressProviderConfiguration._(this.endpoint);
  final Uri? endpoint;

  factory AddressProviderConfiguration.fromValues({
    String enabled = '',
    String endpoint = '',
    String approved = '',
    String environment = 'staging',
  }) {
    if (environment != 'staging' || enabled != 'true' || approved != 'true') {
      return const AddressProviderConfiguration._(null);
    }
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.host == 'localhost' ||
        uri.host.endsWith('.invalid')) {
      return const AddressProviderConfiguration._(null);
    }
    return AddressProviderConfiguration._(uri);
  }

  factory AddressProviderConfiguration.fromEnvironment() =>
      AddressProviderConfiguration.fromValues(
        environment: const String.fromEnvironment('APP_ENV'),
        enabled: const String.fromEnvironment('ADDRESS_SEARCH_ENABLED'),
        endpoint: const String.fromEnvironment('ADDRESS_PHOTON_ORIGIN'),
        approved: const String.fromEnvironment('ADDRESS_PROVIDER_APPROVED'),
      );
}

/// Photon GeoJSON. Nessun token, identità, log o cache persistente; una sola pagina
/// di suggerimenti è conservata in memoria fino alla query successiva/dispose.
final class PhotonAddressProvider
    implements AddressSearchPort, ReverseGeocodingPort {
  PhotonAddressProvider({
    required this.configuration,
    required this.client,
    this.timeout = const Duration(seconds: 6),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final AddressProviderConfiguration configuration;
  final http.Client client;
  final Duration timeout;
  final DateTime Function() clock;
  final Map<String, ReverseGeocodedAddress> _results = {};
  int _generation = 0;
  bool _disposed = false;
  DateTime? _retryAfter;

  @override
  bool get configured => !_disposed && configuration.endpoint != null;

  void dispose() {
    _disposed = true;
    _generation++;
    _results.clear();
    client.close();
  }

  @override
  Future<List<AddressSearchSuggestion>> search(String query) async {
    final generation = ++_generation;
    _results.clear();
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.runes.length < 3 || normalized.runes.length > 160) {
      return const [];
    }
    final features = await _request('/api', {'q': normalized, 'limit': '8'});
    if (!configured || generation != _generation) return const [];
    final suggestions = <AddressSearchSuggestion>[];
    for (final feature in features.take(8)) {
      final address = _address(feature);
      if (address == null) continue;
      final id = '$generation:${suggestions.length}';
      _results[id] = address;
      suggestions.add(
        AddressSearchSuggestion(
          displayText: [
            address.addressLine1,
            address.commune,
            address.region,
          ].where((s) => s.isNotEmpty).join(', '),
          providerPlaceId: id,
        ),
      );
    }
    return List.unmodifiable(suggestions);
  }

  @override
  Future<ReverseGeocodedAddress?> resolve(
    AddressSearchSuggestion suggestion,
  ) async {
    if (!configured) throw const AddressProviderNotConfiguredException();
    return _results[suggestion.providerPlaceId];
  }

  @override
  Future<ReverseGeocodedAddress?> reverse(DeliveryCoordinate coordinate) async {
    if (!_validCoordinate(coordinate.longitude, coordinate.latitude)) {
      return null;
    }
    final features = await _request('/reverse', {
      'lat': coordinate.latitude.toStringAsFixed(5),
      'lon': coordinate.longitude.toStringAsFixed(5),
      'limit': '1',
    });
    if (!configured || features.isEmpty) return null;
    final address = _address(features.first);
    if (address == null) return null;
    return ReverseGeocodedAddress(
      addressLine1: address.addressLine1,
      commune: address.commune,
      region: address.region,
      postalCode: address.postalCode,
      countryCode: address.countryCode,
      coordinate: coordinate,
    );
  }

  Future<List<Object?>> _request(String path, Map<String, String> query) async {
    if (!configured) throw const AddressProviderNotConfiguredException();
    if (_retryAfter case final retry? when clock().isBefore(retry)) {
      throw const AddressProviderUnavailableException();
    }
    try {
      final request =
          http.Request(
              'GET',
              configuration.endpoint!.replace(
                path: path,
                queryParameters: query,
              ),
            )
            ..followRedirects = false
            ..headers['Accept'] = 'application/json';
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode == 429) {
        final seconds =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        _retryAfter = clock().add(Duration(seconds: seconds.clamp(1, 300)));
      }
      if (response.statusCode != 200) {
        throw const AddressProviderUnavailableException();
      }
      final bytes = <int>[];
      await response.stream
          .forEach((chunk) {
            if (bytes.length + chunk.length > 65536) {
              throw const AddressProviderUnavailableException();
            }
            bytes.addAll(chunk);
          })
          .timeout(timeout);
      final body = jsonDecode(utf8.decode(bytes));
      if (body is! Map<String, dynamic> || body['features'] is! List) {
        throw const AddressProviderUnavailableException();
      }
      return body['features'] as List<Object?>;
    } on Object {
      // Non propagare URL, query, coordinate, body o errori del transport.
      throw const AddressProviderUnavailableException();
    }
  }

  static ReverseGeocodedAddress? _address(Object? feature) {
    if (feature is! Map<String, dynamic>) return null;
    final props = feature['properties'];
    final geometry = feature['geometry'];
    if (props is! Map<String, dynamic> ||
        geometry is! Map<String, dynamic> ||
        geometry['type'] != 'Point') {
      return null;
    }
    final xy = geometry['coordinates'];
    if (xy is! List || xy.length != 2 || xy[0] is! num || xy[1] is! num) {
      return null;
    }
    final lon = (xy[0] as num).toDouble();
    final lat = (xy[1] as num).toDouble();
    if (!_validCoordinate(lon, lat)) return null;
    String field(String name) {
      final value = props[name];
      return value is String &&
              value.runes.length <= 160 &&
              !RegExp(r'[\x00-\x1f]').hasMatch(value)
          ? value.trim()
          : '';
    }

    final street = field('street').isEmpty ? field('name') : field('street');
    final country = field('countrycode').toUpperCase();
    if (street.isEmpty || !RegExp(r'^[A-Z]{2}$').hasMatch(country)) return null;
    return ReverseGeocodedAddress(
      addressLine1: [
        street,
        field('housenumber'),
      ].where((s) => s.isNotEmpty).join(' '),
      commune: field('city').isEmpty ? field('district') : field('city'),
      region: field('state'),
      postalCode: field('postcode').isEmpty ? null : field('postcode'),
      countryCode: country,
      coordinate: DeliveryCoordinate(latitude: lat, longitude: lon),
    );
  }

  static bool _validCoordinate(double lon, double lat) =>
      lon.isFinite &&
      lat.isFinite &&
      lon >= -180 &&
      lon <= 180 &&
      lat >= -90 &&
      lat <= 90;
}

final class AddressProviderUnavailableException implements Exception {
  const AddressProviderUnavailableException();
}
