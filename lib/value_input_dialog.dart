// value_input_dialog.dart - Диалог для ввода значения и применения допуска
// Отображает диалог, где пользователь может ввести значение и увидеть применение допуска

import 'package:flutter/material.dart';
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
  final Color minColor = Colors.blue.shade700;
  final Color maxColor = Colors.red.shade700;
  final Color avgColor = Colors.green.shade700;
  final Color nominalColor = Colors.orange.shade700;

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

  // Вычисляем граничные значения на основе введенного базового значения
  void calculateValues(String inputValue) {
    try {
      // Всегда интерпретируем ввод как миллиметры
      baseValue = double.parse(inputValue);
      
      // Парсим допуск
      List<double> toleranceValues = parseTolerance(toleranceValue);
      
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
    }
  }
  
  // Создаем виджет для отображения значения с иконкой
  Widget buildValueRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
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
  
  // Создаем stateful билдер для обновления результатов при вводе
  StatefulBuilder statefulBuilder = StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Отображаем тип детали (вал/отверстие) и значение допуска в карточке
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.withOpacity(0.1),
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
                          toleranceValue,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
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
                    calculateValues(value);
                    // Обновление происходит, так как setState вызывает перестроение всего виджета
                  });
                },
                autofocus: true,
              ),
              const SizedBox(height: 20),
              
              // Результаты расчета - визуально привлекательно
              const Text(
                'Результаты:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Используем созданный нами виджет для отображения значений
              buildValueRow('Номинальный:', nominalValueStr, Icons.crop_free, nominalColor),
              const SizedBox(height: 8),
              buildValueRow('Минимальный:', minValueStr, Icons.arrow_downward, minColor),
              const SizedBox(height: 8),
              buildValueRow('Средний:', avgValueStr, Icons.sync_alt, avgColor),
              const SizedBox(height: 8),
              buildValueRow('Максимальный:', maxValueStr, Icons.arrow_upward, maxColor),
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