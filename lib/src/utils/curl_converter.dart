/// cURL converter utility
library;

import 'dart:convert';
import '../model/http_log.dart';

/// Utility class for converting HTTP logs to cURL commands
///
/// This class provides methods to convert HttpLog objects into
/// executable cURL commands that can be used to reproduce requests.
class CurlConverter {
  /// Converts an HTTP log to a cURL command
  ///
  /// [log] The HTTP log to convert
  /// [includeHeaders] Whether to include headers in the command (default: true)
  /// [compressed] Whether to add --compressed flag (default: false)
  /// Returns a cURL command string
  static String toCurl(
    HttpLog log, {
    bool includeHeaders = true,
    bool compressed = false,
  }) {
    final buffer = StringBuffer('curl');

    // Add method
    if (log.method != 'GET') {
      buffer.write(' -X ${log.method}');
    }

    // Add URL (quoted to handle special characters)
    buffer.write(' \'${log.url}\'');

    // Add headers
    if (includeHeaders && log.headers.isNotEmpty) {
      log.headers.forEach((key, value) {
        // Skip certain headers that curl adds automatically
        if (!_shouldSkipHeader(key)) {
          final escapedValue = _escapeValue(value.toString());
          buffer.write(' -H \'$key: $escapedValue\'');
        }
      });
    }

    // Add body
    if (log.body != null && _hasBody(log.method)) {
      final bodyString = _formatBody(log.body);
      if (bodyString.isNotEmpty) {
        final escapedBody = _escapeValue(bodyString);
        buffer.write(' -d \'$escapedBody\'');
      }
    }

    // Add compressed flag
    if (compressed) {
      buffer.write(' --compressed');
    }

    return buffer.toString();
  }

  /// Converts an HTTP log to a cURL command with pretty formatting
  ///
  /// [log] The HTTP log to convert
  /// [includeHeaders] Whether to include headers in the command (default: true)
  /// [compressed] Whether to add --compressed flag (default: false)
  /// Returns a formatted cURL command string with line breaks
  static String toCurlPretty(
    HttpLog log, {
    bool includeHeaders = true,
    bool compressed = false,
  }) {
    final buffer = StringBuffer('curl');

    // Add method
    if (log.method != 'GET') {
      buffer.write(' \\\n  -X ${log.method}');
    }

    // Add URL
    buffer.write(' \\\n  \'${log.url}\'');

    // Add headers
    if (includeHeaders && log.headers.isNotEmpty) {
      log.headers.forEach((key, value) {
        if (!_shouldSkipHeader(key)) {
          final escapedValue = _escapeValue(value.toString());
          buffer.write(' \\\n  -H \'$key: $escapedValue\'');
        }
      });
    }

    // Add body
    if (log.body != null && _hasBody(log.method)) {
      final bodyString = _formatBody(log.body);
      if (bodyString.isNotEmpty) {
        final escapedBody = _escapeValue(bodyString);
        buffer.write(' \\\n  -d \'$escapedBody\'');
      }
    }

    // Add compressed flag
    if (compressed) {
      buffer.write(' \\\n  --compressed');
    }

    return buffer.toString();
  }

  /// Checks if a header should be skipped
  static bool _shouldSkipHeader(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey == 'content-length' ||
        lowerKey == 'host' ||
        lowerKey == 'connection';
  }

  /// Checks if the HTTP method typically has a body
  static bool _hasBody(String method) {
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Formats the body for cURL command
  static String _formatBody(dynamic body) {
    if (body == null) return '';

    if (body is String) {
      return body;
    }

    if (body is Map || body is List) {
      try {
        return jsonEncode(body);
      } catch (_) {
        return body.toString();
      }
    }

    return body.toString();
  }

  /// Escapes special characters in values
  static String _escapeValue(String value) {
    // Escape single quotes by replacing ' with '\''
    return value.replaceAll('\'', '\'\\\'\'');
  }
}
