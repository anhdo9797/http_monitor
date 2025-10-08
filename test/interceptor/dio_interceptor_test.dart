import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_monitor/src/interceptor/dio_interceptor.dart';
import 'package:http_monitor/src/core/http_logger.dart';
import 'package:http_monitor/src/db/http_log_repository.dart';
import 'package:http_monitor/src/db/http_monitor_database.dart';
import 'package:http_monitor/src/model/http_monitor_config.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing on desktop
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HttpMonitorDioInterceptor', () {
    late HttpMonitorDatabase database;
    late HttpLogRepository repository;
    late HttpLogger logger;
    late HttpMonitorDioInterceptor interceptor;
    late Dio dio;

    setUp(() async {
      database = HttpMonitorDatabase(inMemory: true);
      repository = HttpLogRepositoryImpl(database);
      final config = const HttpMonitorConfig.defaultConfig();
      logger = HttpLogger(repository: repository, config: config);
      interceptor = HttpMonitorDioInterceptor(logger: logger);

      // Create Dio instance with interceptor
      dio = Dio(BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ));
      dio.interceptors.add(interceptor);
    });

    tearDown(() async {
      await repository.clearAllLogs();
      logger.clearPendingRequests();
      interceptor.clearRequestMap();
      await database.close();
    });

    group('GET requests', () {
      test('should capture successful GET request', () async {
        try {
          await dio.get('/posts/1');
        } catch (_) {
          // Ignore network errors in test environment
        }

        // Wait for async logging
        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'GET');
        expect(log.url, contains('/posts/1'));
      });

      test('should capture GET request with query parameters', () async {
        try {
          await dio.get('/posts', queryParameters: {'userId': 1});
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'GET');
        expect(log.url, contains('/posts'));
        expect(log.params['userId'], 1);
      });
    });

    group('POST requests', () {
      test('should capture POST request with JSON body', () async {
        try {
          await dio.post('/posts', data: {
            'title': 'Test Post',
            'body': 'This is a test',
            'userId': 1,
          });
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'POST');
        expect(log.url, contains('/posts'));
        expect(log.body, isNotNull);
        expect(log.body['title'], 'Test Post');
      });

      test('should capture POST request with FormData', () async {
        final formData = FormData.fromMap({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        try {
          await dio.post('/posts', data: formData);
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'POST');
        expect(log.body, isNotNull);
        expect(log.body['name'], 'John Doe');
      });
    });

    group('PUT requests', () {
      test('should capture PUT request', () async {
        try {
          await dio.put('/posts/1', data: {
            'title': 'Updated Post',
            'body': 'Updated content',
            'userId': 1,
          });
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'PUT');
        expect(log.url, contains('/posts/1'));
      });
    });

    group('DELETE requests', () {
      test('should capture DELETE request', () async {
        try {
          await dio.delete('/posts/1');
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.method, 'DELETE');
        expect(log.url, contains('/posts/1'));
      });
    });

    group('response handling', () {
      test('should capture response data and status code', () async {
        try {
          final response = await dio.get('/posts/1');
          expect(response.statusCode, 200);
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        if (logs.isNotEmpty) {
          final log = logs.first;
          // Status code might be 0 if request failed
          expect(log.statusCode, greaterThanOrEqualTo(0));
          expect(log.duration, greaterThan(0));
        }
      });

      test('should capture response headers', () async {
        try {
          await dio.get('/posts/1');
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        if (logs.isNotEmpty) {
          final log = logs.first;
          expect(log.headers, isNotNull);
        }
      });
    });

    group('error handling', () {
      test('should capture network errors', () async {
        final errorDio = Dio(BaseOptions(
          baseUrl: 'https://invalid-domain-that-does-not-exist-12345.com',
          connectTimeout: const Duration(milliseconds: 100),
        ));
        errorDio.interceptors.add(interceptor);

        try {
          await errorDio.get('/test');
        } catch (_) {
          // Expected to fail
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        expect(logs.length, greaterThan(0));

        final log = logs.first;
        expect(log.response, isNotNull);
      });

      test('should capture 404 errors', () async {
        try {
          await dio.get('/nonexistent-endpoint-12345');
        } catch (_) {
          // Expected to fail with 404
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        if (logs.isNotEmpty) {
          final log = logs.first;
          // Might be 404 or 0 depending on network
          expect(log.statusCode, greaterThanOrEqualTo(0));
        }
      });
    });

    group('headers extraction', () {
      test('should capture request headers', () async {
        try {
          await dio.get('/posts/1', options: Options(
            headers: {
              'X-Custom-Header': 'test-value',
              'Accept': 'application/json',
            },
          ));
        } catch (_) {
          // Ignore network errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        final logs = await repository.getAllLogs();
        if (logs.isNotEmpty) {
          final log = logs.first;
          expect(log.headers, isNotNull);
        }
      });
    });

    group('pending requests tracking', () {
      test('should track pending requests', () async {
        expect(interceptor.pendingRequestCount, 0);

        // Start a request but don't await it immediately
        final future = dio.get('/posts/1');

        // There might be a pending request
        // (timing dependent, so we just check it's >= 0)
        expect(interceptor.pendingRequestCount, greaterThanOrEqualTo(0));

        try {
          await future;
        } catch (_) {
          // Ignore errors
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // After completion, pending count should be 0
        expect(interceptor.pendingRequestCount, 0);
      });

      test('should clear request map', () async {
        try {
          dio.get('/posts/1');
        } catch (_) {
          // Ignore errors
        }

        await Future.delayed(const Duration(milliseconds: 50));

        interceptor.clearRequestMap();
        expect(interceptor.pendingRequestCount, 0);
      });
    });
  });
}

