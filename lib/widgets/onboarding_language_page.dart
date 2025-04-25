import 'package:flutter/material.dart';
import 'package:tolerance/core/localization/app_localizations.dart';
import 'package:tolerance/engineering_theme.dart';

class OnboardingLanguagePage extends StatelessWidget {
  final Function(Locale) onLanguageSelected;

  const OnboardingLanguagePage({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Language icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: EngineeringTheme.primaryBlue.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language,
                  size: 60,
                  color: EngineeringTheme.primaryBlue,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title - use static text for initial language selection screen
              const Text(
                'Select language / Выберите язык',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Description - use static text for initial language selection
              const Text(
                'Choose your preferred language for the application interface.\n\nВыберите предпочтительный язык интерфейса приложения.',
                style: TextStyle(
                  fontSize: 16,
                  color: EngineeringTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Language options
              _buildLanguageOption(
                context, 
                'English', 
                'en',
                () => onLanguageSelected(const Locale('en')),
              ),
              
              const SizedBox(height: 16),
              
              _buildLanguageOption(
                context, 
                'Русский', 
                'ru',
                () => onLanguageSelected(const Locale('ru')),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption(
    BuildContext context, 
    String languageName, 
    String languageCode,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: EngineeringTheme.primaryBlue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: EngineeringTheme.primaryBlue,
              child: Text(
                languageCode.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              languageName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}