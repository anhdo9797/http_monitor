/// HTTP logger for processing and storing intercepted data
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import '../db/http_log_repository.dart';
import '../model/http_log.dart';
import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';
import '../model/http_monitor_config.dart';
import 'database_queue.dart';
import 'thread_safe_map.dart';
import '../utils/retry_helper.dart';

/// Logger class for processing and storing HTTP intercepted data
///
/// This class handles the conversion of intercepted HTTP data into log entries
/// and stores them in the repository. It also handles data sanitization,
/// size limits, and asynchronous logging.
class HttpLogger {
  final HttpLogRepository _repository;
  final HttpMonitorConfig _config;
  final ThreadSafeMap<String, _PendingRequest> _pendingRequests;
  final DatabaseQueue _dbQueue;

  /// Creates a new HttpLogger instance
  HttpLogger({
    required HttpLogRepository repository,
    required HttpMonitorConfig config,
    DatabaseQueue? dbQueue,
  })  : _repository = repository,
        _config = config,
        _pendingRequests = ThreadSafeMap<String, _PendingRequest>(),
        _dbQueue = dbQueue ?? DatabaseQueue();

  /// Logs an HTTP request
  ///
  /// This method stores the request data temporarily and creates a log entry.
  /// The log will be updated when the corresponding response is received.
  Future<void> logRequest(HttpRequestData request) async {
    if (!_config.enabled) return;

    // Store pending request for later matching with response
    await _pendingRequests.put(
        request.id,
        _PendingRequest(
          request: request,
          timestamp: request.timestamp,
        ));

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

    // Store using database queue with retry mechanism
    await RetryHelper.withRetry(() async {
      return await _dbQueue.enqueue(() async {
        return await _repository.insertLog(log);
      }, operationName: 'InsertLog_${request.id}');
    }).then((id) async {
      final logWithId = log.copyWith(id: id);

      // Update pending request with the stored log
      await _pendingRequests.updateIfExists(request.id, (pending) {
        return pending.copyWith(log: logWithId);
      });
    }).catchError((error) {
      // Silently fail - don't break the application flow
      // But we can add logging here for debugging
      developer.log('Failed to store request log: $error');
    });
  }

  /// Logs an HTTP response
  ///
  /// This method updates the existing log entry with response data.
  Future<void> logResponse(HttpResponseData response) async {
    if (!_config.enabled) return;

    final pending = await _pendingRequests.remove(response.requestId);
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
      // Update using database queue with retry mechanism
      await RetryHelper.withRetry(() async {
        return await _dbQueue.enqueue(() async {
          await _repository.updateLog(updatedLog);
          return updatedLog;
        }, operationName: 'UpdateLog_${response.requestId}');
      }).catchError((error) {
        // Silently fail
        developer.log('Failed to update log with response: $error');
        return updatedLog;
      });
    }
  }

  /// Logs an HTTP error
  ///
  /// This method updates the existing log entry with error data.
  Future<void> logError(HttpErrorData error) async {
    if (!_config.enabled) return;

    final pending = await _pendingRequests.remove(error.requestId);
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
      // Update using database queue with retry mechanism
      await RetryHelper.withRetry(() async {
        return await _dbQueue.enqueue(() async {
          await _repository.updateLog(updatedLog);
          return updatedLog;
        }, operationName: 'UpdateLogError_${error.requestId}');
      }).catchError((error) {
        // Silently fail
        developer.log('Failed to update log with error: $error');
        return updatedLog;
      });
    }
  }

  /// Logs a response that doesn't have a matching request
  Future<void> _logOrphanResponse(HttpResponseData response) async {
    await RetryHelper.withRetry(() async {
      return await _dbQueue.enqueue(() async {
        final log = HttpLog(
          url: 'Unknown',
          method: 'UNKNOWN',
          headers: {},
          params: {},
          body: null,
          response:
              _config.logResponseBody ? _truncateBody(response.body) : null,
          statusCode: response.statusCode,
          duration: response.duration,
          createdAt: response.timestamp,
        );

        return await _repository.insertLog(log);
      }, operationName: 'InsertOrphanResponse');
    }).catchError((error) {
      // Silently fail
      developer.log('Failed to log orphan response: $error');
      return -1; // Return error indicator
    });
  }

  /// Logs an error that doesn't have a matching request
  Future<void> _logOrphanError(HttpErrorData error) async {
    await RetryHelper.withRetry(() async {
      return await _dbQueue.enqueue(() async {
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

        return await _repository.insertLog(log);
      }, operationName: 'InsertOrphanError');
    }).catchError((error) {
      // Silently fail
      developer.log('Failed to log orphan error: $error');
      return -1; // Return error indicator
    });
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
  Future<void> clearPendingRequests() async {
    await _pendingRequests.clear();
  }

  /// Gets the count of pending requests
  Future<int> get pendingRequestCount async {
    return await _pendingRequests.length;
  }

  /// Gets the database queue status
  int get queueLength => _dbQueue.queueLength;

  /// Clears the database queue
  void clearQueue() {
    _dbQueue.clearQueue();
  }
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
