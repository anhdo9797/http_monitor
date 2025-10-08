/// Repository pattern for data access
library;

import 'dart:async';
import '../model/http_log.dart';
import '../model/http_log_filter.dart';
import 'http_monitor_database.dart';

/// Abstract repository interface for HTTP log data access
abstract class HttpLogRepository {
  /// Inserts a new log entry
  Future<int> insertLog(HttpLog log);

  /// Updates an existing log entry
  Future<void> updateLog(HttpLog log);

  /// Gets all logs with optional pagination
  Future<List<HttpLog>> getAllLogs({int? limit, int? offset});

  /// Gets filtered logs based on filter criteria
  Future<List<HttpLog>> getFilteredLogs(HttpLogFilter filter);

  /// Gets a single log by id
  Future<HttpLog?> getLogById(int id);

  /// Deletes a log entry by id
  Future<void> deleteLog(int id);

  /// Deletes all log entries
  Future<void> clearAllLogs();

  /// Gets the total count of logs
  Future<int> getLogCount();

  /// Gets the count of filtered logs
  Future<int> getFilteredLogCount(HttpLogFilter filter);

  /// Deletes logs older than the specified date
  Future<int> deleteOlderThan(DateTime threshold);

  /// Deletes logs exceeding the maximum count
  Future<int> deleteExceedingLimit(int maxCount);

  /// Inserts multiple logs in a batch
  Future<List<int>> insertBatch(List<HttpLog> logs);

  /// Clears the cache
  void clearCache();

  /// Closes the repository and releases resources
  Future<void> close();
}

/// Concrete implementation of HttpLogRepository with caching
class HttpLogRepositoryImpl implements HttpLogRepository {
  final HttpMonitorDatabase _database;
  final Map<int, HttpLog> _cache = {};
  final List<HttpLog> _recentLogs = [];
  static const int _maxCacheSize = 100;
  static const int _maxRecentLogs = 50;

  HttpLogRepositoryImpl(this._database);

  @override
  Future<int> insertLog(HttpLog log) async {
    try {
      final id = await _database.insert(log);
      final logWithId = log.copyWith(id: id);

      // Add to cache
      _cache[id] = logWithId;

      // Add to recent logs
      _recentLogs.insert(0, logWithId);
      if (_recentLogs.length > _maxRecentLogs) {
        _recentLogs.removeLast();
      }

      // Trim cache if needed
      _trimCache();

      return id;
    } catch (e) {
      // Graceful degradation: store in memory only
      final tempId = DateTime.now().millisecondsSinceEpoch;
      final logWithId = log.copyWith(id: tempId);
      _cache[tempId] = logWithId;
      _recentLogs.insert(0, logWithId);
      if (_recentLogs.length > _maxRecentLogs) {
        _recentLogs.removeLast();
      }
      return tempId;
    }
  }

  @override
  Future<void> updateLog(HttpLog log) async {
    try {
      await _database.update(log);

      // Update cache
      if (log.id != null) {
        _cache[log.id!] = log;

        // Update in recent logs
        final index = _recentLogs.indexWhere((l) => l.id == log.id);
        if (index != -1) {
          _recentLogs[index] = log;
        }
      }
    } catch (e) {
      // Graceful degradation: update in memory only
      if (log.id != null) {
        _cache[log.id!] = log;
        final index = _recentLogs.indexWhere((l) => l.id == log.id);
        if (index != -1) {
          _recentLogs[index] = log;
        }
      }
    }
  }

  @override
  Future<List<HttpLog>> getAllLogs({int? limit, int? offset}) async {
    try {
      // Try to get from database
      final logs = await _database.getAll(limit: limit, offset: offset);

      // Update cache with fetched logs
      for (final log in logs) {
        if (log.id != null) {
          _cache[log.id!] = log;
        }
      }

      return logs;
    } catch (e) {
      // Graceful degradation: return from cache/recent logs
      final logs = _recentLogs.toList();
      if (offset != null && offset < logs.length) {
        final start = offset;
        final end = limit != null ? (start + limit).clamp(0, logs.length) : logs.length;
        return logs.sublist(start, end);
      }
      return limit != null ? logs.take(limit).toList() : logs;
    }
  }

  @override
  Future<List<HttpLog>> getFilteredLogs(HttpLogFilter filter) async {
    try {
      final logs = await _database.getFiltered(filter);

      // Update cache with fetched logs
      for (final log in logs) {
        if (log.id != null) {
          _cache[log.id!] = log;
        }
      }

      return logs;
    } catch (e) {
      // Graceful degradation: filter from cache/recent logs
      return _filterLogsInMemory(_recentLogs, filter);
    }
  }

  @override
  Future<HttpLog?> getLogById(int id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      return _cache[id];
    }

