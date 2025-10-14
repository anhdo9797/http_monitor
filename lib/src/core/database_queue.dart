/// Database operation queue for serialized access
library;

import 'dart:async';
import 'dart:collection';

/// Queue for serializing database operations to prevent race conditions
class DatabaseQueue {
  final Queue<_QueueOperation> _queue = Queue();
  bool _isProcessing = false;

  /// Enqueues an operation and returns a Future that completes when the operation is done
  Future<T> enqueue<T>(Future<T> Function() operation,
      {String? operationName}) async {
    final completer = Completer<T>();
    final queueOperation = _QueueOperation<T>(
      operation: operation,
      completer: completer,
      name: operationName ?? 'Unknown',
      timestamp: DateTime.now(),
    );

    _queue.add(queueOperation);

    // Start processing if not already running
    unawaited(_processQueue());

    return completer.future;
  }

  /// Processes the queue sequentially
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final queueOperation = _queue.removeFirst();

      try {
        final result = await queueOperation.operation();
        queueOperation.completer.complete(result);
      } catch (error, stackTrace) {
        queueOperation.completer.completeError(error, stackTrace);
      }
    }

    _isProcessing = false;
  }

  /// Gets the current queue length
  int get queueLength => _queue.length;

  /// Clears all pending operations
  void clearQueue() {
    for (final operation in _queue) {
      if (!operation.completer.isCompleted) {
        operation.completer.completeError(
          Exception('Queue cleared'),
          StackTrace.current,
        );
      }
    }
    _queue.clear();
  }
}

/// Internal class to represent a queued operation
class _QueueOperation<T> {
  final Future<T> Function() operation;
  final Completer<T> completer;
  final String name;
  final DateTime timestamp;

  _QueueOperation({
    required this.operation,
    required this.completer,
    required this.name,
    required this.timestamp,
  });
}

/// Helper function to unawait a Future without triggering linter warnings
void unawaited(Future<void> future) {
  // Intentionally empty - just marks the Future as unawaited
}
