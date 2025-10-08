import 'package:flutter_test/flutter_test.dart';
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

  group('HttpMonitorDatabase', () {
    late HttpMonitorDatabase db;

    setUp(() async {
      db = HttpMonitorDatabase();
      // Ensure clean state
      try {
        await db.deleteDatabase();
      } catch (_) {
        // Ignore if database doesn't exist
      }
    });

    tearDown(() async {
      await db.close();
      try {
        await db.deleteDatabase();
      } catch (_) {
        // Ignore errors during cleanup
      }
    });

    test('initializes database successfully', () async {
      final database = await db.database;
      expect(database, isNotNull);
      expect(database.isOpen, isTrue);
    });

    test('inserts log entry successfully', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {'content-type': 'application/json'},
        params: {'page': '1'},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await db.insert(log);
      expect(id, greaterThan(0));
    });

    test('retrieves log by id', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await db.insert(log);
      final retrieved = await db.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, id);
      expect(retrieved.url, log.url);
      expect(retrieved.method, log.method);
    });

    test('returns null for non-existent id', () async {
      final retrieved = await db.getById(999);
      expect(retrieved, isNull);
    });

    test('updates log entry', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await db.insert(log);
      final updated = log.copyWith(id: id, statusCode: 404);

      final rowsAffected = await db.update(updated);
      expect(rowsAffected, 1);

      final retrieved = await db.getById(id);
      expect(retrieved!.statusCode, 404);
    });

    test('deletes log entry', () async {
      final log = HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      );

      final id = await db.insert(log);
      final rowsDeleted = await db.delete(id);

      expect(rowsDeleted, 1);

      final retrieved = await db.getById(id);
      expect(retrieved, isNull);
    });

    test('deletes all logs', () async {
      // Insert multiple logs
      for (int i = 0; i < 5; i++) {
        await db.insert(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now(),
        ));
      }

      final count = await db.getCount();
      expect(count, 5);

      await db.deleteAll();

      final newCount = await db.getCount();
      expect(newCount, 0);
    });

    test('gets all logs with limit and offset', () async {
      // Insert 10 logs
      for (int i = 0; i < 10; i++) {
        await db.insert(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));
      }

      final logs = await db.getAll(limit: 5, offset: 0);
      expect(logs.length, 5);

      final nextLogs = await db.getAll(limit: 5, offset: 5);
      expect(nextLogs.length, 5);
    });

    test('filters logs by method', () async {
      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'POST',
        headers: {},
        params: {},
        statusCode: 201,
        duration: 200,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(methods: ['GET']);
      final logs = await db.getFiltered(filter);

      expect(logs.length, 1);
      expect(logs.first.method, 'GET');
    });

    test('filters logs by status group', () async {
      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(statusGroups: ['4xx']);
      final logs = await db.getFiltered(filter);

      expect(logs.length, 1);
      expect(logs.first.statusCode, 404);
    });

    test('filters logs by search term', () async {
      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await db.insert(HttpLog(
        url: 'https://api.test.com/posts',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(searchTerm: 'example');
      final logs = await db.getFiltered(filter);

      expect(logs.length, 1);
      expect(logs.first.url, contains('example'));
    });

    test('filters logs by date range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      await db.insert(HttpLog(
        url: 'https://api.example.com/old',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: yesterday,
      ));

      await db.insert(HttpLog(
        url: 'https://api.example.com/new',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: now,
      ));

      final filter = HttpLogFilter(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: tomorrow,
      );
      final logs = await db.getFiltered(filter);

      expect(logs.length, 1);
      expect(logs.first.url, contains('new'));
    });

    test('gets count of all logs', () async {
      for (int i = 0; i < 5; i++) {
        await db.insert(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now(),
        ));
      }

      final count = await db.getCount();
      expect(count, 5);
    });

    test('deletes logs older than threshold', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 10));

      await db.insert(HttpLog(
        url: 'https://api.example.com/old',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: old,
      ));

      await db.insert(HttpLog(
        url: 'https://api.example.com/new',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: now,
      ));

      final threshold = now.subtract(const Duration(days: 5));
      final deleted = await db.deleteOlderThan(threshold);

      expect(deleted, 1);

      final remaining = await db.getCount();
      expect(remaining, 1);
    });

    test('deletes logs exceeding limit', () async {
      // Insert 10 logs
      for (int i = 0; i < 10; i++) {
        await db.insert(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));
      }

      final deleted = await db.deleteExceedingLimit(5);
      expect(deleted, 5);

      final remaining = await db.getCount();
      expect(remaining, 5);
    });

    test('does not delete when under limit', () async {
      for (int i = 0; i < 3; i++) {
        await db.insert(HttpLog(
          url: 'https://api.example.com/users/$i',
          method: 'GET',
          headers: {},
          params: {},
          statusCode: 200,
          duration: 150,
          createdAt: DateTime.now(),
        ));
      }

      final deleted = await db.deleteExceedingLimit(5);
      expect(deleted, 0);

      final remaining = await db.getCount();
      expect(remaining, 3);
    });

    test('combines multiple filters', () async {
      await db.insert(HttpLog(
        url: 'https://api.example.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 200,
        duration: 150,
        createdAt: DateTime.now(),
      ));

      await db.insert(HttpLog(
        url: 'https://api.example.com/posts',
        method: 'POST',
        headers: {},
        params: {},
        statusCode: 201,
        duration: 200,
        createdAt: DateTime.now(),
      ));

      await db.insert(HttpLog(
        url: 'https://api.test.com/users',
        method: 'GET',
        headers: {},
        params: {},
        statusCode: 404,
        duration: 100,
        createdAt: DateTime.now(),
      ));

      final filter = HttpLogFilter(
        methods: ['GET'],
        statusGroups: ['2xx'],
        searchTerm: 'example',
      );

      final logs = await db.getFiltered(filter);
      expect(logs.length, 1);
      expect(logs.first.url, 'https://api.example.com/users');
    });
  });
}

