import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = AppConfig.allowedAuthRedirectUri;
  const stagingUrl = 'https://project.example.invalid';
  const stagingKey = 'sb_publishable_test_key';

  AppConfig stagingConfig() => AppConfig.fromValues(
    appEnvironment: 'staging',
    supabaseUrl: stagingUrl,
    supabasePublishableKey: stagingKey,
    authRedirectUri: callback,
    googleAuthEnabled: 'false',
    storefrontShopSlug: 'storefront-test',
  );

  test('espone tutti gli stati di readiness richiesti', () {
    expect(BackendReadinessState.values.map((state) => state.name), const [
      'unconfigured',
      'initializing',
      'ready',
      'offline',
      'misconfigured',
      'authenticationRequired',
      'recoverableError',
    ]);
  });

  test('development resta unconfigured senza health remoto', () async {
    final health = _FakeHealthService();
    final repository = SupabaseBackendReadinessRepository(
      config: AppConfig.fromValues(),
      healthService: health,
    );

    final state = await repository.check(
      cancellation: BackendProbeCancellation(),
    );

    expect(repository.initialState, BackendReadinessState.unconfigured);
    expect(repository.canCheck, isFalse);
    expect(state, BackendReadinessState.unconfigured);
    expect(health.calls, 0);
  });

  test('production resta misconfigured senza health remoto', () async {
    final health = _FakeHealthService();
    final repository = SupabaseBackendReadinessRepository(
      config: AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: 'https://production.example.invalid',
        supabasePublishableKey: 'sb_publishable_production',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
        storefrontShopSlug: 'storefront-test',
      ),
      healthService: health,
    );

    final state = await repository.check(
      cancellation: BackendProbeCancellation(),
    );

    expect(repository.initialState, BackendReadinessState.misconfigured);
    expect(repository.canCheck, isFalse);
    expect(state, BackendReadinessState.misconfigured);
    expect(health.calls, 0);
  });

  for (final testCase in const [
    (
      health: BackendHealthResult.healthy,
      readiness: BackendReadinessState.ready,
    ),
    (
      health: BackendHealthResult.offline,
      readiness: BackendReadinessState.offline,
    ),
    (
      health: BackendHealthResult.unauthorized,
      readiness: BackendReadinessState.misconfigured,
    ),
    (
      health: BackendHealthResult.notFound,
      readiness: BackendReadinessState.misconfigured,
    ),
    (
      health: BackendHealthResult.recoverableError,
      readiness: BackendReadinessState.recoverableError,
    ),
    (
      health: BackendHealthResult.invalidResponse,
      readiness: BackendReadinessState.recoverableError,
    ),
    (
      health: BackendHealthResult.cancelled,
      readiness: BackendReadinessState.recoverableError,
    ),
  ]) {
    test(
      'mappa ${testCase.health.name} in ${testCase.readiness.name}',
      () async {
        final health = _FakeHealthService(result: testCase.health);
        final repository = SupabaseBackendReadinessRepository(
          config: stagingConfig(),
          healthService: health,
        );

        final state = await repository.check(
          cancellation: BackendProbeCancellation(),
        );

        expect(state, testCase.readiness);
        expect(health.calls, 1);
        expect(health.receivedOrigin, Uri.parse(stagingUrl));
        expect(health.receivedPublishableKey, stagingKey);
      },
    );
  }

  test('ogni retry ripete il probe pubblico senza stato auth', () async {
    final health = _FakeHealthService();
    final repository = SupabaseBackendReadinessRepository(
      config: stagingConfig(),
      healthService: health,
    );

    await repository.check(cancellation: BackendProbeCancellation());
    await repository.check(cancellation: BackendProbeCancellation());

    expect(health.calls, 2);
  });

  test('cancellazione prima del check non chiama health', () async {
    final health = _FakeHealthService();
    final repository = SupabaseBackendReadinessRepository(
      config: stagingConfig(),
      healthService: health,
    );
    final cancellation = BackendProbeCancellation()..cancel();

    final state = await repository.check(cancellation: cancellation);

    expect(state, BackendReadinessState.recoverableError);
    expect(health.calls, 0);
  });
}

final class _FakeHealthService implements BackendHealthService {
  _FakeHealthService({this.result = BackendHealthResult.healthy});

  final BackendHealthResult result;
  var calls = 0;
  Uri? receivedOrigin;
  String? receivedPublishableKey;

  @override
  Future<BackendHealthResult> check({
    required Uri origin,
    required String publishableKey,
    required BackendProbeCancellation cancellation,
  }) async {
    calls += 1;
    receivedOrigin = origin;
    receivedPublishableKey = publishableKey;
    return result;
  }

  @override
  void close() {}
}
