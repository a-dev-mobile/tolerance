// Страница для ввода значения и расчета допусков

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tolerance/tolerance_constants.dart';
import 'core/models/unit_system.dart';
import 'core/utils/unit_converter.dart';
import 'engineering_theme.dart';

// Класс для представления результатов расчета
class ToleranceResult {
  final String baseValue;
  final String minValue;
  final String maxValue;
  final String nominalValue;
  final String avgValue;
  final String interval;
  final bool isWithinInterval;

  ToleranceResult({
    required this.baseValue,
    required this.minValue,
    required this.maxValue,
    required this.nominalValue,
    required this.avgValue,
    required this.interval,
    required this.isWithinInterval,
  });
}

// Страница для ввода значения вместо диалога
class ValueInputPage extends StatefulWidget {
  final String columnName;
  final String toleranceValue;
  final UnitSystem currentUnit;

  const ValueInputPage({
    super.key,
    required this.columnName,
    required this.toleranceValue,
    required this.currentUnit,
  });

  @override
  State<ValueInputPage> createState() => _ValueInputPageState();
}

class _ValueInputPageState extends State<ValueInputPage> {
  // Контроллер для текстового поля
  final TextEditingController controller = TextEditingController();

  // Переменные для хранения результатов
  double baseValue = 0.0;
  String minValueStr = '-';
  String maxValueStr = '-';
  String nominalValueStr = '-';
  String avgValueStr = '-';

  // Переменные для обработки интервала
  String currentInterval = 'Не определено';
  bool isWithinInterval = true;
  String recommendedInterval = '';
  double maxValueInTolerance = 500.0; // Значение по умолчанию

  // Определение типа детали (отверстие или вал)
  String typeOfPart = 'Не определено';

  // Переменная для отображаемого значения допуска
  String displayedToleranceValue = '';
  
  // Переменная для отслеживания состояния копирования
  bool _justCopied = false;

  @override
  void initState() {
    super.initState();
    // Инициализация отображаемого значения допуска
    displayedToleranceValue = widget.toleranceValue;

    // Определение типа детали
    _determinePartType();
  }

  // Определение типа детали (отверстие или вал)
  void _determinePartType() {
    if (widget.columnName.isNotEmpty) {
      // Ищем первую букву в строке допуска
      RegExp letterRegex = RegExp(r'[A-Za-z]');
      Match? match = letterRegex.firstMatch(widget.columnName);

      if (match != null) {
        String letter = match.group(0) ?? '';

        // Простое правило:
        // Если буква в верхнем регистре (A-Z) - это отверстие
        // Если буква в нижнем регистре (a-z) - это вал
        if (letter == letter.toUpperCase()) {
          typeOfPart = 'Отверстие';
        } else {
          typeOfPart = 'Вал';
        }
      }
    }
  }

  // Разбор границ интервала
  List<double> parseIntervalBoundaries(String intervalStr) {
    // Формат: "0 > 3", "3 > 6", "24 > 30" и т.д.
    List<double> result = [];

    // Разделяем строку по символу >
    List<String> parts = intervalStr.split('>');
    if (parts.length != 2) return [];

    try {
      // Разбор первого значения (минимум)
      double min = double.parse(parts[0].trim());
      // Разбор второго значения (максимум)
      double max = double.parse(parts[1].trim());

      result = [min, max];
    } catch (e) {
      return [];
    }

    return result;
  }

