/// Data model for HTTP log entries
library;

import 'dart:convert';

/// Represents a single HTTP request/response log entry
class HttpLog {
  /// Unique identifier for the log entry
  final int? id;

  /// The URL of the HTTP request
  final String url;

  /// HTTP method (GET, POST, PUT, DELETE, PATCH, etc.)
  final String method;

  /// Request headers as key-value pairs
  final Map<String, dynamic> headers;

  /// Query parameters as key-value pairs
  final Map<String, dynamic> params;

  /// Request body (can be JSON, string, or other types)
  final dynamic body;

  /// Response body (can be JSON, string, or other types)
  final dynamic response;

  /// HTTP status code (200, 404, 500, etc.)
  final int statusCode;

  /// Request duration in milliseconds
  final int duration;

  /// Timestamp when the request was created
  final DateTime createdAt;

  /// Creates a new HttpLog instance
  const HttpLog({
    this.id,
    required this.url,
    required this.method,
    required this.headers,
    required this.params,
    this.body,
    this.response,
    required this.statusCode,
    required this.duration,
    required this.createdAt,
  });

  /// Creates an HttpLog from a JSON map
  factory HttpLog.fromJson(Map<String, dynamic> json) {
    return HttpLog(
      id: json['id'] as int?,
      url: json['url'] as String,
      method: json['method'] as String,
      headers: _parseJsonField(json['headers']),
      params: _parseJsonField(json['params']),
      body: _parseBody(json['body']),
      response: _parseBody(json['response']),
      statusCode: json['status_code'] as int,
      duration: json['duration'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts the HttpLog to a JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'method': method,
      'headers': _encodeJsonField(headers),
      'params': _encodeJsonField(params),
      'body': _encodeBody(body),
      'response': _encodeBody(response),
      'status_code': statusCode,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts the HttpLog to a database map (for SQLite)
  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'method': method,
      'headers': _encodeJsonField(headers),
      'params': _encodeJsonField(params),
      'body': _encodeBody(body),
      'response': _encodeBody(response),
      'status_code': statusCode,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates an HttpLog from a database map
  factory HttpLog.fromDbMap(Map<String, dynamic> map) {
    return HttpLog.fromJson(map);
  }

  /// Returns true if the status code indicates success (2xx)
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Returns true if the status code indicates an error (4xx or 5xx)
  bool get isError => statusCode >= 400;

  /// Returns the status code group (2xx, 3xx, 4xx, 5xx)
  String get statusGroup => '${(statusCode ~/ 100)}xx';

  /// Returns true if the status code indicates a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns true if the status code indicates a server error (5xx)
  bool get isServerError => statusCode >= 500;

  /// Returns true if the status code indicates a redirect (3xx)
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Creates a copy of this HttpLog with the given fields replaced
  HttpLog copyWith({
    int? id,
    String? url,
    String? method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
    dynamic body,
    dynamic response,
    int? statusCode,
    int? duration,
    DateTime? createdAt,
  }) {
    return HttpLog(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      body: body ?? this.body,
      response: response ?? this.response,
      statusCode: statusCode ?? this.statusCode,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'HttpLog(id: $id, method: $method, url: $url, statusCode: $statusCode, duration: ${duration}ms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpLog &&
        other.id == id &&
        other.url == url &&
        other.method == method &&
        other.statusCode == statusCode &&
        other.duration == duration &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      url,
      method,
      statusCode,
      duration,
      createdAt,
    );
  }

  // Helper methods for JSON parsing

  static Map<String, dynamic> _parseJsonField(dynamic field) {
    if (field == null) return {};
    if (field is Map<String, dynamic>) return field;
    if (field is String) {
      try {
        final decoded = jsonDecode(field);
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  static dynamic _parseBody(dynamic body) {
    if (body == null) return null;
    if (body is String) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  static String? _encodeJsonField(Map<String, dynamic>? field) {
    if (field == null || field.isEmpty) return null;
    try {
      return jsonEncode(field);
    } catch (_) {
      return null;
    }
  }

  static String? _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }
}

