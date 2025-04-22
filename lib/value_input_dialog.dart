// value_input_dialog.dart - Диалог для ввода значения и применения допуска
// Отображает диалог, где пользователь может ввести значение и увидеть применение допуска

import 'package:flutter/material.dart';
import 'package:mobile_tolerance/tolerance_constants.dart';
import 'dart:math';
import 'unit_system.dart';

// Показывает диалог для ввода значения, к которому будет применен допуск
void showValueInputDialog({
  required BuildContext context, 
  required String columnName, 
  required String toleranceValue,
  required UnitSystem currentUnit
}) {
  // Контроллер для текстового поля
  final TextEditingController controller = TextEditingController();
  
  // Переменные для хранения результатов
  double baseValue = 0.0;
  String minValueStr = '-';
  String maxValueStr = '-';
  String nominalValueStr = '-';
  String avgValueStr = '-'; // Добавляем среднее значение
  
  // Переменные для работы с интервалами
  String currentInterval = 'Не определено';
  bool isWithinInterval = true;
  String recommendedInterval = '';
  double maxValueInTolerance = 500.0; // Значение по умолчанию
  
// Определяем, это допуск для вала или отверстия
String typeOfPart = 'Не определено';
if (columnName.isNotEmpty) {
  // Ищем первую букву в строке допуска
  RegExp letterRegex = RegExp(r'[A-Za-z]');
  Match? match = letterRegex.firstMatch(columnName);
  
  if (match != null) {
    String letter = match.group(0) ?? '';
    
    // Простое правило:
    // Если буква заглавная (A-Z) - отверстие
    // Если буква строчная (a-z) - вал
    if (letter == letter.toUpperCase()) {
      typeOfPart = 'Отверстие';
    } else {
      typeOfPart = 'Вал';
    }
  }
}
  
  // Цвета для визуального выделения значений
  // Получаем цвета исходя из текущей темы для лучшей совместимости с темной темой
  final Brightness brightness = Theme.of(context).brightness;
  final bool isDarkMode = brightness == Brightness.dark;
  
  // Настраиваем цвета с учетом темы
  final Color minColor = isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
  final Color maxColor = isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
  final Color avgColor = isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
  final Color nominalColor = isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
  final Color warningColor = isDarkMode ? Colors.deepOrange.shade300 : Colors.deepOrange;
  final Color infoColor = isDarkMode ? Colors.indigo.shade300 : Colors.indigo;
  
  // Фоновые цвета для контейнеров, адаптированные под тему
  final Color cardBackground = isDarkMode 
      ? Colors.grey.shade800.withValues(alpha: 70) 
      : Colors.grey.shade200.withValues(alpha: 150);
      
  final Color valueRowBackground = isDarkMode 
      ? Colors.grey.shade900.withValues(alpha: 70) 
      : Colors.white.withValues(alpha: 210);

  // Функция для парсинга границ интервала
  List<double> parseIntervalBoundaries(String intervalStr) {
    // Формат: "0 > 3", "3 > 6", "24 > 30" и т.д.
    List<double> result = [];
    
    // Разделяем строку по символу >
    List<String> parts = intervalStr.split('>');
    if (parts.length != 2) return [];
    
    try {
      // Парсим первое значение (минимум)
      double min = double.parse(parts[0].trim());
      // Парсим второе значение (максимум)
      double max = double.parse(parts[1].trim());
      
      result = [min, max];
    } catch (e) {
      return [];
    }
    
    return result;
  }

  // Функция для определения интервала по значению
  String findIntervalForValue(double inputValue) {
    String result = 'Не определено';
    double closestDiff = double.infinity;
    String closestIntervalBelow = '';
    String closestIntervalAbove = '';
    double maxAllowedValue = 0.0; // Максимальное значение среди всех интервалов
    
    // Проходим по всем интервалам в ToleranceConstants
    for (String intervalKey in ToleranceConstants.toleranceValues.keys) {
      // Парсим границы интервала
      List<double> boundaries = parseIntervalBoundaries(intervalKey);
      if (boundaries.isEmpty || boundaries.length != 2) continue;
      
      double min = boundaries[0];
      double max = boundaries[1];
      
      // Обновляем максимальное значение
      if (max > maxAllowedValue) {
        maxAllowedValue = max;
      }
      
      // Если значение попадает в интервал
      if (inputValue >= min && inputValue <= max) {
        return intervalKey;
      }
      
      // Если значение меньше минимума, сохраняем ближайший интервал сверху
      if (inputValue < min && (min - inputValue < closestDiff)) {
        closestDiff = min - inputValue;
        closestIntervalAbove = intervalKey;
      }
      
      // Если значение больше максимума, сохраняем ближайший интервал снизу
      if (inputValue > max && (inputValue - max < closestDiff)) {
        closestDiff = inputValue - max;
        closestIntervalBelow = intervalKey;
      }
    }
    
    // Если интервал не найден, возвращаем ближайший и сохраняем максимальное значение
    if (result == 'Не определено') {
      if (closestIntervalBelow.isNotEmpty) {
        recommendedInterval = closestIntervalBelow;
      } else if (closestIntervalAbove.isNotEmpty) {
        recommendedInterval = closestIntervalAbove;
      }
      
      // Сохраняем максимальное значение для сообщения об ошибке
      maxValueInTolerance = maxAllowedValue;
    }
    
    return result;
  }
  

  // Парсим значение допуска - возвращает список значений отклонений
  List<double> parseTolerance(String toleranceStr) {
    if (toleranceStr.isEmpty || toleranceStr == '-') return [];
    
    // Результат: [нижнее отклонение, верхнее отклонение]
    List<double> result = [];
    
    // Разбиваем на строки, если есть
    List<String> lines = toleranceStr.split('\n');
    
    for (String line in lines) {
      if (line.isEmpty) continue;
      
      // Очищаем строку и получаем знак
      String cleanLine = line.trim();
      String sign = '';
      
      if (cleanLine.startsWith('+')) {
        sign = '+';
        cleanLine = cleanLine.substring(1);
      } else if (cleanLine.startsWith('-')) {
        sign = '-';
        cleanLine = cleanLine.substring(1);
      }
      
      try {
        double value = double.parse(cleanLine);
        // Применяем знак
        if (sign == '-') value = -value;
        
        result.add(value);
      } catch (e) {
        continue;
      }
    }
    
    return result;
  }

  // Получаем значение допуска для текущего интервала
  String getUpdatedToleranceForInterval(String originalTolerance, String intervalKey) {
    if (intervalKey == 'Не определено' || intervalKey == 'Ошибка') {
      return originalTolerance;
    }
    
    // Получаем значения допусков для найденного интервала
    Map<String, String>? intervalTolerances = ToleranceConstants.toleranceValues[intervalKey];
    if (intervalTolerances == null) {
      return originalTolerance;
    }
    
    // Проверяем, есть ли допуск с таким же именем для нового интервала
    String? newTolerance = intervalTolerances[columnName];
    if (newTolerance == null || newTolerance.isEmpty) {
      return originalTolerance; // Если нет, оставляем оригинальное значение
    }
    
    return newTolerance;
  }

  // Вычисляем граничные значения на основе введенного базового значения
  void calculateValues(String inputValue) {
    try {
      // Всегда интерпретируем ввод как миллиметры
      baseValue = double.parse(inputValue);
      
      // Определяем, к какому интервалу относится значение
      currentInterval = findIntervalForValue(baseValue);
      isWithinInterval = currentInterval != 'Не определено';
      
      // Обновляем значение допуска, если интервал изменился
      String updatedToleranceValue = getUpdatedToleranceForInterval(toleranceValue, currentInterval);
      
      // Парсим допуск
      List<double> toleranceValues = parseTolerance(updatedToleranceValue);
      
      if (toleranceValues.isEmpty) {
        minValueStr = '-';
        maxValueStr = '-';
        avgValueStr = '-';
        nominalValueStr = UnitConverter.formatValue(baseValue, currentUnit);
        return;
      }
      
      // Если только одно значение допуска (несимметричный допуск)
      if (toleranceValues.length == 1) {
        double tolerance = toleranceValues[0];
        double minValue, maxValue;
        
        if (tolerance >= 0) {
          // Положительный допуск: базовое значение + допуск
          minValue = baseValue;
          maxValue = baseValue + tolerance;
        } else {
          // Отрицательный допуск: базовое значение - допуск
          minValue = baseValue + tolerance;  // tolerance уже отрицательный
          maxValue = baseValue;
        }
        
        // Вычисляем среднее значение
        double avgValue = (minValue + maxValue) / 2;

        // Конвертируем значения в выбранные единицы измерения
        minValueStr = UnitConverter.formatValue(minValue, currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, currentUnit);
      } 
      // Если два значения допуска (диапазон)
      else if (toleranceValues.length >= 2) {
        // Сортируем, чтобы быть уверенными, что первый меньше
        toleranceValues.sort();
        
        double minValue = baseValue + toleranceValues[0];
        double maxValue = baseValue + toleranceValues[toleranceValues.length - 1];
        
        // Вычисляем среднее значение
        double avgValue = (minValue + maxValue) / 2;
        
        // Конвертируем значения в выбранные единицы измерения
        minValueStr = UnitConverter.formatValue(minValue, currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, currentUnit);
      }
      
      // Форматируем номинальное значение
      nominalValueStr = UnitConverter.formatValue(baseValue, currentUnit);
    } catch (e) {
      nominalValueStr = 'Ошибка';
      minValueStr = '-';
      maxValueStr = '-';
      avgValueStr = '-';
      currentInterval = 'Ошибка';
      isWithinInterval = false;
    }
  }
  
  // Создаем виджет для отображения значения с иконкой
  Widget buildValueRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: valueRowBackground,
        border: Border.all(
          color: color.withValues(alpha: 40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 20),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label, 
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // Создаем виджет для отображения информации об интервале
  Widget buildIntervalInfo(bool isWithinInterval, String interval, String recommended) {
    final Color bgColor = isWithinInterval 
        ? isDarkMode ? infoColor.withValues(alpha: 20) : infoColor.withValues(alpha: 10)
        : isDarkMode ? Colors.red.shade900.withValues(alpha: 70) : Colors.red.shade100.withValues(alpha: 180);
        
    final Color borderColor = isWithinInterval 
        ? isDarkMode ? infoColor.withValues(alpha: 80) : infoColor.withValues(alpha: 40)
        : isDarkMode ? Colors.red.withValues(alpha: 150) : Colors.red.withValues(alpha: 140);
    
    final IconData iconData = isWithinInterval 
        ? Icons.check_circle 
        : Icons.error;
        
    final Color iconColor = isWithinInterval 
        ? infoColor 
        : isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isWithinInterval ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWithinInterval 
                      ? 'В интервале: $interval'
                      : 'Ошибка! Значение вне допустимого диапазона',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWithinInterval ? 14 : 15,
                    color: isWithinInterval ? infoColor : iconColor,
                  ),
                ),
                if (!isWithinInterval) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Введите значение до $maxValueInTolerance мм',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode 
                          ? Colors.red.shade200
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Строка для отображения текущего допуска, который будет обновляться
  String displayedToleranceValue = toleranceValue;

  // Создаем stateful билдер для обновления результатов при вводе
  StatefulBuilder statefulBuilder = StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        elevation: 8,
        title: Text(
              'Расчет размеров $columnName',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),
            ),
      
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Отображаем информацию о детали только если нет ошибки
              if (controller.text.isEmpty || isWithinInterval)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 10),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$typeOfPart ($columnName)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                    
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.text.isEmpty ? "" : controller.text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          // Используем обновляемое значение допуска
                          controller.text.isEmpty ? toleranceValue : displayedToleranceValue,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: typeOfPart == 'Отверстие' 
                                ? isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700
                                : isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Отступ перед полем ввода зависит от наличия карточки выше
              SizedBox(height: (controller.text.isEmpty || isWithinInterval) ? 16 : 8),
              
              // Поле ввода базового значения с иконкой и подсказкой "всегда в мм"
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Номинальный размер',
                  hintText: 'Например: 10.5',
                  prefixIcon: const Icon(Icons.edit),
                  suffixText: 'мм',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    // Получаем текущий интервал
                    String newInterval = value.isEmpty ? 'Не определено' : findIntervalForValue(double.tryParse(value) ?? 0.0);
                    
                    // Получаем обновленное значение допуска для этого интервала
                    if (newInterval != 'Не определено' && newInterval != 'Ошибка') {
                      displayedToleranceValue = getUpdatedToleranceForInterval(toleranceValue, newInterval);
                    } else {
                      displayedToleranceValue = toleranceValue;
                    }
                    
                    // Вычисляем значения с обновленным допуском
                    calculateValues(value);
                    
                    // Обновление происходит, так как setState вызывает перестроение всего виджета
                  });
                },
                autofocus: true,
              ),
              const SizedBox(height: 20),
              
              // Информация об интервале (если введено значение)
              if (controller.text.isNotEmpty)
                buildIntervalInfo(isWithinInterval, currentInterval, recommendedInterval),
              
              const SizedBox(height: 20),
              
              // Показываем значения только если значение в интервале
              if (controller.text.isEmpty || isWithinInterval) ...[
                // Используем созданный нами виджет для отображения значений
                buildValueRow('Ном: ', nominalValueStr, Icons.crop_free, nominalColor),
                const SizedBox(height: 8),
                buildValueRow('Мин: ', minValueStr, Icons.arrow_downward, minColor),
                const SizedBox(height: 8),
                buildValueRow('Сред: ', avgValueStr, Icons.sync_alt, avgColor),
                const SizedBox(height: 8),
                buildValueRow('Макс: ', maxValueStr, Icons.arrow_upward, maxColor),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Закрыть',
     
            ),
          ),
        ],
      );
    },
  );
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return statefulBuilder;
    },
  );
}