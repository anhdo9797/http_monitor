/// Data class for HTTP response information
library;

/// Represents HTTP response data captured by interceptors
class HttpResponseData {
  /// Unique identifier linking to the corresponding request
  final String requestId;

  /// HTTP status code (200, 404, 500, etc.)
  final int statusCode;

  /// Response headers as key-value pairs
  final Map<String, dynamic> headers;

  /// Response body (can be JSON, string, or other types)
  final dynamic body;

  /// Request duration in milliseconds
  final int duration;

  /// Timestamp when the response was received
  final DateTime timestamp;

  /// Error message if the request failed
  final String? errorMessage;

  /// Creates a new HttpResponseData instance
  const HttpResponseData({
    required this.requestId,
    required this.statusCode,
    this.headers = const {},
    this.body,
    required this.duration,
    required this.timestamp,
    this.errorMessage,
  });

  /// Creates a copy of this HttpResponseData with the given fields replaced
  HttpResponseData copyWith({
    String? requestId,
    int? statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    int? duration,
    DateTime? timestamp,
    String? errorMessage,
  }) {
    return HttpResponseData(
      requestId: requestId ?? this.requestId,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Whether the response indicates success (2xx status code)
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Whether the response indicates an error (4xx or 5xx status code)
  bool get isError => statusCode >= 400;

  @override
  String toString() {
    return 'HttpResponseData(requestId: $requestId, statusCode: $statusCode, duration: ${duration}ms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpResponseData &&
        other.requestId == requestId &&
        other.statusCode == statusCode &&
        other.duration == duration &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(requestId, statusCode, duration, timestamp);
  }
}

