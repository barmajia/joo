// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../storage/storage.dart';

enum ThemeStyle {
  modernLight,
  elegantLight,
  modernDark,
  elegantDark,
  amoledDark,
  cyberpunk,
  forest,
  ocean,
  sunset,
  monochrome,
}

class ThemeProvider extends ChangeNotifier {
  ThemeStyle _currentTheme = ThemeStyle.modernLight;
  bool _useDynamicColors = false;
  double _brightnessLevel = 1.0;

  ThemeStyle get currentTheme => _currentTheme;
  bool get useDynamicColors => _useDynamicColors;
  double get brightnessLevel => _brightnessLevel;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load saved theme from storage
  Future<void> _loadThemePreference() async {
    final savedIndex = await Storage.getThemeIndex();
    _currentTheme =
        ThemeStyle.values[savedIndex.clamp(0, ThemeStyle.values.length - 1)];

    // Load other preferences
    _useDynamicColors = await Storage.getBool('use_dynamic_colors');
    _brightnessLevel = await Storage.getBrightness();

    notifyListeners();
  }

  // Change theme
  Future<void> setTheme(ThemeStyle theme) async {
    _currentTheme = theme;
    await Storage.saveThemeIndex(theme.index);
    notifyListeners();
  }

  // Toggle dynamic colors (Material You)
  Future<void> toggleDynamicColors() async {
    _useDynamicColors = !_useDynamicColors;
    await Storage.saveBool('use_dynamic_colors', _useDynamicColors);
    notifyListeners();
  }

  // Adjust brightness level
  Future<void> setBrightnessLevel(double level) async {
    _brightnessLevel = level.clamp(0.5, 1.5);
    await Storage.saveBrightness(_brightnessLevel);
    notifyListeners();
  }

  // Toggle between light/dark modes (quick switch)
  void toggleTheme() {
    if (_currentTheme.toString().contains('light')) {
      switch (_currentTheme) {
        case ThemeStyle.modernLight:
          setTheme(ThemeStyle.modernDark);
          break;
        case ThemeStyle.elegantLight:
          setTheme(ThemeStyle.elegantDark);
          break;
        default:
          setTheme(ThemeStyle.modernDark);
      }
    } else {
      switch (_currentTheme) {
        case ThemeStyle.modernDark:
          setTheme(ThemeStyle.modernLight);
          break;
        case ThemeStyle.elegantDark:
          setTheme(ThemeStyle.elegantLight);
          break;
        default:
          setTheme(ThemeStyle.modernLight);
      }
    }
  }

  // Main theme data getter
  ThemeData get theme {
    if (_useDynamicColors) {
      return _buildDynamicTheme();
    }
    return _buildCustomTheme();
  }

  // Build custom theme based on selection
  ThemeData _buildCustomTheme() {
    switch (_currentTheme) {
      case ThemeStyle.modernLight:
        return _modernLightTheme();
      case ThemeStyle.elegantLight:
        return _elegantLightTheme();
      case ThemeStyle.modernDark:
        return _modernDarkTheme();
      case ThemeStyle.elegantDark:
        return _elegantDarkTheme();
      case ThemeStyle.amoledDark:
        return _amoledDarkTheme();
      case ThemeStyle.cyberpunk:
        return _cyberpunkTheme();
      case ThemeStyle.forest:
        return _forestTheme();
      case ThemeStyle.ocean:
        return _oceanTheme();
      case ThemeStyle.sunset:
        return _sunsetTheme();
      case ThemeStyle.monochrome:
        return _monochromeTheme();
    }
  }

  // Build dynamic theme using Material 3 with system colors
  ThemeData _buildDynamicTheme() {
    final isDark = _currentTheme.toString().contains('dark');

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============ CUSTOM THEME DEFINITIONS ============

  ThemeData _modernLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6366F1),
        secondary: const Color(0xFF8B5CF6),
        tertiary: const Color(0xFFEC4899),
        surface: Colors.white,
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  ThemeData _elegantLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1E3A8A),
        secondary: const Color(0xFF3B82F6),
        tertiary: const Color(0xFFF59E0B),
        surface: const Color(0xFFFEF3C7),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBEB),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData _modernDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF818CF8),
        secondary: const Color(0xFFA78BFA),
        tertiary: const Color(0xFFF472B6),
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
      ),
    );
  }

  ThemeData _elegantDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF334155),
        secondary: const Color(0xFF475569),
        tertiary: const Color(0xFF94A3B8),
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFE2E8F0),
      ),
    );
  }

  ThemeData _amoledDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00BCD4),
        secondary: const Color(0xFF03DAC6),
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        color: const Color(0xFF121212),
      ),
    );
  }

  ThemeData _cyberpunkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00FF00),
        secondary: const Color(0xFFFF00FF),
        tertiary: const Color(0xFF00FFFF),
        surface: const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFF00FF00),
      ),
    );
  }

  ThemeData _forestTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF166534),
        secondary: const Color(0xFF22C55E),
        tertiary: const Color(0xFFD97706),
        surface: const Color(0xFFF0FDF4),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FEE7),
    );
  }

  ThemeData _oceanTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0284C7),
        secondary: const Color(0xFF0EA5E9),
        tertiary: const Color(0xFF06B6D4),
        surface: const Color(0xFFF0F9FF),
      ),
      scaffoldBackgroundColor: const Color(0xFFE0F2FE),
    );
  }

  ThemeData _sunsetTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFBE123C),
        secondary: const Color(0xFFFB923C),
        tertiary: const Color(0xFFFCD34D),
        surface: const Color(0xFFFFF1F1),
      ),
      scaffoldBackgroundColor: const Color(0xFFFEF2F2),
    );
  }

  ThemeData _monochromeTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF404040),
        secondary: const Color(0xFF737373),
        tertiary: const Color(0xFFA3A3A3),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    );
  }
}
