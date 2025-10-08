/// Base interceptor architecture
library;

import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';

/// Abstract base class for HTTP interceptors
///
/// This class provides a standard interface for intercepting HTTP requests,
/// responses, and errors. Concrete implementations should extend this class
/// and implement the abstract methods to integrate with specific HTTP clients.
abstract class BaseInterceptor {
  /// Called when an HTTP request is about to be sent
  ///
  /// Implementations should extract request data and pass it to the logger.
  /// This method should not block the request flow.
  ///
  /// [request] The HTTP request data
  Future<void> onRequest(HttpRequestData request);

  /// Called when an HTTP response is received
  ///
  /// Implementations should extract response data and pass it to the logger.
  /// This method should not block the response flow.
  ///
  /// [response] The HTTP response data
  Future<void> onResponse(HttpResponseData response);

  /// Called when an HTTP error occurs
  ///
  /// Implementations should extract error data and pass it to the logger.
  /// This method should not block the error handling flow.
  ///
  /// [error] The HTTP error data
  Future<void> onError(HttpErrorData error);

  /// Generates a unique ID for tracking requests
  ///
  /// This ID is used to link requests with their corresponding responses.
  String generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
