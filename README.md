# HTTP Monitor

A comprehensive HTTP tracking and debugging solution for Flutter applications. Monitor, store, and analyze all HTTP requests and responses with an integrated logging system featuring SQLite storage and a user-friendly widget interface.

## Features

- 🔍 **Automatic HTTP Interception**: Capture all HTTP requests and responses automatically
- 💾 **SQLite Storage**: Persistent storage of HTTP logs with efficient querying
- 🎨 **Beautiful UI**: Clean, intuitive interface for browsing and analyzing logs
- 🔧 **Multiple HTTP Clients**: Support for Dio, http.Client, and custom clients
- 🔎 **Advanced Filtering**: Filter by method, status code, URL, and date range
- 📋 **cURL Export**: Copy any request as a cURL command
- 🎯 **Performance Optimized**: Minimal overhead with automatic cleanup
- 🌙 **Theme Support**: Works with light and dark themes
- 📱 **Cross-Platform**: Works on Android, iOS, and other Flutter platforms

## Installation

Add this to your package's `pubspec.yaml` file:

\`\`\`yaml
dependencies:
  http_monitor: ^0.0.1
\`\`\`

Then run:

\`\`\`bash
flutter pub get
\`\`\`

## Quick Start

### 1. Initialize the Monitor

\`\`\`dart
import 'package:http_monitor/http_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HttpMonitor.init();
  runApp(MyApp());
}
\`\`\`

### 2. Add Interceptors

For Dio:
\`\`\`dart
final dio = Dio();
dio.interceptors.add(HttpMonitorDioInterceptor());
\`\`\`

For http.Client:
\`\`\`dart
final client = HttpMonitorClient(http.Client());
\`\`\`

### 3. Display the Monitor Widget

\`\`\`dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const HttpMonitorWidget(),
  ),
);
\`\`\`

## Configuration

\`\`\`dart
await HttpMonitor.init(
  config: const HttpMonitorConfig(
    enabled: true,
    maxLogCount: 1000,
    autoCleanupDuration: Duration(days: 7),
    maxResponseBodySize: 1024 * 1024,
    enableInReleaseMode: false,
  ),
);
\`\`\`

## Example App

Check out the [example](example/) directory for a complete working example.

## License

This project is licensed under the MIT License.
