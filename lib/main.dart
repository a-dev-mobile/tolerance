import 'package:flutter/material.dart';
import 'package:mobile_tolerance/ToleranceConstants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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

  const ToleranceTablePage({Key? key, required this.setThemeMode})
    : super(key: key);

  @override
  State<ToleranceTablePage> createState() => _ToleranceTablePageState();
}

class _ToleranceTablePageState extends State<ToleranceTablePage> {
  late ToleranceDataSource _toleranceDataSource;
  final ScrollController _scrollController = ScrollController();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _toleranceDataSource = ToleranceDataSource();
    // Проверяем текущую тему при инициализации
    _isDarkMode =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        Theme.of(context).primaryColor.withOpacity(0.5),
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
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            alignment: Alignment.center,
            child: Text(
              columnName == "Interval" ? 'Interval\n(mm)' : columnName,
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

  ToleranceDataSource() {
    _initDataGridRows();
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

    ToleranceConstants.toleranceValues.forEach((interval, tolerances) {
      List<DataGridCell<String>> cells = [];

      // Для каждой колонки ищем соответствующее значение
      for (String columnName in _columnNames) {
        String value = '';
        if (columnName == "Interval") {
          value = interval;
        } else {
          value = tolerances[columnName] ?? '';
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

            return Container(
              padding: const EdgeInsets.all(8.0),
              color:
                  isIntervalColumn
                      ? Colors.blue.withOpacity(
                        0.15,
                      ) // Более тонкий оттенок для совместимости с темной темой
                      : Colors.transparent,
              alignment: Alignment.center,
              child: Text(
                cell.value.toString(),
                style: TextStyle(
                  fontWeight:
                      isIntervalColumn ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
    );
  }
}
