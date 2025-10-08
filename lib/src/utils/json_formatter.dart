/// JSON formatter utility
library;

import 'dart:convert';

/// Utility class for formatting JSON data for display
class JsonFormatter {
  /// Formats a JSON object into a pretty-printed string
  ///
  /// Returns a formatted JSON string with proper indentation.
  /// If the input is not valid JSON, returns the original string.
  static String format(dynamic json, {int indent = 2}) {
    if (json == null) return 'null';

    try {
      // If it's already a string, try to parse it first
      if (json is String) {
        try {
          json = jsonDecode(json);
        } catch (_) {
          // If parsing fails, return the original string
          return json;
        }
      }

      // Convert to pretty JSON
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      // If formatting fails, return string representation
      return json.toString();
    }
  }

  /// Formats a JSON object into a compact string (single line)
  static String formatCompact(dynamic json) {
    if (json == null) return 'null';

    try {
      // If it's already a string, try to parse it first
      if (json is String) {
        try {
          json = jsonDecode(json);
        } catch (_) {
          return json;
        }
      }

      return jsonEncode(json);
    } catch (e) {
      return json.toString();
    }
  }

  /// Checks if a string is valid JSON
  static bool isValidJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Truncates a string to a maximum length with ellipsis
  static String truncate(String str, {int maxLength = 100}) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }

  /// Formats a map of headers for display
  static String formatHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return 'No headers';

    final buffer = StringBuffer();
    headers.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  /// Formats query parameters for display
  static String formatParams(Map<String, dynamic> params) {
    if (params.isEmpty) return 'No parameters';

    final buffer = StringBuffer();
    params.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  /// Formats a body (can be JSON, string, or other types)
  static String formatBody(dynamic body) {
    if (body == null) return 'No body';

    if (body is String) {
      if (isValidJson(body)) {
        return format(body);
      }
      return body;
    }

    if (body is Map || body is List) {
      return format(body);
    }

    return body.toString();
  }
}
