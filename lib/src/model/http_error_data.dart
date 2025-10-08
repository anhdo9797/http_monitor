/// Data class for HTTP error information
library;

/// Represents HTTP error data captured by interceptors
class HttpErrorData {
  /// Unique identifier linking to the corresponding request
  final String requestId;

  /// Error message
  final String message;

  /// Error type (e.g., 'DioException', 'SocketException', etc.)
  final String? type;

  /// HTTP status code if available
  final int? statusCode;

  /// Response headers if available
  final Map<String, dynamic>? headers;

  /// Response body if available
  final dynamic body;

  /// Request duration in milliseconds
  final int duration;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  /// Stack trace if available
  final String? stackTrace;

  /// Creates a new HttpErrorData instance
  const HttpErrorData({
    required this.requestId,
    required this.message,
    this.type,
    this.statusCode,
    this.headers,
    this.body,
    required this.duration,
    required this.timestamp,
    this.stackTrace,
  });

  /// Creates a copy of this HttpErrorData with the given fields replaced
  HttpErrorData copyWith({
    String? requestId,
    String? message,
    String? type,
    int? statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    int? duration,
    DateTime? timestamp,
    String? stackTrace,
  }) {
    return HttpErrorData(
      requestId: requestId ?? this.requestId,
      message: message ?? this.message,
      type: type ?? this.type,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() {
    return 'HttpErrorData(requestId: $requestId, message: $message, statusCode: $statusCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpErrorData &&
        other.requestId == requestId &&
        other.message == message &&
        other.statusCode == statusCode &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(requestId, message, statusCode, timestamp);
  }
}

