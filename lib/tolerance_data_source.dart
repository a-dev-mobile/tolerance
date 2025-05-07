// tolerance_data_source.dart - Источник данных для таблицы допусков
// Управляет данными таблицы и их отображением

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tolerance/core/models/tolerance_filter.dart';
import 'package:tolerance/core/utils/unit_converter.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tolerance/core/constants/tolerance_constants.dart';
import 'core/models/unit_system.dart';

// Класс-источник данных для таблицы допусков
class ToleranceDataSource extends DataGridSource {
  late List<DataGridRow> _rows;
  late List<String> _columnNames;
  final UnitSystem unitSystem; // Система единиц измерения
  final ToleranceFilter? toleranceFilter;

  ToleranceDataSource({required this.unitSystem, this.toleranceFilter}) {
    _initDataGridRows();
  }

  // Инициализация строк данных для таблицы
  void _initDataGridRows() {
    // Используем LinkedHashSet для сохранения порядка вставки
    Set<String> uniqueColumnNames = LinkedHashSet<String>();
    uniqueColumnNames.add("Interval"); // Всегда первая

    // Проходим по данным в том порядке, в котором они определены в ToleranceConstants
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      // Для каждого интервала перебираем ключи (допуски) в порядке их объявления
      for (var key in values.keys) {
        // Only add columns that pass the filter or if no filter is set
        if (key == "Interval" ||
            toleranceFilter == null ||
            toleranceFilter!.isVisible(key)) {
          uniqueColumnNames.add(key);
        }
      }
    });

    // Преобразуем в список, сохраняя порядок добавления
    List<String> unsortedColumnNames = uniqueColumnNames.toList();
    
    // Создаем отсортированную копию, сначала удаляя "Interval"
    _columnNames = unsortedColumnNames.where((name) => name != "Interval").toList();
    // Сортируем буквенные обозначения допусков
    _sortTolerancesByNaturalOrder(_columnNames);
    // Вставляем "Interval" обратно как первую колонку
    _columnNames.insert(0, "Interval");

    // Создаем строки данных
    _rows = [];

    ToleranceConstants.toleranceValues.forEach((intervalMm, tolerances) {
      List<DataGridCell<String>> cells = [];
      String displayInterval = intervalMm;

      // Перебираем колонки В ТОМ ЖЕ ПОРЯДКЕ как в _columnNames
      for (String columnName in _columnNames) {
        String value = '';
        if (columnName == "Interval") {
          value = displayInterval;
        } else {
          String mmValue = tolerances[columnName] ?? '';

          // Конвертируем значения в нужные единицы
          value =
              (unitSystem == UnitSystem.millimeters)
                  ? mmValue
                  : _convertValue(mmValue, unitSystem);
        }

        cells.add(DataGridCell<String>(columnName: columnName, value: value));
      }

      _rows.add(DataGridRow(cells: cells));
    });
  }

  // Modify the getAllColumnNames method to filter the columns:
  void getAllColumnNames(Set<String> uniqueColumnNames) {
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      for (var key in values.keys) {
        // Only add columns that pass the filter or if no filter is set
        if (key == "Interval" ||
            toleranceFilter == null ||
            toleranceFilter!.isVisible(key)) {
          uniqueColumnNames.add(key);
        }
      }
    });
  }

  // Natural sort for tolerances like h1, h2, h3...h11 instead of h1, h11, h2...
 void _sortTolerancesByNaturalOrder(List<String> tolerances) {
  tolerances.sort((a, b) {
    // Extract letter prefix and number part for both designations
    RegExp letterRegex = RegExp(r'^([a-zA-Z]+)');
    RegExp numRegex = RegExp(r'(\d+)');
    
    Match? matchA = letterRegex.firstMatch(a);
    Match? matchB = letterRegex.firstMatch(b);
    Match? numMatchA = numRegex.firstMatch(a);
    Match? numMatchB = numRegex.firstMatch(b);
    
    String prefixA = matchA?.group(1) ?? '';
    String prefixB = matchB?.group(1) ?? '';
    
    // Convert prefixes to lowercase for comparison to group same letters
    String lowerPrefixA = prefixA.toLowerCase();
    String lowerPrefixB = prefixB.toLowerCase();
    
    // If lowercase prefixes are different, sort by lowercase prefix
    if (lowerPrefixA != lowerPrefixB) {
      return lowerPrefixA.compareTo(lowerPrefixB);
    }
    
    // If the same letter (ignoring case), extract numbers
    int numA = numMatchA != null ? int.parse(numMatchA.group(1) ?? '0') : 0;
    int numB = numMatchB != null ? int.parse(numMatchB.group(1) ?? '0') : 0;
    
    // If numerical parts are different, sort by numerical value
    if (numA != numB) {
      return numA.compareTo(numB);
    }
    
    // If same letter and number, uppercase comes before lowercase
    return a.compareTo(b);
  });
}

  // Получает индекс колонки по её имени
  int getColumnIndex(String columnName) {
    return _columnNames.indexOf(columnName);
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
      cells:
          row.getCells().map<Widget>((cell) {
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
            } else if (unitSystem == UnitSystem.millimeters &&
                !isIntervalColumn) {
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
              child:
                  unitSystem == UnitSystem.millimeters && !isIntervalColumn
                      ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              null, // Обработка тапа происходит в _handleCellTap
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
              fontWeight:
                  isIntervalColumn ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
