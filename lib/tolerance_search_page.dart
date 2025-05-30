// tolerance_search_page.dart - Страница поиска и выбора допусков
// Заменяет диалог search_dialog.dart для лучшей поддержки мобильных устройств и представления данных

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolerance/core/models/tolerance_filter.dart';
import 'engineering_theme.dart';
import 'core/localization/app_localizations.dart'; // Add this

// Constants for SharedPreferences keys
const String _keySearchHistory = 'searchHistory'; // Key for search history

// Function to navigate to search page
void navigateToSearchPage(
  BuildContext context,
  List<String> tolerances,
  Function(String) onSelect,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (context) => ToleranceSearchPage(
            tolerances: tolerances,
            onToleranceSelected: onSelect,
          ),
    ),
  );
}

// Widget for search page
class ToleranceSearchPage extends StatefulWidget {
  final List<String> tolerances;
  final Function(String) onToleranceSelected;

  const ToleranceSearchPage({
    super.key,
    required this.tolerances,
    required this.onToleranceSelected,
  });

  @override
  State<ToleranceSearchPage> createState() => _ToleranceSearchPageState();
}

class _ToleranceSearchPageState extends State<ToleranceSearchPage> {
  // Controller for text field
  final TextEditingController controller = TextEditingController();

  // Lists for tolerances
  late List<String> filteredTolerances;
  List<String> searchHistory = [];
  List<String> holeTolerances = [];
  List<String> shaftTolerances = [];
  List<String> recentTolerances = [];
  late ToleranceFilter _toleranceFilter;
  // State variables
  bool isLoading = true;
  bool showRecent = true;
  String activeCategory = 'all'; // 'all', 'holes', 'shafts'
  bool _filterActive = false;
  @override
  void initState() {
    super.initState();
    // Initially show all tolerances
    filteredTolerances = List.from(widget.tolerances);

    // Load search history and organize tolerances
    _initializeData();
    // Load tolerance filter
    _loadToleranceFilter();
  }

  // 3. Добавить метод для загрузки фильтра:
  Future<void> _loadToleranceFilter() async {
    try {
      _toleranceFilter = await ToleranceFilter.load();

      // Проверяем, активен ли фильтр (если хотя бы один допуск не выбран)
      bool anyHoleHidden = _toleranceFilter.holeLetters.values.any(
        (value) => !value,
      );
      bool anyShaftHidden = _toleranceFilter.shaftLetters.values.any(
        (value) => !value,
      );

      setState(() {
        _filterActive = anyHoleHidden || anyShaftHidden;
      });
    } catch (e) {
      debugPrint('Error loading tolerance filter: $e');
      // Используем значения по умолчанию, если загрузка не удалась
      _toleranceFilter = ToleranceFilter.defaults();
      setState(() {
        _filterActive = false;
      });
    }
  }

  // Load data and organize tolerances
  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    // Load search history
    searchHistory = await _loadSearchHistory();

    // Split tolerances by type
    _organizeTolerancesByType();

    // Get recent tolerances
    recentTolerances = _getRecentTolerances();

