import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/core/database_queue.dart';
import 'package:http_monitor/src/core/http_logger.dart';
import 'package:http_monitor/src/db/http_log_repository.dart';
import 'package:http_monitor/src/model/http_monitor_config.dart';
import 'package:http_monitor/src/model/http_log.dart';
import 'package:http_monitor/src/model/http_log_filter.dart';
import 'package:http_monitor/src/model/http_request_data.dart';
import 'package:http_monitor/src/model/http_response_data.dart';
import 'package:http_monitor/src/model/http_error_data.dart';

void main() {
  group('HttpLogger Concurrent Tests', () {
    late HttpLogger logger;
    late MockHttpLogRepository mockRepository;
    late DatabaseQueue dbQueue;

    setUp(() {
      mockRepository = MockHttpLogRepository();
      dbQueue = DatabaseQueue();
      logger = HttpLogger(
        repository: mockRepository,
        config: const HttpMonitorConfig.defaultConfig(),
        dbQueue: dbQueue,
      );
    });

    tearDown(() async {
      await logger.clearPendingRequests();
      logger.clearQueue();
    });

    test('should handle concurrent requests without conflicts', () async {
      final futures = <Future>[];
      const requestCount = 100;

      // Create multiple concurrent requests
      for (int i = 0; i < requestCount; i++) {
        final request = HttpRequestData(
          id: 'test_request_$i',
          url: 'https://api.example.com/test/$i',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          params: {'page': i.toString()},
          body: null,
          timestamp: DateTime.now(),
        );

        futures.add(logger.logRequest(request));
      }

      // Wait for all requests to be logged
      await Future.wait(futures);

      // Wait a bit for database operations to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify all requests were logged
      expect(mockRepository.insertCallCount, equals(requestCount));
    });

    test('should handle concurrent request-response pairs correctly', () async {
      final futures = <Future>[];
      final pairCount = 50;

      for (int i = 0; i < pairCount; i++) {
        final request = HttpRequestData(
          id: 'test_request_$i',
          url: 'https://api.example.com/test/$i',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          params: {},
          body: {'data': 'test_$i'},
          timestamp: DateTime.now(),
        );

        final response = HttpResponseData(
          requestId: 'test_request_$i',
          statusCode: 200,
          headers: {'content-type': 'application/json'},
          body: {'result': 'success_$i'},
          duration: 150,
          timestamp: DateTime.now().add(const Duration(milliseconds: 150)),
        );

        // Log request first, then response after a small delay
        futures.add(logger.logRequest(request));
        futures.add(Future.delayed(const Duration(milliseconds: 10),
            () => logger.logResponse(response)));
      }

      await Future.wait(futures);

      // Wait a bit for database operations to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify all operations completed
      expect(mockRepository.insertCallCount, equals(pairCount));
      expect(mockRepository.updateCallCount, equals(pairCount));
    });

    test('should maintain request-response correlation under load', () async {
      final futures = <Future>[];
      final correlationCount = 30;

      for (int i = 0; i < correlationCount; i++) {
        final request = HttpRequestData(
          id: 'correlation_test_$i',
          url: 'https://api.example.com/correlation/$i',
          method: 'PUT',
          headers: {'Authorization': 'Bearer token_$i'},
          params: {},
          body: {'update': 'data_$i'},
          timestamp: DateTime.now(),
        );

        futures.add(logger.logRequest(request));

        // Add response after a small delay to simulate real-world scenario
        Future.delayed(Duration(milliseconds: 10 + (i % 5) * 10), () async {
          final response = HttpResponseData(
            requestId: 'correlation_test_$i',
            statusCode: 204,
            headers: {},
            body: null,
            duration: 75,
            timestamp: DateTime.now(),
          );

          await logger.logResponse(response);
        });
      }

      await Future.wait(futures);

      // Wait a bit more for delayed responses
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify all requests and responses were processed
      expect(mockRepository.insertCallCount, equals(correlationCount));
      expect(mockRepository.updateCallCount, equals(correlationCount));
    });

    test('should handle concurrent error logging', () async {
      final futures = <Future>[];
      final errorCount = 25;

      for (int i = 0; i < errorCount; i++) {
        final request = HttpRequestData(
          id: 'error_test_$i',
          url: 'https://api.example.com/error/$i',
          method: 'DELETE',
          headers: {'Authorization': 'Bearer token_$i'},
          params: {},
          body: null,
          timestamp: DateTime.now(),
        );

        final error = HttpErrorData(
          requestId: 'error_test_$i',
          message: 'Connection timeout for request $i',
          type: 'TimeoutException',
          statusCode: 408,
          headers: {'connection': 'timeout'},
          duration: 5000,
          timestamp: DateTime.now(),
          stackTrace: StackTrace.current.toString(),
        );

        // Log request first, then error after a small delay
        futures.add(logger.logRequest(request));
        futures.add(Future.delayed(
            const Duration(milliseconds: 10), () => logger.logError(error)));
      }

      await Future.wait(futures);

      // Wait a bit for database operations to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify all operations completed
      expect(mockRepository.insertCallCount, equals(errorCount));
      expect(mockRepository.updateCallCount, equals(errorCount));
    });

    test('should handle mixed concurrent operations', () async {
      final futures = <Future>[];
      final operationCount = 40;

      for (int i = 0; i < operationCount; i++) {
        final request = HttpRequestData(
          id: 'mixed_test_$i',
          url: 'https://api.example.com/mixed/$i',
          method: i % 3 == 0 ? 'GET' : (i % 3 == 1 ? 'POST' : 'PUT'),
          headers: {'Content-Type': 'application/json'},
          params: {'test': i.toString()},
          body: i % 2 == 0 ? null : {'data': 'test_$i'},
          timestamp: DateTime.now(),
        );

        futures.add(logger.logRequest(request));

        // Add response or error based on index
        if (i % 4 == 0) {
          // Error case
          Future.delayed(Duration(milliseconds: 20 + (i % 3) * 10), () async {
            final error = HttpErrorData(
              requestId: 'mixed_test_$i',
              message: 'Server error for request $i',
              type: 'ServerError',
              statusCode: 500,
              duration: 1000,
              timestamp: DateTime.now(),
            );

            await logger.logError(error);
          });
        } else {
          // Success case
          Future.delayed(Duration(milliseconds: 20 + (i % 3) * 10), () async {
            final response = HttpResponseData(
              requestId: 'mixed_test_$i',
              statusCode: 200,
              headers: {'content-type': 'application/json'},
              body: {'result': 'success_$i'},
              duration: 200,
              timestamp: DateTime.now(),
            );

            await logger.logResponse(response);
          });
        }
      }

      await Future.wait(futures);

      // Wait for all delayed operations to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify all operations completed
      expect(mockRepository.insertCallCount, equals(operationCount));
      expect(mockRepository.updateCallCount, equals(operationCount));
    });

    test('should track pending request count correctly', () async {
      final initialCount = await logger.pendingRequestCount;
      expect(initialCount, equals(0));

      final futures = <Future>[];
      final requestCount = 20;

      // Add multiple requests
      for (int i = 0; i < requestCount; i++) {
        final request = HttpRequestData(
          id: 'pending_test_$i',
          url: 'https://api.example.com/pending/$i',
          method: 'GET',
          headers: {},
          params: {},
          body: null,
          timestamp: DateTime.now(),
        );

        futures.add(logger.logRequest(request));

        // Add corresponding response after a delay
        final response = HttpResponseData(
          requestId: 'pending_test_$i',
          statusCode: 200,
          headers: {},
          body: {'result': 'success_$i'},
          duration: 100,
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
        );

        futures.add(Future.delayed(const Duration(milliseconds: 50),
            () => logger.logResponse(response)));
      }

      // Wait for all requests and responses to be logged
      await Future.wait(futures);

      // Check queue length - should have processed items
      expect(logger.queueLength, greaterThanOrEqualTo(0));

      // Wait for processing to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final finalCount = await logger.pendingRequestCount;
      expect(finalCount, equals(0));
    });
  });
}

