// main.dart - Improved main application file
// Contains the app widget and entry point with engineering design system

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tolerance/core/localization/app_localizations.dart';
import 'package:tolerance/engineering_theme.dart';
import 'package:tolerance/onboarding_page.dart';
import 'package:tolerance/tolerance_table_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tolerance/widgets/onboarding_language_page.dart';
// Add this
import 'package:flutter_localizations/flutter_localizations.dart';

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
  static const String _prefLocale =
      'locale'; // Add this for language preference

  // State for tracking whether onboarding is complete
  bool _onboardingComplete = false;

  // Current locale setting
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    // Load saved preferences
    _loadPreferences();
  }

  // Update the _loadPreferences method:
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

      // Load locale preference
      final String? localeString = prefs.getString(_prefLocale);
      Locale? loadedLocale;

      // If locale has been explicitly set before, use it
      if (localeString != null) {
        final parts = localeString.split('_');
        loadedLocale =
            parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
      }
      // Otherwise, locale will be null and MaterialApp will use device locale

      // Load onboarding status
      final bool? onboardingComplete = prefs.getBool(_prefOnboardingComplete);

      // Artificial delay for splash screen testing - 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Update state with all loaded preferences
      setState(() {
        _themeMode = loadedThemeMode;
        _onboardingComplete = onboardingComplete ?? false;
        _locale = loadedLocale;
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

  // Method to set locale from child widgets
  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });

    // Save locale preference
    try {
      final prefs = await SharedPreferences.getInstance();
      String localeString = locale.languageCode;
      if (locale.countryCode != null) {
        localeString += '_${locale.countryCode}';
      }

      await prefs.setString(_prefLocale, localeString);
    } catch (e) {
      debugPrint('Error saving locale: $e');
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
      debugShowCheckedModeBanner: false,
      title:
          'Tolerance Calculator', // This will be overridden by device locale settings
      // Use our custom light theme
      theme: EngineeringTheme.lightTheme(),
      // Use our custom dark theme
      darkTheme: EngineeringTheme.darkTheme(),
      // Current theme mode
      themeMode: _themeMode,

      // Localization settings
      locale: _locale, // If null, it will use the device locale
      supportedLocales: const [
        Locale('en'), // English
        Locale('ru'), // Russian
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // Our custom delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Home page - either onboarding or main page
      home:
          !_onboardingComplete
              ? _locale == null
                  // First, show language selection
                  ? OnboardingLanguagePage(
                    onLanguageSelected: (locale) {
                      setLocale(locale);
                      // After selecting language, show the regular onboarding
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (context) => OnboardingPage(
                                onComplete: completeOnboarding,
                              ),
                        ),
                      );
                    },
                  )
                  // Then show the regular onboarding
                  : OnboardingPage(onComplete: completeOnboarding)
              // After onboarding, show the main page
              : ToleranceTablePage(
                setThemeMode: setThemeMode,
                setLocale: setLocale,
              ),
    );
  }
}
