/// Data class for HTTP request information
library;

/// Represents HTTP request data captured by interceptors
class HttpRequestData {
  /// Unique identifier for this request
  final String id;

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

  /// Timestamp when the request was created
  final DateTime timestamp;

  /// Creates a new HttpRequestData instance
  const HttpRequestData({
    required this.id,
    required this.url,
    required this.method,
    this.headers = const {},
    this.params = const {},
    this.body,
    required this.timestamp,
  });

  /// Creates a copy of this HttpRequestData with the given fields replaced
  HttpRequestData copyWith({
    String? id,
    String? url,
    String? method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
    dynamic body,
    DateTime? timestamp,
  }) {
    return HttpRequestData(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'HttpRequestData(id: $id, method: $method, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpRequestData &&
        other.id == id &&
        other.url == url &&
        other.method == method &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, url, method, timestamp);
  }
}

