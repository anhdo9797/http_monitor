/// Thread-safe map implementation using mutex
library;

import 'dart:async';
import 'package:mutex/mutex.dart';

/// Thread-safe map implementation with mutex protection
class ThreadSafeMap<K, V> {
  final Map<K, V> _map = {};
  final Mutex _mutex = Mutex();

  /// Puts a value into the map
  Future<void> put(K key, V value) async {
    await _mutex.protect(() async {
      _map[key] = value;
    });
  }

  /// Gets a value from the map
  Future<V?> get(K key) async {
    return await _mutex.protect(() async {
      return _map[key];
    });
  }

  /// Removes a value from the map
  Future<V?> remove(K key) async {
    return await _mutex.protect(() async {
      return _map.remove(key);
    });
  }

  /// Checks if the map contains a key
  Future<bool> containsKey(K key) async {
    return await _mutex.protect(() async {
      return _map.containsKey(key);
    });
  }

  /// Gets all keys in the map
  Future<Set<K>> getKeys() async {
    return await _mutex.protect(() async {
      return Set<K>.from(_map.keys);
    });
  }

  /// Gets all values in the map
  Future<List<V>> getValues() async {
    return await _mutex.protect(() async {
      return List<V>.from(_map.values);
    });
  }

  /// Clears the map
  Future<void> clear() async {
    await _mutex.protect(() async {
      _map.clear();
    });
  }

  /// Gets the map length
  Future<int> get length async {
    return await _mutex.protect(() async {
      return _map.length;
    });
  }

  /// Updates a value if the key exists
  Future<bool> updateIfExists(K key, V Function(V) updateFn) async {
    return await _mutex.protect(() async {
      final value = _map[key];
      if (value != null) {
        _map[key] = updateFn(value);
        return true;
      }
      return false;
    });
  }

  /// Puts a value only if the key doesn't exist
  Future<bool> putIfAbsent(K key, V value) async {
    return await _mutex.protect(() async {
      if (!_map.containsKey(key)) {
        _map[key] = value;
        return true;
      }
      return false;
    });
  }
}
