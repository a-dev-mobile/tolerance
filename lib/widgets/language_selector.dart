// Step 3: Create a language selector widget

// lib/widgets/language_selector.dart
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../engineering_theme.dart';

class LanguageSelector extends StatelessWidget {
  final Function(Locale) onLocaleChanged;

  const LanguageSelector({super.key, required this.onLocaleChanged});

  @override
  Widget build(BuildContext context) {
    // Get current locale
    final currentLocale = Localizations.localeOf(context);
    final isEnglish = currentLocale.languageCode == 'en';

    return PopupMenuButton<String>(
      tooltip: context.t('change_language'),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isEnglish ? 'EN' : 'RU',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).appBarTheme.iconTheme?.color,
              ),
            ),
          ],
        ),
      ),
      onSelected: (String languageCode) {
        // Change language based on selection
        final newLocale = Locale(languageCode);
        onLocaleChanged(newLocale);
      },
      itemBuilder:
          (BuildContext context) => [
            // English option
            PopupMenuItem<String>(
              value: 'en',
              child: ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      isEnglish
                          ? EngineeringTheme.primaryBlue
                          : Colors.transparent,
                  child: Text(
                    'EN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isEnglish
                              ? Colors.white
                              : EngineeringTheme.getTextColor(
                                Theme.of(context).brightness,
                                true,
                              ),
                    ),
                  ),
                ),
                title: Text(context.t('language_en')),
                trailing:
                    isEnglish
                        ? Icon(
                          Icons.check,
                          color: EngineeringTheme.successColor,
                        )
                        : null,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Russian option
            PopupMenuItem<String>(
              value: 'ru',
              child: ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      !isEnglish
                          ? EngineeringTheme.primaryBlue
                          : Colors.transparent,
                  child: Text(
                    'RU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          !isEnglish
                              ? Colors.white
                              : EngineeringTheme.getTextColor(
                                Theme.of(context).brightness,
                                true,
                              ),
                    ),
                  ),
                ),
                title: Text(context.t('language_ru')),
                trailing:
                    !isEnglish
                        ? Icon(
                          Icons.check,
                          color: EngineeringTheme.successColor,
                        )
                        : null,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
    );
  }
}
