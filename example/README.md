# HTTP Monitor Example App

This is a complete example application demonstrating how to use the HTTP Monitor library in a Flutter application.

## Features Demonstrated

- ✅ HTTP Monitor initialization with configuration
- ✅ Dio interceptor integration
- ✅ http.Client wrapper integration
- ✅ Making various types of HTTP requests (GET, POST)
- ✅ Error handling and monitoring
- ✅ Navigating to HTTP Monitor UI
- ✅ Viewing and filtering HTTP logs
- ✅ Exporting requests as cURL commands

## Getting Started

### Prerequisites

- Flutter SDK (>=3.9.2)
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. Navigate to the example directory:
```bash
cd example
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# On Android
flutter run -d <android-device-id>

# On iOS
flutter run -d <ios-device-id>

# On macOS
flutter run -d macos

# On Chrome
flutter run -d chrome
```

## Project Structure

```
example/
├── lib/
│   └── main.dart           # Main application with HTTP Monitor integration
├── android/                # Android platform files
├── ios/                    # iOS platform files
├── pubspec.yaml           # Dependencies configuration
└── README.md              # This file
```

## Code Overview

### 1. Initialize HTTP Monitor

```dart
await HttpMonitor.init(
  config: const HttpMonitorConfig.development(),
);
```

### 2. Add Dio Interceptor

```dart
final dio = Dio();
dio.interceptors.add(
  HttpMonitorDioInterceptor(
    logger: HttpMonitor.instance.logger,
  ),
);
```

### 3. Wrap http.Client

```dart
final httpClient = HttpMonitorClient(
  client: http.Client(),
  logger: HttpMonitor.instance.logger,
);
```

### 4. Make HTTP Requests

```dart
// Using Dio
await dio.get('https://jsonplaceholder.typicode.com/posts/1');

// Using http.Client
await httpClient.get(
  Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
);
```

### 5. View HTTP Monitor UI

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const HttpMonitorWidget(),
  ),
);
```

## Available Actions in the Example App

1. **Make GET Request (Dio)** - Fetches a post from JSONPlaceholder API
2. **Make POST Request (Dio)** - Creates a new post
3. **Make GET Request (http.Client)** - Fetches a user
4. **Make Error Request** - Triggers a 404 error for testing
5. **View HTTP Monitor** - Opens the HTTP Monitor UI

## Testing the App

### Test Scenarios

1. **Basic Request Monitoring**
   - Tap "Make GET Request (Dio)"
   - Tap "View HTTP Monitor"
   - Verify the request appears in the list

2. **Filtering**
   - Make multiple requests with different methods
   - Open HTTP Monitor
   - Use the filter button to filter by method or status

3. **Request Details**
   - Tap on any request in the list
   - View headers, parameters, request/response bodies
   - Test the "Copy as cURL" button

4. **Error Handling**
   - Tap "Make Error Request"
   - Open HTTP Monitor
   - Verify the error is logged with 404 status

5. **Search**
   - Make multiple requests
   - Use the search bar to filter by URL

## Configuration Options

The example uses `HttpMonitorConfig.development()` which includes:
- Enabled monitoring
- 7 days log retention
- 1000 max logs
- 1 hour auto-cleanup interval

You can customize the configuration:

```dart
await HttpMonitor.init(
  config: const HttpMonitorConfig(
    enabled: true,
    maxLogCount: 500,
    autoCleanupDuration: Duration(days: 3),
    autoCleanupInterval: Duration(hours: 2),
  ),
);
```

## Platform Support

This example app has been tested on:
- ✅ Android (API 28+)
- ✅ iOS (iOS 12+)
- ✅ macOS
- ✅ Chrome (Web)

## Troubleshooting

### Android Build Issues

If you encounter build issues on Android:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### iOS Build Issues

If you encounter build issues on iOS:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### Hot Reload

The app supports hot reload. After making changes to the code, press `r` in the terminal to hot reload.

## Learn More

- [HTTP Monitor Documentation](../README.md)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dio Package](https://pub.dev/packages/dio)
- [http Package](https://pub.dev/packages/http)

## License

This example is part of the HTTP Monitor package and is licensed under the MIT License.
