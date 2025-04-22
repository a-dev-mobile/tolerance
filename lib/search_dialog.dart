// search_dialog.dart - Dialog for searching tolerances
// Allows users to find the needed tolerance by name with improved UI

import 'package:flutter/material.dart';
import 'package:mobile_tolerance/engineering_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'engineering_theme.dart';

// Constants for SharedPreferences keys
const String _keySearchHistory = 'searchHistory'; // Key for search history

// Function to display search dialog with history
Future<String?> showSearchDialog(
  BuildContext context, 
  List<String> tolerances,
) async {
  // Controller for text field
  final TextEditingController controller = TextEditingController();
  
  // Load search history
  final List<String> searchHistory = await _loadSearchHistory();
  
  // Sort tolerance list: recently used first, then the rest
  List<String> sortedTolerances = _sortTolerancesByHistory(tolerances, searchHistory);
  
  // List of filtered tolerances (initially showing all)
  List<String> filteredTolerances = List.from(sortedTolerances);
  
  // Result selected by user
  String? selectedTolerance;
  
  // Get the engineering style
  final style = EngineeringTheme.widgetStyle(context);
  
  // Show dialog and wait for result
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Filter tolerance list by entered text, preserving history sorting
          void filterTolerances(String query) {
            setState(() {
              if (query.isEmpty) {
                // If search is empty, show full sorted list
                filteredTolerances = List.from(sortedTolerances);
              } else {
                // Filter case-insensitive, preserving history priority
                String lowercaseQuery = query.toLowerCase();
                
                List<String> historyFiltered = searchHistory
                    .where((tolerance) => 
                        tolerance.toLowerCase().contains(lowercaseQuery) &&
                        tolerances.contains(tolerance))
                    .toList();
                
                List<String> otherFiltered = tolerances
                    .where((tolerance) => 
                        tolerance.toLowerCase().contains(lowercaseQuery) &&
                        !searchHistory.contains(tolerance))
                    .toList();
                
                // Combine results: first from history, then others
                filteredTolerances = [...historyFiltered, ...otherFiltered];
              }
            });
          }
          
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Поиск допуска',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: style.divider,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(
                maxHeight: 450,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input field for search
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Введите обозначение допуска',
                      hintText: 'например: h7, H8, k6',
                      prefixIcon: Icon(
                        Icons.search,
                        color: EngineeringTheme.primaryBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: filterTolerances,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  
                  // Results list with headers for better organization
                  Expanded(
                    child: filteredTolerances.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: style.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет результатов',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                  color: style.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildResultsList(
                          context, 
                          filteredTolerances, 
                          searchHistory,
                          onSelect: (tolerance) {
                            selectedTolerance = tolerance;
                            // Save selected tolerance to history
                            _saveToSearchHistory(tolerance);
                            Navigator.of(context).pop();
                          }
                        ),
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Отмена'),
              ),
            ],
          );
        },
      );
    },
  );
  
  return selectedTolerance;
}

// Build result list with sections for recent and other tolerances
Widget _buildResultsList(
  BuildContext context, 
  List<String> tolerances, 
  List<String> history,
  {required Function(String) onSelect}
) {
  // Get the engineering style
  final style = EngineeringTheme.widgetStyle(context);
  
  // Separate recent from other tolerances
  final List<String> recentTolerances = tolerances
      .where((t) => history.contains(t))
      .toList();
  
  final List<String> otherTolerances = tolerances
      .where((t) => !history.contains(t))
      .toList();
  
  return ListView(
    children: [
      // Show recent section only if there are recent searches
      if (recentTolerances.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Недавние',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: style.textSecondary,
            ),
          ),
        ),
        ...recentTolerances.map((tolerance) => _buildToleranceItem(
          context, tolerance, true, onSelect
        )).toList(),
        const Divider(height: 24),
      ],
      
      // Other tolerances section
      if (otherTolerances.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Все допуски',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: style.textSecondary,
            ),
          ),
        ),
        ...otherTolerances.map((tolerance) => _buildToleranceItem(
          context, tolerance, false, onSelect
        )).toList(),
      ],
    ],
  );
}

// Build individual list item for a tolerance
Widget _buildToleranceItem(
  BuildContext context, 
  String tolerance, 
  bool isRecent, 
  Function(String) onSelect
) {
  // Determine if it's a hole or shaft
  final bool isHole = tolerance[0] == tolerance[0].toUpperCase();
  
  // Get colors based on hole or shaft
  final Color typeColor = isHole 
      ? EngineeringTheme.infoColor
      : EngineeringTheme.errorColor;
      
  final String typeText = isHole ? 'Отверстие' : 'Вал';
  
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: EngineeringTheme.getDividerColor(Theme.of(context).brightness),
        width: 1,
      ),
    ),
    child: InkWell(
      onTap: () => onSelect(tolerance),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Recent icon or part type icon
            isRecent
                ? const Icon(
                    Icons.history,
                    color: Colors.grey,
                    size: 20,
                  )
                : Icon(
                    isHole ? Icons.radio_button_unchecked : Icons.circle,
                    color: typeColor,
                    size: 20,
                  ),
            const SizedBox(width: 16),
            
            // Tolerance code with custom styling
            Text(
              tolerance,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const Spacer(),
            
            // Part type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: typeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                typeText,
                style: TextStyle(
                  fontSize: 12,
                  color: typeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
    
    // Limit history size (for example, to 10 items)
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }
    
    // Save updated history
    await prefs.setStringList(_keySearchHistory, history);
  } catch (e) {
    debugPrint('Error saving search history: $e');
  }
}

// Sort tolerances: first from history, then others
List<String> _sortTolerancesByHistory(List<String> tolerances, List<String> history) {
  // Filter history, keeping only existing tolerances
  List<String> validHistory = history.where((item) => tolerances.contains(item)).toList();
  
  // Create list of tolerances not in history
  List<String> remainingTolerances = tolerances.where((item) => !validHistory.contains(item)).toList();
  
  // Sort remaining tolerances alphabetically
  remainingTolerances.sort();
  
  // Combine two lists: first history, then others
  return [...validHistory, ...remainingTolerances];
}