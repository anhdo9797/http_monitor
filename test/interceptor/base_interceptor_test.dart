import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/interceptor/base_interceptor.dart';
import 'package:http_monitor/src/model/http_request_data.dart';
import 'package:http_monitor/src/model/http_response_data.dart';
import 'package:http_monitor/src/model/http_error_data.dart';

// Mock implementation for testing
class MockInterceptor extends BaseInterceptor {
  final List<HttpRequestData> capturedRequests = [];
  final List<HttpResponseData> capturedResponses = [];
  final List<HttpErrorData> capturedErrors = [];

  @override
  Future<void> onRequest(HttpRequestData request) async {
    capturedRequests.add(request);
  }

  @override
  Future<void> onResponse(HttpResponseData response) async {
    capturedResponses.add(response);
  }

  @override
  Future<void> onError(HttpErrorData error) async {
    capturedErrors.add(error);
  }
}

void main() {
  group('BaseInterceptor', () {
    late MockInterceptor interceptor;

    setUp(() {
      interceptor = MockInterceptor();
    });

    group('onRequest', () {
      test('should capture request data', () async {
        final request = HttpRequestData(
          id: 'test-1',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          params: {'page': '1'},
          timestamp: DateTime.now(),
        );

        await interceptor.onRequest(request);

        expect(interceptor.capturedRequests.length, 1);
        expect(interceptor.capturedRequests.first, request);
      });

      test('should handle multiple requests', () async {
        final request1 = HttpRequestData(
          id: 'test-1',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        final request2 = HttpRequestData(
          id: 'test-2',
          url: 'https://api.example.com/posts',
          method: 'POST',
          headers: {},
          params: {},
          body: {'title': 'Test'},
          timestamp: DateTime.now(),
        );

        await interceptor.onRequest(request1);
        await interceptor.onRequest(request2);

        expect(interceptor.capturedRequests.length, 2);
        expect(interceptor.capturedRequests[0].id, 'test-1');
        expect(interceptor.capturedRequests[1].id, 'test-2');
      });
    });

    group('onResponse', () {
      test('should capture response data', () async {
        final response = HttpResponseData(
          requestId: 'test-1',
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
          body: {'users': []},
          duration: 150,
          timestamp: DateTime.now(),
        );

        await interceptor.onResponse(response);

        expect(interceptor.capturedResponses.length, 1);
        expect(interceptor.capturedResponses.first, response);
      });

      test('should handle multiple responses', () async {
        final response1 = HttpResponseData(
          requestId: 'test-1',
          statusCode: 200,
          headers: {},
          body: {},
          duration: 100,
          timestamp: DateTime.now(),
        );

        final response2 = HttpResponseData(
          requestId: 'test-2',
          statusCode: 404,
          headers: {},
          body: {'error': 'Not found'},
          duration: 50,
          timestamp: DateTime.now(),
        );

        await interceptor.onResponse(response1);
        await interceptor.onResponse(response2);

        expect(interceptor.capturedResponses.length, 2);
        expect(interceptor.capturedResponses[0].statusCode, 200);
        expect(interceptor.capturedResponses[1].statusCode, 404);
      });
    });

    group('onError', () {
      test('should capture error data', () async {
        final error = HttpErrorData(
          requestId: 'test-1',
          message: 'Network error',
          type: 'SocketException',
          statusCode: 0,
          duration: 5000,
          timestamp: DateTime.now(),
        );

        await interceptor.onError(error);

        expect(interceptor.capturedErrors.length, 1);
        expect(interceptor.capturedErrors.first, error);
      });

      test('should handle multiple errors', () async {
        final error1 = HttpErrorData(
          requestId: 'test-1',
          message: 'Connection timeout',
          type: 'TimeoutException',
          duration: 30000,
          timestamp: DateTime.now(),
        );

        final error2 = HttpErrorData(
          requestId: 'test-2',
          message: 'Server error',
          type: 'HttpException',
          statusCode: 500,
          duration: 200,
          timestamp: DateTime.now(),
        );

        await interceptor.onError(error1);
        await interceptor.onError(error2);

        expect(interceptor.capturedErrors.length, 2);
        expect(interceptor.capturedErrors[0].message, 'Connection timeout');
        expect(interceptor.capturedErrors[1].message, 'Server error');
      });
    });

    group('generateRequestId', () {
      test('should generate unique IDs', () {
        final id1 = interceptor.generateRequestId();
        final id2 = interceptor.generateRequestId();

        expect(id1, isNotEmpty);
        expect(id2, isNotEmpty);
        expect(id1, isNot(equals(id2)));
      });

      test('should generate IDs with timestamp format', () {
        final id = interceptor.generateRequestId();

        expect(id, contains('_'));
        final parts = id.split('_');
        expect(parts.length, 2);
        expect(int.tryParse(parts[0]), isNotNull);
        expect(int.tryParse(parts[1]), isNotNull);
      });
    });
  });
}

