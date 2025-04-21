// unit_system.dart - Определение систем единиц измерения
// Содержит перечисление и вспомогательные функции для работы с единицами измерения

// Перечисление единиц измерения
enum UnitSystem { 
  millimeters, // Миллиметры (мм)
  inches,      // Дюймы (in)
  microns      // Микроны (μm)
}

// Расширение для UnitSystem с вспомогательными методами
extension UnitSystemExtension on UnitSystem {
  // Возвращает символ единицы измерения
  String get symbol {
    switch (this) {
      case UnitSystem.millimeters:
        return 'мм';
      case UnitSystem.inches:
        return 'in';
      case UnitSystem.microns:
        return 'мкм';
    }
  }
  
  // Возвращает количество знаков после запятой для форматирования
  int get decimalPlaces {
    switch (this) {
      case UnitSystem.millimeters:
        return 3;
      case UnitSystem.inches:
        return 5;
      case UnitSystem.microns:
        return 0;
    }
  }

  // Возвращает название единицы измерения для отображения
  String get displayName {
    switch (this) {
      case UnitSystem.millimeters:
        return 'миллиметры';
      case UnitSystem.inches:
        return 'дюймы';
      case UnitSystem.microns:
        return 'микроны';
    }
  }
}

// Константы для конвертации
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