// Step 1: First, create a localization class to manage translations

// lib/core/localization/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to get current instance from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static delegate for the localization
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Static method to know if a locale is supported
  static bool isSupported(Locale locale) {
    return ['en', 'ru'].contains(locale.languageCode);
  }

  // Translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'change_language': 'Change language',
      'language_selection_title': 'Select language',
      'language_selection_description':
          'Choose your preferred language for the application interface.',
      'language_en': 'English',
      'language_ru': 'Russian',
      'part_not_defined': 'Not defined',
      'app_title': 'Tolerances',
      'clickable': 'Clickable',
      'search': 'Search',
      'about': 'About',
      'close': 'CLOSE',
      'done': 'Done',

      // Unit System
      'units': 'Units',
      'mm': 'mm',
      'in': 'in',
      'microns': 'µm',
      'millimeters': 'millimeters',
      'inches': 'inches',

      // AppBar and Menu
      'tolerances': 'Tolerances',
      'search_tolerance': 'Search tolerance',
      'units_with_value': 'Units: \$units_value',
      'tap_to_change_units': 'Tap to change units',
      'light_theme': 'Light theme',
      'dark_theme': 'Dark theme',
      'about_app': 'About',

      // Tolerances and Parts
      'all_tolerances': 'All tolerances',
      'holes': 'Holes',
      'shafts': 'Shafts',
      'hole': 'Hole',
      'shaft': 'Shaft',
      'interval': 'Interval',
      'interval_mm': 'Interval\n(mm)',
      'in_interval': 'In interval: \$interval_value',
      'interval_not_defined': 'Not defined',

      // Search Page
      'search_tolerance_title': 'Search tolerance',
      'enter_designation': 'Enter designation',
      'recently_used': 'RECENTLY USED',
      'holes_count': 'Holes (\$count)',
      'shafts_count': 'Shafts (\$count)',
      'clear_search': 'Clear search',
      'no_results': 'No results for "\$query"',

      // Dimension Calculation
      'nominal_size': 'Nominal size',
      'enter_size': 'Enter size',
      'error_value_outside_range': 'Error! Value outside allowed range',
      'enter_value_up_to': 'Enter value up to \$max_value mm',
      'calculation_results': 'Calculation results',
      'copy_results': 'Copy results',
      'results_copied': 'Results copied to clipboard',
      'no_results_to_copy': 'No results to copy',

      // Short labels
      'nom': 'Nom:',
      'min': 'Min:',
      'max': 'Max:',
      'avg': 'Avg:',

      // Full labels
      'nominal_size_full': 'Nominal size',
      'minimum_size_full': 'Minimum size',
      'maximum_size_full': 'Maximum size',
      'average_size_full': 'Average size',

      // About dialog
      'about_title': 'About',
      'tolerance_reference': 'Tolerance reference',
      'app_description':
          'Application for calculating dimensions with allowances.',
      'version': 'Version: \$version_number',

      // Onboarding
      'skip': 'SKIP',
      'next': 'NEXT',
      'start': 'START',
      'welcome_title': 'Welcome to the tolerance reference',
      'welcome_description':
          'The application will help you calculate dimensions with tolerances. Swipe right to learn about the main features.',
      'search_title': 'Search for tolerances',
      'search_description':
          'Click on the search button to quickly find the tolerance you need. You can filter by holes and shafts.',
      'calculation_title': 'Size calculation',
      'calculation_description':
          'Select a cell with a tolerance and enter the nominal size to get the minimum and maximum values.',
      'units_switching_title': 'Unit switching',
      'units_switching_description':
          'You can switch between millimeters, inches and microns through the settings menu in the upper right corner.',
      'dark_theme_title': 'Dark theme',
      'dark_theme_description':
          'For comfortable work in low light conditions, turn on the dark theme through the settings menu.',
      'got_it': 'GOT IT',

      // Messages
      'units_changed': 'Units changed: \$old_units → \$new_units',
      'calculation_only_in_mm':
          'Size calculation is only available in millimeter (mm) mode',
      'switch': 'SWITCH',
      'tip': 'Tip',
      'cells_clickable_tip':
          'Click on a tolerance cell to calculate dimensions.',
      'theme_units_tip': 'Theme and units settings are in the menu',

      'filter_tolerances': 'Filter tolerances',
      'filter_settings': 'Filter Settings',
      'filter_info_title': 'Show/Hide Tolerances',
      'filter_info_description':
          'Select which tolerance designations you want to display in the table. Unchecked designations will be hidden.',
      'hole_tolerances': 'Hole Tolerances',
      'shaft_tolerances': 'Shaft Tolerances',
      'selected_count': '\$count / \$total selected',
      'select_all': 'Select All',
      'deselect_all': 'Deselect All',
      'apply': 'Apply',
      'cancel': 'Cancel',
      'reset': 'Reset',
      'reset_filters': 'Reset Filters',
      'reset_filters_confirm':
          'Are you sure you want to reset all filters to default settings?',
      'filter_save_error': 'Error saving filter settings',
      'unsaved_changes': 'Unsaved Changes',
      'discard_changes_question': 'You have unsaved changes. Discard them?',
      'discard': 'Discard',
      'reset_to_defaults': 'Reset to defaults',
      'warning': 'Warning',
      'no_tolerances_selected_warning':
          'You haven\'t selected any tolerances. The table will be empty. Please select at least one tolerance or reset to defaults.',
      'filter_active_warning':
          'Filter is active! Some tolerances are hidden. To show all tolerances, go to Filter settings in the main menu.',
          'hide_warning': 'Hide warning',
          'filter_active_notice': 'Filter active: some tolerances are hidden',
    },
    'ru': {
      // General
      'change_language': 'Изменить язык',
      'language_selection_title': 'Выберите язык',
      'language_selection_description':
          'Выберите предпочтительный язык интерфейса приложения.',
      'language_en': 'Английский',
      'language_ru': 'Русский',
      'part_not_defined': 'Не определено',
      'app_title': 'Допуски',
      'clickable': 'Кликабельно',
      'search': 'Поиск',
      'about': 'О программе',
      'close': 'ЗАКРЫТЬ',
      'done': 'Готово',

      // Unit System
      'units': 'Единицы',
      'mm': 'мм',
      'in': 'in',
      'microns': 'мкм',
      'millimeters': 'миллиметры',
      'inches': 'дюймы',

      // AppBar and Menu
      'tolerances': 'Допуски',
      'search_tolerance': 'Поиск допуска',
      'units_with_value': 'Единицы: \$units_value',
      'tap_to_change_units': 'Нажмите для смены единиц измерения',
      'light_theme': 'Светлая тема',
      'dark_theme': 'Темная тема',
      'about_app': 'О программе',

      // Tolerances and Parts
      'all_tolerances': 'Все допуски',
      'holes': 'Отверстия',
      'shafts': 'Валы',
      'hole': 'Отверстие',
      'shaft': 'Вал',
      'interval': 'Интервал',
      'interval_mm': 'Интервал\n(мм)',
      'in_interval': 'В интервале: \$interval_value',
      'interval_not_defined': 'Не определено',

      // Search Page
      'search_tolerance_title': 'Поиск допуска',
      'enter_designation': 'Введите обозначение',
      'recently_used': 'НЕДАВНО ИСПОЛЬЗОВАННЫЕ',
      'holes_count': 'Отверстия (\$count)',
      'shafts_count': 'Валы (\$count)',
      'clear_search': 'Очистить поиск',
      'no_results': 'Нет результатов по запросу "\$query"',

      // Dimension Calculation
      'nominal_size': 'Номинальный размер',
      'enter_size': 'Введите размер',
      'error_value_outside_range': 'Ошибка! Значение вне допустимого диапазона',
      'enter_value_up_to': 'Введите значение до \$max_value мм',
      'calculation_results': 'Результаты расчета',
      'copy_results': 'Скопировать результаты',
      'results_copied': 'Результаты скопированы в буфер обмена',
      'no_results_to_copy': 'Нет результатов для копирования',

      // Short labels
      'nom': 'Ном:',
      'min': 'Мин:',
      'max': 'Макс:',
      'avg': 'Сред:',

      // Full labels
      'nominal_size_full': 'Номинальный размер',
      'minimum_size_full': 'Минимальный размер',
      'maximum_size_full': 'Максимальный размер',
      'average_size_full': 'Средний размер',

      // About dialog
      'about_title': 'О программе',
      'tolerance_reference': 'Справочник допусков и посадок',
      'app_description': 'Приложение для расчета размеров с учетом допусков.',
      'version': 'Версия: \$version_number',

      // Onboarding
      'skip': 'ПРОПУСТИТЬ',
      'next': 'ДАЛЕЕ',
      'start': 'НАЧАТЬ',
      'welcome_title': 'Добро пожаловать в справочник по допускам',
      'welcome_description':
          'Приложение поможет рассчитать размеры с учетом допусков. Пролистайте вправо, чтобы ознакомиться с основными функциями.',
      'search_title': 'Поиск допусков',
      'search_description':
          'Нажмите на кнопку поиска, чтобы быстро найти необходимый допуск. Вы можете фильтровать по отверстиям и валам.',
      'calculation_title': 'Расчет размеров',
      'calculation_description':
          'Выберите ячейку с допуском и введите номинальный размер для получения минимальных и максимальных значений.',
      'units_switching_title': 'Переключение единиц',
      'units_switching_description':
          'Вы можете переключаться между миллиметрами, дюймами и микронами через меню настроек в правом верхнем углу.',
      'dark_theme_title': 'Темная тема',
      'dark_theme_description':
          'Для комфортной работы в условиях плохого освещения включите темную тему через меню настроек.',
      'got_it': 'ПОНЯТНО',

      // Messages
      'units_changed': 'Единицы измерения изменены: \$old_units → \$new_units',
      'calculation_only_in_mm':
          'Расчет размеров доступен только в режиме миллиметров (мм)',
      'switch': 'ПЕРЕКЛЮЧИТЬ',
      'tip': 'Подсказка',
      'cells_clickable_tip':
          'Нажмите на ячейку с допуском, чтобы рассчитать размеры.',
      'theme_units_tip': 'Настройки темы и единиц измерения находятся в меню',

      'filter_tolerances': 'Фильтр допусков',
      'filter_settings': 'Настройки фильтра',
      'filter_info_title': 'Показать/Скрыть допуски',
      'filter_info_description':
          'Выберите, какие обозначения допусков вы хотите отображать в таблице. Неотмеченные обозначения будут скрыты.',
      'hole_tolerances': 'Допуски отверстий',
      'shaft_tolerances': 'Допуски валов',
      'selected_count': '\$count / \$total выбрано',
      'select_all': 'Выбрать все',
      'deselect_all': 'Снять выбор',
      'apply': 'Применить',
      'cancel': 'Отмена',
      'reset': 'Сбросить',
      'reset_filters': 'Сбросить фильтры',
      'reset_filters_confirm':
          'Вы уверены, что хотите сбросить все фильтры к настройкам по умолчанию?',
      'filter_save_error': 'Ошибка сохранения настроек фильтра',
      'unsaved_changes': 'Несохраненные изменения',
      'discard_changes_question':
          'У вас есть несохраненные изменения. Отменить их?',
      'discard': 'Отменить',
      'reset_to_defaults': 'Сбросить к настройкам по умолчанию',
      'warning': 'Предупреждение',
      'no_tolerances_selected_warning':
          'Вы не выбрали ни одного допуска. Таблица будет пустой. Пожалуйста, выберите хотя бы один допуск или сбросьте настройки.',
      'filter_active_warning':
          'Фильтр активен! Некоторые допуски скрыты. Чтобы показать все допуски, перейдите в настройки фильтра в главном меню.',
          'hide_warning': 'Скрыть предупреждение',
          'filter_active_notice': 'Фильтр активен: некоторые допуски скрыты',
    },
  };

  String translate(String key, {Map<String, String>? args}) {
    // Get the translation map for the current locale
    final translations =
        _localizedValues[locale.languageCode] ?? _localizedValues['en']!;

    // Get the translation or fallback to English or the key itself
    String value = translations[key] ?? _localizedValues['en']?[key] ?? key;

    // Replace arguments if provided
    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('\$$argKey', argValue);
      });
    }

    return value;
  }
}

// Delegate for localization
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.isSupported(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easy access
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  // Helper method to translate with variables
  String t(String key, {Map<String, String>? args}) {
    return l10n.translate(key, args: args);
  }
}