    try {
      final log = await _database.getById(id);
      if (log != null) {
        _cache[id] = log;
      }
      return log;
    } catch (e) {
      // Try to find in recent logs
      try {
        return _recentLogs.firstWhere((log) => log.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> deleteLog(int id) async {
    try {
      await _database.delete(id);

      // Remove from cache
      _cache.remove(id);

      // Remove from recent logs
      _recentLogs.removeWhere((log) => log.id == id);
    } catch (e) {
      // Graceful degradation: remove from memory only
      _cache.remove(id);
      _recentLogs.removeWhere((log) => log.id == id);
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      await _database.deleteAll();

      // Clear cache and recent logs
      _cache.clear();
      _recentLogs.clear();
    } catch (e) {
      // Graceful degradation: clear memory only
      _cache.clear();
      _recentLogs.clear();
    }
  }

  @override
  Future<int> getLogCount() async {
    try {
      return await _database.getCount();
    } catch (e) {
      // Graceful degradation: return count from recent logs
      return _recentLogs.length;
    }
  }

  @override
  Future<int> getFilteredLogCount(HttpLogFilter filter) async {
    try {
      return await _database.getFilteredCount(filter);
    } catch (e) {
      // Graceful degradation: count from filtered memory logs
      final filtered = _filterLogsInMemory(_recentLogs, filter);
      return filtered.length;
    }
  }

  @override
  Future<int> deleteOlderThan(DateTime threshold) async {
    try {
      final deleted = await _database.deleteOlderThan(threshold);

      // Remove from cache and recent logs
      _cache.removeWhere((_, log) => log.createdAt.isBefore(threshold));
      _recentLogs.removeWhere((log) => log.createdAt.isBefore(threshold));

      return deleted;
    } catch (e) {
      // Graceful degradation: remove from memory only
      final beforeCount = _recentLogs.length;
      _cache.removeWhere((_, log) => log.createdAt.isBefore(threshold));
      _recentLogs.removeWhere((log) => log.createdAt.isBefore(threshold));
      return beforeCount - _recentLogs.length;
    }
  }

  @override
  Future<int> deleteExceedingLimit(int maxCount) async {
    try {
      final deleted = await _database.deleteExceedingLimit(maxCount);

      // Refresh cache from database
      if (deleted > 0) {
        final remainingLogs = await _database.getAll(limit: _maxRecentLogs);
        _recentLogs.clear();
        _recentLogs.addAll(remainingLogs);

        // Update cache
        _cache.clear();
        for (final log in remainingLogs) {
          if (log.id != null) {
            _cache[log.id!] = log;
          }
        }
      }

      return deleted;
    } catch (e) {
      // Graceful degradation: trim memory logs
      if (_recentLogs.length > maxCount) {
        final toRemove = _recentLogs.length - maxCount;
        _recentLogs.removeRange(maxCount, _recentLogs.length);
        return toRemove;
      }
      return 0;
    }
  }

  @override
  Future<List<int>> insertBatch(List<HttpLog> logs) async {
    final ids = <int>[];

    for (final log in logs) {
      try {
        final id = await insertLog(log);
        ids.add(id);
      } catch (e) {
        // Continue with next log even if one fails
        continue;
      }
    }

    return ids;
  }

  @override
  void clearCache() {
    _cache.clear();
    _recentLogs.clear();
  }

  @override
  Future<void> close() async {
    _cache.clear();
    _recentLogs.clear();
    await _database.close();
  }

  // Helper methods

  void _trimCache() {
    if (_cache.length > _maxCacheSize) {
      // Remove oldest entries (simple LRU-like behavior)
      final keysToRemove = _cache.keys.take(_cache.length - _maxCacheSize);
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
  }

  List<HttpLog> _filterLogsInMemory(List<HttpLog> logs, HttpLogFilter filter) {
    var filtered = logs;

    // Filter by methods
    if (filter.methods != null && filter.methods!.isNotEmpty) {
      filtered = filtered
          .where((log) => filter.methods!.contains(log.method))
          .toList();
    }

    // Filter by status groups
    if (filter.statusGroups != null && filter.statusGroups!.isNotEmpty) {
      filtered = filtered
          .where((log) => filter.statusGroups!.contains(log.statusGroup))
          .toList();
    }

    // Filter by search term
    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      filtered = filtered
          .where((log) => log.url.contains(filter.searchTerm!))
          .toList();
    }

    // Filter by date range
    if (filter.startDate != null) {
      filtered = filtered
          .where((log) => log.createdAt.isAfter(filter.startDate!) ||
              log.createdAt.isAtSameMomentAs(filter.startDate!))
          .toList();
    }

    if (filter.endDate != null) {
      filtered = filtered
          .where((log) => log.createdAt.isBefore(filter.endDate!) ||
              log.createdAt.isAtSameMomentAs(filter.endDate!))
          .toList();
    }

    // Apply limit and offset
    if (filter.offset != null && filter.offset! < filtered.length) {
      filtered = filtered.sublist(filter.offset!);
    }

    if (filter.limit != null && filter.limit! < filtered.length) {
      filtered = filtered.take(filter.limit!).toList();
    }

    return filtered;
  }
}

