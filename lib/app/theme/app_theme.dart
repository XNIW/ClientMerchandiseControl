import 'package:flutter/material.dart';

import '../design_system/theme/storefront_semantic_colors.dart';
import '../design_system/tokens/app_radii.dart';
import '../design_system/tokens/app_sizes.dart';

abstract final class AppTheme {
  static const provisionalSeedColor = Color(0xFF245C55);

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: provisionalSeedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size.square(AppSizes.minimumTouchTarget),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigationBarHeight,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      extensions: [StorefrontSemanticColors.forScheme(colorScheme)],
    );
  }
}
