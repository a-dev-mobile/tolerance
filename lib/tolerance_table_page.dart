// tolerance_table_page.dart - Improved main page with tolerance table
// Contains the page widget and its logic with engineering design system

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tolerance/core/localization/app_localizations.dart';
import 'package:tolerance/core/models/tolerance_filter.dart';

import 'package:tolerance/engineering_theme.dart';

import 'package:tolerance/tolerance_data_source.dart';
import 'package:tolerance/core/models/unit_system.dart';
import 'package:tolerance/tolerance_filter_page.dart';
import 'package:tolerance/tolerance_search_page.dart';
import 'package:tolerance/value_input_page.dart';
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
  // Function to change locale for the entire app
  final Function(Locale) setLocale;

  const ToleranceTablePage({
    super.key,
    required this.setThemeMode,
    required this.setLocale,
  });

  @override
  State<ToleranceTablePage> createState() => _ToleranceTablePageState();
}

// Tolerance table page state
class _ToleranceTablePageState extends State<ToleranceTablePage> {
  // Data source for the table
  late ToleranceDataSource _toleranceDataSource;
  late ToleranceFilter _toleranceFilter;
  bool _filterActive = false;
  // Scroll controllers for vertical and horizontal scrolling
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // Timer for scroll debouncing
  Timer? _scrollDebounceTimer;

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

  // Variable to track AppBar visibility
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    // Initialize data source with current unit system
    _toleranceDataSource = ToleranceDataSource(unitSystem: _currentUnit);
    // Load tolerance filter
    _loadToleranceFilter();
    // Load saved scroll position
    _loadScrollPosition();

    // Add listener for hiding/showing AppBar on scroll
    _verticalScrollController.addListener(_handleScroll);

    // Add listeners to save scroll position on scroll
    _verticalScrollController.addListener(_saveScrollPosition);
    _horizontalScrollController.addListener(_saveScrollPosition);

    // Add listener for scroll refresh
    _verticalScrollController.addListener(_refreshOnScroll);

