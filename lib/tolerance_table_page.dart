// tolerance_table_page.dart - Improved main page with tolerance table
// Contains the page widget and its logic with engineering design system

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile_tolerance/engineering_theme.dart';
import 'package:mobile_tolerance/search_dialog.dart';
import 'package:mobile_tolerance/tolerance_data_source.dart';
import 'package:mobile_tolerance/core/models/unit_system.dart';
import 'package:mobile_tolerance/value_input_dialog.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import our custom theme
// import 'engineering_theme.dart';
// import other required files

// Constants for SharedPreferences keys
const String _keyScrollPositionX = 'scrollPositionX';
const String _keyScrollPositionY = 'scrollPositionY';

// Tolerance table page widget
class ToleranceTablePage extends StatefulWidget {
  // Function to change theme for the entire app
  final Function(ThemeMode) setThemeMode;

  const ToleranceTablePage({super.key, required this.setThemeMode});

  @override
  State<ToleranceTablePage> createState() => _ToleranceTablePageState();
}

// Tolerance table page state
class _ToleranceTablePageState extends State<ToleranceTablePage> {
  // Data source for the table
  late ToleranceDataSource _toleranceDataSource;
  
  // Scroll controllers for vertical and horizontal scrolling
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  
  // Current theme mode (dark/light)
  bool _isDarkMode = false;
  
  // Current unit system (millimeters by default)
  UnitSystem _currentUnit = UnitSystem.millimeters;
  
  // Flag to track if scroll position is loaded
  bool _scrollPositionRestored = false;
  
  // Highlighted column (search result)
  String? _highlightedColumn;
  
  // Show tooltips for unit system changes
  bool _showTooltip = false;
  
  // Переменная для отслеживания видимости AppBar
  bool _isAppBarVisible = true;
  
