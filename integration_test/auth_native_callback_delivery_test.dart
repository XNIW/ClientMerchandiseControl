import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app_links consegna un callback warm canonico al validator', (
    tester,
  ) async {
    final source = AppLinksAuthCallbackSource();
    addTearDown(source.dispose);
    final callbackFuture = source.callbacks.first.timeout(
      const Duration(seconds: 30),
    );

    final callback = await callbackFuture;
    final canonical = Uri.parse(AppConfig.allowedAuthRedirectUri);
    final validation = AuthCallbackValidator(
      allowedScheme: canonical.scheme,
      allowedHost: canonical.host,
      allowedPath: canonical.path,
    ).validate(callback);

    expect(validation, isA<AuthCallbackAccepted>());
    expect(tester.takeException(), isNull);
    binding.reportData = <String, Object?>{
      'nativeWarmDelivery': 'PASS',
      'canonicalValidation': 'PASS',
      'exchangeAttempted': 'false',
      'processAlive': 'PASS',
    };
  });
}
