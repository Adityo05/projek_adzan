import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  final storage = StorageService();
  await storage.init();

  // Initialize and register background worker for daily refresh
  await BackgroundService.initialize();
  await BackgroundService.registerPeriodicTask();

  // Check if first run
  final isFirstRun = await storage.isFirstRun();

  runApp(AzanApp(showOnboarding: isFirstRun));
}

/// Widget utama aplikasi
class AzanApp extends StatefulWidget {
  final bool showOnboarding;

  const AzanApp({super.key, this.showOnboarding = false});

  @override
  State<AzanApp> createState() => _AzanAppState();
}

class _AzanAppState extends State<AzanApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projek Adzan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          _showOnboarding
              ? OnboardingScreen(onComplete: _onOnboardingComplete)
              : const HomeScreen(),
    );
  }
}