class MockHttpLogRepository implements HttpLogRepository {
  int insertCallCount = 0;
  int updateCallCount = 0;
  final List<HttpLog> insertedLogs = [];
  final List<HttpLog> updatedLogs = [];

  @override
  Future<int> insertLog(HttpLog log) async {
    insertCallCount++;
    insertedLogs.add(log.copyWith(id: insertCallCount));
    return insertCallCount;
  }

  @override
  Future<void> updateLog(HttpLog log) async {
    updateCallCount++;
    updatedLogs.add(log);
  }

  @override
  Future<List<HttpLog>> getAllLogs({int? limit, int? offset}) async {
    return [];
  }

  @override
  Future<List<HttpLog>> getFilteredLogs(HttpLogFilter filter) async {
    return [];
  }

  @override
  Future<HttpLog?> getLogById(int id) async {
    return null;
  }

  @override
  Future<void> deleteLog(int id) async {}

  @override
  Future<void> clearAllLogs() async {}

  @override
  Future<int> getLogCount() async {
    return 0;
  }

  @override
  Future<int> getFilteredLogCount(HttpLogFilter filter) async {
    return 0;
  }

  @override
  Future<int> deleteOlderThan(DateTime threshold) async {
    return 0;
  }

  @override
  Future<int> deleteExceedingLimit(int maxCount) async {
    return 0;
  }

  @override
  Future<List<int>> insertBatch(List<HttpLog> logs) async {
    return [];
  }

  @override
  void clearCache() {}

  @override
  Future<void> close() async {}
}
