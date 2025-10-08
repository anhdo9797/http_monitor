/// HTTP Client interceptor implementation
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/http_logger.dart';
import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';

/// HTTP Client wrapper for capturing HTTP requests and responses
///
/// This class wraps the standard dart:http Client to automatically
/// capture all requests, responses, and errors for monitoring.
class HttpMonitorClient extends http.BaseClient {
  final http.Client _inner;
  final HttpLogger _logger;
  final Map<String, _RequestInfo> _requestMap = {};

  /// Creates a new HttpMonitorClient instance
  ///
  /// [client] The underlying HTTP client to wrap
  /// [logger] The logger instance for capturing requests/responses
  HttpMonitorClient({
    required http.Client client,
    required HttpLogger logger,
  })  : _inner = client,
        _logger = logger;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestId = _generateRequestId();
    final timestamp = DateTime.now();

    // Store request info for later matching with response
    _requestMap[requestId] = _RequestInfo(
      id: requestId,
      timestamp: timestamp,
    );

    // Extract and log request data
    final requestData = await _extractRequestData(request, requestId, timestamp);
    await _logger.logRequest(requestData);

    try {
      // Send the actual request
      final response = await _inner.send(request);
      final duration = DateTime.now().difference(timestamp).inMilliseconds;

      // Read response body
      final responseBytes = await response.stream.toBytes();
      final responseBody = _decodeResponseBody(responseBytes, response.headers);

      // Create a new response with the consumed stream
      final newResponse = http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );

      // Extract and log response data
      final responseData = HttpResponseData(
        requestId: requestId,
        statusCode: response.statusCode,
        headers: Map<String, dynamic>.from(response.headers),
        body: responseBody,
        duration: duration,
        timestamp: DateTime.now(),
      );

      await _logger.logResponse(responseData);
      _requestMap.remove(requestId);

      return newResponse;
    } catch (error, stackTrace) {
      final duration = DateTime.now().difference(timestamp).inMilliseconds;

      // Extract and log error data
      final errorData = HttpErrorData(
        requestId: requestId,
        message: error.toString(),
        type: error.runtimeType.toString(),
        duration: duration,
        timestamp: DateTime.now(),
        stackTrace: stackTrace.toString(),
      );

      await _logger.logError(errorData);
      _requestMap.remove(requestId);

      rethrow;
    }
  }

  /// Extracts request data from http.BaseRequest
  Future<HttpRequestData> _extractRequestData(
    http.BaseRequest request,
    String requestId,
    DateTime timestamp,
  ) async {
    final uri = request.url;
    final headers = Map<String, dynamic>.from(request.headers);
    final params = Map<String, dynamic>.from(uri.queryParameters);

    dynamic body;
    if (request is http.Request) {
      body = _extractBody(request.body, request.headers);
    } else if (request is http.MultipartRequest) {
      body = _extractMultipartBody(request);
    }

    return HttpRequestData(
      id: requestId,
      url: uri.toString(),
      method: request.method,
      headers: headers,
      params: params,
      body: body,
      timestamp: timestamp,
    );
  }

  /// Extracts body from request
  dynamic _extractBody(String body, Map<String, String> headers) {
    if (body.isEmpty) return null;

    final contentType = headers['content-type'] ?? '';

    // Try to parse as JSON
    if (contentType.contains('application/json')) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    // Try to parse as form data
    if (contentType.contains('application/x-www-form-urlencoded')) {
      try {
        return Uri.splitQueryString(body);
      } catch (_) {
        return body;
      }
    }

    // Return as string for other types
    return body;
  }

  /// Extracts multipart request body
  Map<String, dynamic> _extractMultipartBody(http.MultipartRequest request) {
    final result = <String, dynamic>{};

    // Add fields
    result.addAll(request.fields);

    // Add file information
    if (request.files.isNotEmpty) {
      result['_files'] = request.files.map((file) {
        return {
          'field': file.field,
          'filename': file.filename,
          'contentType': file.contentType.toString(),
          'length': file.length,
        };
      }).toList();
    }

    return result;
  }

  /// Decodes response body
  dynamic _decodeResponseBody(List<int> bytes, Map<String, String> headers) {
    if (bytes.isEmpty) return null;

    try {
      final body = utf8.decode(bytes);
      final contentType = headers['content-type'] ?? '';

      // Try to parse as JSON
      if (contentType.contains('application/json')) {
        try {
          return jsonDecode(body);
        } catch (_) {
          return body;
        }
      }

      // Return as string for other types
      return body;
    } catch (_) {
      // If decoding fails, return raw bytes info
      return {
        'type': 'binary',
        'length': bytes.length,
        'message': 'Binary data not decoded',
      };
    }
  }

  /// Generates a unique request ID
  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Clears the request map
  ///
  /// This is useful for cleanup or testing purposes.
  void clearRequestMap() {
    _requestMap.clear();
  }

  /// Gets the count of pending requests
  int get pendingRequestCount => _requestMap.length;

  @override
  void close() {
    _inner.close();
    _requestMap.clear();
  }
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
