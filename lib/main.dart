import 'package:flutter/material.dart';
import 'package:mobile_tolerance/tolerance_constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

// Перечисление единиц измерения, вынесенное на уровень файла
enum UnitSystem { millimeters, inches, microns }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Допуски машиностроительные',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
      ),
      themeMode: _themeMode,
      home: ToleranceTablePage(setThemeMode: setThemeMode),
    );
  }
}

class ToleranceTablePage extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const ToleranceTablePage({super.key, required this.setThemeMode});

  @override
  State<ToleranceTablePage> createState() => _ToleranceTablePageState();
}

class _ToleranceTablePageState extends State<ToleranceTablePage> {
  late ToleranceDataSource _toleranceDataSource;
  final ScrollController _scrollController = ScrollController();
  bool _isDarkMode = false;
  
  // Текущая система единиц измерения (изначально миллиметры)
  UnitSystem _currentUnit = UnitSystem.millimeters;

  @override
  void initState() {
    super.initState();
    _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    // Изначально устанавливаем _isDarkMode в false, 
    // правильная тема будет определена в didChangeDependencies
    _isDarkMode = false;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Безопасно проверяем текущую тему здесь, после того как виджет встроен в дерево
    _isDarkMode = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeUnitSystem() {
    setState(() {
      // Циклическое переключение между единицами измерения
      switch (_currentUnit) {
        case UnitSystem.millimeters:
          _currentUnit = UnitSystem.inches;
          break;
        case UnitSystem.inches:
          _currentUnit = UnitSystem.microns;
          break;
        case UnitSystem.microns:
          _currentUnit = UnitSystem.millimeters;
          break;
      }
      // Обновляем источник данных таблицы с новой системой единиц
      _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Определяем текущую тему
    final currentBrightness = Theme.of(context).brightness;
    _isDarkMode = currentBrightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Допуски машиностроительные'),
              pinned: false, // Не фиксировать верхнюю часть аппбара
              floating:
                  true, // Позволяет аппбару появляться сразу при прокрутке вверх
              snap: true, // Аппбар автоматически расширяется или сворачивается
              forceElevated: innerBoxIsScrolled,
              actions: [
                // Кнопка переключения единиц измерения
                IconButton(
                  icon: Text(
                    _currentUnit == UnitSystem.millimeters ? 'мм' : 
                    _currentUnit == UnitSystem.inches ? 'in' : 'мкм',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  tooltip: 'Сменить единицы измерения',
                  onPressed: _changeUnitSystem,
                ),
                // Кнопка переключения темы
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                      // Применяем тему ко всему приложению
                      final themeMode =
                          _isDarkMode ? ThemeMode.dark : ThemeMode.light;
                      widget.setThemeMode(themeMode);
                    });
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  height: 4.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withAlpha(128),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SfDataGrid(
          source: _toleranceDataSource,
          columnWidthMode: ColumnWidthMode.auto,
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
          frozenColumnsCount: 1, // Закрепляем первую колонку (интервалы)
          allowSorting: false,
          allowFiltering: false,
          allowSwiping: false,
          allowEditing: false,
          isScrollbarAlwaysShown: true,
          rowHeight: 60, // Увеличиваем высоту строк для предотвращения переполнения
          columns: _buildGridColumns(),
        ),
      ),
    );
  }

  List<GridColumn> _buildGridColumns() {
    // Получаем все уникальные имена колонок из данных
    Set<String> uniqueColumnNames = {"Interval"};
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      for (var key in values.keys) {
        uniqueColumnNames.add(key);
      }
    });

    List<String> sortedColumnNames = uniqueColumnNames.toList()..sort();
    // Перемещаем "Interval" в начало списка
    sortedColumnNames.remove("Interval");
    sortedColumnNames.insert(0, "Interval");

    List<GridColumn> columns = [];

    // Создаем колонки на основе ключей из данных
    for (String columnName in sortedColumnNames) {
      columns.add(
        GridColumn(
          columnName: columnName,
          label: Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).primaryColor.withAlpha(51),
            alignment: Alignment.center,
            child: Text(
              columnName == "Interval" 
                ? 'Interval\n(mm)'
                : columnName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          width: columnName == "Interval" ? 100 : 80, // Ширина колонки
        ),
      );
    }

    return columns;
  }
}

class ToleranceDataSource extends DataGridSource {
  late List<DataGridRow> _rows;
  late List<String> _columnNames;
  final UnitSystem unitSystem; // Система единиц измерения

  // Константы для конвертации (используем lowerCamelCase согласно рекомендациям Dart)
  static const double mmToInch = 0.0393701; // Коэффициент перевода мм в дюймы
  static const double mmToMicron = 1000.0; // Коэффициент перевода мм в микроны

  ToleranceDataSource({required this.unitSystem}) {
    _initDataGridRows();
  }

