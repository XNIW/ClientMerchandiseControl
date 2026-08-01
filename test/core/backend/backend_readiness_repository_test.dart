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

  test('development resta unconfigured senza SDK o health', () async {
    final health = _FakeHealthService();
    var initializationCalls = 0;
    final repository = SupabaseBackendReadinessRepository(
      config: AppConfig.fromValues(),
      healthService: health,
      sdkInitializer: (config) async {
        initializationCalls += 1;
        return BackendReadinessState.initializing;
      },
    );

    final state = await repository.check(
      cancellation: BackendProbeCancellation(),
    );

    expect(repository.initialState, BackendReadinessState.unconfigured);
    expect(repository.canCheck, isFalse);
    expect(state, BackendReadinessState.unconfigured);
    expect(initializationCalls, 0);
    expect(health.calls, 0);
  });

  test('production resta misconfigured senza SDK o health', () async {
    final health = _FakeHealthService();
    var initializationCalls = 0;
    final repository = SupabaseBackendReadinessRepository(
      config: AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: 'https://production.example.invalid',
        supabasePublishableKey: 'sb_publishable_production',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
      ),
      healthService: health,
      sdkInitializer: (config) async {
        initializationCalls += 1;
        return BackendReadinessState.initializing;
      },
    );

    final state = await repository.check(
      cancellation: BackendProbeCancellation(),
    );

    expect(repository.initialState, BackendReadinessState.misconfigured);
    expect(repository.canCheck, isFalse);
    expect(state, BackendReadinessState.misconfigured);
    expect(initializationCalls, 0);
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
        var initializationCalls = 0;
        final repository = SupabaseBackendReadinessRepository(
          config: stagingConfig(),
          healthService: health,
          sdkInitializer: (config) async {
            initializationCalls += 1;
            return BackendReadinessState.initializing;
          },
        );

        final state = await repository.check(
          cancellation: BackendProbeCancellation(),
        );

        expect(state, testCase.readiness);
        expect(initializationCalls, 1);
        expect(health.calls, 1);
        expect(health.receivedOrigin, Uri.parse(stagingUrl));
        expect(health.receivedPublishableKey, stagingKey);
      },
    );
  }

  test('inizializza SDK una sola volta tra retry sequenziali', () async {
    final health = _FakeHealthService();
    var initializationCalls = 0;
    final repository = SupabaseBackendReadinessRepository(
      config: stagingConfig(),
      healthService: health,
      sdkInitializer: (config) async {
        initializationCalls += 1;
        return BackendReadinessState.initializing;
      },
    );

    await repository.check(cancellation: BackendProbeCancellation());
    await repository.check(cancellation: BackendProbeCancellation());

    expect(initializationCalls, 1);
    expect(health.calls, 2);
  });

  test('errore SDK è recuperabile, sanitizzato e non chiama health', () async {
    final health = _FakeHealthService();
    final repository = SupabaseBackendReadinessRepository(
      config: stagingConfig(),
      healthService: health,
      sdkInitializer: (config) async {
        throw StateError('$stagingUrl $stagingKey');
      },
    );

    final state = await repository.check(
      cancellation: BackendProbeCancellation(),
    );

    expect(state, BackendReadinessState.recoverableError);
    expect(state.toString(), isNot(contains(stagingUrl)));
    expect(state.toString(), isNot(contains(stagingKey)));
    expect(health.calls, 0);
  });

  test('cancellazione prima del check non inizializza SDK o health', () async {
    final health = _FakeHealthService();
    var initializationCalls = 0;
    final repository = SupabaseBackendReadinessRepository(
      config: stagingConfig(),
      healthService: health,
      sdkInitializer: (config) async {
        initializationCalls += 1;
        return BackendReadinessState.initializing;
      },
    );
    final cancellation = BackendProbeCancellation()..cancel();

    final state = await repository.check(cancellation: cancellation);

    expect(state, BackendReadinessState.recoverableError);
    expect(initializationCalls, 0);
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
