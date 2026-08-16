import 'dart:convert';

import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';
import 'package:client_merchandise_control/core/observability/telemetry_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final instant = DateTime.utc(2026, 8, 16, 12);

  group('TelemetryRedactor', () {
    test('redige le classi PII e secret riconoscibili centralmente', () {
      const redactor = TelemetryRedactor();
      const forbidden = [
        'person@example.com',
        'Bearer header.payload.signature',
        'access_token=secret-token',
        'oauth_code:oauth-secret',
        'payment_secret=payment-secret',
        'push_token=push-secret',
        'service_role=service-secret',
        'https://carrier.example.test/track/private',
        '123e4567-e89b-12d3-a456-426614174000',
        '-33.448900,-70.669300',
        '+56 9 1234 5678',
      ];
      final output = redactor.redact(forbidden.join(' | '));

      for (final value in forbidden) {
        expect(output, isNot(contains(value)));
      }
      expect(output, contains('[REDACTED_EMAIL]'));
      expect(output, contains('[REDACTED_AUTH]'));
      expect(output, contains('[REDACTED_SECRET]'));
      expect(output, contains('[REDACTED_URL]'));
      expect(output, contains('[REDACTED_UUID]'));
      expect(output, contains('[REDACTED_COORDINATES]'));
      expect(output, contains('[REDACTED_PHONE]'));
    });

    test('serialization è bounded e sostituisce oggetti non supportati', () {
      const serializer = CrashSafeTelemetrySerializer(
        redactor: TelemetryRedactor(maximumLength: 256),
      );
      final output = serializer.serialize({
        'safe': 'x' * 400,
        'unsupported': Object(),
      });

      expect(output.length, lessThanOrEqualTo(267));
      expect(output, contains('[TRUNCATED]'));
    });
  });

  group('event catalog bounded', () {
    test(
      'ogni evento espone solo nome, ambiente, tempo e attributi allowlisted',
      () {
        final events = <ObservabilityEvent>[
          ObservabilityEvent.appStart(
            occurredAt: instant,
            kind: AppStartKind.cold,
          ),
          ObservabilityEvent.screenView(
            occurredAt: instant,
            screen: AppScreen.catalog,
          ),
          ObservabilityEvent.catalogQueryResult(
            occurredAt: instant,
            kind: CatalogQueryKind.search,
            outcome: ObservabilityOutcome.success,
            resultCount: ResultCountBucket.elevenToFifty,
            cache: CacheDisposition.none,
            duration: DurationBucket.under500ms,
          ),
          ObservabilityEvent.addToCartOutcome(
            occurredAt: instant,
            outcome: ObservabilityOutcome.success,
            quantity: QuantityBucket.one,
          ),
          ObservabilityEvent.checkoutStep(
            occurredAt: instant,
            step: CheckoutTelemetryStep.payment,
            outcome: ObservabilityOutcome.pending,
          ),
          ObservabilityEvent.orderCreated(
            occurredAt: instant,
            outcome: ObservabilityOutcome.success,
          ),
          ObservabilityEvent.orderStatus(
            occurredAt: instant,
            status: OrderStatusGroup.processing,
            source: OrderStatusSource.refresh,
          ),
          ObservabilityEvent.notificationRouting(
            occurredAt: instant,
            destination: NotificationDestination.order,
            outcome: ObservabilityOutcome.success,
          ),
          ObservabilityEvent.trackingAvailability(
            occurredAt: instant,
            mode: TrackingModeTelemetry.liveCourier,
            availability: TrackingAvailabilityTelemetry.available,
          ),
          ObservabilityEvent.trackingSignal(
            occurredAt: instant,
            signal: TrackingSignalTelemetry.reconnecting,
            outcome: ObservabilityOutcome.pending,
          ),
          ObservabilityEvent.backendFailure(
            occurredAt: instant,
            component: ObservabilityComponent.backend,
            category: BackendFailureCategory.timeout,
            retryable: true,
          ),
          ObservabilityEvent.performanceBudgetViolation(
            occurredAt: instant,
            operation: PerformanceOperation.catalogSearch,
            budget: DurationBucket.under1s,
            observed: DurationBucket.over3s,
          ),
        ];

        expect(
          events.map((event) => event.name).toSet(),
          ObservabilityEventName.values.toSet(),
        );
        for (final event in events) {
          final safe = event.toSafeMap(environment: 'staging');
          expect(
            safe.keys,
            everyElement(
              isIn({
                'schema',
                'name',
                'channel',
                'environment',
                'occurredAt',
                'correlationId',
                'attributes',
              }),
            ),
          );
          final serialized = jsonEncode(safe);
          expect(serialized, isNot(contains('queryText')));
          expect(serialized, isNot(contains('publicationId')));
          expect(serialized, isNot(contains('orderId')));
        }
      },
    );

    test('bucket non espongono conteggi, quantità o latenze precise', () {
      expect(resultCountBucket(0), ResultCountBucket.zero);
      expect(resultCountBucket(37), ResultCountBucket.elevenToFifty);
      expect(quantityBucket(99), QuantityBucket.overTen);
      expect(
        durationBucket(const Duration(milliseconds: 501)),
        DurationBucket.under1s,
      );
    });
  });

  group('StructuredLocalObservabilityPort', () {
    test('crash payload non include messaggio, stack, coordinate o secret', () {
      final payloads = <String>[];
      final port = StructuredLocalObservabilityPort(
        environment: 'development',
        clock: () => instant,
        sink: payloads.add,
        maximumBreadcrumbs: 2,
      );
      port
        ..record(
          ObservabilityEvent.screenView(
            occurredAt: instant,
            screen: AppScreen.home,
          ),
        )
        ..record(
          ObservabilityEvent.screenView(
            occurredAt: instant,
            screen: AppScreen.cart,
          ),
        )
        ..record(
          ObservabilityEvent.screenView(
            occurredAt: instant,
            screen: AppScreen.checkout,
          ),
        )
        ..recordError(
          StateError(
            'Alice, Av. Siempre Viva 742, person@example.com, '
            '-33.448900,-70.669300, access_token=secret, '
            'https://carrier.example.test/private',
          ),
          StackTrace.fromString(
            'person@example.com -33.448900,-70.669300 Bearer secret',
          ),
          component: ObservabilityComponent.checkout,
          category: BackendFailureCategory.unexpected,
        );

      final crash = jsonDecode(payloads.last) as Map<String, Object?>;
      final serialized = payloads.last;
      for (final forbidden in [
        'Alice',
        'Siempre Viva',
        'person@example.com',
        '-33.448900',
        '-70.669300',
        'secret',
        'carrier.example.test',
      ]) {
        expect(serialized, isNot(contains(forbidden)));
      }
      expect(crash['fingerprint'], hasLength(24));
      expect((crash['breadcrumbs'] as List<Object?>), hasLength(2));
    });
  });

  group('ConfigurableProductionObservabilityPort', () {
    test('config invalida o exporter mancante falliscono chiusi', () {
      expect(
        () => ConfigurableProductionObservabilityPort(
          config: const ProductionObservabilityConfig(
            environment: 'production',
            consent: TelemetryConsent.analytics,
            analyticsEnabled: true,
            crashReportingEnabled: false,
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => ConfigurableProductionObservabilityPort(
          config: const ProductionObservabilityConfig(
            environment: 'development',
            consent: TelemetryConsent.none,
            analyticsEnabled: false,
            crashReportingEnabled: false,
          ),
        ),
        throwsFormatException,
      );
    });

    test('consent none non esporta eventi o crash', () async {
      final exporter = _Exporter();
      final reporter = _Reporter();
      final port = ConfigurableProductionObservabilityPort(
        config: const ProductionObservabilityConfig(
          environment: 'production',
          consent: TelemetryConsent.none,
          analyticsEnabled: true,
          crashReportingEnabled: true,
        ),
        analyticsExporter: exporter,
        crashReporter: reporter,
        clock: () => instant,
      );

      port.record(
        ObservabilityEvent.screenView(
          occurredAt: instant,
          screen: AppScreen.home,
        ),
      );
      port.recordError(
        StateError('secret'),
        StackTrace.current,
        component: ObservabilityComponent.bootstrap,
        category: BackendFailureCategory.unexpected,
      );
      await port.flush();

      expect(exporter.payloads, isEmpty);
      expect(reporter.payloads, isEmpty);
    });

    test(
      'diagnostics non esporta analytics ma consente failure e crash',
      () async {
        final exporter = _Exporter();
        final reporter = _Reporter();
        final port = ConfigurableProductionObservabilityPort(
          config: const ProductionObservabilityConfig(
            environment: 'staging',
            consent: TelemetryConsent.diagnostics,
            analyticsEnabled: true,
            crashReportingEnabled: true,
          ),
          analyticsExporter: exporter,
          crashReporter: reporter,
          clock: () => instant,
        );

        port
          ..record(
            ObservabilityEvent.screenView(
              occurredAt: instant,
              screen: AppScreen.home,
            ),
          )
          ..record(
            ObservabilityEvent.backendFailure(
              occurredAt: instant,
              component: ObservabilityComponent.auth,
              category: BackendFailureCategory.offline,
              retryable: true,
            ),
          )
          ..recordError(
            StateError('private-message'),
            StackTrace.current,
            component: ObservabilityComponent.auth,
            category: BackendFailureCategory.offline,
          );
        await port.flush();

        expect(exporter.payloads, hasLength(1));
        expect(exporter.payloads.single, contains('backendFailure'));
        expect(reporter.payloads, hasLength(1));
        expect(reporter.payloads.single, isNot(contains('private-message')));
      },
    );

    test(
      'rate limit usa clock controllato e riparte nella finestra successiva',
      () async {
        var now = instant;
        final exporter = _Exporter();
        final port = ConfigurableProductionObservabilityPort(
          config: const ProductionObservabilityConfig(
            environment: 'production',
            consent: TelemetryConsent.analytics,
            analyticsEnabled: true,
            crashReportingEnabled: false,
            maximumEventsPerMinute: 2,
          ),
          analyticsExporter: exporter,
          clock: () => now,
        );

        for (var index = 0; index < 3; index++) {
          port.record(
            ObservabilityEvent.screenView(
              occurredAt: now,
              screen: AppScreen.home,
            ),
          );
        }
        await port.flush();
        expect(exporter.payloads, hasLength(2));

        now = now.add(const Duration(minutes: 1));
        port.record(
          ObservabilityEvent.screenView(
            occurredAt: now,
            screen: AppScreen.cart,
          ),
        );
        await port.flush();
        expect(exporter.payloads, hasLength(3));
      },
    );

    test(
      'failure exporter usa buffer bounded e flush riprova senza crash',
      () async {
        final exporter = _Exporter(fail: true);
        final port = ConfigurableProductionObservabilityPort(
          config: const ProductionObservabilityConfig(
            environment: 'production',
            consent: TelemetryConsent.analytics,
            analyticsEnabled: true,
            crashReportingEnabled: false,
            maximumEventsPerMinute: 50,
            maximumBufferedEvents: 3,
            maximumBufferedBytes: 4096,
          ),
          analyticsExporter: exporter,
          clock: () => instant,
        );

        for (var index = 0; index < 8; index++) {
          port.record(
            ObservabilityEvent.screenView(
              occurredAt: instant,
              screen: AppScreen.values[index % AppScreen.values.length],
            ),
          );
        }
        await port.flush();
        expect(port.bufferedEventCount, 3);

        exporter.fail = false;
        await port.flush();
        expect(port.bufferedEventCount, 0);
        expect(exporter.payloads, hasLength(3));
      },
    );

    test('correlation ID è random, bounded e non è un UUID interno', () {
      final port = ConfigurableProductionObservabilityPort(
        config: const ProductionObservabilityConfig(
          environment: 'production',
          consent: TelemetryConsent.none,
          analyticsEnabled: false,
          crashReportingEnabled: false,
        ),
      );

      final first = port.createCorrelationId().value;
      final second = port.createCorrelationId().value;
      expect(first, matches(RegExp(r'^[a-f0-9]{24}$')));
      expect(second, isNot(first));
      expect(first, isNot(contains('-')));
    });
  });
}

final class _Exporter implements AnalyticsExporter {
  _Exporter({this.fail = false});

  bool fail;
  final payloads = <String>[];

  @override
  Future<void> exportEvent(String serializedEvent) async {
    if (fail) throw StateError('offline');
    payloads.add(serializedEvent);
  }
}

final class _Reporter implements CrashReporter {
  final payloads = <String>[];

  @override
  Future<void> reportCrash(String serializedCrash) async {
    payloads.add(serializedCrash);
  }
}
