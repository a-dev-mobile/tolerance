// tolerance_filter_page.dart - Page for selecting which tolerances to display
// Allows users to filter tolerances by their letter designations

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/localization/app_localizations.dart';
import 'core/models/tolerance_filter.dart';
import 'engineering_theme.dart';

class ToleranceFilterPage extends StatefulWidget {
  final Function() onFiltersChanged;

  const ToleranceFilterPage({super.key, required this.onFiltersChanged});

  @override
  State<ToleranceFilterPage> createState() => _ToleranceFilterPageState();
}

class _ToleranceFilterPageState extends State<ToleranceFilterPage> {
  // Filter state
  ToleranceFilter _filter = ToleranceFilter.defaults();

  // Loading state
  bool _isLoading = true;

  // Original filter state (to detect changes)
  Map<String, bool> _originalState = {};

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  // Load saved filters from SharedPreferences
  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _filter = await ToleranceFilter.load();

      // Store original state to detect changes
      _originalState = {..._filter.holeLetters, ..._filter.shaftLetters};
    } catch (e) {
      debugPrint('Error loading filters: $e');
      // Initialize with default values if loading fails
      _filter = ToleranceFilter.defaults();
      _originalState = {..._filter.holeLetters, ..._filter.shaftLetters};
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Save filter settings
  Future<void> _saveFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _filter.save();
      // Notify parent that filters have changed
      widget.onFiltersChanged();
    } catch (e) {
      debugPrint('Error saving filters: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('filter_save_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Reset all filters to defaults
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.t('reset_filters')),
            content: Text(context.t('reset_filters_confirm')),
            actions: [
             
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _filter = ToleranceFilter.defaults();
                  });
                  _saveFilters();
                },

                child: Text(context.t('reset')),
              ),
            ],
          ),
    );
  }

  // Toggle all hole tolerances
  void _toggleAllHoles(bool value) {
    setState(() {
      for (var key in _filter.holeLetters.keys) {
        _filter.holeLetters[key] = value;
      }
    });
  }

  // Toggle all shaft tolerances
  void _toggleAllShafts(bool value) {
    setState(() {
      for (var key in _filter.shaftLetters.keys) {
        _filter.shaftLetters[key] = value;
      }
    });
  }

  // Check if any changes were made
  bool _hasChanges() {
    // Compare current state with original
    for (var key in _filter.holeLetters.keys) {
      if (_filter.holeLetters[key] != _originalState[key]) {
        return true;
      }
    }

    for (var key in _filter.shaftLetters.keys) {
      if (_filter.shaftLetters[key] != _originalState[key]) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final style = EngineeringTheme.widgetStyle(context);

    // Determine if there are any changes to enable/disable apply button
    final hasChanges = _hasChanges();

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog if there are unsaved changes
        if (hasChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(context.t('unsaved_changes')),
                  content: Text(context.t('discard_changes_question')),
                  actions: [
                 
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),

                      child: Text(context.t('discard')),
                    ),
                  ],
                ),
          );

          // If user cancels, prevent navigation
          if (result == null || !result) {
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('filter_settings')),
          actions: [
            // Reset button
            IconButton(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              tooltip: context.t('reset_to_defaults'),
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: Column(
                    children: [
                      // Main scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description
                              Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: style.infoColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            context.t('filter_info_title'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.t('filter_info_description'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Hole tolerances section
                              _buildSection(
                                title: context.t('hole_tolerances'),
                                icon: Icons.radio_button_unchecked,
                                iconColor: style.infoColor,
                                letters: _filter.holeLetters,
                                onToggleAll: _toggleAllHoles,
                                uppercase: true,
                              ),

                              const SizedBox(height: 24),

                              // Shaft tolerances section
                              _buildSection(
                                title: context.t('shaft_tolerances'),
                                icon: Icons.circle,
                                iconColor: EngineeringTheme.shaftColor,
                                letters: _filter.shaftLetters,
                                onToggleAll: _toggleAllShafts,
                                uppercase: false,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom action bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Cancel button
                
                            // Apply button
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    hasChanges
                                        ? () {
                                          // Check if at least one tolerance is selected
                                          bool hasHoleSelected = _filter
                                              .holeLetters
                                              .values
                                              .any((selected) => selected);
                                          bool hasShaftSelected = _filter
                                              .shaftLetters
                                              .values
                                              .any((selected) => selected);

                                          if (!hasHoleSelected &&
                                              !hasShaftSelected) {
                                            // Show warning if nothing is selected
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text(
                                                      context.t('warning'),
                                                    ),
                                                    content: Text(
                                                      context.t(
                                                        'no_tolerances_selected_warning',
                                                      ),
                                                    ),
                                                 
                                                  ),
                                            );
                                          } else {
                                            // Save and close if at least one tolerance is selected
                                            _saveFilters();
                                            Navigator.of(context).pop();
                                          }
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(context.t('apply')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // Build a section for a group of tolerance letters
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, bool> letters,
    required Function(bool) onToggleAll,
    required bool uppercase,
  }) {
    // Count how many are selected
    final int selected = letters.values.where((v) => v).length;
    final int total = letters.length;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with improved styling
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(isDark ? 0.3 : 0.2),
                iconColor.withOpacity(isDark ? 0.1 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              // Selection counter with improved styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  context.t(
                    'selected_count',
                    args: {
                      'count': selected.toString(),
                      'total': total.toString(),
                    },
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Select/Deselect all with improved styling
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onToggleAll(true),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(context.t('select_all')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  backgroundColor: iconColor.withOpacity(0.2),
                  foregroundColor: iconColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: iconColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onToggleAll(false),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(context.t('deselect_all')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  foregroundColor:
                      isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Tolerance letters grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: letters.length,
          itemBuilder: (context, index) {
            final letter = letters.keys.elementAt(index);
            final isSelected = letters[letter] ?? false;

            return _buildLetterTile(
              letter: letter,
              isSelected: isSelected,
              iconColor: iconColor,
              uppercase: uppercase,
              onChanged: (value) {
                setState(() {
                  letters[letter] = value ?? false;

                  // Add haptic feedback
                  HapticFeedback.selectionClick();
                });
              },
            );
          },
        ),
      ],
    );
  }

  // Build a tile for a single tolerance letter
  Widget _buildLetterTile({
    required String letter,
    required bool isSelected,
    required Color iconColor,
    required bool uppercase,
    required ValueChanged<bool?> onChanged,
  }) {
    final displayLetter =
        uppercase ? letter.toUpperCase() : letter.toLowerCase();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient:
            isSelected
                ? LinearGradient(
                  colors: [
                    iconColor.withOpacity(isDark ? 0.3 : 0.2),
                    iconColor.withOpacity(isDark ? 0.15 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected
                  ? iconColor
                  : isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade300,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!isSelected),
          borderRadius: BorderRadius.circular(12),
          splashColor: iconColor.withOpacity(0.2),
          highlightColor: iconColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isSelected
                              ? iconColor
                              : isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? iconColor : Colors.transparent,
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 6),
                Text(
                  displayLetter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected ? iconColor : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