  // Функция для конвертации значения из мм в другие единицы измерения
  String _convertValue(String mmValue, UnitSystem toUnit) {
    // Пустые значения оставляем без изменений
    if (mmValue.isEmpty || mmValue == '-') return mmValue;

    // Обрабатываем значения с переносом строки
    if (mmValue.contains('\n')) {
      List<String> lines = mmValue.split('\n');
      return lines.map((line) => _convertValue(line, toUnit)).join('\n');
    }

    // Обрабатываем символы +/-
    String sign = '';
    if (mmValue.startsWith('+')) {
      sign = '+';
      mmValue = mmValue.substring(1);
    } else if (mmValue.startsWith('-')) {
      sign = '-';
      mmValue = mmValue.substring(1);
    }

    try {
      double valueMm = double.parse(mmValue);
      double convertedValue;
      String formattedValue = '';

      switch (toUnit) {
        case UnitSystem.millimeters:
          // Оставляем как есть
          return '$sign$mmValue';
          
        case UnitSystem.inches:
          convertedValue = valueMm * mmToInch;
          // Форматируем дюймовые значения с 5 знаками после запятой
          formattedValue = convertedValue.toStringAsFixed(5);
          break;
          
        case UnitSystem.microns:
          convertedValue = valueMm * mmToMicron;
          // Форматируем микронные значения как целые числа
          formattedValue = convertedValue.toStringAsFixed(0);
          break;
      }
      
      return '$sign$formattedValue';
    } catch (e) {
      // Если конвертация не удалась, возвращаем исходное значение
      return '$sign$mmValue';
    }
  }

  void _initDataGridRows() {
    // Сначала определяем все уникальные колонки из данных
    Set<String> uniqueColumnNames = {"Interval"};
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      for (var key in values.keys) {
        uniqueColumnNames.add(key);
      }
    });

    _columnNames = uniqueColumnNames.toList()..sort();
    // Перемещаем "Interval" в начало списка
    _columnNames.remove("Interval");
    _columnNames.insert(0, "Interval");

    // Создаем строки данных
    _rows = [];

    ToleranceConstants.toleranceValues.forEach((intervalMm, tolerances) {
      List<DataGridCell<String>> cells = [];
      String displayInterval = intervalMm;
      
      // Интервалы всегда отображаются в миллиметрах, независимо от выбранной системы единиц
      // Для каждой колонки ищем соответствующее значение
      for (String columnName in _columnNames) {
        String value = '';
        if (columnName == "Interval") {
          value = displayInterval;
        } else {
          String mmValue = tolerances[columnName] ?? '';
          
          // Конвертируем значения в нужные единицы
          value = (unitSystem == UnitSystem.millimeters) 
                  ? mmValue 
                  : _convertValue(mmValue, unitSystem);
        }

        cells.add(DataGridCell<String>(columnName: columnName, value: value));
      }

      _rows.add(DataGridRow(cells: cells));
    });
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map<Widget>((cell) {
            // Особое форматирование для первой колонки с интервалами
            bool isIntervalColumn = cell.columnName == 'Interval';
            String cellValue = cell.value.toString();

            // Для ячеек с переносом строки создаем многострочный текст
            Widget textWidget;
            if (cellValue.contains('\n')) {
              List<String> lines = cellValue.split('\n');
              textWidget = LayoutBuilder(
                builder: (context, constraints) {
                  // Вычисляем размер шрифта на основе ширины контейнера
                  // Начинаем с размера 12 и уменьшаем при необходимости
                  double fontSize = 12.0;
                  
                  // Находим самую длинную строку для определения минимального размера шрифта
                  String longestLine = lines.reduce((a, b) => a.length > b.length ? a : b);
                  
                  // Простой алгоритм для определения размера шрифта
                  // Если длина строки больше 6 символов, начинаем уменьшать шрифт
                  if (longestLine.length > 6) {
                    fontSize = 12.0 - (longestLine.length - 6) * 0.5;
                    fontSize = fontSize.clamp(8.0, 12.0); // Ограничиваем минимальный размер шрифта
                  }
                  
                  return Container(
                    constraints: const BoxConstraints(
                      minHeight: 40, // Минимальная высота для предотвращения переполнения
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: lines.map((line) => 
                        Text(
                          line,
                          style: TextStyle(
                            fontWeight: isIntervalColumn ? FontWeight.bold : FontWeight.normal,
                            fontSize: fontSize, // Динамически подобранный размер шрифта
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible, // Позволяем тексту отображаться полностью
                        )
                      ).toList(),
                    ),
                  );
                }
              );
            } else {
              // Для однострочных ячеек используем FittedBox для автомасштабирования
              textWidget = LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown, // Уменьшаем только если необходимо
                    alignment: Alignment.center,
                    child: Text(
                      cellValue,
                      style: TextStyle(
                        fontWeight: isIntervalColumn ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              );
            }

            return Container(
              padding: const EdgeInsets.all(8.0),
              color:
                  isIntervalColumn
                      ? Colors.blue.withAlpha(38)
                      : Colors.transparent,
              alignment: Alignment.center,
              child: textWidget,
            );
          }).toList(),
    );
  }
}