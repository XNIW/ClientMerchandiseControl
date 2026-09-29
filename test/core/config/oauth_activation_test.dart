import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppConfig config({
    String host = 'login.storefront.example.org',
    String? redirect,
    String environment = 'staging',
  }) => AppConfig.fromValues(
    appEnvironment: environment,
    supabaseUrl: 'https://project.example.invalid',
    supabasePublishableKey: 'sb_publishable_test',
    storefrontShopSlug: 'storefront-test',
    googleAuthEnabled: 'true',
    authCallbackVerifiedHost: host,
    authRedirectUri: redirect ?? 'https://$host/auth-callback/',
  );
  test('config staging ordinaria abilita OAuth con host approvato esatto', () {
    final value = config();
    expect(value.googleAuthEnabled, isTrue);
    expect(
      value.authRedirectUri,
      'https://login.storefront.example.org/auth-callback/',
    );
    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(value)],
    );
    addTearDown(container.dispose);
    expect(
      container.read(authCallbackValidatorProvider).allowedHost,
      'login.storefront.example.org',
    );
  });
  test(
    'host assente, sentinel, wildcard, callback diversa o production restano chiusi',
    () {
      for (final host in [
        '',
        'clientmerchandisecontrol.invalid',
        '*.example.org',
        'a.test',
        'x.example.org/path',
        'a.example.org:443',
      ]) {
        expect(
          () => config(host: host),
          throwsA(isA<AppConfigurationException>()),
        );
      }
      for (final uri in [
        'http://login.storefront.example.org/auth-callback/',
        'https://other.example.org/auth-callback/',
        'https://login.storefront.example.org/auth-callback/?x=1',
        'https://login.storefront.example.org/auth-callback/#token',
        'https://login.storefront.example.org/',
      ]) {
        expect(
          () => config(redirect: uri),
          throwsA(isA<AppConfigurationException>()),
        );
      }
      expect(
        () => config(environment: 'production'),
        throwsA(isA<AppConfigurationException>()),
      );
    },
  );
}