    setState(() {
      isLoading = false;
    });
  }

  // Organize tolerances by hole/shaft
  void _organizeTolerancesByType() {
    holeTolerances = [];
    shaftTolerances = [];

    for (String tolerance in widget.tolerances) {
      // If first character is uppercase, it's a hole tolerance
      if (tolerance.isNotEmpty) {
        if (tolerance[0] == tolerance[0].toUpperCase()) {
          holeTolerances.add(tolerance);
        } else {
          shaftTolerances.add(tolerance);
        }
      }
    }

    // Sort lists alphabetically
    holeTolerances.sort();
    shaftTolerances.sort();
  }

  // Get recent tolerances that exist in the full list
  List<String> _getRecentTolerances() {
    return searchHistory
        .where((item) => widget.tolerances.contains(item))
        .take(8) // Limit to 8 recent items for display
        .toList();
  }

  // Filter tolerances by search query
  void _filterTolerances(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all tolerances based on active category
        _updateFilteredTolerancesByCategory();
      } else {
        // Filter based on query and category

        List<String> sourceList = [];
        switch (activeCategory) {
          case 'holes':
            sourceList = holeTolerances;
            break;
          case 'shafts':
            sourceList = shaftTolerances;
            break;
          case 'all':
          default:
            sourceList = widget.tolerances;
            break;
        }

        // First add items from history that match
        List<String> historyMatches =
            searchHistory
                .where(
                  (tolerance) =>
                      tolerance.contains(query) &&
                      sourceList.contains(tolerance),
                )
                .toList();

        // Then add other items that match but aren't in history
        List<String> otherMatches =
            sourceList
                .where(
                  (tolerance) =>
                      tolerance.contains(query) &&
                      !historyMatches.contains(tolerance),
                )
                .toList();

        // Combine results
        filteredTolerances = [...historyMatches, ...otherMatches];
      }

      // Reset recent display flag based on query
      showRecent = query.isEmpty;
    });
  }

  // Update filtered tolerances based on selected category
  void _updateFilteredTolerancesByCategory() {
    switch (activeCategory) {
      case 'holes':
        filteredTolerances = List.from(holeTolerances);
        break;
      case 'shafts':
        filteredTolerances = List.from(shaftTolerances);
        break;
      case 'all':
      default:
        filteredTolerances = List.from(widget.tolerances);
        break;
    }
  }

  // Handle tolerance selection
  void _selectTolerance(String tolerance) {
    // Save to history
    _saveToSearchHistory(tolerance);

    // Call the callback
    widget.onToleranceSelected(tolerance);

    // Return to previous screen
    Navigator.of(context).pop();
  }

  // Build search header with search field and category toggles
  Widget _buildSearchHeader() {
    return Column(
      children: [
        // Search Field
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.t('search_tolerance'),
            hintText: context.t('enter_designation'),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: _filterTolerances,
          // autofocus: true,
        ),
        if (_filterActive)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  context.t('filter_active_notice'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Filter Chips for category selection
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All tolerances
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    context.t('all_tolerances'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      // Use white text when selected for better contrast, otherwise use primary color
                      color:
                          activeCategory == 'all'
                              ? Colors.white
                              : EngineeringTheme.secondaryBlue,
                      fontSize: 14,
                    ),
                  ),
                  selected: activeCategory == 'all',
                  // Enhanced colors for the active state
                  selectedColor: EngineeringTheme.primaryBlue,
                  checkmarkColor: Colors.white,
                  // Improved background and border when not selected
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  side: BorderSide(
                    color:
                        activeCategory == 'all'
                            ? EngineeringTheme.primaryBlue
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  elevation: activeCategory == 'all' ? 2 : 0,
                  shadowColor: EngineeringTheme.primaryBlue.withAlpha(100),
                  onSelected: (selected) {
                    setState(() {
                      activeCategory = 'all';
                      _updateFilteredTolerancesByCategory();
                      _filterTolerances(controller.text);
                    });
                  },
                  avatar:
                      activeCategory != 'all'
                          ? Icon(
                            Icons.list,
                            color:
                                activeCategory == 'all'
                                    ? Colors.white
                                    : EngineeringTheme.secondaryBlue,
                            size: 18,
                          )
                          : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),

              // Holes
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    context.t(
                      'holes_count',
                      args: {'count': holeTolerances.length.toString()},
                    ),
                    style: TextStyle(
                      color:
                          activeCategory == 'holes'
                              ? Colors.white
                              : EngineeringTheme.infoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: activeCategory == 'holes',
                  selectedColor: EngineeringTheme.infoColor,
                  checkmarkColor: Colors.white,
                  elevation: activeCategory == 'holes' ? 2 : 0,
                  shadowColor: EngineeringTheme.infoColor.withAlpha(100),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  onSelected: (selected) {
                    setState(() {
                      activeCategory = 'holes';
                      _updateFilteredTolerancesByCategory();
                      _filterTolerances(controller.text);
                    });
                  },
                  avatar: Icon(
                    Icons.radio_button_unchecked,
                    color:
                        activeCategory == 'holes'
                            ? Colors.white
                            : EngineeringTheme.infoColor,
                    size: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),

              // Shafts
              FilterChip(
                label: Text(
                  context.t(
                    'shafts_count',
                    args: {'count': shaftTolerances.length.toString()},
                  ),
                  style: TextStyle(
                    color:
                        activeCategory == 'shafts'
                            ? Colors.white
                            : EngineeringTheme.shaftColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: activeCategory == 'shafts',
                selectedColor: EngineeringTheme.shaftColor,
                shadowColor: EngineeringTheme.shaftColor.withAlpha(100),
                checkmarkColor: Colors.white,
                elevation: activeCategory == 'shafts' ? 2 : 0,
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                onSelected: (selected) {
                  setState(() {
                    activeCategory = 'shafts';
                    _updateFilteredTolerancesByCategory();
                    _filterTolerances(controller.text);
                  });
                },
                avatar: Icon(
                  Icons.circle,
                  color:
                      activeCategory == 'shafts'
                          ? Colors.white
                          : EngineeringTheme.shaftColor,
                  size: 16,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build the recent tolerances section
  Widget _buildRecentTolerancesSection() {
    if (recentTolerances.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EngineeringTheme.primaryBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EngineeringTheme.primaryBlue.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: EngineeringTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('recently_used'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Recent tolerances in wrap layout
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              recentTolerances.map((tolerance) {
                // Determine if it's a hole or shaft
                bool isHole =
                    tolerance.isNotEmpty &&
                    tolerance[0] == tolerance[0].toUpperCase();

                return _buildToleranceChip(tolerance, isHole, isRecent: true);
              }).toList(),
        ),

        const Divider(height: 32),
      ],
    );
  }

  // Build tolerance chips for the wrap layout
  Widget _buildToleranceChip(
    String tolerance,
    bool isHole, {
    bool isRecent = false,
  }) {
    final Color baseColor =
        isHole ? EngineeringTheme.holeColor : EngineeringTheme.shaftColor;

    return InkWell(
      onTap: () => _selectTolerance(tolerance),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: baseColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: baseColor.withAlpha(50), width: 1),
          boxShadow: [
            BoxShadow(
              color: baseColor.withAlpha(10),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            tolerance,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: baseColor,
            ),
          ),
        ),
      ),
    );
  }

  // Build the tolerance categories section
  Widget _buildToleranceCategoriesSection() {
    // Split by hole and shaft
    List<String> holeTolerances =
        filteredTolerances
            .where((t) => t.isNotEmpty && t[0] == t[0].toUpperCase())
            .toList();

    List<String> shaftTolerances =
        filteredTolerances
            .where((t) => t.isNotEmpty && t[0] == t[0].toLowerCase())
            .toList();

    // Sort tolerances by prefix then by IT grade
    _sortTolerancesByNaturalOrder(holeTolerances);
    _sortTolerancesByNaturalOrder(shaftTolerances);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Holes section if there are hole tolerances to show
        if (activeCategory != 'shafts' && holeTolerances.isNotEmpty) ...[
          // Section header
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EngineeringTheme.infoColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EngineeringTheme.infoColor.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 18,
                  color: EngineeringTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t('holes').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // All hole tolerances in a single wrap layout
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children:
                holeTolerances
                    .map((tolerance) => _buildToleranceChip(tolerance, true))
                    .toList(),
          ),

          const SizedBox(height: 24),
        ],

        // Shafts section if there are shaft tolerances to show
        if (activeCategory != 'holes' && shaftTolerances.isNotEmpty) ...[
          // Section header
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EngineeringTheme.shaftColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EngineeringTheme.shaftColor.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 16,
                  color: EngineeringTheme.shaftColor,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t('shafts').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // All shaft tolerances in a single wrap layout
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children:
                shaftTolerances
                    .map((tolerance) => _buildToleranceChip(tolerance, false))
                    .toList(),
          ),
        ],
      ],
    );
  }

  // 
 void _sortTolerancesByNaturalOrder(List<String> tolerances) {
  tolerances.sort((a, b) {
    // Extract letter prefix and number part for both designations
    RegExp letterRegex = RegExp(r'^([a-zA-Z]+)');
    RegExp numRegex = RegExp(r'(\d+)');
    
    Match? matchA = letterRegex.firstMatch(a);
    Match? matchB = letterRegex.firstMatch(b);
    Match? numMatchA = numRegex.firstMatch(a);
    Match? numMatchB = numRegex.firstMatch(b);
    
    String prefixA = matchA?.group(1) ?? '';
    String prefixB = matchB?.group(1) ?? '';
    
    // Convert prefixes to lowercase for comparison to group same letters
    String lowerPrefixA = prefixA.toLowerCase();
    String lowerPrefixB = prefixB.toLowerCase();
    
    // If lowercase prefixes are different, sort by lowercase prefix
    if (lowerPrefixA != lowerPrefixB) {
      return lowerPrefixA.compareTo(lowerPrefixB);
    }
    
    // If the same letter (ignoring case), extract numbers
    int numA = numMatchA != null ? int.parse(numMatchA.group(1) ?? '0') : 0;
    int numB = numMatchB != null ? int.parse(numMatchB.group(1) ?? '0') : 0;
    
    // If numerical parts are different, sort by numerical value
    if (numA != numB) {
      return numA.compareTo(numB);
    }
    
    // If same letter and number, uppercase comes before lowercase
    return a.compareTo(b);
  });
}

  // Build the no results widget
  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: EngineeringTheme.getTextColor(
              Theme.of(context).brightness,
              false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('no_results', args: {'query': controller.text}),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: EngineeringTheme.getTextColor(
                Theme.of(context).brightness,
                false,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              controller.clear();
              _filterTolerances('');
            },
            icon: const Icon(Icons.refresh),
            label: Text(context.t('clear_search')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('search_tolerance_title')),
        elevation: 2,
        actions: [
          // Clear button
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                _filterTolerances('');
              },
              tooltip: context.t('clear_search'),
            ),
        ],
      ),
      body: GestureDetector(
        // Add tap handler to close keyboard
        onTap: () {
          // Close keyboard when tapping empty space
          FocusScope.of(context).unfocus();
        },
        // Ensure GestureDetector tracks all taps
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search header with search field and category filters
                _buildSearchHeader(),

                // Loading indicator
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child:
                        filteredTolerances.isEmpty
                            ? _buildNoResultsWidget()
                            : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Recent tolerances section
                                  if (showRecent && recentTolerances.isNotEmpty)
                                    _buildRecentTolerancesSection(),

                                  // Tolerances by category
                                  _buildToleranceCategoriesSection(),
                                ],
                              ),
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Load search history from SharedPreferences
  Future<List<String>> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? history = prefs.getStringList(_keySearchHistory);
      return history ?? [];
    } catch (e) {
      debugPrint('Error loading search history: $e');
      return [];
    }
  }

  // Save tolerance to search history
  Future<void> _saveToSearchHistory(String tolerance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await _loadSearchHistory();

      // Remove tolerance from list if it already exists
      history.remove(tolerance);

      // Add tolerance to beginning of list (most recently used)
      history.insert(0, tolerance);

      // Limit history size (for example, to 15 items)
      if (history.length > 15) {
        history = history.sublist(0, 15);
      }

      // Save updated history
      await prefs.setStringList(_keySearchHistory, history);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }
}
