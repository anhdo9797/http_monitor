import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/db/http_log_repository.dart';
import 'package:http_monitor/src/db/http_monitor_database.dart';
import 'package:http_monitor/src/model/http_log.dart';
import 'package:http_monitor/src/model/http_log_filter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing on desktop
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HttpLogRepositoryImpl', () {
    late HttpMonitorDatabase database;
    late HttpLogRepository repository;

    setUp(() async {
      database = HttpMonitorDatabase();
      try {
        await database.deleteDatabase();
      } catch (_) {
        // Ignore if database doesn't exist
      }
      repository = HttpLogRepositoryImpl(database);
    });

    tearDown(() async {
      await repository.close();
      try {
        await database.deleteDatabase();
      } catch (_) {
        // Ignore errors during cleanup
      }
    });

    test('inserts log and caches it', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await repository.insertLog(log);
      expect(id, greaterThan(0));

      // Should be retrievable from cache
      final retrieved = await repository.getLogById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.url, log.url);
    });

    test('updates log and updates cache', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await repository.insertLog(log);
      final updated = log.copyWith(id: id, statusCode: 404);

      await repository.updateLog(updated);

      final retrieved = await repository.getLogById(id);
      expect(retrieved!.statusCode, 404);
    });

    test('deletes log and removes from cache', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await repository.insertLog(log);
      await repository.deleteLog(id);

      final retrieved = await repository.getLogById(id);
      expect(retrieved, isNull);
    });

    test('clears all logs', () async {
      for (int i = 0; i < 5; i++) {
        await repository.insertLog(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now(),
        ));
      }

      await repository.clearAllLogs();

      final count = await repository.getLogCount();
      expect(count, 0);
    });

    test('gets all logs with pagination', () async {
      for (int i = 0; i < 10; i++) {
        await repository.insertLog(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));
      }

      final firstPage = await repository.getAllLogs(limit: 5, offset: 0);
      expect(firstPage.length, 5);

      final secondPage = await repository.getAllLogs(limit: 5, offset: 5);
      expect(secondPage.length, 5);
    });

    test('filters logs by method', () async {
      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'POST',
        headers: {},
        params: {},
        statusCode: 201,
        duration: 200,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(methods: ['GET']);
      final logs = await repository.getFilteredLogs(filter);

      expect(logs.length, 1);
      expect(logs.first.method, 'GET');
    });

    test('filters logs by status group', () async {
      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(statusGroups: ['4xx']);
      final logs = await repository.getFilteredLogs(filter);

      expect(logs.length, 1);
      expect(logs.first.statusCode, 404);
    });

    test('filters logs by search term', () async {
      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await repository.insertLog(HttpLog(
        url: 'https://api.test.com/posts',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(searchTerm: 'example');
      final logs = await repository.getFilteredLogs(filter);

      expect(logs.length, 1);
      expect(logs.first.url, contains('example'));
    });

    test('gets filtered log count', () async {
      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/users',
        method: 'POST',
        headers: {},
        params: {},
        statusCode: 201,
        duration: 200,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(methods: ['GET']);
      final count = await repository.getFilteredLogCount(filter);

      expect(count, 1);
    });

    test('deletes logs older than threshold', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 10));

      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/old',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: old,
      ));

      await repository.insertLog(HttpLog(
        url: 'https://api.example.com/new',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: now,
      ));

      final threshold = now.subtract(const Duration(days: 5));
      final deleted = await repository.deleteOlderThan(threshold);

      expect(deleted, 1);

      final remaining = await repository.getLogCount();
      expect(remaining, 1);
    });

    test('deletes logs exceeding limit', () async {
      for (int i = 0; i < 10; i++) {
        await repository.insertLog(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));
      }

      final deleted = await repository.deleteExceedingLimit(5);
      expect(deleted, 5);

      final remaining = await repository.getLogCount();
      expect(remaining, 5);
    });

    test('inserts batch of logs', () async {
      final logs = List.generate(
        5,
        (i) => HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now(),
        ),
      );

      final ids = await repository.insertBatch(logs);
      expect(ids.length, 5);

      final count = await repository.getLogCount();
      expect(count, 5);
    });

    test('clears cache', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await repository.insertLog(log);

      repository.clearCache();

      // Should still be retrievable from database
      final retrieved = await repository.getLogById(id);
      expect(retrieved, isNotNull);
    });
  });
}