  @override
  void initState() {
    super.initState();
    // Initialize data source with current unit system
    _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    
    // Load saved scroll position
    _loadScrollPosition();
    
    // Добавляем слушатель для скрытия/показа AppBar при скролле
    _verticalScrollController.addListener(_handleScroll);
    
    // Add listeners to save scroll position on scroll
    _verticalScrollController.addListener(_saveScrollPosition);
    _horizontalScrollController.addListener(_saveScrollPosition);
    
    // Show tooltip after a delay on first launch
    _checkFirstLaunch();
  }
  

void _handleScroll() {
  if (_verticalScrollController.hasClients) {
    final offset = _verticalScrollController.offset;
    // Скрываем AppBar при малейшем скролле вниз (offset > 0)
    // и показываем только когда пользователь в самом верху (offset = 0)
    if (offset > 0 && _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = false;
      });
    } else if (offset <= 0 && !_isAppBarVisible) {
      setState(() {
        _isAppBarVisible = true;
      });
    }
  }
}
  
  // Check if this is the first launch to show tooltip
  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? firstLaunch = prefs.getBool('firstLaunch');
      
      if (firstLaunch == null || firstLaunch) {
        // First launch, show tooltip
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _showTooltip = true;
            });
            
            // Hide tooltip after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showTooltip = false;
                });
              }
            });
          }
        });
        
        // Save that app has been launched
        await prefs.setBool('firstLaunch', false);
      }
    } catch (e) {
      debugPrint('Error checking first launch: $e');
    }
  }
  
  // Load saved scroll position
  Future<void> _loadScrollPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedScrollX = prefs.getDouble(_keyScrollPositionX);
      final double? savedScrollY = prefs.getDouble(_keyScrollPositionY);
      
      // Restore scroll position if saved
      if (savedScrollX != null && savedScrollY != null) {
        // Use Future.delayed to give table time to initialize
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            if (_horizontalScrollController.hasClients && 
                savedScrollX <= _horizontalScrollController.position.maxScrollExtent) {
              _horizontalScrollController.jumpTo(savedScrollX);
            }
            
            if (_verticalScrollController.hasClients && 
                savedScrollY <= _verticalScrollController.position.maxScrollExtent) {
              _verticalScrollController.jumpTo(savedScrollY);
            }
            
            setState(() {
              _scrollPositionRestored = true;
            });
          }
        });
      } else {
        // If no saved position, mark as restored to allow saving new positions
        setState(() {
          _scrollPositionRestored = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading scroll position: $e');
    }
  }
  
  // Save current scroll position
  Future<void> _saveScrollPosition() async {
    // Save only if not in process of restoring
    if (!_scrollPositionRestored) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_horizontalScrollController.hasClients) {
        await prefs.setDouble(_keyScrollPositionX, _horizontalScrollController.offset);
      }
      
      if (_verticalScrollController.hasClients) {
        await prefs.setDouble(_keyScrollPositionY, _verticalScrollController.offset);
      }
    } catch (e) {
      debugPrint('Error saving scroll position: $e');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely check current theme here, after widget is built in tree
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    // Save scroll position before destroying widget
    _saveScrollPosition();
    
    // Remove listeners
    _verticalScrollController.removeListener(_saveScrollPosition);
    _horizontalScrollController.removeListener(_saveScrollPosition);
    _verticalScrollController.removeListener(_handleScroll);
    
    // Free resources
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Method to cycle through unit systems with feedback
  void _changeUnitSystem() {
    // Запоминаем предыдущую единицу измерения
    final UnitSystem oldUnit = _currentUnit;
    
    setState(() {
      // Cycle between unit systems
      switch (_currentUnit) {
        case UnitSystem.millimeters:
          _currentUnit = UnitSystem.inches;
          break;
        case UnitSystem.inches:
          _currentUnit = UnitSystem.microns;
          break;
        case UnitSystem.microns:
          _currentUnit = UnitSystem.millimeters;
          break;
      }
      // Update table data source with new unit system
      _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    });
    
    // Показываем пользователю сообщение о смене единиц измерения
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Единицы измерения изменены: ${oldUnit.symbol} → ${_currentUnit.symbol}',
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine current theme
    final currentBrightness = Theme.of(context).brightness;
    _isDarkMode = currentBrightness == Brightness.dark;

  return Scaffold(
    // Используем пустой AppBar с нулевой высотой вместо null,
    // чтобы сохранить цвет StatusBar при скрытии основного AppBar
    appBar: _isAppBarVisible 
      ? _buildStandardAppBar() 
      : AppBar(
          toolbarHeight: 0,
          elevation: 0,

          automaticallyImplyLeading: false,
        ),
      body: NotificationListener<ScrollNotification>(
        // Add scroll handler to save position
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification) {
            _saveScrollPosition();
          }
          return false;
        },
        child: Stack(
          children: [
            // Background pattern for engineering aesthetic (subtle grid)
            Positioned.fill(
              child: CustomPaint(
                painter: EngineeringBackgroundPainter(isDarkMode: _isDarkMode),
              ),
            ),
            // Main data grid
            _buildDataGrid(),
            // Tooltip for first launch
            if (_showTooltip)
              _buildHelpTooltip(),
          ],
        ),
      ),
      // Floating action button for quick search
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchDialog,
        backgroundColor: EngineeringTheme.primaryBlue,
        child: const Icon(Icons.search),
      ),
    );
  }
  
  // Новый метод для построения стандартного AppBar
  AppBar _buildStandardAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('Допуски и посадки'),
          if (_currentUnit == UnitSystem.millimeters)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Tooltip(
                message: 'Ячейки кликабельны в режиме мм',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: EngineeringTheme.successColor.withAlpha(38), // 0.15 * 255 = 38
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: EngineeringTheme.successColor.withAlpha(77), // 0.3 * 255 = 77
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: EngineeringTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Кликабельно',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'search':
                _showSearchDialog();
                break;
              case 'units':
                _changeUnitSystem();
                break;
              case 'theme':
                _toggleTheme();
                break;
              case 'about':
                _showAboutDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Поиск допуска'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Добавляем пункт меню для переключения единиц измерения
            PopupMenuItem<String>(
              value: 'units',
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: Text('Единицы: ${_currentUnit.symbol}'),
                subtitle: Text('Нажмите для смены единиц измерения'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Добавляем пункт меню для переключения темы
            PopupMenuItem<String>(
              value: 'theme',
              child: ListTile(
                leading: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                title: Text(_isDarkMode ? 'Светлая тема' : 'Темная тема'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('О программе'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4.0),
        child: Container(
          height: 4.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EngineeringTheme.primaryBlue,
                EngineeringTheme.primaryBlue.withAlpha(153), // 0.6 * 255 = 153
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Build tooltip for first-time users
  Widget _buildHelpTooltip() {
    return Positioned(
      top: 80,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: EngineeringTheme.primaryBlue,
            width: 2,
          ),
        ),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: EngineeringTheme.infoColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Подсказка',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Нажмите на ячейку с допуском, чтобы рассчитать размеры.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.menu,
                    size: 16, 
                    color: EngineeringTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Настройки темы и единиц измерения находятся в меню',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showTooltip = false;
                    });
                  },
                  child: const Text('ПОНЯТНО'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'О программе',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(height: 24),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Справочник допусков и посадок',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Приложение для расчета размеров деталей с учетом допусков.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Версия: 1.3.0',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing,
                    color: EngineeringTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Для инженеров-машиностроителей',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ЗАКРЫТЬ'),
            ),
          ],
        );
      },
    );
  }
  
  // Method to toggle theme with feedback
  void _toggleTheme() {
    final bool oldIsDarkMode = _isDarkMode;
    
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Apply theme to entire app
      final themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      widget.setThemeMode(themeMode);
    });
  }
  
  // Create data grid
  Widget _buildDataGrid() {
    return SfDataGrid(
      source: _toleranceDataSource,
      columnWidthMode: ColumnWidthMode.auto,
      gridLinesVisibility: GridLinesVisibility.both,
      headerGridLinesVisibility: GridLinesVisibility.both,
      frozenColumnsCount: 1, // Freeze first column (intervals)
      allowSorting: false,
      allowFiltering: false,
      allowSwiping: false,
      allowEditing: false,
      isScrollbarAlwaysShown: true,
      rowHeight: 56, // Increase row height to prevent overflow
      columns: _buildGridColumns(),
      onCellTap: _handleCellTap,
      verticalScrollController: _verticalScrollController,
      horizontalScrollController: _horizontalScrollController,
      // Custom styling for data grid
      headerRowHeight: 60,
      selectionMode: SelectionMode.none,
      navigationMode: GridNavigationMode.row,
      showCheckboxColumn: false,
    );
  }
  
  // Display search dialog
  Future<void> _showSearchDialog() async {
    // Get list of all tolerances (columns), excluding Interval
    Set<String> allTolerances = {};
    _toleranceDataSource.getAllColumnNames(allTolerances);
    allTolerances.remove("Interval");
    List<String> tolerancesList = allTolerances.toList()..sort();
    
    // Small delay for smoothness
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Show search dialog
    final String? selectedTolerance = await showSearchDialog(context, tolerancesList);
    
    // If user selected a tolerance
    if (selectedTolerance != null && mounted) {
      _scrollToColumn(selectedTolerance);
    }
  }
  
  // Scroll to specified column and highlight it
  void _scrollToColumn(String columnName) {
    setState(() {
      _highlightedColumn = columnName;
    });
    
    // Use delay to give time for column rebuild with highlighting
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      // Get column index from data source
      int columnIndex = _toleranceDataSource.getColumnIndex(columnName);
      if (columnIndex == -1) return;
      
      // Calculate approximate position for scrolling, accounting for column widths
      // First column (Interval) has width 120, others 90
      double scrollOffset = 120.0 + (columnIndex - 1) * 90.0;
      
      // Scroll horizontally to column if controller is initialized
      if (_horizontalScrollController.hasClients) {
        // Subtract half of visible area to center column
        double viewportWidth = MediaQuery.of(context).size.width;
        double targetOffset = scrollOffset - (viewportWidth / 2) + 45; // 45 - half column width
        
        // Ensure we don't go beyond scroll limits
        targetOffset = targetOffset.clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
        
        _horizontalScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      
      // Clear highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedColumn = null;
          });
        }
      });
    });
  }
  
  // Handle cell tap
  void _handleCellTap(DataGridCellTapDetails details) {
    // Handle taps only if millimeters are selected
    if (_currentUnit != UnitSystem.millimeters) {
      // Show message if user taps in other unit modes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Расчет размеров доступен только в режиме миллиметров (мм)',
            style: TextStyle(fontSize: 14),
          ),
          action: SnackBarAction(
            label: 'ПЕРЕКЛЮЧИТЬ',
            onPressed: () {
              setState(() {
                _currentUnit = UnitSystem.millimeters;
                _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
              });
            },
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Skip taps on header (index 0)
    if (details.rowColumnIndex.rowIndex == 0) return;
    
    // Get tapped cell data
    DataGridRow row = _toleranceDataSource.rows[details.rowColumnIndex.rowIndex - 1];
    String columnName = _buildGridColumns()[details.rowColumnIndex.columnIndex].columnName;
    String cellValue = row.getCells().firstWhere((cell) => cell.columnName == columnName).value.toString();
    
    // If it's interval column, don't show dialog
    if (columnName == 'Interval') return;
    
    // Guard context with mounted check before async gap (using showValueInputDialog)
    if (!mounted) return;
    
    // Show value input dialog
    showValueInputDialog(
      context: context, 
      columnName: columnName, 
      toleranceValue: cellValue,
      currentUnit: _currentUnit
    );
  }

  // Create columns for table
  List<GridColumn> _buildGridColumns() {
    // Get all unique column names from data
    Set<String> uniqueColumnNames = {"Interval"};
    _toleranceDataSource.getAllColumnNames(uniqueColumnNames);

    List<String> sortedColumnNames = uniqueColumnNames.toList()..sort();
    // Move "Interval" to beginning of list
    sortedColumnNames.remove("Interval");
    sortedColumnNames.insert(0, "Interval");

    List<GridColumn> columns = [];

    // Create columns based on keys from data
    for (String columnName in sortedColumnNames) {
      // Determine if this column should be highlighted (search result)
      bool isHighlighted = _highlightedColumn != null && 
                         columnName == _highlightedColumn;
                         
      Color backgroundColor = isHighlighted 
          ? EngineeringTheme.highlightColor // Color for highlighted column
          : (columnName == "Interval" 
              ? EngineeringTheme.infoColor.withAlpha(38) // 0.15 * 255 = 38 
              : EngineeringTheme.primaryBlue.withAlpha(13)); // 0.05 * 255 = 13
      
      columns.add(
        GridColumn(
          columnName: columnName,
          label: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: isHighlighted ? Border.all(
                color: EngineeringTheme.highlightColor.withAlpha(204), // 0.8 * 255 = 204
                width: 2,
              ) : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              columnName == "Interval" 
                ? 'Интервал\n(мм)'  // Intervals always in mm
                : columnName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlighted 
                    ? _isDarkMode ? Colors.black : Colors.black87
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          width: columnName == "Interval" ? 120 : 90, // Column width
        ),
      );
    }

    return columns;
  }
}

// Custom painter for engineering background
class EngineeringBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  
  EngineeringBackgroundPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw blueprint-style grid
    final paint = Paint()
      ..color = isDarkMode 
          ? Colors.blue.shade900.withAlpha(13) // 0.05 * 255 = 13
          : Colors.blue.shade900.withAlpha(5)  // 0.02 * 255 = 5
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw grid lines
    const double spacing = 20;
    
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw some engineering symbols/marks
    final symbolPaint = Paint()
      ..color = isDarkMode 
          ? Colors.blue.shade700.withAlpha(18) // 0.07 * 255 = 18
          : Colors.blue.shade700.withAlpha(10) // 0.04 * 255 = 10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw circle symbols at intersections
    for (double x = spacing * 4; x < size.width; x += spacing * 10) {
      for (double y = spacing * 4; y < size.height; y += spacing * 10) {
        canvas.drawCircle(
          Offset(x, y),
          spacing / 2,
          symbolPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(EngineeringBackgroundPainter oldDelegate) => 
      oldDelegate.isDarkMode != isDarkMode;
}