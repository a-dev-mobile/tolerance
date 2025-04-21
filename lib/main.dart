// main.dart - Основной входной файл приложения
// Содержит виджет приложения и стартовую точку

import 'package:flutter/material.dart';
import 'tolerance_table_page.dart';

// Запуск приложения
void main() {
  runApp(const MyApp());
}

// Основной виджет приложения
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Состояние основного виджета приложения
class _MyAppState extends State<MyApp> {
  // Текущий режим темы (светлая/темная/системная)
  ThemeMode _themeMode = ThemeMode.system;

  // Метод для установки режима темы из дочерних виджетов
  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Допуски машиностроительные',
      // Настройки светлой темы
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      // Настройки темной темы
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
      ),
      // Текущий режим темы
      themeMode: _themeMode,
      // Домашний экран - страница с таблицей допусков
      home: ToleranceTablePage(setThemeMode: setThemeMode),
    );
  }
}