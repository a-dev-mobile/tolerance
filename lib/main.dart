// main.dart - Improved main application file
// Contains the app widget and entry point with engineering design system

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tolerance/engineering_theme.dart';
import 'package:tolerance/onboarding_page.dart';
import 'package:tolerance/tolerance_table_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import our custom theme
// import 'engineering_theme.dart';
// import other required files

// App launch
void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
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
  bool _initialLoadComplete = false;

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
      
      // Update state with all loaded preferences
      setState(() {
        _themeMode = loadedThemeMode;
        _onboardingComplete = onboardingComplete ?? false;
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      // Set initialLoadComplete even on error to avoid getting stuck
      setState(() {
        _initialLoadComplete = true;
      });
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
      // Show loading indicator while preferences are loading
      home: !_initialLoadComplete
          ? SplashScreen(loading: true)
          : _onboardingComplete
              ? ToleranceTablePage(setThemeMode: setThemeMode)
              : OnboardingPage(onComplete: completeOnboarding),
    );
  }
}

// Enhanced splash screen with loading state
class SplashScreen extends StatefulWidget {
  final bool loading;
  
  const SplashScreen({super.key, this.loading = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for fade in/out
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start the animation
    _animationController.forward();
    
    // Navigate to main page after delay unless explicitly in loading mode
    if (!widget.loading) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          // Fade out before navigation
          _animationController.reverse().then((_) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ToleranceTablePage(
                  setThemeMode: (context as _MachineryToleranceAppState).setThemeMode,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness for proper logo color
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with subtle animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Icon(
                  Icons.precision_manufacturing,
                  size: 80,
                  color: EngineeringTheme.primaryBlue,
                ),
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
              // Loading indicator with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(EngineeringTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 20),
              // Version
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Версия 1.3.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: EngineeringTheme.getTextColor(brightness, false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}