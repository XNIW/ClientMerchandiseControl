import '../config/app_config.dart';
import '../config/app_environment.dart';
import 'backend_health_service.dart';
import 'backend_readiness_state.dart';
import 'supabase_bootstrap.dart';

typedef BackendSdkInitializer =
    Future<BackendReadinessState> Function(AppConfig config);

abstract interface class BackendReadinessRepository {
  BackendReadinessState get initialState;

  bool get canCheck;

  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  });
}

final class SupabaseBackendReadinessRepository
    implements BackendReadinessRepository {
  factory SupabaseBackendReadinessRepository({
    required AppConfig config,
    required BackendHealthService healthService,
    BackendSdkInitializer sdkInitializer = SupabaseBootstrap.initialize,
  }) => SupabaseBackendReadinessRepository._(
    config,
    healthService,
    sdkInitializer,
  );

  SupabaseBackendReadinessRepository._(
    this._config,
    this._healthService,
    this._sdkInitializer,
  );

  final AppConfig _config;
  final BackendHealthService _healthService;
  final BackendSdkInitializer _sdkInitializer;

  Future<BackendReadinessState>? _initialization;

  @override
  BackendReadinessState get initialState => switch (_config.environment) {
    AppEnvironment.development => BackendReadinessState.unconfigured,
    AppEnvironment.staging => BackendReadinessState.initializing,
    AppEnvironment.production => BackendReadinessState.misconfigured,
  };

  @override
  bool get canCheck =>
      _config.environment == AppEnvironment.staging &&
      _config.isBackendConfigured;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async {
    if (!canCheck) {
      return initialState;
    }
    if (cancellation.isCancelled) {
      return BackendReadinessState.recoverableError;
    }

    try {
      await (_initialization ??= _initializeSdk());
    } on Object {
      _initialization = null;
      return BackendReadinessState.recoverableError;
    }

    if (cancellation.isCancelled) {
      return BackendReadinessState.recoverableError;
    }

    final health = await _healthService.check(
      origin: Uri.parse(_config.supabaseUrl!),
      publishableKey: _config.supabasePublishableKey!,
      cancellation: cancellation,
    );

    return switch (health) {
      BackendHealthResult.healthy => BackendReadinessState.ready,
      BackendHealthResult.offline => BackendReadinessState.offline,
      BackendHealthResult.unauthorized ||
      BackendHealthResult.notFound => BackendReadinessState.misconfigured,
      BackendHealthResult.recoverableError ||
      BackendHealthResult.invalidResponse =>
        BackendReadinessState.recoverableError,
      BackendHealthResult.cancelled => BackendReadinessState.recoverableError,
    };
  }

  Future<BackendReadinessState> _initializeSdk() async {
    final state = await _sdkInitializer(_config);
    if (state != BackendReadinessState.initializing) {
      throw StateError('Bootstrap staging non inizializzato.');
    }
    return state;
  }
}