  // Поиск интервала для значения
  String findIntervalForValue(double inputValue) {
    String result = 'Не определено';
    double closestDiff = double.infinity;
    String closestIntervalBelow = '';
    String closestIntervalAbove = '';
    double maxAllowedValue = 0.0; // Максимальное значение среди всех интервалов

    // Перебираем все интервалы в ToleranceConstants
    for (String intervalKey in ToleranceConstants.toleranceValues.keys) {
      // Разбор границ интервала
      List<double> boundaries = parseIntervalBoundaries(intervalKey);
      if (boundaries.isEmpty || boundaries.length != 2) continue;

      double min = boundaries[0];
      double max = boundaries[1];

      // Обновление максимального значения
      if (max > maxAllowedValue) {
        maxAllowedValue = max;
      }

      // Если значение находится в интервале
      if (inputValue >= min && inputValue <= max) {
        return intervalKey;
      }

      // Если значение меньше минимума, сохраняем ближайший интервал выше
      if (inputValue < min && (min - inputValue < closestDiff)) {
        closestDiff = min - inputValue;
        closestIntervalAbove = intervalKey;
      }

      // Если значение больше максимума, сохраняем ближайший интервал ниже
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

  // Разбор допуска - возвращает список значений отклонений
  List<double> parseTolerance(String toleranceStr) {
    if (toleranceStr.isEmpty || toleranceStr == '-') return [];

    // Результат: [нижнее отклонение, верхнее отклонение]
    List<double> result = [];

    // Разделение на строки, если есть
    List<String> lines = toleranceStr.split('\n');

    for (String line in lines) {
      if (line.isEmpty) continue;

      // Очистка строки и получение знака
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
        // Применение знака
        if (sign == '-') value = -value;

        result.add(value);
      } catch (e) {
        continue;
      }
    }

    return result;
  }

  // Получение обновленного допуска для интервала
  String getUpdatedToleranceForInterval(
    String originalTolerance,
    String intervalKey,
  ) {
    if (intervalKey == 'Не определено' || intervalKey == 'Ошибка') {
      return originalTolerance;
    }

    // Получение значений допуска для найденного интервала
    Map<String, String>? intervalTolerances =
        ToleranceConstants.toleranceValues[intervalKey];
    if (intervalTolerances == null) {
      return originalTolerance;
    }

    // Проверка наличия допуска с тем же именем для нового интервала
    String? newTolerance = intervalTolerances[widget.columnName];
    if (newTolerance == null || newTolerance.isEmpty) {
      return originalTolerance; // Если нет, сохраняем исходное значение
    }

    return newTolerance;
  }

  // Расчет граничных значений на основе введенного базового значения
  void calculateValues(String inputValue) {
    try {
      // Всегда интерпретируем ввод как миллиметры
      baseValue = double.parse(inputValue);

      // Определение интервала, к которому принадлежит значение
      currentInterval = findIntervalForValue(baseValue);
      isWithinInterval = currentInterval != 'Не определено';

      // Обновление значения допуска, если интервал изменился
      String updatedToleranceValue = getUpdatedToleranceForInterval(
        widget.toleranceValue,
        currentInterval,
      );

      // Разбор допуска
      List<double> toleranceValues = parseTolerance(updatedToleranceValue);

      if (toleranceValues.isEmpty) {
        minValueStr = '-';
        maxValueStr = '-';
        avgValueStr = '-';
        nominalValueStr = UnitConverter.formatValue(
          baseValue,
          widget.currentUnit,
        );
        return;
      }

      // Если только одно значение допуска (асимметричный допуск)
      if (toleranceValues.length == 1) {
        double tolerance = toleranceValues[0];
        double minValue, maxValue;

        if (tolerance >= 0) {
          // Положительный допуск: базовое значение + допуск
          minValue = baseValue;
          maxValue = baseValue + tolerance;
        } else {
          // Отрицательный допуск: базовое значение - допуск
          minValue = baseValue + tolerance; // tolerance уже отрицательный
          maxValue = baseValue;
        }

        // Расчет среднего значения
        double avgValue = (minValue + maxValue) / 2;

        // Конвертация значений в выбранные единицы
        minValueStr = UnitConverter.formatValue(minValue, widget.currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, widget.currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, widget.currentUnit);
      }
      // Если два значения допуска (диапазон)
      else if (toleranceValues.length >= 2) {
        // Сортировка для гарантии, что первое значение меньше
        toleranceValues.sort();

        double minValue = baseValue + toleranceValues[0];
        double maxValue =
            baseValue + toleranceValues[toleranceValues.length - 1];

        // Расчет среднего значения
        double avgValue = (minValue + maxValue) / 2;

        // Конвертация значений в выбранные единицы
        minValueStr = UnitConverter.formatValue(minValue, widget.currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, widget.currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, widget.currentUnit);
      }

      // Форматирование номинального значения
      nominalValueStr = UnitConverter.formatValue(
        baseValue,
        widget.currentUnit,
      );
    } catch (e) {
      nominalValueStr = 'Ошибка';
      minValueStr = '-';
      maxValueStr = '-';
      avgValueStr = '-';
      currentInterval = 'Ошибка';
      isWithinInterval = false;
    }
  }

// Копирование результатов в буфер обмена с улучшенным форматированием
void _copyResultsToClipboard() {
  if (!isWithinInterval || controller.text.isEmpty) {
    // Нет результатов для копирования
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Нет результатов для копирования'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // Форматируем значение допуска
  String formattedTolerance = displayedToleranceValue;
  // Проверяем, содержит ли допуск перенос строки (несколько значений)
  if (displayedToleranceValue.contains('\n')) {
    // Заменяем перенос строки на слеш для более компактного отображения
    formattedTolerance = displayedToleranceValue.replaceAll('\n', ' / ');
  }

  // Форматируем данные для копирования
  String toleranceInfo = 'Допуск: ${widget.columnName} $formattedTolerance';
  String intervalInfo = 'Интервал: $currentInterval';
  String nominalInfo = 'Номинальный размер: $nominalValueStr';
  String minInfo = 'Минимальный размер: $minValueStr';
  String maxInfo = 'Максимальный размер: $maxValueStr';
  String avgInfo = 'Средний размер: $avgValueStr';
  
  String clipboardText = '$toleranceInfo\n$intervalInfo\n$nominalInfo\n$minInfo\n$maxInfo\n$avgInfo';
  
  // Копируем в буфер обмена
  Clipboard.setData(ClipboardData(text: clipboardText)).then((_) {
    // Показываем уведомление об успешном копировании
    setState(() {
      _justCopied = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Результаты скопированы в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Сбрасываем состояние копирования через небольшую задержку
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _justCopied = false;
        });
      }
    });
  });
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

