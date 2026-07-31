enum BackendReadinessState {
  unconfigured,
  initializing,
  ready,
  offline,
  misconfigured,
  authenticationRequired,
  recoverableError,
}

extension BackendReadinessStatePresentation on BackendReadinessState {
  bool get canRetry =>
      this == BackendReadinessState.offline ||
      this == BackendReadinessState.recoverableError;
}
