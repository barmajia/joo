import 'package:aurora/pages/seller/add_product_page.dart';
import 'package:aurora/pages/seller/products_page.dart';
import 'package:aurora/pages/analysis/analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:aurora/storage/storage.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/services/api_service.dart';
import 'package:aurora/pages/welcome/welcome.dart';
import 'package:aurora/pages/home.dart';
import 'package:aurora/pages/customers/customer_list.dart';
import 'package:aurora/pages/profile/profile.dart';
import 'package:aurora/pages/settings.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:aurora/locale/locale_provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:aurora/supabase/supabase_auth.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/providers/app_settings_provider.dart';
import 'package:aurora/widgets/app_lock_screen.dart';
import 'package:aurora/utils/page_transitions.dart';

Future<Map<String, String>> _loadEnvVars() async {
  final content = await rootBundle.loadString('.env');
  final lines = content.split('\n');
  final Map<String, String> envVars = {};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('=');
    if (parts.length == 2) {
      envVars[parts[0].trim()] = parts[1].trim();
    }
  }
  return envVars;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final envVars = await _loadEnvVars();
  String supabaseUrl = envVars['SUPABASE_URL']!;
  String supabaseAnonKey = envVars['SUPABASE_ANON_KEY']!;
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await Storage.init();

  final appSettings = AppSettingsProvider();
  await appSettings.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider(create: (_) => SupabaseAuth()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserStorage()),
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: const AuroraApp(),
    ),
  );

  if (!kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }
}

Future<void> _requestLocationPermission() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('[main._requestLocationPermission] Error: $e');
  }
}

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final appSettings = Provider.of<AppSettingsProvider>(context);

    final pageTransitions = appSettings.reduceAnimations
        ? const <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: ReducedAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: ReducedAnimationPageTransitionsBuilder(),
          }
        : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurora',
      theme: themeProvider.theme.copyWith(
        pageTransitionsTheme: pageTransitions != null
            ? PageTransitionsTheme(builders: pageTransitions)
            : null,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/seller_product': (context) => const SellerProductsPage(),
        '/seller_add_product': (context) => const AddProductPage(),
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => const Homepapge(),
        '/customers': (context) => const CustomerListPage(),
        '/analytics': (context) => const AnalysisPage(),
      },
      home: const AppLockScreen(child: SplashScreen()),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
        return;
      }

      final accountType = await Storage.getAccountType();
      final userStorage = Provider.of<UserStorage>(context, listen: false);

      try {
        await userStorage.loadUser(
          accountType == 'factory' ? AccountType.factory : AccountType.seller,
        );
      } catch (e) {
        debugPrint('[SplashScreen] Error loading user: $e');
      }

      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      debugPrint('[SplashScreen] Error: $e');
      if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 100, color: Color(0xFF6366F1)),
            const SizedBox(height: 24),
            const Text(
              'Aurora',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
