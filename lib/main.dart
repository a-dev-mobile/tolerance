import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Таблица допусков',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const ScrollableTableScreen(),
    );
  }
}

class ScrollableTableScreen extends StatefulWidget {
  const ScrollableTableScreen({Key? key}) : super(key: key);

  @override
  _ScrollableTableScreenState createState() => _ScrollableTableScreenState();
}

class _ScrollableTableScreenState extends State<ScrollableTableScreen> {
  // Контроллеры для синхронизации прокрутки
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  
  // Размеры ячеек и заголовков
  final double _rowHeight = 50.0;
  final double _firstColumnWidth = 120.0;
  final double _columnWidth = 80.0;
  
  // Данные для таблицы
  late List<String> _horizontalHeaders;
  late List<String> _verticalHeaders;
  late List<List<String>> _tableData;
  
  // Количество строк и столбцов
  final int _rowCount = 100; // Количество строк
  final int _columnCount = 100; // Количество столбцов
  
  @override
  void initState() {
    super.initState();
    _generateTableData();
  }
  
  // Генерируем данные для таблицы допусков
  void _generateTableData() {
    // Создаем заголовки столбцов (допуски)
    final List<String> fitTypes = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'js', 'k', 'm', 'n', 'p', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z', 'za', 'zb', 'zc'];
    final List<String> fitGrades = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18'];
    
    _horizontalHeaders = [];
    
    // Добавляем малые буквы (отверстия)
    for (var type in fitTypes) {
      for (var grade in fitGrades) {
        _horizontalHeaders.add('$type$grade');
      }
    }
    
    // Добавляем большие буквы (валы)
    for (var type in fitTypes) {
      String upperType = type.toUpperCase();
      for (var grade in fitGrades) {
        _horizontalHeaders.add('$upperType$grade');
      }
    }
    
    // Создаем заголовки строк (диаметры)
    _verticalHeaders = List.generate(_rowCount, (index) => 'Ø ${index + 1} мм');
    
    // Создаем данные таблицы
    _tableData = List.generate(_rowCount, (rowIndex) {
      return List.generate(_columnCount, (colIndex) {
        // Здесь можно добавить реальные данные допусков
        // Для примера генерируем случайные значения
        final sign = (rowIndex + colIndex) % 3 == 0 ? '+' : '-';
        final value = ((rowIndex + 1) * (colIndex + 1)) % 100;
        return '$sign$value';
      });
    });
  }
  
  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица допусков'),
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Таблица допусков ISO для валов и отверстий',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _buildScrollableTable(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScrollableTable() {
    return Stack(
      children: [
        // 1. Основная часть таблицы (прокручиваемая во всех направлениях)
        Positioned.fill(
          top: _rowHeight,
          left: _firstColumnWidth,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              // Синхронизируем горизонтальную прокрутку
              if (notification is ScrollUpdateNotification &&
                  notification.metrics.axis == Axis.horizontal) {
                _horizontalController.jumpTo(_horizontalController.offset + notification.scrollDelta!);
              }
              // Синхронизируем вертикальную прокрутку
              if (notification is ScrollUpdateNotification &&
                  notification.metrics.axis == Axis.vertical) {
                _verticalController.jumpTo(_verticalController.offset + notification.scrollDelta!);
              }
              return true;
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const ClampingScrollPhysics(),
                child: _buildMainTable(),
              ),
            ),
          ),
        ),
        
        // 2. Фиксированный левый верхний угол
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: _firstColumnWidth,
            height: _rowHeight,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'Размер / Допуск',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        // 3. Фиксированная верхняя строка (прокручивается только по горизонтали)
        Positioned(
          top: 0,
          left: _firstColumnWidth,
          right: 0,
          height: _rowHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalController,
            physics: const ClampingScrollPhysics(),
            child: _buildHorizontalHeaderRow(),
          ),
        ),
        
        // 4. Фиксированная левая колонка (прокручивается только по вертикали)
        Positioned(
          top: _rowHeight,
          left: 0,
          bottom: 0,
          width: _firstColumnWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: _verticalController,
            physics: const ClampingScrollPhysics(),
            child: _buildVerticalHeaderColumn(),
          ),
        ),
      ],
    );
  }
  
  // Строит основную часть таблицы (все данные)
  Widget _buildMainTable() {
    return Table(
      columnWidths: Map.fromIterable(
        List.generate(_columnCount, (index) => index),
        key: (index) => index,
        value: (index) => FixedColumnWidth(_columnWidth),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.grey.shade300),
      children: List.generate(_rowCount, (rowIndex) {
        return TableRow(
          children: List.generate(_columnCount, (colIndex) {
            // Определяем цвет ячейки в зависимости от типа допуска
            final headerText = _horizontalHeaders[colIndex];
            Color cellColor = Colors.white;
            
            // Если это допуск отверстия (маленькая буква)
            if (headerText[0].toLowerCase() == headerText[0]) {
              cellColor = Colors.blue.shade50;
            } 
            // Если это допуск вала (большая буква)
            else {
              cellColor = Colors.green.shade50;
            }
            
            // Применяем дополнительные стили в зависимости от значения
            final value = _tableData[rowIndex][colIndex];
            if (value.startsWith('+')) {
              cellColor = value.startsWith('+0') ? cellColor : Colors.green.shade100;
            } else if (value.startsWith('-')) {
              cellColor = value.startsWith('-0') ? cellColor : Colors.red.shade100;
            }
            
            return Container(
              height: _rowHeight,
              color: cellColor,
              child: Center(
                child: Text(
                  _tableData[rowIndex][colIndex],
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        );
      }),
    );
  }
  
  // Строит строку заголовков (типы допусков)
  Widget _buildHorizontalHeaderRow() {
    return Row(
      children: List.generate(_columnCount, (index) {
        final headerText = _horizontalHeaders[index];
        
        // Определяем цвет заголовка
        Color headerColor;
        Color textColor = Colors.white;
        
        // Если это допуск отверстия (маленькая буква)
        if (headerText[0].toLowerCase() == headerText[0]) {
          headerColor = Colors.blue.shade600;
        } 
        // Если это допуск вала (большая буква)
        else {
          headerColor = Colors.green.shade600;
        }
        
        return Container(
          width: _columnWidth,
          height: _rowHeight,
          decoration: BoxDecoration(
            color: headerColor,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }
  
  // Строит колонку заголовков (размеры)
  Widget _buildVerticalHeaderColumn() {
    return Column(
      children: List.generate(_rowCount, (index) {
        return Container(
          width: _firstColumnWidth,
          height: _rowHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              _verticalHeaders[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }
}