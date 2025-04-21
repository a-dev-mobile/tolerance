// tolerance_data_source.dart - Источник данных для таблицы допусков
// Управляет данными таблицы и их отображением

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:mobile_tolerance/tolerance_constants.dart';
import 'unit_system.dart';

// Класс-источник данных для таблицы допусков
class ToleranceDataSource extends DataGridSource {
  late List<DataGridRow> _rows;
  late List<String> _columnNames;
  final UnitSystem unitSystem; // Система единиц измерения

  ToleranceDataSource({required this.unitSystem}) {
    _initDataGridRows();
  }

  // Инициализация строк данных для таблицы
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

  // Заполняет набор всех имен колонок
  void getAllColumnNames(Set<String> uniqueColumnNames) {
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      for (var key in values.keys) {
        uniqueColumnNames.add(key);
      }
    });
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
          convertedValue = valueMm * UnitConverter.mmToInch;
          // Форматируем дюймовые значения с 5 знаками после запятой
          formattedValue = convertedValue.toStringAsFixed(toUnit.decimalPlaces);
          break;
          
        case UnitSystem.microns:
          convertedValue = valueMm * UnitConverter.mmToMicron;
          // Форматируем микронные значения как целые числа
          formattedValue = convertedValue.toStringAsFixed(toUnit.decimalPlaces);
          break;
      }
      
      return '$sign$formattedValue';
    } catch (e) {
      // Если конвертация не удалась, возвращаем исходное значение
      return '$sign$mmValue';
    }
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        // Особое форматирование для первой колонки с интервалами
        bool isIntervalColumn = cell.columnName == 'Interval';
        String cellValue = cell.value.toString();

        // Для ячеек с переносом строки создаем многострочный текст
        Widget textWidget;
        if (cellValue.contains('\n')) {
          textWidget = _buildSingleLineCell(cellValue, isIntervalColumn);
        } else {
          // Для однострочных ячеек используем FittedBox для автомасштабирования
          textWidget = _buildSingleLineCell(cellValue, isIntervalColumn);
        }

      // Определяем цвет фона ячейки в зависимости от типа колонки и единиц измерения
      Color backgroundColor;
      if (isIntervalColumn) {
        backgroundColor = Colors.blue.withAlpha(38);
      } else if (unitSystem == UnitSystem.millimeters && !isIntervalColumn) {
        // Для кликабельных ячеек в режиме мм добавляем легкую подсветку
        backgroundColor = Colors.green.withAlpha(15);
      } else {
        backgroundColor = Colors.transparent;
      }

      return Container(
        padding: const EdgeInsets.all(8.0),
        color: backgroundColor,
        alignment: Alignment.center,
        // Для кликабельных ячеек (мм) добавляем эффект материала и курсор-указатель
        child: unitSystem == UnitSystem.millimeters && !isIntervalColumn
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null, // Обработка тапа происходит в _handleCellTap
                  splashColor: Colors.blue.withAlpha(30),
                  hoverColor: Colors.blue.withAlpha(15),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: textWidget,
                  ),
                ),
              )
            : textWidget,
      );
    }).toList(),
  );
}

  // Создает виджет для однострочной ячейки
  Widget _buildSingleLineCell(String cellValue, bool isIntervalColumn) {
    return LayoutBuilder(
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
}