// tolerance_table_page.dart - Основная страница с таблицей допусков
// Содержит виджет страницы и его логику

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tolerance_data_source.dart';
import 'unit_system.dart';
import 'value_input_dialog.dart';

// Константы для ключей SharedPreferences
const String _keyScrollPositionX = 'scrollPositionX';
const String _keyScrollPositionY = 'scrollPositionY';

// Виджет страницы с таблицей допусков
class ToleranceTablePage extends StatefulWidget {
  // Функция для изменения темы всего приложения
  final Function(ThemeMode) setThemeMode;

  const ToleranceTablePage({super.key, required this.setThemeMode});

  @override
  State<ToleranceTablePage> createState() => _ToleranceTablePageState();
}

// Состояние страницы с таблицей допусков
class _ToleranceTablePageState extends State<ToleranceTablePage> {
  // Источник данных для таблицы
  late ToleranceDataSource _toleranceDataSource;
  
  // Контроллеры прокрутки для вертикальной и горизонтальной прокрутки
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  
  // Текущий режим темы (темная/светлая)
  bool _isDarkMode = false;
  
  // Текущая система единиц измерения (миллиметры по умолчанию)
  UnitSystem _currentUnit = UnitSystem.millimeters;
  
  // Флаг для отслеживания, загружены ли данные прокрутки
  bool _scrollPositionRestored = false;

  @override
  void initState() {
    super.initState();
    // Инициализация источника данных с текущей системой единиц
    _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    // Изначально устанавливаем темный режим в false,
    // правильное значение будет установлено в didChangeDependencies
    _isDarkMode = false;
    
    // Загружаем сохраненную позицию прокрутки
    _loadScrollPosition();
    
    // Добавляем слушатели для сохранения позиции прокрутки при прокрутке
    _verticalScrollController.addListener(_saveScrollPosition);
    _horizontalScrollController.addListener(_saveScrollPosition);
  }
  
  // Загрузка сохраненной позиции прокрутки
  Future<void> _loadScrollPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedScrollX = prefs.getDouble(_keyScrollPositionX);
      final double? savedScrollY = prefs.getDouble(_keyScrollPositionY);
      
      // Восстанавливаем позицию прокрутки, если она была сохранена
      if (savedScrollX != null && savedScrollY != null) {
        // Используем Future.delayed, чтобы дать таблице время на инициализацию
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (_horizontalScrollController.hasClients && savedScrollX <= _horizontalScrollController.position.maxScrollExtent) {
              _horizontalScrollController.jumpTo(savedScrollX);
            }
            
            if (_verticalScrollController.hasClients && savedScrollY <= _verticalScrollController.position.maxScrollExtent) {
              _verticalScrollController.jumpTo(savedScrollY);
            }
            
            setState(() {
              _scrollPositionRestored = true;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке позиции прокрутки: $e');
    }
  }
  
  // Сохранение текущей позиции прокрутки
  Future<void> _saveScrollPosition() async {
    // Сохраняем только если не находимся в процессе восстановления
    if (!_scrollPositionRestored) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_horizontalScrollController.hasClients) {
        await prefs.setDouble(_keyScrollPositionX, _horizontalScrollController.offset);
      }
      
      if (_verticalScrollController.hasClients) {
        await prefs.setDouble(_keyScrollPositionY, _verticalScrollController.offset);
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении позиции прокрутки: $e');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Безопасно проверяем текущую тему здесь, после того как виджет встроен в дерево
    _isDarkMode = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  void dispose() {
    // Сохраняем позицию прокрутки перед уничтожением виджета
    _saveScrollPosition();
    
    // Удаляем слушатели
    _verticalScrollController.removeListener(_saveScrollPosition);
    _horizontalScrollController.removeListener(_saveScrollPosition);
    
    // Освобождаем ресурсы
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Метод для циклического переключения единиц измерения
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
      body: NotificationListener<ScrollNotification>(
        // Добавляем обработчик прокрутки для сохранения позиции
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification) {
            _saveScrollPosition();
          }
          return false;
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              _buildAppBar(innerBoxIsScrolled),
            ];
          },
          body: _buildDataGrid(),
        ),
      ),
    );
  }
  
  // Создание аппбара с заголовком и кнопками
  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      title: Row(
        children: [
          const Text('Допуски'),
          if (_currentUnit == UnitSystem.millimeters)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: 'Ячейки кликабельны в режиме мм',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Кликабельно',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      pinned: false,     // Не фиксировать верхнюю часть аппбара при прокрутке
      floating: true,    // Позволяет аппбару появляться при прокрутке вверх
      snap: true,        // Быстрое появление аппбара при небольшой прокрутке вверх
      forceElevated: innerBoxIsScrolled,
      actions: [
        // Кнопка переключения единиц измерения
        IconButton(
          icon: Text(
            _currentUnit.symbol,
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
          onPressed: _toggleTheme,
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
    );
  }
  
  // Метод для переключения темы
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Применяем тему ко всему приложению
      final themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      widget.setThemeMode(themeMode);
    });
  }
  
  // Создание таблицы данных
  Widget _buildDataGrid() {
    return SfDataGrid(
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
      onCellTap: _handleCellTap,
      // Добавляем контроллеры прокрутки для сохранения позиции
      verticalScrollController: _verticalScrollController,
      horizontalScrollController: _horizontalScrollController,
    );
  }
  
  // Обработка нажатия на ячейку
  void _handleCellTap(DataGridCellTapDetails details) {
    // Обрабатываем нажатия только если выбраны миллиметры
    if (_currentUnit != UnitSystem.millimeters) return;

    // Пропускаем нажатия на заголовок (индекс 0)
    if (details.rowColumnIndex.rowIndex == 0) return;
    
    // Получаем данные о нажатой ячейке
    DataGridRow row = _toleranceDataSource.rows[details.rowColumnIndex.rowIndex - 1];
    String columnName = _buildGridColumns()[details.rowColumnIndex.columnIndex].columnName;
    String cellValue = row.getCells().firstWhere((cell) => cell.columnName == columnName).value.toString();
    
    // Если это колонка с интервалом, не показываем диалог
    if (columnName == 'Interval') return;
    
    // Показываем диалог ввода значения
    showValueInputDialog(
      context: context, 
      columnName: columnName, 
      toleranceValue: cellValue,
      currentUnit: _currentUnit
    );
  }

  // Создание колонок для таблицы
  List<GridColumn> _buildGridColumns() {
    // Получаем все уникальные имена колонок из данных
    Set<String> uniqueColumnNames = {"Interval"};
    _toleranceDataSource.getAllColumnNames(uniqueColumnNames);

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
                ? 'Interval\n(mm)'  // Интервалы всегда в мм
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