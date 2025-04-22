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
