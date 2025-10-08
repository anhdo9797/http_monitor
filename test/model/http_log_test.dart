import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_log.dart';

void main() {
  group('HttpLog', () {
    test('creates instance with required fields', () {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {'content-type': 'application/json'},
        params: {'page': '1'},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(log.url, 'https://api.example.com/users');
      expect(log.method, 'GET');
      expect(log.statusCode, 200);
      expect(log.duration, 150);
    });

    test('toJson and fromJson work correctly', () {
      final originalLog = HttpLog(
        id: 1,
        url: 'https://api.example.com/users',
        method: 'POST',
        headers: {'content-type': 'application/json'},
        params: {'page': '1'},
        body: {'name': 'John'},
        response: {'id': 123, 'name': 'John'},
        statusCode: 201,
        duration: 200,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = originalLog.toJson();
      final decodedLog = HttpLog.fromJson(json);

      expect(decodedLog.id, originalLog.id);
      expect(decodedLog.url, originalLog.url);
      expect(decodedLog.method, originalLog.method);
      expect(decodedLog.statusCode, originalLog.statusCode);
      expect(decodedLog.duration, originalLog.duration);
    });

    test('isSuccessful returns true for 2xx status codes', () {
      final log200 = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime.now(),
      );

      final log201 = log200.copyWith(statusCode: 201);
      final log299 = log200.copyWith(statusCode: 299);

      expect(log200.isSuccessful, isTrue);
      expect(log201.isSuccessful, isTrue);
      expect(log299.isSuccessful, isTrue);
    });

    test('isSuccessful returns false for non-2xx status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isSuccessful, isFalse);
      expect(log.copyWith(statusCode: 500).isSuccessful, isFalse);
      expect(log.copyWith(statusCode: 301).isSuccessful, isFalse);
    });

    test('isError returns true for 4xx and 5xx status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isError, isTrue);
      expect(log.copyWith(statusCode: 500).isError, isTrue);
      expect(log.copyWith(statusCode: 403).isError, isTrue);
    });

    test('isError returns false for non-error status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isError, isFalse);
      expect(log.copyWith(statusCode: 301).isError, isFalse);
    });

    test('statusGroup returns correct group', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.statusGroup, '2xx');
      expect(log.copyWith(statusCode: 301).statusGroup, '3xx');
      expect(log.copyWith(statusCode: 404).statusGroup, '4xx');
      expect(log.copyWith(statusCode: 500).statusGroup, '5xx');
    });

    test('isClientError returns true for 4xx status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isClientError, isTrue);
      expect(log.copyWith(statusCode: 403).isClientError, isTrue);
      expect(log.copyWith(statusCode: 500).isClientError, isFalse);
    });

    test('isServerError returns true for 5xx status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 500,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isServerError, isTrue);
      expect(log.copyWith(statusCode: 503).isServerError, isTrue);
      expect(log.copyWith(statusCode: 404).isServerError, isFalse);
    });

    test('isRedirect returns true for 3xx status codes', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 301,
        duration: 100,
        createdAt: DateTime.now(),
      );

      expect(log.isRedirect, isTrue);
      expect(log.copyWith(statusCode: 302).isRedirect, isTrue);
      expect(log.copyWith(statusCode: 200).isRedirect, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = HttpLog(
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        statusCode: 404,
        duration: 200,
      );

      expect(updated.statusCode, 404);
      expect(updated.duration, 200);
      expect(updated.url, original.url);
      expect(updated.method, original.method);
    });

    test('equality works correctly', () {
      final log1 = HttpLog(
        id: 1,
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      final log2 = HttpLog(
        id: 1,
        url: 'https://api.example.com',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      final log3 = log1.copyWith(statusCode: 404);

      expect(log1, equals(log2));
      expect(log1, isNot(equals(log3)));
    });

    test('handles JSON string fields correctly', () {
      final log = HttpLog(
        url: 'https://api.example.com',
        method: 'POST',
        headers: {'content-type': 'application/json'},
        params: {},
        body: {'name': 'John'},
        response: {'id': 123},
        statusCode: 201,
        duration: 150,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = log.toJson();
      final decoded = HttpLog.fromJson(json);

      expect(decoded.body, isA<Map>());
      expect(decoded.response, isA<Map>());
    });

    test('toDbMap works correctly', () {
      final log = HttpLog(
        id: 1,
        url: 'https://api.example.com',
        method: 'GET',
        headers: {'content-type': 'application/json'},
        params: {'page': '1'},
        statusCode: 200,
        duration: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      final dbMap = log.toDbMap();

      expect(dbMap['id'], 1);
      expect(dbMap['url'], 'https://api.example.com');
      expect(dbMap['method'], 'GET');
      expect(dbMap['status_code'], 200);
      expect(dbMap['duration'], 100);
      expect(dbMap['created_at'], isA<String>());
    });

    test('fromDbMap works correctly', () {
      final dbMap = {
        'id': 1,
        'url': 'https://api.example.com',
        'method': 'GET',
        'headers': '{"content-type":"application/json"}',
        'params': '{"page":"1"}',
        'body': null,
        'response': null,
        'status_code': 200,
        'duration': 100,
        'created_at': '2024-01-01T00:00:00.000',
      };

      final log = HttpLog.fromDbMap(dbMap);

      expect(log.id, 1);
      expect(log.url, 'https://api.example.com');
      expect(log.method, 'GET');
      expect(log.statusCode, 200);
      expect(log.duration, 100);
    });
  });
}

