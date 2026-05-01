import 'package:aurora/pages/seller/add_product_page.dart';
import 'package:aurora/pages/seller/products_page.dart';
import 'package:aurora/pages/analysis/analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/supabase/supabase_auth.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/pages/auth/customer_login_page.dart';
import 'package:aurora/pages/auth/customer_signup_page.dart';
import 'package:aurora/pages/customers/customer_home_page.dart';
import 'package:aurora/pages/orders/customer_orders_page.dart';
import 'package:aurora/users/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await Storage.init();

  if (!kIsWeb) {
    await _requestLocationPermission();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseAuth()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserStorage()),
        ChangeNotifierProvider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AuroraApp(),
    ),
  );
}

Future<void> _requestLocationPermission() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    await Permission.location.request();
    await Permission.locationAlways.request();
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurora',
      theme: themeProvider.theme,
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
        // Customer routes
        '/customer-login': (context) => const CustomerLoginPage(),
        '/customer-signup': (context) => const CustomerSignupPage(),
        '/customer-home': (context) => const CustomerHomePage(),
        '/customer-orders': (context) => const CustomerOrdersPage(),
      },
      home: const SplashScreen(),
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

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
      return;
    }

    final accountType = await Storage.getAccountType();
    final userStorage = Provider.of<UserStorage>(context, listen: false);

    try {
      // Handle customer account type
      if (accountType == 'customer') {
        await userStorage.loadUser(AccountType.customer);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/customer-home');
        }
        return;
      }
      
      await userStorage.loadUser(
        accountType == 'factory' ? AccountType.factory : AccountType.seller,
      );
    } catch (e) {
      debugPrint('[main._checkAuthAndNavigate] Error: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
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
