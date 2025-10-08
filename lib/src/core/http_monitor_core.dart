/// Core functionality for HTTP monitoring
library;

import 'dart:async';
import '../db/http_log_repository.dart';
import '../db/http_monitor_database.dart';
import '../model/http_log.dart';
import '../model/http_log_filter.dart';
import '../model/http_monitor_config.dart';
import '../model/http_request_data.dart';
import '../model/http_response_data.dart';
import '../model/http_error_data.dart';
import 'http_logger.dart';
import 'cleanup_service.dart';

/// Singleton class for HTTP monitoring
///
/// This is the main entry point for the HTTP monitor library.
/// It provides methods for initialization, logging, and log management.
class HttpMonitor {
  static HttpMonitor? _instance;
  static HttpMonitorConfig? _config;
  static HttpMonitorDatabase? _database;
  static HttpLogRepository? _repository;
  static HttpLogger? _logger;
  static CleanupService? _cleanupService;
  static bool _isInitialized = false;

  /// Private constructor for singleton pattern
  HttpMonitor._();

  /// Gets the singleton instance
  ///
  /// Throws [StateError] if not initialized
  static HttpMonitor get instance {
    if (!_isInitialized || _instance == null) {
      throw StateError(
        'HttpMonitor not initialized. Call HttpMonitor.init() first.',
      );
    }
    return _instance!;
  }

  /// Initializes the HTTP monitor
  ///
  /// This must be called before using any other methods.
  /// [config] Optional configuration. Uses default if not provided.
  static Future<void> init({HttpMonitorConfig? config}) async {
    if (_isInitialized) {
      return; // Already initialized
    }

    _config = config ?? const HttpMonitorConfig.defaultConfig();

    // Initialize database
    _database = HttpMonitorDatabase();

    // Initialize repository
    _repository = HttpLogRepositoryImpl(_database!);

    // Initialize logger
    _logger = HttpLogger(
      repository: _repository!,
      config: _config!,
    );

    // Initialize cleanup service
    _cleanupService = CleanupService(
      repository: _repository!,
      config: _config!,
    );

    // Create instance
    _instance = HttpMonitor._();
    _isInitialized = true;

    // Perform initial cleanup if configured
    if (_config!.autoCleanupDuration.inDays > 0) {
      final threshold = DateTime.now().subtract(_config!.autoCleanupDuration);
      await _repository!.deleteOlderThan(threshold);
    }

    // Enforce max log count
    if (_config!.maxLogCount > 0) {
      await _repository!.deleteExceedingLimit(_config!.maxLogCount);
    }

    // Start automatic cleanup service
    _cleanupService!.start();
  }

  /// Manually logs an HTTP request
  ///
  /// This can be used for custom HTTP clients or manual logging.
  Future<void> logRequest(HttpRequestData request) async {
    _ensureInitialized();
    await _logger!.logRequest(request);
  }

  /// Manually logs an HTTP response
  ///
  /// This can be used for custom HTTP clients or manual logging.
  Future<void> logResponse(HttpResponseData response) async {
    _ensureInitialized();
    await _logger!.logResponse(response);
  }

  /// Manually logs an HTTP error
  ///
  /// This can be used for custom HTTP clients or manual logging.
  Future<void> logError(HttpErrorData error) async {
    _ensureInitialized();
    await _logger!.logError(error);
  }

  /// Gets all logs with optional filtering
  ///
  /// [filter] Optional filter criteria
  /// Returns a list of HTTP logs
  Future<List<HttpLog>> getLogs({HttpLogFilter? filter}) async {
    _ensureInitialized();

    if (filter != null) {
      return await _repository!.getFilteredLogs(filter);
    }

    return await _repository!.getAllLogs();
  }

  /// Gets a single log by ID
  ///
  /// [id] The log ID
  /// Returns the log or null if not found
  Future<HttpLog?> getLogById(int id) async {
    _ensureInitialized();
    return await _repository!.getLogById(id);
  }

  /// Gets the total count of logs
  ///
  /// [filter] Optional filter criteria
  /// Returns the count of logs
  Future<int> getLogCount({HttpLogFilter? filter}) async {
    _ensureInitialized();

    if (filter != null) {
      return await _repository!.getFilteredLogCount(filter);
    }

    return await _repository!.getLogCount();
  }

  /// Deletes a single log by ID
  ///
  /// [id] The log ID to delete
  Future<void> deleteLog(int id) async {
    _ensureInitialized();
    await _repository!.deleteLog(id);
  }

  /// Clears all logs
  Future<void> clearAllLogs() async {
    _ensureInitialized();
    await _repository!.clearAllLogs();
  }

  /// Deletes logs older than the specified duration
  ///
  /// [duration] The age threshold
  /// Returns the number of deleted logs
  Future<int> deleteOlderThan(Duration duration) async {
    _ensureInitialized();
    final threshold = DateTime.now().subtract(duration);
    return await _repository!.deleteOlderThan(threshold);
  }

  /// Deletes logs exceeding the maximum count
  ///
  /// [maxCount] The maximum number of logs to keep
  /// Returns the number of deleted logs
  Future<int> deleteExceedingLimit(int maxCount) async {
    _ensureInitialized();
    return await _repository!.deleteExceedingLimit(maxCount);
  }

  /// Gets the current configuration
  HttpMonitorConfig get config {
    _ensureInitialized();
    return _config!;
  }

  /// Gets the logger instance
  ///
  /// This is useful for creating custom interceptors.
  HttpLogger get logger {
    _ensureInitialized();
    return _logger!;
  }

  /// Checks if the monitor is initialized
  static bool get isInitialized => _isInitialized;

  /// Gets the cleanup service instance
  ///
  /// This is useful for manual cleanup operations.
  CleanupService get cleanupService {
    _ensureInitialized();
    return _cleanupService!;
  }

  /// Closes the HTTP monitor and releases resources
  ///
  /// After calling this, you must call init() again before using the monitor.
  static Future<void> close() async {
    if (!_isInitialized) return;

    _cleanupService?.stop();
    await _repository?.close();
    await _database?.close();

    _instance = null;
    _config = null;
    _database = null;
    _repository = null;
    _logger = null;
    _cleanupService = null;
    _isInitialized = false;
  }

  /// Ensures the monitor is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HttpMonitor not initialized. Call HttpMonitor.init() first.',
      );
    }
  }
}
