/// Database layer for HTTP log storage
library;

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../model/http_log.dart';
import '../model/http_log_filter.dart';

/// Database manager for HTTP log storage using SQLite
class HttpMonitorDatabase {
  static const String _databaseName = 'http_monitor.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'http_logs';

  Database? _database;
  bool _isInitialized = false;
  final bool _inMemory;

  /// Creates a new HttpMonitorDatabase instance
  ///
  /// [inMemory] If true, creates an in-memory database for testing
  HttpMonitorDatabase({bool inMemory = false}) : _inMemory = inMemory;

  /// Gets the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null && _isInitialized) {
      return _database!;
    }
    _database = await _initDatabase();
    _isInitialized = true;
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    try {
      if (_inMemory) {
        // Create in-memory database for testing
        return await openDatabase(
          inMemoryDatabasePath,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        );
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to initialize database: $e');
    }
  }

  /// Configures the database
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys if needed in the future
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates the database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        method TEXT NOT NULL,
        headers TEXT,
        params TEXT,
        body TEXT,
        response TEXT,
        status_code INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_created_at ON $_tableName(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_method ON $_tableName(method)',
    );
    await db.execute(
      'CREATE INDEX idx_status_code ON $_tableName(status_code)',
    );
    await db.execute(
      'CREATE INDEX idx_url ON $_tableName(url)',
    );
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < newVersion) {
      // Migration logic will be added here when needed
    }
  }

  /// Inserts a new log entry
  Future<int> insert(HttpLog log) async {
    try {
      final db = await database;
      final map = log.toDbMap();
      map.remove('id'); // Remove id for auto-increment
      return await db.insert(_tableName, map);
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to insert log: $e');
    }
  }

  /// Updates an existing log entry
  Future<int> update(HttpLog log) async {
    try {
      final db = await database;
      if (log.id == null) {
        throw ArgumentError('Cannot update log without id');
      }
      return await db.update(
        _tableName,
        log.toDbMap(),
        where: 'id = ?',
        whereArgs: [log.id],
      );
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to update log: $e');
    }
  }

  /// Deletes a log entry by id
  Future<int> delete(int id) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to delete log: $e');
    }
  }

  /// Deletes all log entries
  Future<int> deleteAll() async {
    try {
      final db = await database;
      return await db.delete(_tableName);
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to delete all logs: $e');
    }
  }

  /// Gets a log entry by id
  Future<HttpLog?> getById(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return HttpLog.fromDbMap(results.first);
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to get log by id: $e');
    }
  }

  /// Gets all log entries with optional limit and offset
  Future<List<HttpLog>> getAll({int? limit, int? offset}) async {
    try {
      final db = await database;
      final results = await db.query(
        _tableName,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => HttpLog.fromDbMap(map)).toList();
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to get all logs: $e');
    }
  }

  /// Gets filtered log entries
  Future<List<HttpLog>> getFiltered(HttpLogFilter filter) async {
    try {
      final db = await database;
      final whereClause = <String>[];
      final whereArgs = <dynamic>[];

      // Filter by methods
      if (filter.methods != null && filter.methods!.isNotEmpty) {
        final placeholders = List.filled(filter.methods!.length, '?').join(',');
        whereClause.add('method IN ($placeholders)');
        whereArgs.addAll(filter.methods!);
      }

      // Filter by status groups
      if (filter.statusGroups != null && filter.statusGroups!.isNotEmpty) {
        final statusConditions = <String>[];
        for (final group in filter.statusGroups!) {
          final statusPrefix = int.tryParse(group.substring(0, 1));
          if (statusPrefix != null) {
            statusConditions.add(
              '(status_code >= ? AND status_code < ?)',
            );
            whereArgs.add(statusPrefix * 100);
            whereArgs.add((statusPrefix + 1) * 100);
          }
        }
        if (statusConditions.isNotEmpty) {
          whereClause.add('(${statusConditions.join(' OR ')})');
        }
      }

      // Filter by search term (URL contains)
      if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
        whereClause.add('url LIKE ?');
        whereArgs.add('%${filter.searchTerm}%');
      }

      // Filter by date range
      if (filter.startDate != null) {
        whereClause.add('created_at >= ?');
        whereArgs.add(filter.startDate!.toIso8601String());
      }

      if (filter.endDate != null) {
        whereClause.add('created_at <= ?');
        whereArgs.add(filter.endDate!.toIso8601String());
      }

      final results = await db.query(
        _tableName,
        where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: filter.limit,
        offset: filter.offset,
      );

      return results.map((map) => HttpLog.fromDbMap(map)).toList();
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to get filtered logs: $e');
    }
  }

  /// Gets the total count of log entries
  Future<int> getCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to get log count: $e');
    }
  }

  /// Gets the count of filtered log entries
  Future<int> getFilteredCount(HttpLogFilter filter) async {
    try {
      final db = await database;
      final whereClause = <String>[];
      final whereArgs = <dynamic>[];

      // Apply same filters as getFiltered
      if (filter.methods != null && filter.methods!.isNotEmpty) {
        final placeholders = List.filled(filter.methods!.length, '?').join(',');
        whereClause.add('method IN ($placeholders)');
        whereArgs.addAll(filter.methods!);
      }

      if (filter.statusGroups != null && filter.statusGroups!.isNotEmpty) {
        final statusConditions = <String>[];
        for (final group in filter.statusGroups!) {
          final statusPrefix = int.tryParse(group.substring(0, 1));
          if (statusPrefix != null) {
            statusConditions.add(
              '(status_code >= ? AND status_code < ?)',
            );
            whereArgs.add(statusPrefix * 100);
            whereArgs.add((statusPrefix + 1) * 100);
          }
        }
        if (statusConditions.isNotEmpty) {
          whereClause.add('(${statusConditions.join(' OR ')})');
        }
      }

      if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
        whereClause.add('url LIKE ?');
        whereArgs.add('%${filter.searchTerm}%');
      }

      if (filter.startDate != null) {
        whereClause.add('created_at >= ?');
        whereArgs.add(filter.startDate!.toIso8601String());
      }

      if (filter.endDate != null) {
        whereClause.add('created_at <= ?');
        whereArgs.add(filter.endDate!.toIso8601String());
      }

      final where = whereClause.isNotEmpty ? whereClause.join(' AND ') : null;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $_tableName${where != null ? ' WHERE $where' : ''}',
        whereArgs.isNotEmpty ? whereArgs : null,
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to get filtered count: $e');
    }
  }

  /// Deletes old logs based on a date threshold
  Future<int> deleteOlderThan(DateTime threshold) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'created_at < ?',
        whereArgs: [threshold.toIso8601String()],
      );
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to delete old logs: $e');
    }
  }

  /// Deletes logs exceeding a maximum count, keeping the most recent ones
  Future<int> deleteExceedingLimit(int maxCount) async {
    try {
      final db = await database;
      final count = await getCount();

      if (count <= maxCount) return 0;

      final logsToDelete = count - maxCount;

      // Get the IDs of the oldest logs to delete
      final oldestLogs = await db.query(
        _tableName,
        columns: ['id'],
        orderBy: 'created_at ASC',
        limit: logsToDelete,
      );

      if (oldestLogs.isEmpty) return 0;

      final ids = oldestLogs.map((log) => log['id']).toList();
      final placeholders = List.filled(ids.length, '?').join(',');

      return await db.delete(
        _tableName,
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw HttpMonitorDatabaseException(
        'Failed to delete logs exceeding limit: $e',
      );
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  /// Deletes the database file (for testing purposes)
  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      _isInitialized = false;
    } catch (e) {
      throw HttpMonitorDatabaseException('Failed to delete database: $e');
    }
  }
}

/// Custom exception for database errors
class HttpMonitorDatabaseException implements Exception {
  final String message;

  HttpMonitorDatabaseException(this.message);

  @override
  String toString() => 'HttpMonitorDatabaseException: $message';
}

