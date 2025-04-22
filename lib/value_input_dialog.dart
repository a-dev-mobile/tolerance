// value_input_dialog.dart - Improved dialog for value input and tolerance application
// Displays a dialog where users can enter a value and see tolerance application results

import 'package:flutter/material.dart';
import 'package:mobile_tolerance/core/utils/unit_converter.dart';
import 'package:mobile_tolerance/engineering_theme.dart';
import 'package:mobile_tolerance/tolerance_constants.dart';
import 'package:mobile_tolerance/core/models/unit_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import our custom theme
// import 'engineering_theme.dart';

// Shows a dialog for entering a value to which tolerance will be applied
void showValueInputDialog({
  required BuildContext context, 
  required String columnName, 
  required String toleranceValue,
  required UnitSystem currentUnit
}) {
  // Controller for the text field
  final TextEditingController controller = TextEditingController();
  
  // Variables for storing results
  double baseValue = 0.0;
  String minValueStr = '-';
  String maxValueStr = '-';
  String nominalValueStr = '-';
  String avgValueStr = '-';
  
  // Variables for interval handling
  String currentInterval = 'Не определено';
  bool isWithinInterval = true;
  String recommendedInterval = '';
  double maxValueInTolerance = 500.0; // Default value
  
  // Determine if it's a hole or shaft
  String typeOfPart = 'Не определено';
  if (columnName.isNotEmpty) {
    // Find the first letter in the tolerance string
    RegExp letterRegex = RegExp(r'[A-Za-z]');
    Match? match = letterRegex.firstMatch(columnName);
    
    if (match != null) {
      String letter = match.group(0) ?? '';
      
      // Simple rule:
      // If the letter is uppercase (A-Z) - it's a hole
      // If the letter is lowercase (a-z) - it's a shaft
      if (letter == letter.toUpperCase()) {
        typeOfPart = 'Отверстие';
      } else {
        typeOfPart = 'Вал';
      }
    }
  }
  
  // Get the widget style based on the current theme
  final style = EngineeringTheme.widgetStyle(context);
  
  // Function to parse interval boundaries
  List<double> parseIntervalBoundaries(String intervalStr) {
    // Format: "0 > 3", "3 > 6", "24 > 30" etc.
    List<double> result = [];
    
    // Split string by > symbol
    List<String> parts = intervalStr.split('>');
    if (parts.length != 2) return [];
    
    try {
      // Parse first value (minimum)
      double min = double.parse(parts[0].trim());
      // Parse second value (maximum)
      double max = double.parse(parts[1].trim());
      
      result = [min, max];
    } catch (e) {
      return [];
    }
    
    return result;
  }

  // Function to find the interval for a value
  String findIntervalForValue(double inputValue) {
    String result = 'Не определено';
    double closestDiff = double.infinity;
    String closestIntervalBelow = '';
    String closestIntervalAbove = '';
    double maxAllowedValue = 0.0; // Maximum value among all intervals
    
    // Go through all intervals in ToleranceConstants
    for (String intervalKey in ToleranceConstants.toleranceValues.keys) {
      // Parse interval boundaries
      List<double> boundaries = parseIntervalBoundaries(intervalKey);
      if (boundaries.isEmpty || boundaries.length != 2) continue;
      
      double min = boundaries[0];
      double max = boundaries[1];
      
      // Update maximum value
      if (max > maxAllowedValue) {
        maxAllowedValue = max;
      }
      
      // If value is within interval
      if (inputValue >= min && inputValue <= max) {
        return intervalKey;
      }
      
      // If value is less than minimum, save the closest interval above
      if (inputValue < min && (min - inputValue < closestDiff)) {
        closestDiff = min - inputValue;
        closestIntervalAbove = intervalKey;
      }
      
      // If value is greater than maximum, save the closest interval below
      if (inputValue > max && (inputValue - max < closestDiff)) {
        closestDiff = inputValue - max;
        closestIntervalBelow = intervalKey;
      }
    }
    
    // If interval is not found, return the closest and save maximum value
    if (result == 'Не определено') {
      if (closestIntervalBelow.isNotEmpty) {
        recommendedInterval = closestIntervalBelow;
      } else if (closestIntervalAbove.isNotEmpty) {
        recommendedInterval = closestIntervalAbove;
      }
      
      // Save maximum value for error message
      maxValueInTolerance = maxAllowedValue;
    }
    
    return result;
  }
  
  // Parse tolerance value - returns a list of deviation values
  List<double> parseTolerance(String toleranceStr) {
    if (toleranceStr.isEmpty || toleranceStr == '-') return [];
    
    // Result: [lower deviation, upper deviation]
    List<double> result = [];
    
    // Split into lines, if any
    List<String> lines = toleranceStr.split('\n');
    
    for (String line in lines) {
      if (line.isEmpty) continue;
      
      // Clean the string and get the sign
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
        // Apply sign
        if (sign == '-') value = -value;
        
        result.add(value);
      } catch (e) {
        continue;
      }
    }
    
    return result;
  }

  // Get tolerance value for current interval
  String getUpdatedToleranceForInterval(String originalTolerance, String intervalKey) {
    if (intervalKey == 'Не определено' || intervalKey == 'Ошибка') {
      return originalTolerance;
    }
    
    // Get tolerance values for found interval
    Map<String, String>? intervalTolerances = ToleranceConstants.toleranceValues[intervalKey];
    if (intervalTolerances == null) {
      return originalTolerance;
    }
    
    // Check if there's a tolerance with the same name for the new interval
    String? newTolerance = intervalTolerances[columnName];
    if (newTolerance == null || newTolerance.isEmpty) {
      return originalTolerance; // If not, keep original value
    }
    
    return newTolerance;
  }

  // Calculate boundary values based on entered base value
  void calculateValues(String inputValue) {
    try {
      // Always interpret input as millimeters
      baseValue = double.parse(inputValue);
      
      // Determine which interval the value belongs to
      currentInterval = findIntervalForValue(baseValue);
      isWithinInterval = currentInterval != 'Не определено';
      
      // Update tolerance value if interval changed
      String updatedToleranceValue = getUpdatedToleranceForInterval(toleranceValue, currentInterval);
      
      // Parse tolerance
      List<double> toleranceValues = parseTolerance(updatedToleranceValue);
      
      if (toleranceValues.isEmpty) {
        minValueStr = '-';
        maxValueStr = '-';
        avgValueStr = '-';
        nominalValueStr = UnitConverter.formatValue(baseValue, currentUnit);
        return;
      }
      
      // If only one tolerance value (asymmetric tolerance)
      if (toleranceValues.length == 1) {
        double tolerance = toleranceValues[0];
        double minValue, maxValue;
        
        if (tolerance >= 0) {
          // Positive tolerance: base value + tolerance
          minValue = baseValue;
          maxValue = baseValue + tolerance;
        } else {
          // Negative tolerance: base value - tolerance
          minValue = baseValue + tolerance;  // tolerance is already negative
          maxValue = baseValue;
        }
        
        // Calculate average value
        double avgValue = (minValue + maxValue) / 2;

        // Convert values to selected units
        minValueStr = UnitConverter.formatValue(minValue, currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, currentUnit);
      } 
      // If two tolerance values (range)
      else if (toleranceValues.length >= 2) {
        // Sort to ensure the first is smaller
        toleranceValues.sort();
        
        double minValue = baseValue + toleranceValues[0];
        double maxValue = baseValue + toleranceValues[toleranceValues.length - 1];
        
        // Calculate average value
        double avgValue = (minValue + maxValue) / 2;
        
        // Convert values to selected units
        minValueStr = UnitConverter.formatValue(minValue, currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, currentUnit);
      }
      
      // Format nominal value
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
  // Получение компактной подписи для отображения
String _getShortLabel(String label) {
  switch (label.trim()) {
    case 'Номинальный размер':
      return 'Ном:';
    case 'Минимальный размер':
      return 'Мин:';
    case 'Максимальный размер':
      return 'Макс:';
    case 'Средний размер':
      return 'Сред:';
    default:
      return label;
  }
}

// Получение полной подписи для подсказки
String _getFullLabel(String label) {
  switch (label.trim()) {
    case 'Ном:':
      return 'Номинальный размер';
    case 'Мин:':
      return 'Минимальный размер';
    case 'Макс:':
      return 'Максимальный размер';
    case 'Сред:':
      return 'Средний размер';
    default:
      return label;
  }
}
  // Create widget for displaying value with icon
  // Создание виджета для отображения значения с иконкой - компактная версия
Widget buildValueRow(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: style.getValueRowDecoration(color),
    child: Row(
      children: [
        // Иконка с подсказкой для обозначения типа значения
        Tooltip(
          message: _getFullLabel(label),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        // Компактная подпись
        Expanded(
          child: Text(
            _getShortLabel(label), 
            style: TextStyle(
              fontWeight: FontWeight.w500, 
              color: color,
              fontSize: 14,
            ),
          ),
        ),
        // Само значение в моноширинном шрифте для лучшего выравнивания
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: color,
            fontFamily: 'RobotoMono',
          ),
        ),
      ],
    ),
  );
}


  
  // Create widget to display interval information
  Widget buildIntervalInfo(bool isWithinInterval, String interval, String recommended) {
    final Brightness currentBrightness = Theme.of(context).brightness;
    
    final Color bgColor = isWithinInterval 
        ? style.intervalBackground
        : Colors.red.withAlpha(currentBrightness == Brightness.light ? 26 : 51); // 0.1, 0.2
        
    final Color borderColor = isWithinInterval 
        ? EngineeringTheme.infoColor.withAlpha(currentBrightness == Brightness.light ? 77 : 102)
        : Colors.red.withAlpha(currentBrightness == Brightness.light ? 128 : 77); // 0.5, 0.3
    
    final IconData iconData = isWithinInterval 
        ? Icons.check_circle_outline
        : Icons.error_outline;
        
    final Color iconColor = isWithinInterval 
        ? style.infoColor
        : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isWithinInterval ? 1 : 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
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
                    fontSize: isWithinInterval ? 15 : 16,
                    color: isWithinInterval ? style.infoColor : Colors.red,
                  ),
                ),
                if (!isWithinInterval) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Введите значение до $maxValueInTolerance мм',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
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
  
  // Variable for displayed tolerance value that will be updated
  String displayedToleranceValue = toleranceValue;

  // Create stateful builder to update results on input
  StatefulBuilder statefulBuilder = StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: style.surface,
        elevation: 8,
        title: // Улучшенный заголовок для диалога расчета размеров
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Заголовок с подзаголовком
    Row(
      children: [
        // Иконка в зависимости от типа детали
        Icon(
          typeOfPart == 'Отверстие' 
              ? Icons.radio_button_unchecked 
              : Icons.circle,
          color: typeOfPart == 'Отверстие' 
              ? style.infoColor 
              : style.errorColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Расчет размеров',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeOfPart == 'Отверстие'
                          ? style.infoColor.withAlpha(30)
                          : style.errorColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeOfPart,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: typeOfPart == 'Отверстие'
                            ? style.infoColor
                            : style.errorColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      columnName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: typeOfPart == 'Отверстие'
                            ? style.infoColor
                            : style.errorColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    // Разделитель
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Divider(height: 2, thickness: 1, color: style.divider),
    ),
  ],
),
      
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display part information only if no error
              if (controller.text.isEmpty || isWithinInterval)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: style.getCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
   
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.text.isEmpty ? "" : controller.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.text.isEmpty ? toleranceValue : displayedToleranceValue,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'RobotoMono',
                            color: typeOfPart == 'Отверстие' 
                                ? style.infoColor
                                : style.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Input field for base value with icon and hint
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Номинальный размер',
                  hintText: 'Например: 10.5',
                  prefixIcon: Icon(Icons.straighten, color: style.nominalValueColor),
                  suffixText: 'мм',
                  suffixStyle: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: style.textSecondary
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {
                    // Get current interval
                    String newInterval = value.isEmpty ? 'Не определено' : findIntervalForValue(double.tryParse(value) ?? 0.0);
                    
                    // Get updated tolerance value for this interval
                    if (newInterval != 'Не определено' && newInterval != 'Ошибка') {
                      displayedToleranceValue = getUpdatedToleranceForInterval(toleranceValue, newInterval);
                    } else {
                      displayedToleranceValue = toleranceValue;
                    }
                    
                    // Calculate values with updated tolerance
                    calculateValues(value);
                    
                    // Update happens because setState calls rebuilding of the entire widget
                  });
                },
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'RobotoMono', // Use monospace font for numerical input
                ),
              ),
              
              // Interval information (if value is entered)
              if (controller.text.isNotEmpty)
                buildIntervalInfo(isWithinInterval, currentInterval, recommendedInterval),
              
              // Show values only if value is within interval
// Часть кода, отображающая результаты расчета
if (controller.text.isEmpty || isWithinInterval) ...[
  const Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Text(
      'Результаты:',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    ),
  ),
  // Используем компактные строки для мобильных устройств
  buildValueRow('Номинальный размер', nominalValueStr, Icons.crop_free, style.nominalValueColor),
  buildValueRow('Минимальный размер', minValueStr, Icons.arrow_downward, style.minValueColor),
  buildValueRow('Средний размер', avgValueStr, Icons.sync_alt, style.avgValueColor),
  buildValueRow('Максимальный размер', maxValueStr, Icons.arrow_upward, style.maxValueColor),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Закрыть',
              style: TextStyle(fontSize: 16),
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