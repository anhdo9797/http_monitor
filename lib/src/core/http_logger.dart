/// HTTP logger for processing and storing intercepted data
library;

import 'dart:async';
import 'dart:convert';
import '../db/http_log_repository.dart';
import '../model/http_log.dart';
import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';
import '../model/http_monitor_config.dart';

/// Logger class for processing and storing HTTP intercepted data
///
/// This class handles the conversion of intercepted HTTP data into log entries
/// and stores them in the repository. It also handles data sanitization,
/// size limits, and asynchronous logging.
class HttpLogger {
  final HttpLogRepository _repository;
  final HttpMonitorConfig _config;
  final Map<String, _PendingRequest> _pendingRequests = {};

  /// Creates a new HttpLogger instance
  HttpLogger({
    required HttpLogRepository repository,
    required HttpMonitorConfig config,
  })  : _repository = repository,
        _config = config;

  /// Logs an HTTP request
  ///
  /// This method stores the request data temporarily and creates a log entry.
  /// The log will be updated when the corresponding response is received.
  Future<void> logRequest(HttpRequestData request) async {
    if (!_config.enabled) return;

    // Store pending request for later matching with response
    _pendingRequests[request.id] = _PendingRequest(
      request: request,
      timestamp: request.timestamp,
    );

    // Create initial log entry (without response data)
    final log = HttpLog(
      url: request.url,
      method: request.method,
      headers: _sanitizeHeaders(request.headers),
      params: request.params,
      body: _config.logRequestBody ? _truncateBody(request.body) : null,
      response: null,
      statusCode: 0, // Will be updated when response arrives
      duration: 0, // Will be updated when response arrives
      createdAt: request.timestamp,
    );

    // Store asynchronously without blocking
    unawaited(_storeLog(request.id, log));
  }

  /// Logs an HTTP response
  ///
  /// This method updates the existing log entry with response data.
  Future<void> logResponse(HttpResponseData response) async {
    if (!_config.enabled) return;

    final pending = _pendingRequests.remove(response.requestId);
    if (pending == null) {
      // Response without matching request - log it anyway
      await _logOrphanResponse(response);
      return;
    }

    // Update the log with response data
    final updatedLog = pending.log?.copyWith(
      response: _config.logResponseBody ? _truncateBody(response.body) : null,
      statusCode: response.statusCode,
      duration: response.duration,
    );

    if (updatedLog != null) {
      // Update asynchronously without blocking
      unawaited(_repository.updateLog(updatedLog));
    }
  }

  /// Logs an HTTP error
  ///
  /// This method updates the existing log entry with error data.
  Future<void> logError(HttpErrorData error) async {
    if (!_config.enabled) return;

    final pending = _pendingRequests.remove(error.requestId);
    if (pending == null) {
      // Error without matching request - log it anyway
      await _logOrphanError(error);
      return;
    }

    // Update the log with error data
    final errorResponse = {
      'error': error.message,
      'type': error.type,
      if (error.stackTrace != null) 'stackTrace': error.stackTrace,
      if (error.body != null) 'body': error.body,
    };

    final updatedLog = pending.log?.copyWith(
      response: _truncateBody(errorResponse),
      statusCode: error.statusCode ?? 0,
      duration: error.duration,
    );

    if (updatedLog != null) {
      // Update asynchronously without blocking
      unawaited(_repository.updateLog(updatedLog));
    }
  }

  /// Stores a log entry and associates it with a request ID
  Future<void> _storeLog(String requestId, HttpLog log) async {
    try {
      final id = await _repository.insertLog(log);
      final logWithId = log.copyWith(id: id);

      // Update pending request with the stored log
      final pending = _pendingRequests[requestId];
      if (pending != null) {
        _pendingRequests[requestId] = pending.copyWith(log: logWithId);
      }
    } catch (e) {
      // Silently fail - don't break the application flow
      // Error is already handled by repository's graceful degradation
    }
  }

  /// Logs a response that doesn't have a matching request
  Future<void> _logOrphanResponse(HttpResponseData response) async {
    try {
      final log = HttpLog(
        url: 'Unknown',
        method: 'UNKNOWN',
        headers: {},
        params: {},
        body: null,
        response: _config.logResponseBody ? _truncateBody(response.body) : null,
        statusCode: response.statusCode,
        duration: response.duration,
        createdAt: response.timestamp,
      );

      await _repository.insertLog(log);
    } catch (e) {
      // Silently fail
    }
  }

  /// Logs an error that doesn't have a matching request
  Future<void> _logOrphanError(HttpErrorData error) async {
    try {
      final errorResponse = {
        'error': error.message,
        'type': error.type,
        if (error.stackTrace != null) 'stackTrace': error.stackTrace,
        if (error.body != null) 'body': error.body,
      };

      final log = HttpLog(
        url: 'Unknown',
        method: 'UNKNOWN',
        headers: error.headers ?? {},
        params: {},
        body: null,
        response: _truncateBody(errorResponse),
        statusCode: error.statusCode ?? 0,
        duration: error.duration,
        createdAt: error.timestamp,
      );

      await _repository.insertLog(log);
    } catch (e) {
      // Silently fail
    }
  }

  /// Sanitizes headers by removing or masking sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    for (final sensitiveHeader in _config.sensitiveHeaders) {
      final key = headers.keys.firstWhere(
        (k) => k.toLowerCase() == sensitiveHeader.toLowerCase(),
        orElse: () => '',
      );

      if (key.isNotEmpty && sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }

  /// Truncates body data if it exceeds the maximum size
  dynamic _truncateBody(dynamic body) {
    if (body == null) return null;

    try {
      String bodyString;

      if (body is String) {
        bodyString = body;
      } else if (body is Map || body is List) {
        bodyString = jsonEncode(body);
      } else {
        bodyString = body.toString();
      }

      if (bodyString.length > _config.maxResponseBodySize) {
        final truncated = bodyString.substring(0, _config.maxResponseBodySize);
        return {
          'truncated': true,
          'originalSize': bodyString.length,
          'data': truncated,
          'message': 'Body truncated due to size limit',
        };
      }

      return body;
    } catch (e) {
      // If encoding fails, return a safe representation
      return {
        'error': 'Failed to encode body',
        'type': body.runtimeType.toString(),
      };
    }
  }

  /// Clears all pending requests
  ///
  /// This is useful for cleanup or testing purposes.
  void clearPendingRequests() {
    _pendingRequests.clear();
  }

  /// Gets the count of pending requests
  int get pendingRequestCount => _pendingRequests.length;
}

/// Internal class to track pending requests
class _PendingRequest {
  final HttpRequestData request;
  final DateTime timestamp;
  final HttpLog? log;

  _PendingRequest({
    required this.request,
    required this.timestamp,
    this.log,
  });

  _PendingRequest copyWith({
    HttpRequestData? request,
    DateTime? timestamp,
    HttpLog? log,
  }) {
    return _PendingRequest(
      request: request ?? this.request,
      timestamp: timestamp ?? this.timestamp,
      log: log ?? this.log,
    );
  }
}
