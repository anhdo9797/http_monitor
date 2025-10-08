/// Background cleanup service for HTTP logs
library;

import 'dart:async';
import '../db/http_log_repository.dart';
import '../model/http_monitor_config.dart';

/// Service for automatic cleanup of old HTTP logs
class CleanupService {
  final HttpLogRepository _repository;
  final HttpMonitorConfig _config;
  Timer? _cleanupTimer;
  bool _isRunning = false;

  /// Creates a new CleanupService
  CleanupService({
    required HttpLogRepository repository,
    required HttpMonitorConfig config,
  })  : _repository = repository,
        _config = config;

  /// Starts the automatic cleanup service
  ///
  /// Runs cleanup based on the configured interval.
  /// Default interval is 1 hour.
  void start({Duration interval = const Duration(hours: 1)}) {
    if (_isRunning) return;

    _isRunning = true;
    _cleanupTimer = Timer.periodic(interval, (_) => _performCleanup());

    // Run initial cleanup
    _performCleanup();
  }

  /// Stops the automatic cleanup service
  void stop() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isRunning = false;
  }

  /// Performs a manual cleanup
  Future<CleanupResult> performManualCleanup() async {
    return await _performCleanup();
  }

  /// Internal cleanup method
  Future<CleanupResult> _performCleanup() async {
    int deletedByAge = 0;
    int deletedByLimit = 0;

    try {
      // Delete logs older than configured duration
      if (_config.autoCleanupDuration.inDays > 0) {
        final threshold = DateTime.now().subtract(_config.autoCleanupDuration);
        deletedByAge = await _repository.deleteOlderThan(threshold);
      }

      // Delete logs exceeding max count
      if (_config.maxLogCount > 0) {
        deletedByLimit = await _repository.deleteExceedingLimit(_config.maxLogCount);
      }

      return CleanupResult(
        success: true,
        deletedByAge: deletedByAge,
        deletedByLimit: deletedByLimit,
      );
    } catch (e) {
      return CleanupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Gets the current status of the cleanup service
  bool get isRunning => _isRunning;
}

/// Result of a cleanup operation
class CleanupResult {
  /// Whether the cleanup was successful
  final bool success;

  /// Number of logs deleted due to age
  final int deletedByAge;

  /// Number of logs deleted due to limit
  final int deletedByLimit;

  /// Error message if cleanup failed
  final String? error;

  /// Creates a new CleanupResult
  const CleanupResult({
    required this.success,
    this.deletedByAge = 0,
    this.deletedByLimit = 0,
    this.error,
  });

  /// Total number of logs deleted
  int get totalDeleted => deletedByAge + deletedByLimit;

  @override
  String toString() {
    if (!success) {
      return 'CleanupResult(success: false, error: $error)';
    }
    return 'CleanupResult(success: true, deletedByAge: $deletedByAge, deletedByLimit: $deletedByLimit, total: $totalDeleted)';
  }
}

