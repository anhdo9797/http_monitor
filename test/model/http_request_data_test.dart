import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_request_data.dart';

void main() {
  group('HttpRequestData', () {
    test('should create instance with required fields', () {
      final timestamp = DateTime.now();
      final request = HttpRequestData(
        id: 'test-1',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      expect(request.id, 'test-1');
      expect(request.url, 'https://api.example.com/users');
      expect(request.method, 'GET');
      expect(request.timestamp, timestamp);
      expect(request.headers, isEmpty);
      expect(request.params, isEmpty);
      expect(request.body, isNull);
    });

    test('should create instance with all fields', () {
      final timestamp = DateTime.now();
      final headers = {'Content-Type': 'application/json'};
      final params = {'page': '1', 'limit': '10'};
      final body = {'name': 'John'};

      final request = HttpRequestData(
        id: 'test-2',
        url: 'https://api.example.com/users',
        method: 'POST',
        headers: headers,
        params: params,
        body: body,
        timestamp: timestamp,
      );

      expect(request.id, 'test-2');
      expect(request.url, 'https://api.example.com/users');
      expect(request.method, 'POST');
      expect(request.headers, headers);
      expect(request.params, params);
      expect(request.body, body);
      expect(request.timestamp, timestamp);
    });

    test('should create copy with modified fields', () {
      final timestamp = DateTime.now();
      final request = HttpRequestData(
        id: 'test-3',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      final newTimestamp = DateTime.now().add(const Duration(seconds: 1));
      final copy = request.copyWith(
        method: 'POST',
        timestamp: newTimestamp,
      );

      expect(copy.id, 'test-3');
      expect(copy.url, 'https://api.example.com/users');
      expect(copy.method, 'POST');
      expect(copy.timestamp, newTimestamp);
    });

    test('should have correct toString representation', () {
      final request = HttpRequestData(
        id: 'test-4',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: DateTime.now(),
      );

      final str = request.toString();
      expect(str, contains('test-4'));
      expect(str, contains('GET'));
      expect(str, contains('https://api.example.com/users'));
    });

    test('should implement equality correctly', () {
      final timestamp = DateTime.now();
      final request1 = HttpRequestData(
        id: 'test-5',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      final request2 = HttpRequestData(
        id: 'test-5',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      final request3 = HttpRequestData(
        id: 'test-6',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });

    test('should have consistent hashCode', () {
      final timestamp = DateTime.now();
      final request1 = HttpRequestData(
        id: 'test-7',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      final request2 = HttpRequestData(
        id: 'test-7',
        url: 'https://api.example.com/users',
        method: 'GET',
        timestamp: timestamp,
      );

      expect(request1.hashCode, equals(request2.hashCode));
    });
  });
}

