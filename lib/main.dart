import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Двусторонняя прокрутка таблицы',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const OptimizedDataTableExample(),
    );
  }
}

class OptimizedDataTableExample extends StatefulWidget {
  const OptimizedDataTableExample({Key? key}) : super(key: key);

  @override
  State<OptimizedDataTableExample> createState() => _OptimizedDataTableExampleState();
}

class _OptimizedDataTableExampleState extends State<OptimizedDataTableExample> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  
  // Генерируем большой набор данных
  late final List<List<String>> _tableData;
  
  final int _rowCount = 1000;  // Увеличиваем количество строк для проверки производительности
  final int _colCount = 100;   // Увеличиваем количество колонок
  
  final double _cellWidth = 120.0;
  final double _cellHeight = 50.0;
  final double _firstColWidth = 100.0;
  final double _headerHeight = 50.0;

  @override
  void initState() {
    super.initState();
    // Инициализируем данные только один раз
    _tableData = List.generate(
      _rowCount,
      (rowIndex) => List.generate(
        _colCount,
        (colIndex) => 'Ячейка R${rowIndex + 1}C${colIndex + 1}',
      ),
    );
  }
  
  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оптимизированная таблица'),
      ),
      body: Column(
        children: [
          _buildHeaderRow(),
          Expanded(
            child: Row(
              children: [
                _buildFirstColumn(),
                Expanded(child: _buildOptimizedDataTable()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          Container(
            width: _firstColWidth,
            height: _headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              border: Border.all(color: Colors.grey),
            ),
            child: const Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Отключаем собственную прокрутку
              child: Row(
                children: List.generate(
                  _colCount,
                  (index) => Container(
                    width: _cellWidth,
                    height: _headerHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      'Col ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstColumn() {
    return SizedBox(
      width: _firstColWidth,
      child: ListView.builder(
        controller: _verticalController,
        physics: const NeverScrollableScrollPhysics(), // Отключаем собственную прокрутку
        itemCount: _rowCount,
        itemExtent: _cellHeight, // Фиксированная высота для повышения производительности
        itemBuilder: (context, rowIndex) => Container(
          width: _firstColWidth,
          height: _cellHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.grey),
          ),
          child: Text(
            'Row ${rowIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedDataTable() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Обрабатываем вертикальную прокрутку данных - синхронизируем с первой колонкой
        if (scrollInfo is ScrollUpdateNotification && 
            scrollInfo.metrics.axis == Axis.vertical) {
          _verticalController.jumpTo(scrollInfo.metrics.pixels);
        }
        // Обрабатываем горизонтальную прокрутку данных - синхронизируем с заголовком
        if (scrollInfo is ScrollUpdateNotification && 
            scrollInfo.metrics.axis == Axis.horizontal) {
          _horizontalController.jumpTo(scrollInfo.metrics.pixels);
        }
        return false; // Позволяем событию продолжить распространение
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: _cellWidth * _colCount,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: _rowCount,
            itemExtent: _cellHeight, // Фиксированная высота для повышения производительности
            itemBuilder: (context, rowIndex) {
              return SizedBox(
                height: _cellHeight,
                child: _buildOptimizedRow(rowIndex),
              );
            },
          ),
        ),
      ),
    );
  }

  // Используем ListView.builder для ячеек для оптимизации рендеринга
  Widget _buildOptimizedRow(int rowIndex) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Отключаем прокрутку для строки
      itemCount: _colCount,
      itemExtent: _cellWidth, // Фиксированная ширина для повышения производительности
      itemBuilder: (context, colIndex) {
        return Container(
          width: _cellWidth,
          height: _cellHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            color: (rowIndex % 2 == 0) ? Colors.white : Colors.grey[50],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            _tableData[rowIndex][colIndex],
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      },
    );
  }
}