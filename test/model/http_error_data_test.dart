import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_error_data.dart';

void main() {
  group('HttpErrorData', () {
    test('should create instance with required fields', () {
      final timestamp = DateTime.now();
      final error = HttpErrorData(
        requestId: 'test-1',
        message: 'Network error',
        duration: 5000,
        timestamp: timestamp,
      );

      expect(error.requestId, 'test-1');
      expect(error.message, 'Network error');
      expect(error.duration, 5000);
      expect(error.timestamp, timestamp);
      expect(error.type, isNull);
      expect(error.statusCode, isNull);
      expect(error.headers, isNull);
      expect(error.body, isNull);
      expect(error.stackTrace, isNull);
    });

    test('should create instance with all fields', () {
      final timestamp = DateTime.now();
      final headers = {'Content-Type': 'application/json'};
      final body = {'error': 'Server error'};

      final error = HttpErrorData(
        requestId: 'test-2',
        message: 'Server error',
        type: 'HttpException',
        statusCode: 500,
        headers: headers,
        body: body,
        duration: 200,
        timestamp: timestamp,
        stackTrace: 'Stack trace here',
      );

      expect(error.requestId, 'test-2');
      expect(error.message, 'Server error');
      expect(error.type, 'HttpException');
      expect(error.statusCode, 500);
      expect(error.headers, headers);
      expect(error.body, body);
      expect(error.duration, 200);
      expect(error.timestamp, timestamp);
      expect(error.stackTrace, 'Stack trace here');
    });

    test('should create copy with modified fields', () {
      final timestamp = DateTime.now();
      final error = HttpErrorData(
        requestId: 'test-3',
        message: 'Network error',
        duration: 5000,
        timestamp: timestamp,
      );

      final copy = error.copyWith(
        type: 'SocketException',
        statusCode: 0,
      );

      expect(copy.requestId, 'test-3');
      expect(copy.message, 'Network error');
      expect(copy.type, 'SocketException');
      expect(copy.statusCode, 0);
      expect(copy.duration, 5000);
    });

    test('should have correct toString representation', () {
      final error = HttpErrorData(
        requestId: 'test-4',
        message: 'Connection timeout',
        statusCode: 0,
        duration: 30000,
        timestamp: DateTime.now(),
      );

      final str = error.toString();
      expect(str, contains('test-4'));
      expect(str, contains('Connection timeout'));
      expect(str, contains('0'));
    });

    test('should implement equality correctly', () {
      final timestamp = DateTime.now();
      final error1 = HttpErrorData(
        requestId: 'test-5',
        message: 'Network error',
        statusCode: 0,
        duration: 5000,
        timestamp: timestamp,
      );

      final error2 = HttpErrorData(
        requestId: 'test-5',
        message: 'Network error',
        statusCode: 0,
        duration: 5000,
        timestamp: timestamp,
      );

      final error3 = HttpErrorData(
        requestId: 'test-6',
        message: 'Network error',
        statusCode: 0,
        duration: 5000,
        timestamp: timestamp,
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });

    test('should have consistent hashCode', () {
      final timestamp = DateTime.now();
      final error1 = HttpErrorData(
        requestId: 'test-7',
        message: 'Network error',
        statusCode: 0,
        duration: 5000,
        timestamp: timestamp,
      );

      final error2 = HttpErrorData(
        requestId: 'test-7',
        message: 'Network error',
        statusCode: 0,
        duration: 5000,
        timestamp: timestamp,
      );

      expect(error1.hashCode, equals(error2.hashCode));
    });

    test('should handle different error types', () {
      final socketError = HttpErrorData(
        requestId: 'test-8',
        message: 'Connection refused',
        type: 'SocketException',
        duration: 1000,
        timestamp: DateTime.now(),
      );

      final timeoutError = HttpErrorData(
        requestId: 'test-9',
        message: 'Request timeout',
        type: 'TimeoutException',
        duration: 30000,
        timestamp: DateTime.now(),
      );

      final httpError = HttpErrorData(
        requestId: 'test-10',
        message: 'Internal server error',
        type: 'HttpException',
        statusCode: 500,
        duration: 200,
        timestamp: DateTime.now(),
      );

      expect(socketError.type, 'SocketException');
      expect(timeoutError.type, 'TimeoutException');
      expect(httpError.type, 'HttpException');
      expect(httpError.statusCode, 500);
    });
  });
}

