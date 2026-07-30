import 'package:flutter/material.dart';

@immutable
class StorefrontSemanticColors
    extends ThemeExtension<StorefrontSemanticColors> {
  const StorefrontSemanticColors({
    required this.information,
    required this.onInformation,
    required this.informationContainer,
    required this.onInformationContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.promotion,
    required this.onPromotion,
    required this.promotionContainer,
    required this.onPromotionContainer,
    required this.price,
    required this.originalPrice,
    required this.availabilityPositive,
    required this.availabilityLimited,
    required this.availabilityUnavailable,
  });

  final Color information;
  final Color onInformation;
  final Color informationContainer;
  final Color onInformationContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color promotion;
  final Color onPromotion;
  final Color promotionContainer;
  final Color onPromotionContainer;
  final Color price;
  final Color originalPrice;
  final Color availabilityPositive;
  final Color availabilityLimited;
  final Color availabilityUnavailable;

  factory StorefrontSemanticColors.forScheme(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return StorefrontSemanticColors(
        information: const Color(0xFF8DCDFF),
        onInformation: const Color(0xFF00344F),
        informationContainer: const Color(0xFF004B70),
        onInformationContainer: const Color(0xFFCDE5FF),
        success: const Color(0xFF8CD899),
        onSuccess: const Color(0xFF003914),
        successContainer: const Color(0xFF0B5225),
        onSuccessContainer: const Color(0xFFA9F5B1),
        warning: const Color(0xFFF7BD48),
        onWarning: const Color(0xFF402D00),
        warningContainer: const Color(0xFF5D4300),
        onWarningContainer: const Color(0xFFFFDEA6),
        promotion: const Color(0xFFEAB4FF),
        onPromotion: const Color(0xFF4A0067),
        promotionContainer: const Color(0xFF620087),
        onPromotionContainer: const Color(0xFFF7D8FF),
        price: scheme.onSurface,
        originalPrice: scheme.onSurfaceVariant,
        availabilityPositive: const Color(0xFF8CD899),
        availabilityLimited: const Color(0xFFF7BD48),
        availabilityUnavailable: scheme.error,
      );
    }

    return StorefrontSemanticColors(
      information: const Color(0xFF006493),
      onInformation: Colors.white,
      informationContainer: const Color(0xFFCDE5FF),
      onInformationContainer: const Color(0xFF001E30),
      success: const Color(0xFF256D37),
      onSuccess: Colors.white,
      successContainer: const Color(0xFFA9F5B1),
      onSuccessContainer: const Color(0xFF002109),
      warning: const Color(0xFF7A5900),
      onWarning: Colors.white,
      warningContainer: const Color(0xFFFFDEA6),
      onWarningContainer: const Color(0xFF271900),
      promotion: const Color(0xFF7B1FA2),
      onPromotion: Colors.white,
      promotionContainer: const Color(0xFFF7D8FF),
      onPromotionContainer: const Color(0xFF2C003F),
      price: scheme.onSurface,
      originalPrice: scheme.onSurfaceVariant,
      availabilityPositive: const Color(0xFF256D37),
      availabilityLimited: const Color(0xFF7A5900),
      availabilityUnavailable: scheme.error,
    );
  }

  static StorefrontSemanticColors of(BuildContext context) {
    final colors = Theme.of(context).extension<StorefrontSemanticColors>();
    assert(colors != null, 'StorefrontSemanticColors must be installed.');
    return colors!;
  }

  @override
  StorefrontSemanticColors copyWith({
    Color? information,
    Color? onInformation,
    Color? informationContainer,
    Color? onInformationContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? promotion,
    Color? onPromotion,
    Color? promotionContainer,
    Color? onPromotionContainer,
    Color? price,
    Color? originalPrice,
    Color? availabilityPositive,
    Color? availabilityLimited,
    Color? availabilityUnavailable,
  }) {
    return StorefrontSemanticColors(
      information: information ?? this.information,
      onInformation: onInformation ?? this.onInformation,
      informationContainer: informationContainer ?? this.informationContainer,
      onInformationContainer:
          onInformationContainer ?? this.onInformationContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      promotion: promotion ?? this.promotion,
      onPromotion: onPromotion ?? this.onPromotion,
      promotionContainer: promotionContainer ?? this.promotionContainer,
      onPromotionContainer: onPromotionContainer ?? this.onPromotionContainer,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      availabilityPositive: availabilityPositive ?? this.availabilityPositive,
      availabilityLimited: availabilityLimited ?? this.availabilityLimited,
      availabilityUnavailable:
          availabilityUnavailable ?? this.availabilityUnavailable,
    );
  }

  @override
  StorefrontSemanticColors lerp(
    covariant StorefrontSemanticColors? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }

    return StorefrontSemanticColors(
      information: Color.lerp(information, other.information, t)!,
      onInformation: Color.lerp(onInformation, other.onInformation, t)!,
      informationContainer: Color.lerp(
        informationContainer,
        other.informationContainer,
        t,
      )!,
      onInformationContainer: Color.lerp(
        onInformationContainer,
        other.onInformationContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      promotion: Color.lerp(promotion, other.promotion, t)!,
      onPromotion: Color.lerp(onPromotion, other.onPromotion, t)!,
      promotionContainer: Color.lerp(
        promotionContainer,
        other.promotionContainer,
        t,
      )!,
      onPromotionContainer: Color.lerp(
        onPromotionContainer,
        other.onPromotionContainer,
        t,
      )!,
      price: Color.lerp(price, other.price, t)!,
      originalPrice: Color.lerp(originalPrice, other.originalPrice, t)!,
      availabilityPositive: Color.lerp(
        availabilityPositive,
        other.availabilityPositive,
        t,
      )!,
      availabilityLimited: Color.lerp(
        availabilityLimited,
        other.availabilityLimited,
        t,
      )!,
      availabilityUnavailable: Color.lerp(
        availabilityUnavailable,
        other.availabilityUnavailable,
        t,
      )!,
    );
  }
}
