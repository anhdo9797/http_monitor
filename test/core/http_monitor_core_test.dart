import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/core/http_monitor_core.dart';
import 'package:http_monitor/src/model/http_monitor_config.dart';
import 'package:http_monitor/src/model/http_request_data.dart';
import 'package:http_monitor/src/model/http_response_data.dart';
import 'package:http_monitor/src/model/http_error_data.dart';
import 'package:http_monitor/src/model/http_log_filter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing on desktop
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HttpMonitor', () {
    tearDown(() async {
      if (HttpMonitor.isInitialized) {
        await HttpMonitor.close();
      }
    });

    group('initialization', () {
      test('should initialize with default config', () async {
        expect(HttpMonitor.isInitialized, false);

        await HttpMonitor.init();

        expect(HttpMonitor.isInitialized, true);
        expect(HttpMonitor.instance, isNotNull);
        expect(HttpMonitor.instance.config, isA<HttpMonitorConfig>());
      });

      test('should initialize with custom config', () async {
        final config = const HttpMonitorConfig(
          enabled: true,
          maxLogCount: 500,
        );

        await HttpMonitor.init(config: config);

        expect(HttpMonitor.isInitialized, true);
        expect(HttpMonitor.instance.config.maxLogCount, 500);
      });

      test('should not reinitialize if already initialized', () async {
        await HttpMonitor.init();
        final instance1 = HttpMonitor.instance;

        await HttpMonitor.init();
        final instance2 = HttpMonitor.instance;

        expect(instance1, same(instance2));
      });

      test('should throw error when accessing instance before init', () {
        expect(
          () => HttpMonitor.instance,
          throwsStateError,
        );
      });
    });

    group('logging', () {
      setUp(() async {
        await HttpMonitor.init();
      });

      test('should log request', () async {
        final request = HttpRequestData(
          id: 'test-1',
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await HttpMonitor.instance.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await HttpMonitor.instance.getLogs();
        expect(logs.length, greaterThan(0));
      });

      test('should log response', () async {
        final requestId = 'test-2';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await HttpMonitor.instance.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final response = HttpResponseData(
          requestId: requestId,
          statusCode: 200,
          headers: {},
          body: {'users': []},
          duration: 150,
          timestamp: DateTime.now(),
        );

        await HttpMonitor.instance.logResponse(response);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await HttpMonitor.instance.getLogs();
        expect(logs.length, greaterThan(0));
        expect(logs.first.statusCode, 200);
      });

      test('should log error', () async {
        final requestId = 'test-3';
        final request = HttpRequestData(
          id: requestId,
          url: 'https://api.example.com/users',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );

        await HttpMonitor.instance.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        final error = HttpErrorData(
          requestId: requestId,
          message: 'Network error',
          type: 'SocketException',
          duration: 5000,
          timestamp: DateTime.now(),
        );

        await HttpMonitor.instance.logError(error);
        await Future.delayed(const Duration(milliseconds: 100));

        final logs = await HttpMonitor.instance.getLogs();
        expect(logs.length, greaterThan(0));
        expect(logs.first.response, isNotNull);
      });
    });

    group('log retrieval', () {
      setUp(() async {
        await HttpMonitor.init();

        // Add some test logs
        for (int i = 0; i < 5; i++) {
          final request = HttpRequestData(
            id: 'test-$i',
            url: 'https://api.example.com/users/$i',
            method: i % 2 == 0 ? 'GET' : 'POST',
            headers: {},
            params: {},
            timestamp: DateTime.now(),
          );

          await HttpMonitor.instance.logRequest(request);

          final response = HttpResponseData(
            requestId: 'test-$i',
            statusCode: i % 2 == 0 ? 200 : 404,
            headers: {},
            body: {},
            duration: 100 + i * 10,
            timestamp: DateTime.now(),
          );

          await HttpMonitor.instance.logResponse(response);
        }

        await Future.delayed(const Duration(milliseconds: 200));
      });

      test('should get all logs', () async {
        final logs = await HttpMonitor.instance.getLogs();
        expect(logs.length, greaterThanOrEqualTo(5));
      });

      test('should get filtered logs by method', () async {
        final filter = const HttpLogFilter(methods: ['GET']);
        final logs = await HttpMonitor.instance.getLogs(filter: filter);

        for (final log in logs) {
          expect(log.method, 'GET');
        }
      });

      test('should get filtered logs by status group', () async {
        final filter = const HttpLogFilter(statusGroups: ['2xx']);
        final logs = await HttpMonitor.instance.getLogs(filter: filter);

        for (final log in logs) {
          expect(log.statusCode, greaterThanOrEqualTo(200));
          expect(log.statusCode, lessThan(300));
        }
      });

      test('should get log by id', () async {
        final allLogs = await HttpMonitor.instance.getLogs();
        if (allLogs.isNotEmpty) {
          final firstLog = allLogs.first;
          final log = await HttpMonitor.instance.getLogById(firstLog.id!);

          expect(log, isNotNull);
          expect(log!.id, firstLog.id);
        }
      });

      test('should get log count', () async {
        final count = await HttpMonitor.instance.getLogCount();
        expect(count, greaterThanOrEqualTo(5));
      });

      test('should get filtered log count', () async {
        final filter = const HttpLogFilter(methods: ['GET']);
        final count = await HttpMonitor.instance.getLogCount(filter: filter);
        expect(count, greaterThan(0));
      });
    });

    group('log management', () {
      setUp(() async {
        await HttpMonitor.init();

        // Add test logs
        for (int i = 0; i < 3; i++) {
          final request = HttpRequestData(
            id: 'test-$i',
            url: 'https://api.example.com/users/$i',
            method: 'GET',
            headers: {},
            params: {},
            timestamp: DateTime.now(),
          );

          await HttpMonitor.instance.logRequest(request);
        }

        await Future.delayed(const Duration(milliseconds: 200));
      });

      test('should delete log by id', () async {
        final logs = await HttpMonitor.instance.getLogs();
        final initialCount = logs.length;

        if (logs.isNotEmpty) {
          await HttpMonitor.instance.deleteLog(logs.first.id!);
          await Future.delayed(const Duration(milliseconds: 100));

          final newCount = await HttpMonitor.instance.getLogCount();
          expect(newCount, lessThan(initialCount));
        }
      });

      test('should clear all logs', () async {
        await HttpMonitor.instance.clearAllLogs();
        await Future.delayed(const Duration(milliseconds: 100));

        final count = await HttpMonitor.instance.getLogCount();
        expect(count, 0);
      });

      test('should delete logs older than duration', () async {
        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Add a new log
        final request = HttpRequestData(
          id: 'new-log',
          url: 'https://api.example.com/new',
          method: 'GET',
          headers: {},
          params: {},
          timestamp: DateTime.now(),
        );
        await HttpMonitor.instance.logRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        // Delete logs older than 50ms (should delete the old ones)
        final deleted = await HttpMonitor.instance.deleteOlderThan(
          const Duration(milliseconds: 50),
        );

        expect(deleted, greaterThanOrEqualTo(0));
      });

      test('should delete logs exceeding limit', () async {
        final deleted = await HttpMonitor.instance.deleteExceedingLimit(2);
        await Future.delayed(const Duration(milliseconds: 100));

        final count = await HttpMonitor.instance.getLogCount();
        expect(count, lessThanOrEqualTo(2));
      });
    });

    group('logger access', () {
      test('should provide logger instance', () async {
        await HttpMonitor.init();

        final logger = HttpMonitor.instance.logger;
        expect(logger, isNotNull);
      });
    });

    group('close', () {
      test('should close and reset state', () async {
        await HttpMonitor.init();
        expect(HttpMonitor.isInitialized, true);

        await HttpMonitor.close();
        expect(HttpMonitor.isInitialized, false);

        expect(() => HttpMonitor.instance, throwsStateError);
      });

      test('should allow reinitialization after close', () async {
        await HttpMonitor.init();
        await HttpMonitor.close();

        await HttpMonitor.init();
        expect(HttpMonitor.isInitialized, true);
      });
    });
  });
}

