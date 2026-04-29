import 'package:flutter/material.dart';
import '../storage/storage.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    final savedCode = await Storage.getLanguageCode();
    _locale = Locale(savedCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await Storage.saveLanguageCode(locale.languageCode);
    notifyListeners();
  }

  void setLocaleByLanguageCode(String languageCode) {
    _locale = Locale(languageCode);
    Storage.saveLanguageCode(languageCode);
    notifyListeners();
  }
}