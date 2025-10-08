import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_response_data.dart';

void main() {
  group('HttpResponseData', () {
    test('should create instance with required fields', () {
      final timestamp = DateTime.now();
      final response = HttpResponseData(
        requestId: 'test-1',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      expect(response.requestId, 'test-1');
      expect(response.statusCode, 200);
      expect(response.duration, 150);
      expect(response.timestamp, timestamp);
      expect(response.headers, isEmpty);
      expect(response.body, isNull);
      expect(response.errorMessage, isNull);
    });

    test('should create instance with all fields', () {
      final timestamp = DateTime.now();
      final headers = {'Content-Type': 'application/json'};
      final body = {'users': []};

      final response = HttpResponseData(
        requestId: 'test-2',
        statusCode: 404,
        headers: headers,
        body: body,
        duration: 100,
        timestamp: timestamp,
        errorMessage: 'Not found',
      );

      expect(response.requestId, 'test-2');
      expect(response.statusCode, 404);
      expect(response.headers, headers);
      expect(response.body, body);
      expect(response.duration, 100);
      expect(response.timestamp, timestamp);
      expect(response.errorMessage, 'Not found');
    });

    test('should create copy with modified fields', () {
      final timestamp = DateTime.now();
      final response = HttpResponseData(
        requestId: 'test-3',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      final copy = response.copyWith(
        statusCode: 404,
        errorMessage: 'Not found',
      );

      expect(copy.requestId, 'test-3');
      expect(copy.statusCode, 404);
      expect(copy.duration, 150);
      expect(copy.errorMessage, 'Not found');
    });

    test('isSuccessful should return true for 2xx status codes', () {
      final response200 = HttpResponseData(
        requestId: 'test-4',
        statusCode: 200,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response201 = HttpResponseData(
        requestId: 'test-5',
        statusCode: 201,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response299 = HttpResponseData(
        requestId: 'test-6',
        statusCode: 299,
        duration: 100,
        timestamp: DateTime.now(),
      );

      expect(response200.isSuccessful, true);
      expect(response201.isSuccessful, true);
      expect(response299.isSuccessful, true);
    });

    test('isSuccessful should return false for non-2xx status codes', () {
      final response404 = HttpResponseData(
        requestId: 'test-7',
        statusCode: 404,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response500 = HttpResponseData(
        requestId: 'test-8',
        statusCode: 500,
        duration: 100,
        timestamp: DateTime.now(),
      );

      expect(response404.isSuccessful, false);
      expect(response500.isSuccessful, false);
    });

    test('isError should return true for 4xx and 5xx status codes', () {
      final response400 = HttpResponseData(
        requestId: 'test-9',
        statusCode: 400,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response404 = HttpResponseData(
        requestId: 'test-10',
        statusCode: 404,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response500 = HttpResponseData(
        requestId: 'test-11',
        statusCode: 500,
        duration: 100,
        timestamp: DateTime.now(),
      );

      expect(response400.isError, true);
      expect(response404.isError, true);
      expect(response500.isError, true);
    });

    test('isError should return false for non-error status codes', () {
      final response200 = HttpResponseData(
        requestId: 'test-12',
        statusCode: 200,
        duration: 100,
        timestamp: DateTime.now(),
      );

      final response301 = HttpResponseData(
        requestId: 'test-13',
        statusCode: 301,
        duration: 100,
        timestamp: DateTime.now(),
      );

      expect(response200.isError, false);
      expect(response301.isError, false);
    });

    test('should have correct toString representation', () {
      final response = HttpResponseData(
        requestId: 'test-14',
        statusCode: 200,
        duration: 150,
        timestamp: DateTime.now(),
      );

      final str = response.toString();
      expect(str, contains('test-14'));
      expect(str, contains('200'));
      expect(str, contains('150ms'));
    });

    test('should implement equality correctly', () {
      final timestamp = DateTime.now();
      final response1 = HttpResponseData(
        requestId: 'test-15',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      final response2 = HttpResponseData(
        requestId: 'test-15',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      final response3 = HttpResponseData(
        requestId: 'test-16',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });

    test('should have consistent hashCode', () {
      final timestamp = DateTime.now();
      final response1 = HttpResponseData(
        requestId: 'test-17',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      final response2 = HttpResponseData(
        requestId: 'test-17',
        statusCode: 200,
        duration: 150,
        timestamp: timestamp,
      );

      expect(response1.hashCode, equals(response2.hashCode));
    });
  });
}

