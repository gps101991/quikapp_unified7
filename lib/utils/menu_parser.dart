import 'dart:convert';

/// Utility class for parsing menu items with automatic JSON format fixing
class MenuParser {
  /// Parse menu items from a string, automatically fixing common JSON format issues
  static List<Map<String, dynamic>> parseMenuItems(String menuString) {
    if (menuString.isEmpty) {
      return [];
    }

    try {
      // First attempt: Parse as-is
      return _parseJson(menuString);
    } catch (e) {
      try {
        // Second attempt: Fix common JSON issues
        return _parseJson(_fixJsonFormat(menuString));
      } catch (e) {
        try {
          // Third attempt: Convert Python-style dict to JSON
          return _parseJson(_convertPythonDictToJson(menuString));
        } catch (e) {
          // Final attempt: Try to extract valid JSON structure
          return _parseJson(_extractValidJson(menuString));
        }
      }
    }
  }

  /// Parse JSON string to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _parseJson(String jsonString) {
    final cleaned = jsonString.trim();
    final decoded = json.decode(cleaned);
    
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw FormatException('Expected List, got ${decoded.runtimeType}');
    }
  }

  /// Fix common JSON formatting issues
  static String _fixJsonFormat(String input) {
    String fixed = input
        .replaceAll('\\n', '')  // Remove escaped newlines
        .replaceAll('\\r', '')  // Remove escaped carriage returns
        .replaceAll('\\t', '')  // Remove escaped tabs
        .trim();

    // Replace single quotes with double quotes
    fixed = fixed.replaceAll("'", '"');
    
    // Fix potential trailing commas
    fixed = fixed.replaceAll(',]', ']');
    fixed = fixed.replaceAll(',}', '}');
    
    // Fix common Python/JavaScript differences
    fixed = fixed.replaceAll('True', 'true');
    fixed = fixed.replaceAll('False', 'false');
    fixed = fixed.replaceAll('None', 'null');
    
    return fixed;
  }

  /// Convert Python-style dict string to valid JSON
  static String _convertPythonDictToJson(String input) {
    String converted = input;
    
    // Replace Python boolean values
    converted = converted.replaceAll('True', 'true');
    converted = converted.replaceAll('False', 'false');
    converted = converted.replaceAll('None', 'null');
    
    // Replace single quotes with double quotes
    converted = converted.replaceAll("'", '"');
    
    // Fix potential trailing commas
    converted = converted.replaceAll(',]', ']');
    converted = converted.replaceAll(',}', '}');
    
    return converted;
  }

  /// Extract valid JSON structure from malformed string
  static String _extractValidJson(String input) {
    // Find the first '[' and last ']' to extract array content
    final startIndex = input.indexOf('[');
    final endIndex = input.lastIndexOf(']');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final extracted = input.substring(startIndex, endIndex + 1);
      return _fixJsonFormat(extracted);
    }
    
    // If no array brackets found, try to wrap in brackets
    return '[$input]';
  }

  /// Validate menu item structure
  static bool isValidMenuItem(Map<String, dynamic> item) {
    // Check required fields
    if (!item.containsKey('label') || !item.containsKey('icon')) {
      return false;
    }
    
    // Check if label is string
    if (item['label'] is! String) {
      return false;
    }
    
    // Check if icon is map with required fields
    if (item['icon'] is! Map<String, dynamic>) {
      return false;
    }
    
    final icon = item['icon'] as Map<String, dynamic>;
    if (!icon.containsKey('type') || !icon.containsKey('name')) {
      return false;
    }
    
    return true;
  }

  /// Clean and validate menu items
  static List<Map<String, dynamic>> cleanMenuItems(List<Map<String, dynamic>> items) {
    return items.where((item) => isValidMenuItem(item)).toList();
  }

  /// Get parsing status and error information
  static Map<String, dynamic> getParsingStatus(String menuString) {
    try {
      final items = parseMenuItems(menuString);
      return {
        'success': true,
        'itemCount': items.length,
        'validItems': cleanMenuItems(items).length,
        'error': null,
      };
    } catch (e) {
      return {
        'success': false,
        'itemCount': 0,
        'validItems': 0,
        'error': e.toString(),
      };
    }
  }
}
