/// Configuration model for HTTP monitor
library;

/// Configuration options for the HTTP monitor
class HttpMonitorConfig {
  /// Whether HTTP monitoring is enabled
  final bool enabled;

  /// Maximum number of logs to store in the database
  final int maxLogCount;

  /// Duration after which old logs are automatically cleaned up
  final Duration autoCleanupDuration;

  /// List of header names that should be treated as sensitive
  /// (e.g., 'authorization', 'cookie')
  final List<String> sensitiveHeaders;

  /// Maximum size of response body to store (in bytes)
  final int maxResponseBodySize;

  /// Whether to enable monitoring in release mode
  final bool enableInReleaseMode;

  /// Whether to show notifications for HTTP errors
  final bool showErrorNotifications;

  /// Whether to log request bodies
  final bool logRequestBody;

  /// Whether to log response bodies
  final bool logResponseBody;

  /// Creates a new HttpMonitorConfig instance
  const HttpMonitorConfig({
    this.enabled = true,
    this.maxLogCount = 1000,
    this.autoCleanupDuration = const Duration(days: 7),
    this.sensitiveHeaders = const ['authorization', 'cookie', 'set-cookie'],
    this.maxResponseBodySize = 1024 * 1024, // 1MB
    this.enableInReleaseMode = false,
    this.showErrorNotifications = false,
    this.logRequestBody = true,
    this.logResponseBody = true,
  });

  /// Creates a default configuration
  const HttpMonitorConfig.defaultConfig()
      : enabled = true,
        maxLogCount = 1000,
        autoCleanupDuration = const Duration(days: 7),
        sensitiveHeaders = const ['authorization', 'cookie', 'set-cookie'],
        maxResponseBodySize = 1024 * 1024,
        enableInReleaseMode = false,
        showErrorNotifications = false,
        logRequestBody = true,
        logResponseBody = true;

  /// Creates a configuration for debug mode only
  const HttpMonitorConfig.debugOnly()
      : enabled = true,
        maxLogCount = 500,
        autoCleanupDuration = const Duration(days: 3),
        sensitiveHeaders = const ['authorization', 'cookie', 'set-cookie'],
        maxResponseBodySize = 512 * 1024, // 512KB
        enableInReleaseMode = false,
        showErrorNotifications = true,
        logRequestBody = true,
        logResponseBody = true;

  /// Creates a configuration with minimal logging
  const HttpMonitorConfig.minimal()
      : enabled = true,
        maxLogCount = 100,
        autoCleanupDuration = const Duration(days: 1),
        sensitiveHeaders = const ['authorization', 'cookie', 'set-cookie'],
        maxResponseBodySize = 100 * 1024, // 100KB
        enableInReleaseMode = false,
        showErrorNotifications = false,
        logRequestBody = false,
        logResponseBody = false;

  /// Creates a disabled configuration
  const HttpMonitorConfig.disabled()
      : enabled = false,
        maxLogCount = 0,
        autoCleanupDuration = Duration.zero,
        sensitiveHeaders = const [],
        maxResponseBodySize = 0,
        enableInReleaseMode = false,
        showErrorNotifications = false,
        logRequestBody = false,
        logResponseBody = false;

  /// Validates the configuration
  bool validate() {
    if (maxLogCount < 0) return false;
    if (maxResponseBodySize < 0) return false;
    if (autoCleanupDuration.isNegative) return false;
    return true;
  }

  /// Creates a copy of this config with the given fields replaced
  HttpMonitorConfig copyWith({
    bool? enabled,
    int? maxLogCount,
    Duration? autoCleanupDuration,
    List<String>? sensitiveHeaders,
    int? maxResponseBodySize,
    bool? enableInReleaseMode,
    bool? showErrorNotifications,
    bool? logRequestBody,
    bool? logResponseBody,
  }) {
    return HttpMonitorConfig(
      enabled: enabled ?? this.enabled,
      maxLogCount: maxLogCount ?? this.maxLogCount,
      autoCleanupDuration: autoCleanupDuration ?? this.autoCleanupDuration,
      sensitiveHeaders: sensitiveHeaders ?? this.sensitiveHeaders,
      maxResponseBodySize: maxResponseBodySize ?? this.maxResponseBodySize,
      enableInReleaseMode: enableInReleaseMode ?? this.enableInReleaseMode,
      showErrorNotifications:
          showErrorNotifications ?? this.showErrorNotifications,
      logRequestBody: logRequestBody ?? this.logRequestBody,
      logResponseBody: logResponseBody ?? this.logResponseBody,
    );
  }

  @override
  String toString() {
    return 'HttpMonitorConfig(enabled: $enabled, maxLogCount: $maxLogCount, autoCleanupDuration: $autoCleanupDuration, maxResponseBodySize: $maxResponseBodySize, enableInReleaseMode: $enableInReleaseMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpMonitorConfig &&
        other.enabled == enabled &&
        other.maxLogCount == maxLogCount &&
        other.autoCleanupDuration == autoCleanupDuration &&
        _listEquals(other.sensitiveHeaders, sensitiveHeaders) &&
        other.maxResponseBodySize == maxResponseBodySize &&
        other.enableInReleaseMode == enableInReleaseMode &&
        other.showErrorNotifications == showErrorNotifications &&
        other.logRequestBody == logRequestBody &&
        other.logResponseBody == logResponseBody;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      maxLogCount,
      autoCleanupDuration,
      sensitiveHeaders,
      maxResponseBodySize,
      enableInReleaseMode,
      showErrorNotifications,
      logRequestBody,
      logResponseBody,
    );
  }

  // Helper method for list comparison
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

