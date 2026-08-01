import '../../../core/backend/backend_readiness_state.dart';

enum CatalogPresentationState { connecting, empty, offline, unavailable, retry }

extension CatalogPresentationStateFromBackend on BackendReadinessState {
  CatalogPresentationState get catalogPresentationState => switch (this) {
    BackendReadinessState.unconfigured ||
    BackendReadinessState.ready => CatalogPresentationState.empty,
    BackendReadinessState.initializing => CatalogPresentationState.connecting,
    BackendReadinessState.offline => CatalogPresentationState.offline,
    BackendReadinessState.misconfigured ||
    BackendReadinessState.authenticationRequired =>
      CatalogPresentationState.unavailable,
    BackendReadinessState.recoverableError => CatalogPresentationState.retry,
  };
}
