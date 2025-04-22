// main.dart - Improved main application file
// Contains the app widget and entry point with engineering design system

import 'package:flutter/material.dart';
import 'package:tolerance/engineering_theme.dart';
import 'package:tolerance/tolerance_table_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import our custom theme
// import 'engineering_theme.dart';
// import other required files

// App launch
void main() {
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
  // Key for shared preferences
  static const String _prefThemeMode = 'themeMode';

  @override
  void initState() {
    super.initState();
    // Load saved theme mode
    _loadThemeMode();
  }

  // Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedMode = prefs.getString(_prefThemeMode);
      
      if (savedMode != null) {
        setState(() {
          switch (savedMode) {
            case 'light':
              _themeMode = ThemeMode.light;
              break;
            case 'dark':
              _themeMode = ThemeMode.dark;
              break;
            default:
              _themeMode = ThemeMode.system;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
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
      // Home screen - tolerance table page
      home: ToleranceTablePage(setThemeMode: setThemeMode),
    );
  }
}

// Add a splash screen for better UX
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to main page after short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ToleranceTablePage(
              setThemeMode: (context as _MachineryToleranceAppState).setThemeMode,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness for proper logo color
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.precision_manufacturing,
              size: 80,
              color: EngineeringTheme.primaryBlue,
            ),
            const SizedBox(height: 24),
            // App title
            const Text(
              'ДОПУСКИ И ПОСАДКИ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // App subtitle
            Text(
              'Справочник инженера-машиностроителя',
              style: TextStyle(
                fontSize: 16,
                color: EngineeringTheme.getTextColor(brightness, false),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(EngineeringTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}