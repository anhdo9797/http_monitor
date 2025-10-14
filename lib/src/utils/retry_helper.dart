/// Retry mechanism for handling transient failures
library;

import 'dart:async';

/// Helper class for retrying operations with exponential backoff
class RetryHelper {
  /// Retries an operation with exponential backoff
  ///
  /// [operation] The operation to retry
  /// [maxRetries] Maximum number of retry attempts (default: 3)
  /// [initialDelay] Initial delay before first retry (default: 100ms)
  /// [maxDelay] Maximum delay between retries (default: 5 seconds)
  /// [factor] Backoff multiplier (default: 2.0)
  /// [shouldRetry] Function to determine if an error should be retried
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    Duration maxDelay = const Duration(seconds: 5),
    double factor = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    var delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        // Check if we should retry
        final shouldRetryError = shouldRetry ?? _defaultShouldRetry;
        if (attempts >= maxRetries || !shouldRetryError(error)) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * factor)
              .round()
              .clamp(initialDelay.inMilliseconds, maxDelay.inMilliseconds),
        );
      }
    }
  }

  /// Default retry logic - retry on transient errors
  static bool _defaultShouldRetry(dynamic error) {
    // Retry on database lock errors, timeout errors, etc.
    final errorMessage = error.toString().toLowerCase();

    return errorMessage.contains('database is locked') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('temporary') ||
        errorMessage.contains('busy');
  }

  /// Retries an operation with a fixed delay between attempts
  static Future<T> withFixedDelay<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    return withRetry(
      operation,
      maxRetries: maxRetries,
      initialDelay: delay,
      maxDelay: delay,
      factor: 1.0,
      shouldRetry: shouldRetry,
    );
  }
}