  // Создание виджета для отображения значения с иконкой - компактная версия (старый метод)
  Widget buildValueRow(String label, String value, IconData icon, Color color) {
    final style = EngineeringTheme.widgetStyle(context);

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

  // Новый более компактный метод для двухколоночного отображения
  Widget _buildCompactValueTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          // Компактная подпись
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Значение
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }

  // Создание виджета для отображения информации об интервале
  Widget buildIntervalInfo(
    bool isWithinInterval,
    String interval,
    String recommended,
  ) {
    final style = EngineeringTheme.widgetStyle(context);
    final Brightness currentBrightness = Theme.of(context).brightness;

    final Color bgColor =
        isWithinInterval
            ? style.intervalBackground
            : Colors.red.withAlpha(
              currentBrightness == Brightness.light ? 26 : 51,
            ); // 0.1, 0.2

    final Color borderColor =
        isWithinInterval
            ? EngineeringTheme.infoColor.withAlpha(
              currentBrightness == Brightness.light ? 77 : 102,
            )
            : Colors.red.withAlpha(
              currentBrightness == Brightness.light ? 128 : 77,
            ); // 0.5, 0.3

    final IconData iconData =
        isWithinInterval ? Icons.check_circle_outline : Icons.error_outline;

    final Color iconColor = isWithinInterval ? style.infoColor : Colors.red;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
        border: Border.all(color: borderColor, width: isWithinInterval ? 1 : 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 24),
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

  @override
  Widget build(BuildContext context) {
    final style = EngineeringTheme.widgetStyle(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчет размеров'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          // Закрыть клавиатуру при тапе вне поля ввода
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Более компактная шапка с информацией о типе детали и допуске
                  Row(
                    children: [
                      // Значок детали с соответствующим цветовым оформлением
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (typeOfPart == 'Отверстие'
                                  ? style.infoColor
                                  : style.errorColor)
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          typeOfPart == 'Отверстие'
                              ? Icons.radio_button_unchecked
                              : Icons.circle,
                          color:
                              typeOfPart == 'Отверстие'
                                  ? style.infoColor
                                  : style.errorColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Информация о допуске и детали
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Обозначение допуска
                            Text(
                              widget.columnName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    typeOfPart == 'Отверстие'
                                        ? style.infoColor
                                        : style.errorColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Тип детали
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (typeOfPart == 'Отверстие'
                                            ? style.infoColor
                                            : style.errorColor)
                                        .withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    typeOfPart,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          typeOfPart == 'Отверстие'
                                              ? style.infoColor
                                              : style.errorColor,
                                    ),
                                  ),
                                ),

                                // Показываем текущий интервал, если он уже определен
                                if (controller.text.isNotEmpty &&
                                    isWithinInterval) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: style.infoColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Интервал: $currentInterval',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: style.infoColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Поле ввода для базового значения с иконкой и улучшенной подсказкой
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Номинальный размер',
                      hintText:
                          controller.text.isEmpty
                              ? 'Введите размер'
                              : isWithinInterval
                              ? 'Интервал: $currentInterval'
                              : 'Значение вне допустимого диапазона',
                      prefixIcon: Icon(
                        Icons.straighten,
                        color:
                            controller.text.isEmpty
                                ? style.nominalValueColor
                                : isWithinInterval
                                ? style.infoColor
                                : Colors.red,
                      ),

                      suffixIcon:
                          (isWithinInterval)
                              ? Text(
                                '$displayedToleranceValue   ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'RobotoMono',
                                  color:
                                      typeOfPart == 'Отверстие'
                                          ? style.infoColor
                                          : style.errorColor,
                                ),
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              controller.text.isEmpty
                                  ? EngineeringTheme.primaryBlue
                                  : isWithinInterval
                                  ? style.infoColor
                                  : Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Получаем текущий интервал
                        String newInterval =
                            value.isEmpty
                                ? 'Не определено'
                                : findIntervalForValue(
                                  double.tryParse(value) ?? 0.0,
                                );

                        // Получаем обновленное значение допуска для этого интервала
                        if (newInterval != 'Не определено' &&
                            newInterval != 'Ошибка') {
                          displayedToleranceValue =
                              getUpdatedToleranceForInterval(
                                widget.toleranceValue,
                                newInterval,
                              );
                        } else {
                          displayedToleranceValue = widget.toleranceValue;
                        }

                        // Рассчитываем значения с обновленным допуском
                        calculateValues(value);
                      });
                    },
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily:
                          'RobotoMono', // Используем моноширинный шрифт для численного ввода
                    ),
                  ),

                  // Показываем ошибку только если значение вне интервала и поле не пустое
                  if (controller.text.isNotEmpty && !isWithinInterval)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Введите значение до $maxValueInTolerance мм',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Показываем результаты в компактном виде с улучшенным оформлением
                  if (controller.text.isNotEmpty && isWithinInterval) ...[
                    const SizedBox(height: 20),

                    // Заголовок результатов
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 18,
                          color: style.infoColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Результаты расчета',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                         const Spacer(),
                        // Кнопка копирования результатов
                        Tooltip(
                          message: 'Скопировать результаты',
                          child: InkWell(
                            onTap: _copyResultsToClipboard,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _justCopied 
                                  ? EngineeringTheme.successColor.withAlpha(30)
                                  : EngineeringTheme.primaryBlue.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _justCopied ? Icons.check : Icons.content_copy,
                                size: 20,
                                color: _justCopied 
                                  ? EngineeringTheme.successColor
                                  : EngineeringTheme.primaryBlue,
                              ),
                            ),
                          ), )
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Карточка с результатами - более компактное отображение
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: style.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Размеры в две колонки для экономии места
                          Row(
                            children: [
                              // Левая колонка
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildCompactValueTile(
                                      'Ном:',
                                      nominalValueStr,
                                      Icons.crop_free,
                                      style.nominalValueColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactValueTile(
                                      'Сред:',
                                      avgValueStr,
                                      Icons.sync_alt,
                                      style.avgValueColor,
                                    )
                                    ,
                                  ],
                                ),
                              ),
                              // Вертикальный разделитель
                              Container(
                                height: 70,
                                width: 1,
                                color: style.divider,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              // Правая колонка
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildCompactValueTile(
                                      'Мин:',
                                      minValueStr,
                                      Icons.arrow_downward,
                                      style.minValueColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactValueTile(
                                      'Макс:',
                                      maxValueStr,
                                      Icons.arrow_upward,
                                      style.maxValueColor,
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Кнопка завершения расчета
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Готово', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Функция для перехода на страницу ввода значения и расчета
void navigateToValueInputPage({
  required BuildContext context,
  required String columnName,
  required String toleranceValue,
  required UnitSystem currentUnit,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (context) => ValueInputPage(
            columnName: columnName,
            toleranceValue: toleranceValue,
            currentUnit: currentUnit,
          ),
    ),
  );
}
