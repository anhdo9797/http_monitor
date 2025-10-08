/// Dio interceptor implementation
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/http_logger.dart';
import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';

/// Dio interceptor for capturing HTTP requests and responses
///
/// This interceptor integrates with Dio HTTP client to automatically
/// capture all requests, responses, and errors for monitoring.
class HttpMonitorDioInterceptor extends Interceptor {
  final HttpLogger _logger;
  final Map<RequestOptions, _RequestInfo> _requestMap = {};

  /// Creates a new HttpMonitorDioInterceptor instance
  HttpMonitorDioInterceptor({required HttpLogger logger}) : _logger = logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _generateRequestId();
    final timestamp = DateTime.now();

    // Store request info for later matching with response
    _requestMap[options] = _RequestInfo(
      id: requestId,
      timestamp: timestamp,
    );

    // Extract request data
    final requestData = HttpRequestData(
      id: requestId,
      url: options.uri.toString(),
      method: options.method,
      headers: _extractHeaders(options.headers),
      params: _extractQueryParams(options.queryParameters),
      body: _extractRequestBody(options.data),
      timestamp: timestamp,
    );

    // Log request asynchronously
    _logger.logRequest(requestData);

    // Continue with the request
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestInfo = _requestMap.remove(response.requestOptions);
    if (requestInfo != null) {
      final duration = DateTime.now().difference(requestInfo.timestamp).inMilliseconds;

      // Extract response data
      final responseData = HttpResponseData(
        requestId: requestInfo.id,
        statusCode: response.statusCode ?? 0,
        headers: _extractHeaders(response.headers.map),
        body: _extractResponseBody(response.data),
        duration: duration,
        timestamp: DateTime.now(),
      );

      // Log response asynchronously
      _logger.logResponse(responseData);
    }

    // Continue with the response
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestInfo = _requestMap.remove(err.requestOptions);
    if (requestInfo != null) {
      final duration = DateTime.now().difference(requestInfo.timestamp).inMilliseconds;

      // Extract error data
      final errorData = HttpErrorData(
        requestId: requestInfo.id,
        message: err.message ?? 'Unknown error',
        type: err.type.toString(),
        statusCode: err.response?.statusCode,
        headers: err.response?.headers.map != null
            ? _extractHeaders(err.response!.headers.map)
            : null,
        body: err.response?.data != null
            ? _extractResponseBody(err.response!.data)
            : null,
        duration: duration,
        timestamp: DateTime.now(),
        stackTrace: err.stackTrace.toString(),
      );

      // Log error asynchronously
      _logger.logError(errorData);
    }

    // Continue with the error
    handler.next(err);
  }

  /// Generates a unique request ID
  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Extracts headers from Dio headers map
  Map<String, dynamic> _extractHeaders(Map<String, dynamic> headers) {
    final extracted = <String, dynamic>{};

    headers.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        extracted[key] = value.first;
      } else {
        extracted[key] = value;
      }
    });

    return extracted;
  }

  /// Extracts query parameters
  Map<String, dynamic> _extractQueryParams(Map<String, dynamic> params) {
    return Map<String, dynamic>.from(params);
  }

  /// Extracts request body data
  dynamic _extractRequestBody(dynamic data) {
    if (data == null) return null;

    try {
      // Handle FormData
      if (data is FormData) {
        return _extractFormData(data);
      }

      // Handle Map
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      // Handle List
      if (data is List) {
        return List.from(data);
      }

      // Handle String (might be JSON)
      if (data is String) {
        try {
          return jsonDecode(data);
        } catch (_) {
          return data;
        }
      }

      // For other types, convert to string
      return data.toString();
    } catch (e) {
      return {'error': 'Failed to extract request body', 'type': data.runtimeType.toString()};
    }
  }

  /// Extracts response body data
  dynamic _extractResponseBody(dynamic data) {
    if (data == null) return null;

    try {
      // Handle Map
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      // Handle List
      if (data is List) {
        return List.from(data);
      }

      // Handle String (might be JSON)
      if (data is String) {
        try {
          return jsonDecode(data);
        } catch (_) {
          return data;
        }
      }

      // For other types, convert to string
      return data.toString();
    } catch (e) {
      return {'error': 'Failed to extract response body', 'type': data.runtimeType.toString()};
    }
  }

  /// Extracts FormData fields
  Map<String, dynamic> _extractFormData(FormData formData) {
    final result = <String, dynamic>{};

    for (final field in formData.fields) {
      result[field.key] = field.value;
    }

    // Add file information
    if (formData.files.isNotEmpty) {
      result['_files'] = formData.files.map((file) {
        return {
          'key': file.key,
          'filename': file.value.filename,
          'contentType': file.value.contentType?.toString(),
          'length': file.value.length,
        };
      }).toList();
    }

    return result;
  }

  /// Clears the request map
  ///
  /// This is useful for cleanup or testing purposes.
  void clearRequestMap() {
    _requestMap.clear();
  }

  /// Gets the count of pending requests
  int get pendingRequestCount => _requestMap.length;
}

/// Internal class to track request information
class _RequestInfo {
  final String id;
  final DateTime timestamp;

  _RequestInfo({
    required this.id,
    required this.timestamp,
  });
}
