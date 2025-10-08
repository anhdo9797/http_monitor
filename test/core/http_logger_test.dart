import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/core/http_logger.dart';
import 'package:http_monitor/src/db/http_log_repository.dart';
import 'package:http_monitor/src/db/http_monitor_database.dart';
import 'package:http_monitor/src/model/http_log.dart';
import 'package:http_monitor/src/model/http_request_data.dart';
import 'package:http_monitor/src/model/http_response_data.dart';
import 'package:http_monitor/src/model/http_error_data.dart';
import 'package:http_monitor/src/model/http_monitor_config.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing on desktop
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HttpLogger', () {
    late HttpMonitorDatabase database;
    late HttpLogRepository repository;
    late HttpLogger logger;
    late HttpMonitorConfig config;

    setUp(() async {
      database = HttpMonitorDatabase(inMemory: true);
      repository = HttpLogRepositoryImpl(database);
      config = const HttpMonitorConfig.defaultConfig();
      logger = HttpLogger(repository: repository, config: config);
    });

    tearDown(() async {
      await repository.clearAllLogs();
      logger.clearPendingRequests();
      await database.close();
    });

    group('logRequest', () {
      test('should store request data', () async {
        final request = HttpRequestData(
          id: 'test-1',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          params: {'page': '1'},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request);

        // Wait a bit for async operation
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.url, request.url);
        expect(logs.first.method, request.method);
      });

      test('should sanitize sensitive headers', () async {
        final request = HttpRequestData(
          id: 'test-2',
          url: 'https://api.example.com/users',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer secret-token',
            'Cookie': 'session=abc123',
          },
          params: {},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.headers['Authorization'], '***REDACTED***');
        expect(logs.first.headers['Cookie'], '***REDACTED***');
        expect(logs.first.headers['Content-Type'], 'application/json');
      });

      test('should track pending requests', () async {
        final request = HttpRequestData(
          id: 'test-3',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        expect(logger.pendingRequestCount, 0);
        await logger.logRequest(request);
        expect(logger.pendingRequestCount, 1);
      });

      test('should not log when disabled', () async {
        // Create a new database and repository for this test
        final testDatabase = HttpMonitorDatabase(inMemory: true);
        final testRepository = HttpLogRepositoryImpl(testDatabase);
        final disabledConfig = const HttpMonitorConfig(enabled: false);
        final disabledLogger = HttpLogger(
          repository: testRepository,
          config: disabledConfig,
        );

        final request = HttpRequestData(
          id: 'test-4',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await disabledLogger.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await testRepository.getAllLogs();
        expect(logs.length, 0);

        await testDatabase.close();
      });
    });

    group('logResponse', () {
      test('should update log with response data', () async {
        final requestId = 'test-5';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final response = HttpResponseData(
          requestId: requestId,
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
          body: {'users': []},
          duration: 150,
          timestamp: DateTime.now(),
        );

        await logger.logResponse(response);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.statusCode, 200);
        expect(logs.first.duration, 150);
        expect(logs.first.response, isNotNull);
      });

      test('should remove pending request after response', () async {
        final requestId = 'test-6';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request);
        expect(logger.pendingRequestCount, 1);

        final response = HttpResponseData(
          requestId: requestId,
          statusCode: 200,
          headers: {},
          body: {},
          duration: 100,
          timestamp: DateTime.now(),
        );

        await logger.logResponse(response);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(logger.pendingRequestCount, 0);
      });

      test('should handle orphan response', () async {
        final response = HttpResponseData(
          requestId: 'non-existent',
          statusCode: 404,
          headers: {},
          body: {'error': 'Not found'},
          duration: 50,
          timestamp: DateTime.now(),
        );

        await logger.logResponse(response);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.statusCode, 404);
        expect(logs.first.url, 'Unknown');
      });
    });

    group('logError', () {
      test('should update log with error data', () async {
        final requestId = 'test-7';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final error = HttpErrorData(
          requestId: requestId,
          message: 'Network error',
          type: 'SocketException',
          statusCode: 0,
          duration: 5000,
          timestamp: DateTime.now(),
        );

        await logger.logError(error);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.statusCode, 0);
        expect(logs.first.response, isNotNull);
        expect(logs.first.response['error'], 'Network error');
      });

      test('should handle orphan error', () async {
        final error = HttpErrorData(
          requestId: 'non-existent',
          message: 'Connection timeout',
          type: 'TimeoutException',
          duration: 30000,
          timestamp: DateTime.now(),
        );

        await logger.logError(error);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.url, 'Unknown');
        expect(logs.first.response['error'], 'Connection timeout');
      });
    });

    group('body truncation', () {
      test('should truncate large response bodies', () async {
        final smallConfig = const HttpMonitorConfig(
          maxResponseBodySize: 100,
        );
        final smallLogger = HttpLogger(
          repository: repository,
          config: smallConfig,
        );

        final requestId = 'test-8';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/data',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await smallLogger.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final largeBody = 'x' * 200;
        final response = HttpResponseData(
          requestId: requestId,
          statusCode: 200,
          headers: {},
          body: largeBody,
          duration: 100,
          timestamp: DateTime.now(),
        );

        await smallLogger.logResponse(response);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await repository.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.response, isA<Map>());
        expect(logs.first.response['truncated'], true);
        expect(logs.first.response['originalSize'], 200);
      });
    });

    group('clearPendingRequests', () {
      test('should clear all pending requests', () async {
        final request1 = HttpRequestData(
          id: 'test-9',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        final request2 = HttpRequestData(
          id: 'test-10',
          url: 'https://api.example.com/posts',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await logger.logRequest(request1);
        await logger.logRequest(request2);
        expect(logger.pendingRequestCount, 2);

        logger.clearPendingRequests();
        expect(logger.pendingRequestCount, 0);
      });
    });
  });
}

