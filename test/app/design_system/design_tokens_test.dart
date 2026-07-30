import 'package:client_merchandise_control/app/design_system/tokens/app_breakpoints.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_durations.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_radii.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la scala spacing è positiva, crescente e basata su 4 px', () {
    const values = [
      AppSpacing.xxs,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xxxl,
    ];

    expect(values.every((value) => value > 0 && value % 4 == 0), isTrue);
    for (var index = 1; index < values.length; index++) {
      expect(values[index], greaterThan(values[index - 1]));
    }
  });

  test('radii, size e breakpoint mantengono invarianti accessibili', () {
    expect(AppRadii.control, lessThan(AppRadii.surface));
    expect(AppRadii.surface, lessThan(AppRadii.card));
    expect(AppRadii.card, lessThan(AppRadii.pill));
    expect(AppSizes.minimumTouchTarget, greaterThanOrEqualTo(48));
    expect(AppSizes.iconEmphasis, greaterThan(AppSizes.iconStandard));
    expect(AppBreakpoints.narrow, lessThan(AppBreakpoints.wide));
    expect(AppBreakpoints.wide, lessThan(AppBreakpoints.extraWide));
    expect(AppSizes.contentMaxWidth, greaterThan(AppBreakpoints.wide));
  });

  test('le durate motion sono positive e ordinate', () {
    expect(AppDurations.short, greaterThan(Duration.zero));
    expect(AppDurations.short, lessThan(AppDurations.medium));
    expect(AppDurations.medium, lessThan(AppDurations.long));
    expect(AppDurations.standardCurve.transform(0), 0);
    expect(AppDurations.standardCurve.transform(1), 1);
    expect(AppDurations.emphasizedCurve.transform(0), 0);
    expect(AppDurations.emphasizedCurve.transform(1), 1);
  });

  testWidgets('la preferenza di sistema disabilita il motion', (tester) async {
    late Duration enabled;
    late Duration disabled;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            enabled = AppDurations.effective(context, AppDurations.medium);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  disabled = AppDurations.effective(
                    context,
                    AppDurations.medium,
                  );
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(enabled, AppDurations.medium);
    expect(disabled, Duration.zero);
  });
}
