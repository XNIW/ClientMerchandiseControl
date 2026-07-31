import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_presentation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mappa ogni readiness nel solo stato Catalogo autorizzato', () {
    expect(
      {
        for (final state in BackendReadinessState.values)
          state: state.catalogPresentationState,
      },
      {
        BackendReadinessState.unconfigured: CatalogPresentationState.empty,
        BackendReadinessState.initializing: CatalogPresentationState.connecting,
        BackendReadinessState.ready: CatalogPresentationState.empty,
        BackendReadinessState.offline: CatalogPresentationState.offline,
        BackendReadinessState.misconfigured:
            CatalogPresentationState.unavailable,
        BackendReadinessState.authenticationRequired:
            CatalogPresentationState.unavailable,
        BackendReadinessState.recoverableError: CatalogPresentationState.retry,
      },
    );
  });
}
