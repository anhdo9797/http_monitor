import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/utils/curl_converter.dart';
import 'package:http_monitor/src/model/http_log.dart';

void main() {
  group('CurlConverter', () {
    group('toCurl', () {
      test('should convert simple GET request', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 100,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, contains('curl'));
        expect(curl, contains('https://api.example.com/users'));
        expect(curl, isNot(contains('-X GET')));
      });

      test('should convert POST request with method flag', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'POST',
          headers: {},
          params: {},
          statusCode: 201,
          duration: 150,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, contains('-X POST'));
        expect(curl, contains('https://api.example.com/users'));
      });

      test('should include headers', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer token123',
            'Content-Type': 'application/json',
          },
          params: {},
          statusCode: 200,
          duration: 100,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, contains('-H'));
        expect(curl, contains('Authorization'));
      });

      test('should include JSON body for POST request', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'POST',
          headers: {},
          params: {},
          body: {
            'name': 'John Doe',
            'email': 'john@example.com',
          },
          statusCode: 201,
          duration: 150,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, contains('-d'));
        expect(curl, contains('name'));
      });

      test('should not include body for GET request', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          body: {'should': 'not appear'},
          statusCode: 200,
          duration: 100,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, isNot(contains('-d')));
      });

      test('should include compressed flag when requested', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 100,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log, compressed: true);

        expect(curl, contains('--compressed'));
      });
    });

    group('toCurlPretty', () {
      test('should format with line breaks', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          params: {},
          body: {'name': 'John'},
          statusCode: 201,
          duration: 150,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurlPretty(log);

        expect(curl, contains('\\\n'));
        expect(curl, contains('-X POST'));
      });
    });

    group('edge cases', () {
      test('should handle empty headers', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 100,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, isNotEmpty);
        expect(curl, contains('curl'));
      });

      test('should handle null body', () {
        final log = HttpLog(
          url: 'https://api.example.com/users',
          method: 'POST',
          headers: {},
          params: {},
          body: null,
          statusCode: 201,
          duration: 150,
          createdAt: DateTime.now(),
        );

        final curl = CurlConverter.toCurl(log);

        expect(curl, isNot(contains('-d')));
      });
    });
  });
}
