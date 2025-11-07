import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Helper extension to access localization easily
/// Usage: context.l10n.signIn
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Locale Manager - Manages app locale changes
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi'); // Default to Vietnamese

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'vi'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' 
        ? const Locale('vi') 
        : const Locale('en');
    notifyListeners();
  }
}
