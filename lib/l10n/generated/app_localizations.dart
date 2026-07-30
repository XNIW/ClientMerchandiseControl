import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// Diagnóstico visible solo en builds debug de development sin backend configurado.
  ///
  /// In es, this message translates to:
  /// **'Backend no configurado: modo de desarrollo sin conexión.'**
  String get backendNotConfigured;

  /// Etiqueta de la navegación hacia Inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// Etiqueta de la navegación hacia el catálogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get navigationCatalog;

  /// Etiqueta de la navegación hacia el carrito.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get navigationCart;

  /// Etiqueta de la navegación hacia la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get navigationAccount;

  /// Título de la pantalla Inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homeTitle;

  /// Estado temporal de Inicio mientras no hay contenido público.
  ///
  /// In es, this message translates to:
  /// **'Pronto podrás descubrir aquí las novedades de la tienda.'**
  String get homeFoundationMessage;

  /// Título de la pantalla Catálogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get catalogTitle;

  /// Estado temporal del catálogo antes de su conexión.
  ///
  /// In es, this message translates to:
  /// **'El catálogo estará disponible aquí próximamente.'**
  String get catalogFoundationMessage;

  /// Título de la pantalla Carrito.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get cartTitle;

  /// Estado temporal del carrito antes de que existan productos.
  ///
  /// In es, this message translates to:
  /// **'Tu carrito estará disponible cuando puedas elegir productos.'**
  String get cartFoundationMessage;

  /// Título de la pantalla Cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get accountTitle;

  /// Estado temporal de la cuenta antes de habilitar el acceso.
  ///
  /// In es, this message translates to:
  /// **'Podrás acceder a tu cuenta cuando esta función esté disponible.'**
  String get accountFoundationMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'it', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
