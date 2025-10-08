# HTTP Monitor

[![pub package](https://img.shields.io/pub/v/http_monitor.svg)](https://pub.dev/packages/http_monitor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive HTTP tracking and debugging solution for Flutter applications. Monitor, store, and analyze all HTTP requests and responses with an integrated logging system featuring SQLite storage and a user-friendly widget interface.

Perfect for debugging API issues, analyzing network behavior, and monitoring HTTP traffic in both development and production environments.

## Features

- 🔍 **Automatic HTTP Interception**: Capture all HTTP requests and responses automatically
- 💾 **SQLite Storage**: Persistent storage of HTTP logs with efficient querying and indexing
- 🎨 **Beautiful UI**: Clean, intuitive interface for browsing and analyzing logs
- 🔧 **Multiple HTTP Clients**: Built-in support for Dio, http.Client, and extensible for custom clients
- 🔎 **Advanced Filtering**: Filter by method, status code, URL, and date range
- 📋 **cURL Export**: Copy any request as a cURL command with one tap
- 🎯 **Performance Optimized**: Minimal overhead with automatic cleanup and in-memory caching
- 🌙 **Theme Support**: Works seamlessly with light and dark themes
- 📱 **Cross-Platform**: Works on Android, iOS, Web, and Desktop
- 🧹 **Auto Cleanup**: Configurable automatic cleanup of old logs
- 🔒 **Sensitive Data Protection**: Automatic sanitization of sensitive headers

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Dio Integration](#dio-integration)
  - [http.Client Integration](#httpclient-integration)
  - [Manual Logging](#manual-logging)
  - [Displaying the Monitor UI](#displaying-the-monitor-ui)
  - [Floating Monitor Button](#floating-monitor-button)
- [Advanced Features](#advanced-features)
  - [Filtering Logs](#filtering-logs)
  - [Exporting as cURL](#exporting-as-curl)
  - [Programmatic Access](#programmatic-access)
  - [Custom Cleanup](#custom-cleanup)
- [Configuration Options](#configuration-options)
- [Best Practices](#best-practices)
- [Example](#example)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add `http_monitor` to your `pubspec.yaml` file:

```yaml
dependencies:
  http_monitor: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the Monitor

Initialize the HTTP Monitor in your `main()` function before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:http_monitor/http_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HTTP Monitor
  await HttpMonitor.init(
    config: const HttpMonitorConfig(
      enabled: true,
      maxLogCount: 500,
      autoCleanupDuration: Duration(days: 3),
      enableInReleaseMode: false,
    ),
  );

  runApp(const MyApp());
}
```

### 2. Add Interceptors

#### For Dio:

```dart
import 'package:dio/dio.dart';
import 'package:http_monitor/http_monitor.dart';

final dio = Dio();
dio.interceptors.add(
  HttpMonitorDioInterceptor(logger: HttpMonitor.instance.logger),
);
```

#### For http.Client:

```dart
import 'package:http/http.dart' as http;
import 'package:http_monitor/http_monitor.dart';

final client = HttpMonitorClient(
  client: http.Client(),
  logger: HttpMonitor.instance.logger,
);
```

### 3. Display the Monitor Widget

Navigate to the HTTP Monitor UI to view all captured requests:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const HttpMonitorWidget(),
  ),
);
```

## Configuration

The `HttpMonitorConfig` class provides various configuration options:

```dart
await HttpMonitor.init(
  config: const HttpMonitorConfig(
    // Enable/disable monitoring
    enabled: true,

    // Maximum number of logs to keep
    maxLogCount: 1000,

    // Auto-delete logs older than this duration
    autoCleanupDuration: Duration(days: 7),

    // Maximum response body size to store (in bytes)
    maxResponseBodySize: 1024 * 1024, // 1MB

    // Enable monitoring in release mode
    enableInReleaseMode: false,

    // Headers to sanitize (values will be replaced with ***)
    sensitiveHeaders: ['authorization', 'cookie', 'api-key'],
  ),
);
```

### Preset Configurations

The library provides convenient preset configurations:

```dart
// Development mode - keeps more logs, shorter cleanup
await HttpMonitor.init(config: HttpMonitorConfig.development());

// Production mode - minimal logs, aggressive cleanup
await HttpMonitor.init(config: HttpMonitorConfig.production());

// Testing mode - in-memory only, no persistence
await HttpMonitor.init(config: HttpMonitorConfig.testing());

// Disabled mode - monitoring turned off
await HttpMonitor.init(config: HttpMonitorConfig.disabled());
```

## Usage

### Dio Integration

Complete example with Dio:

```dart
import 'package:dio/dio.dart';
import 'package:http_monitor/http_monitor.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    // Add HTTP Monitor interceptor
    _dio.interceptors.add(
      HttpMonitorDioInterceptor(logger: HttpMonitor.instance.logger),
    );
  }

  Future<Response> getUsers() async {
    return await _dio.get('/users');
  }

  Future<Response> createUser(Map<String, dynamic> data) async {
    return await _dio.post('/users', data: data);
  }
}
```

### http.Client Integration

Complete example with http.Client:

```dart
import 'package:http/http.dart' as http;
import 'package:http_monitor/http_monitor.dart';

class ApiClient {
  late final http.Client _client;

  ApiClient() {
    _client = HttpMonitorClient(
      client: http.Client(),
      logger: HttpMonitor.instance.logger,
    );
  }

  Future<http.Response> getUsers() async {
    return await _client.get(
      Uri.parse('https://api.example.com/users'),
    );
  }

  Future<http.Response> createUser(Map<String, dynamic> data) async {
    return await _client.post(
      Uri.parse('https://api.example.com/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  void dispose() {
    _client.close();
  }
}
```

### Manual Logging

You can also manually log HTTP requests and responses:

```dart
import 'package:http_monitor/http_monitor.dart';

// Log a request
await HttpMonitor.instance.logRequest(
  HttpRequestData(
    url: 'https://api.example.com/users',
    method: 'GET',
    headers: {'Authorization': 'Bearer token'},
    timestamp: DateTime.now(),
  ),
);

// Log a response
await HttpMonitor.instance.logResponse(
  HttpResponseData(
    requestId: 'unique-request-id',
    statusCode: 200,
    headers: {'content-type': 'application/json'},
    body: {'users': []},
    duration: const Duration(milliseconds: 150),
    timestamp: DateTime.now(),
  ),
);

// Log an error
await HttpMonitor.instance.logError(
  HttpErrorData(
    requestId: 'unique-request-id',
    error: 'Connection timeout',
    stackTrace: StackTrace.current,
    timestamp: DateTime.now(),
  ),
);
```

### Displaying the Monitor UI

The `HttpMonitorWidget` provides a full-featured UI for viewing and analyzing logs:

```dart
import 'package:flutter/material.dart';
import 'package:http_monitor/http_monitor.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.monitor),
            title: const Text('HTTP Monitor'),
            subtitle: const Text('View network requests'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HttpMonitorWidget(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### Floating Monitor Button

Add a floating button for quick access to the monitor:

```dart
import 'package:flutter/material.dart';
import 'package:http_monitor/http_monitor.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          // Your main content
          const Center(child: Text('Home Page')),

          // Floating monitor button
          FloatingMonitorButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HttpMonitorWidget(),
                ),
              );
            },
            childBuilder: (size) => Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Advanced Features

### Filtering Logs

Programmatically filter logs:

```dart
import 'package:http_monitor/http_monitor.dart';

// Get all logs
final allLogs = await HttpMonitor.instance.getLogs();

// Filter by method
final getLogs = await HttpMonitor.instance.getLogs(
  filter: const HttpLogFilter(methods: ['GET']),
);

// Filter by status code group
final errorLogs = await HttpMonitor.instance.getLogs(
  filter: const HttpLogFilter(statusGroups: ['4xx', '5xx']),
);

// Filter by URL search term
final apiLogs = await HttpMonitor.instance.getLogs(
  filter: const HttpLogFilter(searchTerm: 'api.example.com'),
);

// Combine multiple filters
final filteredLogs = await HttpMonitor.instance.getLogs(
  filter: HttpLogFilter(
    methods: ['POST', 'PUT'],
    statusGroups: ['2xx'],
    searchTerm: 'users',
    startDate: DateTime.now().subtract(const Duration(days: 1)),
    endDate: DateTime.now(),
  ),
);
```

### Exporting as cURL

Export any HTTP log as a cURL command:

```dart
import 'package:http_monitor/http_monitor.dart';

// Get a specific log
final log = await HttpMonitor.instance.getLogById(logId);

if (log != null) {
  // Generate cURL command
  final curlCommand = CurlConverter.toCurl(log);
  print(curlCommand);

  // Generate pretty-formatted cURL command
  final prettyCurl = CurlConverter.toCurlPretty(log);
  print(prettyCurl);

  // Copy to clipboard (in UI context)
  await Clipboard.setData(ClipboardData(text: curlCommand));
}
```

### Programmatic Access

Access logs programmatically for custom analysis:

```dart
import 'package:http_monitor/http_monitor.dart';

// Get total log count
final count = await HttpMonitor.instance.getLogCount();
print('Total logs: $count');

// Get a specific log by ID
final log = await HttpMonitor.instance.getLogById(123);

// Delete a specific log
await HttpMonitor.instance.deleteLog(123);

// Clear all logs
await HttpMonitor.instance.clearAllLogs();

// Delete logs older than 7 days
await HttpMonitor.instance.deleteOlderThan(
  DateTime.now().subtract(const Duration(days: 7)),
);

// Delete logs exceeding limit (keep only 100 most recent)
await HttpMonitor.instance.deleteExceedingLimit(100);
```

### Custom Cleanup

Perform manual cleanup operations:

```dart
import 'package:http_monitor/http_monitor.dart';

// Perform manual cleanup based on configuration
final result = await HttpMonitor.instance.cleanupService.performManualCleanup();

print('Deleted ${result.deletedCount} logs');
print('Deleted by age: ${result.deletedByAge}');
print('Deleted by limit: ${result.deletedByLimit}');
print('Remaining logs: ${result.remainingCount}');
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `bool` | `true` | Enable/disable HTTP monitoring |
| `maxLogCount` | `int` | `1000` | Maximum number of logs to keep |
| `autoCleanupDuration` | `Duration` | `7 days` | Auto-delete logs older than this |
| `maxResponseBodySize` | `int` | `1MB` | Maximum response body size to store |
| `enableInReleaseMode` | `bool` | `false` | Enable monitoring in release builds |
| `sensitiveHeaders` | `List<String>` | `['authorization', 'cookie']` | Headers to sanitize |

## Best Practices

### 1. Disable in Production

For production apps, disable monitoring or use minimal configuration:

```dart
await HttpMonitor.init(
  config: kReleaseMode
    ? HttpMonitorConfig.disabled()
    : HttpMonitorConfig.development(),
);
```

### 2. Limit Log Storage

Configure appropriate limits to prevent excessive storage usage:

```dart
await HttpMonitor.init(
  config: const HttpMonitorConfig(
    maxLogCount: 500,
    autoCleanupDuration: Duration(days: 3),
    maxResponseBodySize: 512 * 1024, // 512KB
  ),
);
```

### 3. Protect Sensitive Data

Always configure sensitive headers to prevent logging credentials:

```dart
await HttpMonitor.init(
  config: const HttpMonitorConfig(
    sensitiveHeaders: [
      'authorization',
      'cookie',
      'api-key',
      'x-api-key',
      'x-auth-token',
    ],
  ),
);
```

### 4. Clean Up Resources

Properly dispose of HTTP clients when done:

```dart
@override
void dispose() {
  _httpClient.close();
  super.dispose();
}
```

### 5. Use Floating Button for Easy Access

Add a floating monitor button in debug builds for quick access:

```dart
if (kDebugMode) {
  FloatingMonitorButton(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HttpMonitorWidget()),
    ),
  );
}
```

## Example

A complete example app is available in the [example](example/) directory. To run it:

```bash
cd example
flutter run
```

The example demonstrates:
- Dio integration
- http.Client integration
- Floating monitor button
- Making various HTTP requests
- Viewing and filtering logs
- Exporting as cURL
- Deleting logs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this package useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs and issues
- 💡 Suggesting new features
- 📖 Improving documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.
