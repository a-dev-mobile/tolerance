
// Константы для конвертации
import 'package:mobile_tolerance/core/models/unit_system.dart';

class UnitConverter {
  // Коэффициент перевода мм в дюймы
  static const double mmToInch = 0.0393701;
  
  // Коэффициент перевода мм в микроны
  static const double mmToMicron = 1000.0;

  // Преобразует значение из мм в указанную единицу измерения
  static double convert(double valueMm, UnitSystem toUnit) {
    switch (toUnit) {
      case UnitSystem.millimeters:
        return valueMm;
      case UnitSystem.inches:
        return valueMm * mmToInch;
      case UnitSystem.microns:
        return valueMm * mmToMicron;
    }
  }

  // Форматирует значение в соответствии с выбранной единицей измерения
  static String formatValue(double value, UnitSystem unit) {
    return '${value.toStringAsFixed(unit.decimalPlaces)} ${unit.symbol}';
  }
}