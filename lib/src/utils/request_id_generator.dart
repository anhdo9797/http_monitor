/// Utility for generating unique request IDs
library;

import 'dart:math';
import 'dart:isolate';

/// Generates unique request IDs that are safe for concurrent operations
class RequestIdGenerator {
  static final Random _random = Random();
  static int _counter = 0;

  /// Generates a unique request ID
  /// Format: timestamp_isolateId_counter_random
  static String generate() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final isolateId = Isolate.current.hashCode;
    final counter = _getNextCounter();
    final random = _random.nextInt(0xFFFFFF);

    return '${timestamp}_${isolateId}_${counter}_$random';
  }

  /// Gets the next counter value atomically
  static int _getNextCounter() {
    return ++_counter;
  }

  /// Generates a shorter request ID (for performance-critical scenarios)
  static String generateShort() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final isolateId = Isolate.current.hashCode % 1000;
    final counter = _getNextCounter() % 10000;

    return '${timestamp}_$isolateId$counter';
  }
}