    // Show tooltip after a delay on first launch
    _checkFirstLaunch();
  }

  // Add this method to load the tolerance filter:
  Future<void> _loadToleranceFilter() async {
    try {
      _toleranceFilter = await ToleranceFilter.load();
      setState(() {
        _filterActive = true;
        // Update data source to apply filters
        _updateDataSource();
      });
    } catch (e) {
      debugPrint('Error loading tolerance filter: $e');
      // Use defaults if loading fails
      _toleranceFilter = ToleranceFilter.defaults();
      setState(() {
        _filterActive = true;
      });
    }
  }

  // Add this method to update the data source with filters:
  void _updateDataSource() {
    _toleranceDataSource = ToleranceDataSource(
      unitSystem: _currentUnit,
      toleranceFilter: _toleranceFilter,
    );
  }

  // Add this method to navigate to the filter settings page:
  void _navigateToFilterSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ToleranceFilterPage(
              onFiltersChanged: () {
                // When filters are changed, reload them
                _loadToleranceFilter();
              },
            ),
      ),
    );
  }

  // New method to refresh grid on scroll
  void _refreshOnScroll() {
    // Cancel previous timer if it exists
    _scrollDebounceTimer?.cancel();

    // Set a new timer
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        // This minimal setState ensures the DataGrid refreshes rows properly
        setState(() {
          // No need to change anything, just trigger a rebuild
        });
      }
    });
  }

  void _handleScroll() {
    if (_verticalScrollController.hasClients) {
      final offset = _verticalScrollController.offset;
      // Hide AppBar on the slightest scroll down (offset > 0)
      // and show only when user is at the very top (offset = 0)
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
                savedScrollX <=
                    _horizontalScrollController.position.maxScrollExtent) {
              _horizontalScrollController.jumpTo(savedScrollX);
            }

            if (_verticalScrollController.hasClients &&
                savedScrollY <=
                    _verticalScrollController.position.maxScrollExtent) {
              _verticalScrollController.jumpTo(savedScrollY);

              // Trigger a rebuild after restoring position
              setState(() {});
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
        await prefs.setDouble(
          _keyScrollPositionX,
          _horizontalScrollController.offset,
        );
      }

      if (_verticalScrollController.hasClients) {
        await prefs.setDouble(
          _keyScrollPositionY,
          _verticalScrollController.offset,
        );
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

    // Cancel any active timer
    _scrollDebounceTimer?.cancel();

    // Remove listeners
    _verticalScrollController.removeListener(_saveScrollPosition);
    _horizontalScrollController.removeListener(_saveScrollPosition);
    _verticalScrollController.removeListener(_handleScroll);
    _verticalScrollController.removeListener(_refreshOnScroll);

    // Free resources
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Method to cycle through unit systems with feedback
  void _changeUnitSystem() {
    // Remember previous unit
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

    // Show user message about unit change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'units_changed',
            args: {
              'old_units': oldUnit.symbol,
              'new_units': _currentUnit.symbol,
            },
          ),
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Method to change language
  void _changeLanguage(String languageCode) {
    final newLocale = Locale(languageCode);
    widget.setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    // Determine current theme
    final currentBrightness = Theme.of(context).brightness;
    _isDarkMode = currentBrightness == Brightness.dark;

    return Scaffold(
      // Use empty AppBar with zero height instead of null,
      // to retain StatusBar color when hiding the main AppBar
      appBar:
          _isAppBarVisible
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

            // Trigger rebuild at end of scroll to ensure all rows are visible
            if (scrollInfo.metrics.axis == Axis.vertical) {
              setState(() {});
            }
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
            if (_showTooltip) _buildHelpTooltip(),
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

  // New method for building standard AppBar
  AppBar _buildStandardAppBar() {
    return AppBar(
      title: Row(
        children: [
          Text(context.t('tolerances')),
          if (_currentUnit == UnitSystem.millimeters)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Tooltip(
                message: context.t('cells_clickable_tip'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: EngineeringTheme.successColor.withAlpha(
                      38,
                    ), // 0.15 * 255 = 38
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: EngineeringTheme.successColor.withAlpha(
                        77,
                      ), // 0.3 * 255 = 77
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
                      Text(
                        context.t('clickable'),
                        style: const TextStyle(
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
              case 'language_en':
                _changeLanguage('en');
                break;
              case 'language_ru':
                _changeLanguage('ru');
                break;
              case 'about':
                _showAboutDialog();
                break;
              case 'filter':
                _navigateToFilterSettings();
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            // Get current locale
            final currentLocale = Localizations.localeOf(context);
            final isEnglish = currentLocale.languageCode == 'en';

            return [
              PopupMenuItem<String>(
                value: 'search',
                child: ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(context.t('search_tolerance')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // Add menu item for switching units
              PopupMenuItem<String>(
                value: 'units',
                child: ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(
                    context.t(
                      'units_with_value',
                      args: {'units_value': _currentUnit.symbol},
                    ),
                  ),
                  subtitle: Text(context.t('tap_to_change_units')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // Add menu item for switching theme
              PopupMenuItem<String>(
                value: 'theme',
                child: ListTile(
                  leading: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  title: Text(
                    _isDarkMode
                        ? context.t('light_theme')
                        : context.t('dark_theme'),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // Language submenu
              PopupMenuItem<String>(
                value: 'language',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.language,
                            size: 20,
                            color: EngineeringTheme.getTextColor(
                              Theme.of(context).brightness,
                              false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.t('change_language'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: EngineeringTheme.getTextColor(
                                Theme.of(context).brightness,
                                true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // English option
              PopupMenuItem<String>(
                value: 'language_en',
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        isEnglish
                            ? EngineeringTheme.primaryBlue
                            : Colors.transparent,
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            isEnglish
                                ? Colors.white
                                : EngineeringTheme.getTextColor(
                                  Theme.of(context).brightness,
                                  true,
                                ),
                      ),
                    ),
                  ),
                  title: Text(context.t('language_en')),
                  trailing:
                      isEnglish
                          ? Icon(
                            Icons.check,
                            color: EngineeringTheme.successColor,
                          )
                          : null,
                  contentPadding: const EdgeInsets.only(left: 32),
                ),
              ),
              // Russian option
              PopupMenuItem<String>(
                value: 'language_ru',
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        !isEnglish
                            ? EngineeringTheme.primaryBlue
                            : Colors.transparent,
                    child: Text(
                      'RU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            !isEnglish
                                ? Colors.white
                                : EngineeringTheme.getTextColor(
                                  Theme.of(context).brightness,
                                  true,
                                ),
                      ),
                    ),
                  ),
                  title: Text(context.t('language_ru')),
                  trailing:
                      !isEnglish
                          ? Icon(
                            Icons.check,
                            color: EngineeringTheme.successColor,
                          )
                          : null,
                  contentPadding: const EdgeInsets.only(left: 32),
                ),
              ),
              PopupMenuItem<String>(
                value: 'filter',
                child: ListTile(
                  leading: const Icon(Icons.filter_list),
                  title: Text(context.t('filter_tolerances')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(context.t('about')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
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
          side: BorderSide(color: EngineeringTheme.primaryBlue, width: 2),
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
                  Icon(Icons.info_outline, color: EngineeringTheme.infoColor),
                  const SizedBox(width: 8),
                  Text(
                    context.t('tip'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.t('cells_clickable_tip'),
                style: const TextStyle(fontSize: 14),
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
                  Expanded(
                    child: Text(
                      context.t('theme_units_tip'),
                      style: const TextStyle(fontSize: 14),
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
                  child: Text(context.t('got_it')),
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('about_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('tolerance_reference'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t('app_description'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('version', args: {'version_number': '1.4.0'}),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.t('close')),
            ),
          ],
        );
      },
    );
  }

  // Method to toggle theme with feedback
  void _toggleTheme() {
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
      // Ensure a large enough cache extent to keep rows loaded
      loadMoreViewBuilder: (BuildContext context, LoadMoreRows? loadMoreRows) {
        return const SizedBox.shrink();
      },
      // Add these two properties to help with row recycling issues
      frozenRowsCount: 0,
      rowsPerPage: 20, // Adjust based on your actual data size
    );
  }

  void _showSearchDialog() async {
    // Получаем список всех допусков (колонок), исключая Interval
    Set<String> allTolerances = {};
    _toleranceDataSource.getAllColumnNames(allTolerances);
    allTolerances.remove("Interval");
    List<String> tolerancesList = allTolerances.toList()..sort();

    if (_filterActive) {
      // Получаем полный список всех возможных допусков (без фильтрации)
      Set<String> allPossibleTolerances = {};

      // Создаем временный источник данных без фильтра
      ToleranceDataSource tempDataSource = ToleranceDataSource(
        unitSystem: _currentUnit,
        toleranceFilter: null,
      );

      tempDataSource.getAllColumnNames(allPossibleTolerances);
      allPossibleTolerances.remove("Interval");

      // Если количество допусков в отфильтрованном списке меньше общего количества,
      // значит фильтр активен и некоторые допуски скрыты
    }

    // Переходим на страницу поиска и ждем результат
    navigateToSearchPage(context, tolerancesList, (selectedTolerance) {
      // Когда допуск выбран, прокручиваем к нему
      if (selectedTolerance.isNotEmpty) {
        _scrollToColumn(selectedTolerance);
      }
    });
  }

  // Scroll to specified column and highlight it
  void _scrollToColumn(String columnName) {
    setState(() {
      _highlightedColumn = columnName;
    });

    // Use delay to give time for column rebuild with highlighting
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Get the list of columns in their SORTED display order
      List<GridColumn> columns = _buildGridColumns();

      // Find the target column index in the SORTED list
      int visualColumnIndex = -1;
      for (int i = 0; i < columns.length; i++) {
        if (columns[i].columnName == columnName) {
          visualColumnIndex = i;
          break;
        }
      }

      if (visualColumnIndex == -1) return; // Column not found

      // Calculate scroll offset based on column widths using the visual index
      double scrollOffset = 0.0;
      for (int i = 0; i < visualColumnIndex; i++) {
        // First column (Interval) is wider than others
        scrollOffset += (i == 0) ? 85.0 : 90.0;
      }

      // Scroll horizontally to column if controller is initialized
      if (_horizontalScrollController.hasClients) {
        // Subtract half of visible area to center column
        double viewportWidth = MediaQuery.of(context).size.width;
        double targetOffset =
            scrollOffset - (viewportWidth / 2) + 45; // 45 - half column width

        // Ensure we don't go beyond scroll limits
        targetOffset = targetOffset.clamp(
          0.0,
          _horizontalScrollController.position.maxScrollExtent,
        );

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
            // _highlightedColumn = null;
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
          content: Text(
            context.t('calculation_only_in_mm'),
            style: TextStyle(fontSize: 14),
          ),
          action: SnackBarAction(
            label: context.t('switch'),
            onPressed: () {
              setState(() {
                _currentUnit = UnitSystem.millimeters;
                _toleranceDataSource = ToleranceDataSource(
                  unitSystem: _currentUnit,
                );
              });
            },
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Skip taps on header (index 0)
    if (details.rowColumnIndex.rowIndex == 0) return;

    // Get tapped cell data
    DataGridRow row =
        _toleranceDataSource.rows[details.rowColumnIndex.rowIndex - 1];
    String columnName =
        _buildGridColumns()[details.rowColumnIndex.columnIndex].columnName;
    String cellValue =
        row
            .getCells()
            .firstWhere((cell) => cell.columnName == columnName)
            .value
            .toString();

    // If it's interval column, don't show dialog
    if (columnName == 'Interval') return;

    // Guard context with mounted check before async gap (using showValueInputDialog)
    if (!mounted) return;

    // Show value input dialog
    // Navigate to value input page
    navigateToValueInputPage(
      context: context,
      columnName: columnName,
      toleranceValue: cellValue,
      currentUnit: _currentUnit,
    );
  }

  // Create columns for table
  List<GridColumn> _buildGridColumns() {
    // Get all unique column names from data
    Set<String> uniqueColumnNames = {"Interval"};
    _toleranceDataSource.getAllColumnNames(uniqueColumnNames);

    List<String> sortedColumnNames = uniqueColumnNames.toList();

    // Move "Interval" to beginning of list
    sortedColumnNames.remove("Interval");

    // Perform natural sorting for the remaining column names
    _sortTolerancesByNaturalOrder(sortedColumnNames);

    // Insert Interval at the beginning
    sortedColumnNames.insert(0, "Interval");

    List<GridColumn> columns = [];

    // Create columns based on keys from data
    for (String columnName in sortedColumnNames) {
      // Determine if this column should be highlighted (search result)
      bool isHighlighted =
          _highlightedColumn != null && columnName == _highlightedColumn;

      Color backgroundColor =
          isHighlighted
              ? EngineeringTheme
                  .highlightColor // Color for highlighted column
              : (columnName == "Interval"
                  ? EngineeringTheme.infoColor.withAlpha(38) // 0.15 * 255 = 38
                  : EngineeringTheme.primaryBlue.withAlpha(
                    13,
                  )); // 0.05 * 255 = 13

      columns.add(
        GridColumn(
          columnName: columnName,
          label: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border:
                  isHighlighted
                      ? Border.all(
                        color: EngineeringTheme.highlightColor.withAlpha(
                          204,
                        ), // 0.8 * 255 = 204
                        width: 2,
                      )
                      : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              columnName == "Interval"
                  ? context.t('interval_mm') // Intervals always in mm
                  : columnName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isHighlighted
                        ? _isDarkMode
                            ? Colors.black
                            : Colors.black87
                        : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          width: columnName == "Interval" ? 85 : 90, // Column width
        ),
      );
    }

    return columns;
  }

  // Добавить новый метод для естественной сортировки колонок
  // Используем тот же алгоритм, что есть в tolerance_search_page.dart
  void _sortTolerancesByNaturalOrder(List<String> tolerances) {
    tolerances.sort((a, b) {
      // Extract letter prefix (can be one or more letters)
      RegExp letterRegex = RegExp(r'^([a-zA-Z]+)');
      Match? matchA = letterRegex.firstMatch(a);
      Match? matchB = letterRegex.firstMatch(b);

      String prefixA = matchA?.group(1) ?? '';
      String prefixB = matchB?.group(1) ?? '';

      // If prefixes are different, sort by prefix
      if (prefixA != prefixB) {
        return prefixA.compareTo(prefixB);
      }

      // Extract number part
      RegExp numRegex = RegExp(r'(\d+)');
      Match? numMatchA = numRegex.firstMatch(a);
      Match? numMatchB = numRegex.firstMatch(b);

      // If we can extract numbers from both, sort numerically
      if (numMatchA != null && numMatchB != null) {
        int numA = int.parse(numMatchA.group(1) ?? '0');
        int numB = int.parse(numMatchB.group(1) ?? '0');
        return numA.compareTo(numB);
      }

      // Fallback to standard string comparison
      return a.compareTo(b);
    });
  }
}

// Custom painter for engineering background
class EngineeringBackgroundPainter extends CustomPainter {
  final bool isDarkMode;

  EngineeringBackgroundPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw blueprint-style grid
    final paint =
        Paint()
          ..color =
              isDarkMode
                  ? Colors.blue.shade900.withAlpha(13) // 0.05 * 255 = 13
                  : Colors.blue.shade900.withAlpha(5) // 0.02 * 255 = 5
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Draw grid lines
    const double spacing = 20;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some engineering symbols/marks
    final symbolPaint =
        Paint()
          ..color =
              isDarkMode
                  ? Colors.blue.shade700.withAlpha(18) // 0.07 * 255 = 18
                  : Colors.blue.shade700.withAlpha(10) // 0.04 * 255 = 10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw circle symbols at intersections
    for (double x = spacing * 4; x < size.width; x += spacing * 10) {
      for (double y = spacing * 4; y < size.height; y += spacing * 10) {
        canvas.drawCircle(Offset(x, y), spacing / 2, symbolPaint);
      }
    }
  }

  @override
  bool shouldRepaint(EngineeringBackgroundPainter oldDelegate) =>
      oldDelegate.isDarkMode != isDarkMode;
}
