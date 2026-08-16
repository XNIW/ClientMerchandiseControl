import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  test('feature flag off fails closed without touching the provider', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: false,
        nativeConfigurationPresent: true,
      ),
      adapter: adapter,
    );

    final result = await presenter.present(trackingLiveSnapshot());

    expect(result, isA<DeliveryMapUnavailable>());
    expect(
      (result as DeliveryMapUnavailable).reason,
      DeliveryMapUnavailableReason.featureFlagOff,
    );
    expect(adapter.scenes, isEmpty);
  });

  test('missing native key configuration fails closed', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: true,
        nativeConfigurationPresent: false,
      ),
      adapter: adapter,
    );

    final result = await presenter.present(trackingLiveSnapshot());

    expect(
      (result as DeliveryMapUnavailable).reason,
      DeliveryMapUnavailableReason.missingNativeConfiguration,
    );
    expect(adapter.scenes, isEmpty);
  });

  test('fake adapter receives only the three bounded fresh markers', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: true,
        nativeConfigurationPresent: true,
      ),
      adapter: adapter,
    );

    final result = await presenter.present(trackingLiveSnapshot());

    expect(result, isA<DeliveryMapReady>());
    expect(adapter.scenes, hasLength(1));
    expect(adapter.scenes.single.snapshotVersion, 4);
    expect(adapter.scenes.single.store.latitude, -33.445);
    expect(adapter.scenes.single.destination.latitude, -33.447);
    expect(adapter.scenes.single.courier.latitude, -33.446);
  });

  test(
    'stale state and provider exception never produce a ready map',
    () async {
      final staleAdapter = FakeDeliveryMapAdapter();
      final stalePresenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: staleAdapter,
      );
      final stale = await stalePresenter.present(
        trackingLiveSnapshot(freshness: 'stale'),
      );
      expect(
        (stale as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.trackingUnavailable,
      );

      final failingAdapter = FakeDeliveryMapAdapter(
        renderException: StateError('synthetic_provider_failure'),
      );
      final failingPresenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: failingAdapter,
      );
      final failure = await failingPresenter.present(trackingLiveSnapshot());
      expect(
        (failure as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.providerException,
      );

      await failingPresenter.dispose();
      await failingPresenter.dispose();
      expect(failingAdapter.disposeCalls, 1);
      final disposed = await failingPresenter.present(trackingLiveSnapshot());
      expect(
        (disposed as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.disposed,
      );
    },
  );
}
