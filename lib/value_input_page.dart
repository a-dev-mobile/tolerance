// Updated value_input_page.dart with localization support
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tolerance/tolerance_constants.dart';
import 'engineering_theme.dart';
import 'core/models/unit_system.dart';
import 'core/utils/unit_converter.dart';
import 'core/localization/app_localizations.dart'; // Add this

// Class to represent calculation results
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

// Page for value input instead of dialog
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
  // Controller for text field
  final TextEditingController controller = TextEditingController();

  // Variables for storing results
  double baseValue = 0.0;
  String minValueStr = '-';
  String maxValueStr = '-';
  String nominalValueStr = '-';
  String avgValueStr = '-';

  // Variables for interval handling

  String currentInterval = '';
  bool isWithinInterval = true;
  String recommendedInterval = '';
  double maxValueInTolerance = 500.0; // Default value

  // Determining part type (hole or shaft)
  String typeOfPart = '';  // Initialize empty

  // Variable for displayed tolerance value
  String displayedToleranceValue = '';

  // Variable to track copy state
  bool _justCopied = false;

  @override
  void initState() {
    super.initState();
    // Initialize displayed tolerance value
    displayedToleranceValue = widget.toleranceValue;

    // Determine part type
    _determinePartType();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now it's safe to access context.t()
    if (currentInterval.isEmpty) {
      currentInterval = context.t('interval_not_defined');
    }
    
    if (typeOfPart.isEmpty) {
      typeOfPart = context.t('part_not_defined');
    }
  }
  // Determine part type (hole or shaft)
  void _determinePartType() {
    if (widget.columnName.isNotEmpty) {
      // Find first letter in tolerance designation
      RegExp letterRegex = RegExp(r'[A-Za-z]');
      Match? match = letterRegex.firstMatch(widget.columnName);

      if (match != null) {
        String letter = match.group(0) ?? '';

        // Simple rule:
        // If letter is uppercase (A-Z) - it's a hole
        // If letter is lowercase (a-z) - it's a shaft
        if (letter == letter.toUpperCase()) {
          typeOfPart = 'hole';
        } else {
          typeOfPart = 'shaft';
        }
      }
    }
  }

  // Parse interval boundaries
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

  // Find interval for value
  String findIntervalForValue(double inputValue) {
    String result = context.t('interval_not_defined');
    double closestDiff = double.infinity;
    String closestIntervalBelow = '';
    String closestIntervalAbove = '';
    double maxAllowedValue = 0.0; // Maximum value among all intervals

    // Iterate through all intervals in ToleranceConstants
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

      // If value is in interval
      if (inputValue >= min && inputValue <= max) {
        return intervalKey;
      }

      // If value is less than minimum, save closest interval above
      if (inputValue < min && (min - inputValue < closestDiff)) {
        closestDiff = min - inputValue;
        closestIntervalAbove = intervalKey;
      }

      // If value is greater than maximum, save closest interval below
      if (inputValue > max && (inputValue - max < closestDiff)) {
        closestDiff = inputValue - max;
        closestIntervalBelow = intervalKey;
      }
    }

    // If interval not found, return closest and save maximum value
    if (result == context.t('interval_not_defined')) {
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

  // Parse tolerance - returns list of deviation values
  List<double> parseTolerance(String toleranceStr) {
    if (toleranceStr.isEmpty || toleranceStr == '-') return [];

    // Result: [lower deviation, upper deviation]
    List<double> result = [];

    // Split into lines, if any
    List<String> lines = toleranceStr.split('\n');

    for (String line in lines) {
      if (line.isEmpty) continue;

      // Clean string and get sign
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

  // Get updated tolerance for interval
  String getUpdatedToleranceForInterval(
    String originalTolerance,
    String intervalKey,
  ) {
    if (intervalKey == context.t('interval_not_defined') ||
        intervalKey == 'Ошибка') {
      return originalTolerance;
    }

    // Get tolerance values for found interval
    Map<String, String>? intervalTolerances =
        ToleranceConstants.toleranceValues[intervalKey];
    if (intervalTolerances == null) {
      return originalTolerance;
    }

    // Check if tolerance with same name exists for new interval
    String? newTolerance = intervalTolerances[widget.columnName];
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

      // Determine interval to which value belongs
      currentInterval = findIntervalForValue(baseValue);
      isWithinInterval = currentInterval != context.t('interval_not_defined');

      // Update tolerance value if interval changed
      String updatedToleranceValue = getUpdatedToleranceForInterval(
        widget.toleranceValue,
        currentInterval,
      );

      // Parse tolerance
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
          minValue = baseValue + tolerance; // tolerance is already negative
          maxValue = baseValue;
        }

        // Calculate average value
        double avgValue = (minValue + maxValue) / 2;

        // Convert values to selected units
        minValueStr = UnitConverter.formatValue(minValue, widget.currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, widget.currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, widget.currentUnit);
      }
      // If two tolerance values (range)
      else if (toleranceValues.length >= 2) {
        // Sort to ensure first value is smaller
        toleranceValues.sort();

        double minValue = baseValue + toleranceValues[0];
        double maxValue =
            baseValue + toleranceValues[toleranceValues.length - 1];

        // Calculate average value
        double avgValue = (minValue + maxValue) / 2;

        // Convert values to selected units
        minValueStr = UnitConverter.formatValue(minValue, widget.currentUnit);
        maxValueStr = UnitConverter.formatValue(maxValue, widget.currentUnit);
        avgValueStr = UnitConverter.formatValue(avgValue, widget.currentUnit);
      }

      // Format nominal value
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

  // Copy results to clipboard with improved formatting
  void _copyResultsToClipboard() {
    if (!isWithinInterval || controller.text.isEmpty) {
      // No results to copy
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('no_results_to_copy')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Format tolerance value
    String formattedTolerance = displayedToleranceValue;
    // Check if tolerance contains a line break (multiple values)
    if (displayedToleranceValue.contains('\n')) {
      // Replace line break with slash for more compact display
      formattedTolerance = displayedToleranceValue.replaceAll('\n', ' / ');
    }

    // Format data for copying
    String toleranceInfo =
        '${context.t('search_tolerance')}: ${widget.columnName} $formattedTolerance';
    String intervalInfo = '${context.t('interval')}: $currentInterval';
    String nominalInfo = '${context.t('nominal_size_full')}: $nominalValueStr';
    String minInfo = '${context.t('minimum_size_full')}: $minValueStr';
    String maxInfo = '${context.t('maximum_size_full')}: $maxValueStr';
    String avgInfo = '${context.t('average_size_full')}: $avgValueStr';

    String clipboardText =
        '$toleranceInfo\n$intervalInfo\n$nominalInfo\n$minInfo\n$maxInfo\n$avgInfo';

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: clipboardText)).then((_) {
      // Show notification about successful copying
      setState(() {
        _justCopied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('results_copied')),
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset copy state after small delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _justCopied = false;
          });
        }
      });
    });
  }

  // Get compact label for display
  String _getShortLabel(String label) {
    switch (label.trim()) {
      case 'nominal_size_full':
      case 'Номинальный размер':
        return context.t('nom');
      case 'minimum_size_full':
      case 'Минимальный размер':
        return context.t('min');
      case 'maximum_size_full':
      case 'Максимальный размер':
        return context.t('max');
      case 'average_size_full':
      case 'Средний размер':
        return context.t('avg');
      default:
        return label;
    }
  }

  // Get full label for tooltip
  String _getFullLabel(String label) {
    switch (label.trim()) {
      case 'nom':
      case 'Ном:':
        return context.t('nominal_size_full');
      case 'min':
      case 'Мин:':
        return context.t('minimum_size_full');
      case 'max':
      case 'Макс:':
        return context.t('maximum_size_full');
      case 'avg':
      case 'Сред:':
        return context.t('average_size_full');
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
          // Compact label
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Value
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

  // Create widget for displaying interval information
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
                      ? context.t(
                        'in_interval',
                        args: {'interval_value': interval},
                      )
                      : context.t('error_value_outside_range'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWithinInterval ? 15 : 16,
                    color: isWithinInterval ? style.infoColor : Colors.red,
                  ),
                ),
                if (!isWithinInterval) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.t(
                      'enter_value_up_to',
                      args: {'max_value': maxValueInTolerance.toString()},
                    ),
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
    final partTypeTranslated =
        typeOfPart == 'hole' ? context.t('hole') : context.t('shaft');

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('calculation_results')),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          // Close keyboard when tapping outside input field
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // More compact header with part type and tolerance info
                  Row(
                    children: [
                      // Part icon with corresponding color styling
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (typeOfPart == 'hole'
                                  ? style.infoColor
                                  : style.errorColor)
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          typeOfPart == 'hole'
                              ? Icons.radio_button_unchecked
                              : Icons.circle,
                          color:
                              typeOfPart == 'hole'
                                  ? style.infoColor
                                  : style.errorColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tolerance and part info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tolerance designation
                            Text(
                              widget.columnName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    typeOfPart == 'hole'
                                        ? style.infoColor
                                        : style.errorColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Part type
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (typeOfPart == 'hole'
                                            ? style.infoColor
                                            : style.errorColor)
                                        .withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    partTypeTranslated,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          typeOfPart == 'hole'
                                              ? style.infoColor
                                              : style.errorColor,
                                    ),
                                  ),
                                ),

                                // Show current interval if already determined
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
                                      '${context.t('interval')}: $currentInterval',
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

                  // Input field for base value with icon and improved hint
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: context.t('nominal_size'),
                      hintText:
                          controller.text.isEmpty
                              ? context.t('enter_size')
                              : isWithinInterval
                              ? '${context.t('interval')}: $currentInterval'
                              : context.t('error_value_outside_range'),
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
                          (isWithinInterval && displayedToleranceValue != '-')
                              ? Container(
                                width: 130,
                                padding: const EdgeInsets.only(right: 12),
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.columnName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'RobotoMono',
                                        color:
                                            typeOfPart == 'hole'
                                                ? style.infoColor
                                                : style.errorColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      displayedToleranceValue,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'RobotoMono',
                                        color:
                                            typeOfPart == 'hole'
                                                ? style.infoColor
                                                : style.errorColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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
                        // Get current interval
                        String newInterval =
                            value.isEmpty
                                ? context.t('interval_not_defined')
                                : findIntervalForValue(
                                  double.tryParse(value) ?? 0.0,
                                );

                        // Get updated tolerance value for this interval
                        if (newInterval != context.t('interval_not_defined') &&
                            newInterval != 'Ошибка') {
                          displayedToleranceValue =
                              getUpdatedToleranceForInterval(
                                widget.toleranceValue,
                                newInterval,
                              );
                        } else {
                          displayedToleranceValue = widget.toleranceValue;
                        }

                        // Calculate values with updated tolerance
                        calculateValues(value);
                      });
                    },
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily:
                          'RobotoMono', // Use monospace font for numerical input
                    ),
                  ),

                  // Show error only if value is outside interval and field is not empty
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
                              context.t(
                                'enter_value_up_to',
                                args: {
                                  'max_value': maxValueInTolerance.toString(),
                                },
                              ),
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

                  // Show results in compact form with improved styling
                  if (controller.text.isNotEmpty && isWithinInterval) ...[
                    const SizedBox(height: 20),

                    // Results header
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 18,
                          color: style.infoColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t('calculation_results'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        // Copy results button
                        Tooltip(
                          message: context.t('copy_results'),
                          child: InkWell(
                            onTap: _copyResultsToClipboard,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    _justCopied
                                        ? EngineeringTheme.successColor
                                            .withAlpha(30)
                                        : EngineeringTheme.primaryBlue
                                            .withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _justCopied ? Icons.check : Icons.content_copy,
                                size: 20,
                                color:
                                    _justCopied
                                        ? EngineeringTheme.successColor
                                        : EngineeringTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Results card - more compact display
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
                          // Dimensions in two columns to save space
                          Row(
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildCompactValueTile(
                                      context.t('nom'),
                                      nominalValueStr,
                                      Icons.crop_free,
                                      style.nominalValueColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactValueTile(
                                      context.t('avg'),
                                      avgValueStr,
                                      Icons.sync_alt,
                                      style.avgValueColor,
                                    ),
                                  ],
                                ),
                              ),
                              // Vertical divider
                              Container(
                                height: 70,
                                width: 1,
                                color: style.divider,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildCompactValueTile(
                                      context.t('min'),
                                      minValueStr,
                                      Icons.arrow_downward,
                                      style.minValueColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactValueTile(
                                      context.t('max'),
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

                  // Completion button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      context.t('done'),
                      style: const TextStyle(fontSize: 16),
                    ),
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

// Function to navigate to value input page and calculation
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
