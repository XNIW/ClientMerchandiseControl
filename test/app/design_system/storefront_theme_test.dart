import 'package:client_merchandise_control/app/design_system/theme/storefront_semantic_colors.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    for (final entry in [
      (name: 'light', theme: AppTheme.light(), brightness: Brightness.light),
      (name: 'dark', theme: AppTheme.dark(), brightness: Brightness.dark),
    ]) {
      test('${entry.name} usa Material 3 e semantic colors complete', () {
        final theme = entry.theme;
        final semantic = theme.extension<StorefrontSemanticColors>();

        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, entry.brightness);
        expect(semantic, isNotNull);
      });

      test('${entry.name} mantiene il contrasto delle coppie semantiche', () {
        final theme = entry.theme;
        final semantic = theme.extension<StorefrontSemanticColors>()!;
        final pairs = [
          (semantic.onInformation, semantic.information),
          (semantic.onInformationContainer, semantic.informationContainer),
          (semantic.onSuccess, semantic.success),
          (semantic.onSuccessContainer, semantic.successContainer),
          (semantic.onWarning, semantic.warning),
          (semantic.onWarningContainer, semantic.warningContainer),
          (semantic.onPromotion, semantic.promotion),
          (semantic.onPromotionContainer, semantic.promotionContainer),
          (semantic.price, theme.colorScheme.surface),
          (semantic.originalPrice, theme.colorScheme.surface),
        ];

        for (final pair in pairs) {
          expect(
            _contrastRatio(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${pair.$1} on ${pair.$2}',
          );
        }

        for (final statusColor in [
          semantic.availabilityPositive,
          semantic.availabilityLimited,
          semantic.availabilityUnavailable,
        ]) {
          expect(
            _contrastRatio(statusColor, theme.colorScheme.surface),
            greaterThanOrEqualTo(3),
          );
        }
      });
    }
  });

  test('copyWith cambia solo i ruoli richiesti', () {
    final original = AppTheme.light().extension<StorefrontSemanticColors>()!;
    const replacement = Color(0xFF123456);
    final copied = original.copyWith(information: replacement);

    expect(copied.information, replacement);
    expect(copied.success, original.success);
    expect(copied.promotionContainer, original.promotionContainer);
  });

  test('lerp conserva gli estremi e interpola i colori', () {
    final light = AppTheme.light().extension<StorefrontSemanticColors>()!;
    final dark = AppTheme.dark().extension<StorefrontSemanticColors>()!;

    expect(light.lerp(dark, 0).information, light.information);
    expect(light.lerp(dark, 1).information, dark.information);
    expect(
      light.lerp(dark, 0.5).information,
      isNot(anyOf(light.information, dark.information)),
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = [foreground.computeLuminance(), background.computeLuminance()]
    ..sort();
  return (lighter.last + 0.05) / (lighter.first + 0.05);
}
