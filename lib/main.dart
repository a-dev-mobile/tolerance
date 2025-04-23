// main.dart - Improved main application file
// Contains the app widget and entry point with engineering design system

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tolerance/engineering_theme.dart';
import 'package:tolerance/onboarding_page.dart';
import 'package:tolerance/tolerance_table_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// App launch
void main() {
  // Ensure Flutter bindings are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible until the app is fully loaded
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set preferred device orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MachineryToleranceApp());
}

// Main app widget
class MachineryToleranceApp extends StatefulWidget {
  const MachineryToleranceApp({super.key});

  @override
  State<MachineryToleranceApp> createState() => _MachineryToleranceAppState();
}

// App state
class _MachineryToleranceAppState extends State<MachineryToleranceApp> {
  // Current theme mode (light/dark/system)
  ThemeMode _themeMode = ThemeMode.system;
  // Keys for shared preferences
  static const String _prefThemeMode = 'themeMode';
  static const String _prefOnboardingComplete = 'onboardingComplete';

  // State for tracking whether onboarding is complete
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    // Load saved preferences
    _loadPreferences();
  }

  // Load all preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode preference
      final String? savedMode = prefs.getString(_prefThemeMode);
      ThemeMode loadedThemeMode = ThemeMode.system;

      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            loadedThemeMode = ThemeMode.light;
            break;
          case 'dark':
            loadedThemeMode = ThemeMode.dark;
            break;
          default:
            loadedThemeMode = ThemeMode.system;
        }
      }

      // Load onboarding status
      final bool? onboardingComplete = prefs.getBool(_prefOnboardingComplete);
      // Искусственная задержка для проверки сплэш-экрана - 3 секунды
      await Future.delayed(const Duration(seconds: 3));
      // Update state with all loaded preferences
      setState(() {
        _themeMode = loadedThemeMode;
        _onboardingComplete = onboardingComplete ?? false;
      });

      // Remove splash screen after preferences are loaded
      FlutterNativeSplash.remove();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      // Set initialLoadComplete even on error to avoid getting stuck

      FlutterNativeSplash.remove();
    }
  }

  // Method to set theme mode from child widgets
  void setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    // Save theme mode preference
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;

      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        default:
          modeString = 'system';
      }

      await prefs.setString(_prefThemeMode, modeString);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  // Method to mark onboarding as complete
  void completeOnboarding() async {
    setState(() {
      _onboardingComplete = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefOnboardingComplete, true);
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Допуски и посадки',
      // Use our custom light theme
      theme: EngineeringTheme.lightTheme(),
      // Use our custom dark theme
      darkTheme: EngineeringTheme.darkTheme(),
      // Current theme mode
      themeMode: _themeMode,
      // Remove the SplashScreen - нативный сплэш уже показывается
      home:
          _onboardingComplete
              ? ToleranceTablePage(setThemeMode: setThemeMode)
              : OnboardingPage(onComplete: completeOnboarding),
    );
  }
}
