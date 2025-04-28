// tolerance_filter.dart - Model for tolerance filter settings
// Manages which tolerance designations are visible in the table

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolerance/core/constants/tolerance_constants.dart';

class ToleranceFilter {
  // Map of hole tolerance letters to visibility status
  Map<String, bool> holeLetters;
  
  // Map of shaft tolerance letters to visibility status
  Map<String, bool> shaftLetters;
  
  // SharedPreferences key
  static const String _prefKey = 'tolerance_filter';
  
  // Constructor
  ToleranceFilter({
    required this.holeLetters,
    required this.shaftLetters,
  });
  
  // Factory method for default values
  factory ToleranceFilter.defaults() {
    // Extract tolerance designations from ToleranceConstants
    Map<String, bool> holeLetters = {};
    Map<String, bool> shaftLetters = {};
    
    // Get all column names from all intervals
    Set<String> allDesignations = {};
    
    // Iterate through all tolerance values
    ToleranceConstants.toleranceValues.forEach((interval, values) {
      values.keys.forEach((key) {
        if (key != "Interval") {
          allDesignations.add(key);
        }
      });
    });
    
    // Categorize as hole or shaft based on first character case
    for (String designation in allDesignations) {
      if (designation.isNotEmpty) {
        // Extract letter part (may be one or more letters)
        String letterPart = '';
        for (int i = 0; i < designation.length; i++) {
          if (!RegExp(r'[0-9]').hasMatch(designation[i])) {
            letterPart += designation[i];
          } else {
            break;
          }
        }
        
        // Skip if letter part is empty
        if (letterPart.isEmpty) continue;
        
        // Check if uppercase (hole) or lowercase (shaft)
        if (letterPart[0] == letterPart[0].toUpperCase()) {
          // It's a hole tolerance
          if (!holeLetters.containsKey(letterPart)) {
            holeLetters[letterPart] = true;
          }
        } else {
          // It's a shaft tolerance
          if (!shaftLetters.containsKey(letterPart)) {
            shaftLetters[letterPart] = true;
          }
        }
      }
    }
    
    return ToleranceFilter(
      holeLetters: holeLetters,
      shaftLetters: shaftLetters,
    );
  }
  
  // Load from SharedPreferences
  static Future<ToleranceFilter> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get stored JSON string
      final String? storedJson = prefs.getString(_prefKey);
      
      // If no saved data, return defaults
      if (storedJson == null) {
        return ToleranceFilter.defaults();
      }
      
      // Decode JSON string
      final Map<String, dynamic> decodedJson = Map<String, dynamic>.from(
        json.decode(storedJson),
      );
      
      // Hole letters
      final Map<String, bool> holeLetters = 
        decodedJson['holeLetters'] != null
            ? Map<String, bool>.from(decodedJson['holeLetters'])
            : {};
            
      // Shaft letters
      final Map<String, bool> shaftLetters = 
        decodedJson['shaftLetters'] != null
            ? Map<String, bool>.from(decodedJson['shaftLetters'])
            : {};
      
      // Merge with defaults to ensure all letters are present
      final defaults = ToleranceFilter.defaults();
      
      // Add any missing letters from defaults
      defaults.holeLetters.forEach((key, value) {
        if (!holeLetters.containsKey(key)) {
          holeLetters[key] = value;
        }
      });
      
      defaults.shaftLetters.forEach((key, value) {
        if (!shaftLetters.containsKey(key)) {
          shaftLetters[key] = value;
        }
      });
      
      return ToleranceFilter(
        holeLetters: holeLetters,
        shaftLetters: shaftLetters,
      );
    } catch (e) {
      debugPrint('Error loading tolerance filter: $e');
      return ToleranceFilter.defaults();
    }
  }
  
  // Save to SharedPreferences
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create JSON map
      final Map<String, dynamic> jsonMap = {
        'holeLetters': holeLetters,
        'shaftLetters': shaftLetters,
      };
      
      // Convert to JSON string
      final String jsonString = json.encode(jsonMap);
      
      // Save to SharedPreferences
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving tolerance filter: $e');
      rethrow;
    }
  }
  
  // Check if a tolerance is visible
  bool isVisible(String tolerance) {
    // Empty or null tolerance is always visible
    if (tolerance.isEmpty) return true;
    
    // Interval column is always visible
    if (tolerance == "Interval") return true;
    
    // Extract letter part (may be one or more letters)
    String letterPart = '';
    for (int i = 0; i < tolerance.length; i++) {
      if (!RegExp(r'[0-9]').hasMatch(tolerance[i])) {
        letterPart += tolerance[i];
      } else {
        break;
      }
    }
    
    // Skip if letter part is empty
    if (letterPart.isEmpty) return true;
    
    // Get first character to determine if it's a hole or shaft
    final firstChar = letterPart[0];
    
    // Check if uppercase (hole) or lowercase (shaft)
    final isHole = firstChar == firstChar.toUpperCase();
    
    // Check visibility
    if (isHole) {
      return holeLetters[letterPart] ?? true;
    } else {
      return shaftLetters[letterPart] ?? true;
    }
  }
  
  // Get a list of all visible tolerances
  List<String> getVisibleTolerances(List<String> allTolerances) {
    return allTolerances.where((tolerance) => isVisible(tolerance)).toList();
  }
}

// JSON utility to avoid separate import
class json {
  static String encode(Object? object) {
    return const JsonEncoder().convert(object);
  }
  
  static dynamic decode(String source) {
    return const JsonDecoder().convert(source);
  }
}