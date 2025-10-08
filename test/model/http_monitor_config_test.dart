import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_monitor_config.dart';

void main() {
  group('HttpMonitorConfig', () {
    test('creates default config', () {
      const config = HttpMonitorConfig();

      expect(config.enabled, isTrue);
      expect(config.maxLogCount, 1000);
      expect(config.autoCleanupDuration, const Duration(days: 7));
      expect(config.sensitiveHeaders, contains('authorization'));
      expect(config.maxResponseBodySize, 1024 * 1024);
      expect(config.enableInReleaseMode, isFalse);
    });

    test('creates defaultConfig', () {
      const config = HttpMonitorConfig.defaultConfig();

      expect(config.enabled, isTrue);
      expect(config.maxLogCount, 1000);
      expect(config.autoCleanupDuration, const Duration(days: 7));
    });

    test('creates debugOnly config', () {
      const config = HttpMonitorConfig.debugOnly();

      expect(config.enabled, isTrue);
      expect(config.maxLogCount, 500);
      expect(config.autoCleanupDuration, const Duration(days: 3));
      expect(config.enableInReleaseMode, isFalse);
      expect(config.showErrorNotifications, isTrue);
    });

    test('creates minimal config', () {
      const config = HttpMonitorConfig.minimal();

      expect(config.enabled, isTrue);
      expect(config.maxLogCount, 100);
      expect(config.autoCleanupDuration, const Duration(days: 1));
      expect(config.maxResponseBodySize, 100 * 1024);
      expect(config.logRequestBody, isFalse);
      expect(config.logResponseBody, isFalse);
    });

    test('creates disabled config', () {
      const config = HttpMonitorConfig.disabled();

      expect(config.enabled, isFalse);
      expect(config.maxLogCount, 0);
      expect(config.autoCleanupDuration, Duration.zero);
      expect(config.maxResponseBodySize, 0);
    });

    test('creates custom config', () {
      const config = HttpMonitorConfig(
        enabled: true,
        maxLogCount: 500,
        autoCleanupDuration: Duration(days: 3),
        sensitiveHeaders: ['api-key', 'token'],
        maxResponseBodySize: 512 * 1024,
        enableInReleaseMode: true,
      );

      expect(config.enabled, isTrue);
      expect(config.maxLogCount, 500);
      expect(config.autoCleanupDuration, const Duration(days: 3));
      expect(config.sensitiveHeaders, ['api-key', 'token']);
      expect(config.maxResponseBodySize, 512 * 1024);
      expect(config.enableInReleaseMode, isTrue);
    });

    test('validate returns true for valid config', () {
      const config = HttpMonitorConfig();

      expect(config.validate(), isTrue);
    });

    test('validate returns false for negative maxLogCount', () {
      const config = HttpMonitorConfig(maxLogCount: -1);

      expect(config.validate(), isFalse);
    });

    test('validate returns false for negative maxResponseBodySize', () {
      const config = HttpMonitorConfig(maxResponseBodySize: -1);

      expect(config.validate(), isFalse);
    });

    test('validate returns false for negative autoCleanupDuration', () {
      const config = HttpMonitorConfig(
        autoCleanupDuration: Duration(days: -1),
      );

      expect(config.validate(), isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = HttpMonitorConfig();

      final updated = original.copyWith(
        enabled: false,
        maxLogCount: 500,
      );

      expect(updated.enabled, isFalse);
      expect(updated.maxLogCount, 500);
      expect(updated.autoCleanupDuration, original.autoCleanupDuration);
    });

    test('equality works correctly', () {
      const config1 = HttpMonitorConfig(
        enabled: true,
        maxLogCount: 1000,
      );

      const config2 = HttpMonitorConfig(
        enabled: true,
        maxLogCount: 1000,
      );

      const config3 = HttpMonitorConfig(
        enabled: false,
        maxLogCount: 1000,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('toString returns readable representation', () {
      const config = HttpMonitorConfig();

      final str = config.toString();

      expect(str, contains('HttpMonitorConfig'));
      expect(str, contains('enabled'));
      expect(str, contains('maxLogCount'));
    });

    test('sensitiveHeaders includes common headers by default', () {
      const config = HttpMonitorConfig();

      expect(config.sensitiveHeaders, contains('authorization'));
      expect(config.sensitiveHeaders, contains('cookie'));
      expect(config.sensitiveHeaders, contains('set-cookie'));
    });

    test('logRequestBody and logResponseBody are true by default', () {
      const config = HttpMonitorConfig();

      expect(config.logRequestBody, isTrue);
      expect(config.logResponseBody, isTrue);
    });

    test('showErrorNotifications is false by default', () {
      const config = HttpMonitorConfig();

      expect(config.showErrorNotifications, isFalse);
    });

    test('copyWith preserves all fields when not specified', () {
      const original = HttpMonitorConfig(
        enabled: true,
        maxLogCount: 500,
        autoCleanupDuration: Duration(days: 3),
        sensitiveHeaders: ['custom-header'],
        maxResponseBodySize: 256 * 1024,
        enableInReleaseMode: true,
        showErrorNotifications: true,
        logRequestBody: false,
        logResponseBody: false,
      );

      final updated = original.copyWith(maxLogCount: 600);

      expect(updated.enabled, original.enabled);
      expect(updated.maxLogCount, 600);
      expect(updated.autoCleanupDuration, original.autoCleanupDuration);
      expect(updated.sensitiveHeaders, original.sensitiveHeaders);
      expect(updated.maxResponseBodySize, original.maxResponseBodySize);
      expect(updated.enableInReleaseMode, original.enableInReleaseMode);
      expect(updated.showErrorNotifications, original.showErrorNotifications);
      expect(updated.logRequestBody, original.logRequestBody);
      expect(updated.logResponseBody, original.logResponseBody);
    });
  });
}

