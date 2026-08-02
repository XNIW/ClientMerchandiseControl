import '../config/app_config.dart';
import '../config/app_environment.dart';
import 'backend_health_service.dart';
import 'backend_readiness_state.dart';

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
  }) => SupabaseBackendReadinessRepository._(config, healthService);

  SupabaseBackendReadinessRepository._(this._config, this._healthService);

  final AppConfig _config;
  final BackendHealthService _healthService;

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
}
