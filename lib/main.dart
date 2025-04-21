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
  
  final int _rowCount = 200;
  final int _colCount = 200;
  
  final double _cellWidth = 120.0;
  final double _cellHeight = 50.0;
  final double _firstColWidth = 100.0;
  final double _headerHeight = 50.0;
  
  // Добавляем дебаунсер для ограничения частоты синхронизации скролла
  DateTime _lastScrollUpdate = DateTime.now();
  static const _scrollThrottleDuration = Duration(milliseconds: 5);

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

  // Метод для дроттлинга синхронизации скролла
  void _throttledSync(ScrollController controller, double position) {
    final now = DateTime.now();
    if (now.difference(_lastScrollUpdate) > _scrollThrottleDuration) {
      _lastScrollUpdate = now;
      // Используем animateTo вместо jumpTo для более плавной анимации
      controller.jumpTo(position);
    }
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
              physics: const NeverScrollableScrollPhysics(),
              child: _buildHeaderCells(),
            ),
          ),
        ],
      ),
    );
  }

  // Выделяем метод для создания ячеек заголовка
  Widget _buildHeaderCells() {
    return Row(
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
    );
  }

  Widget _buildFirstColumn() {
    return SizedBox(
      width: _firstColWidth,
      child: ListView.builder(
        controller: _verticalController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _rowCount,
        itemExtent: _cellHeight,
        cacheExtent: 500, // Увеличиваем кэш для лучшей производительности скролла
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
        // Применяем дроттлинг для снижения нагрузки при скролле
        if (scrollInfo is ScrollUpdateNotification) {
          if (scrollInfo.metrics.axis == Axis.vertical) {
            _throttledSync(_verticalController, scrollInfo.metrics.pixels);
          } else if (scrollInfo.metrics.axis == Axis.horizontal) {
            _throttledSync(_horizontalController, scrollInfo.metrics.pixels);
          }
        }
        return false;
      },
      child: _buildDataTableContent(),
    );
  }
  
  Widget _buildDataTableContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        width: _cellWidth * _colCount,
        child: ListView.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: _rowCount,
          itemExtent: _cellHeight,
          cacheExtent: 1500, // Увеличиваем кэш для более плавного скролла
          itemBuilder: (context, rowIndex) {
            return _CachedRow(
              rowIndex: rowIndex,
              cellWidth: _cellWidth,
              cellHeight: _cellHeight,
              colCount: _colCount,
              tableData: _tableData,
            );
          },
        ),
      ),
    );
  }
}

// Выносим строку таблицы в отдельный StatelessWidget для улучшения производительности
class _CachedRow extends StatelessWidget {
  const _CachedRow({
    required this.rowIndex,
    required this.cellWidth,
    required this.cellHeight,
    required this.colCount,
    required this.tableData,
  });
  
  final int rowIndex;
  final double cellWidth;
  final double cellHeight;
  final int colCount;
  final List<List<String>> tableData;

  @override
  Widget build(BuildContext context) {
    // Используем более эффективный подход для строки - Row вместо ListView
    return Container(
      height: cellHeight,
      color: (rowIndex % 2 == 0) ? Colors.white : Colors.grey[50],
      child: Row(
        children: List.generate(
          colCount,
          (colIndex) => Container(
            width: cellWidth,
            height: cellHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              tableData[rowIndex][colIndex],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}