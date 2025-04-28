// unit_system.dart - Определение систем единиц измерения
// Содержит перечисление и вспомогательные функции для работы с единицами измерения

// Перечисление единиц измерения
enum UnitSystem {
  millimeters, // Миллиметры (мм)
  inches, // Дюймы (in)
  microns, // Микроны (μm)
}

// Расширение для UnitSystem с вспомогательными методами
extension UnitSystemExtension on UnitSystem {
  // Возвращает символ единицы измерения
  String get symbol {
    // Эти символы обычно не локализуются, так как являются международными обозначениями
    switch (this) {
      case UnitSystem.millimeters:
        return 'мм';
      case UnitSystem.inches:
        return 'in';
      case UnitSystem.microns:
        return 'мкм';
    }
  }

  // Возвращает локализованный символ единицы измерения (использовать с context.t)
  String get localizationKey {
    switch (this) {
      case UnitSystem.millimeters:
        return 'mm';
      case UnitSystem.inches:
        return 'in';
      case UnitSystem.microns:
        return 'microns';
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

  // Возвращает ключ для локализованного названия единицы измерения
  String get displayNameKey {
    switch (this) {
      case UnitSystem.millimeters:
        return 'millimeters';
      case UnitSystem.inches:
        return 'inches';
      case UnitSystem.microns:
        return 'microns';
    }
  }
}
