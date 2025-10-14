import 'package:flutter/material.dart';
import 'package:http_monitor/http_monitor.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HttpMonitor.init(
    config: const HttpMonitorConfig(
      enabled: true,
      maxLogCount: 500,
      autoCleanupDuration: Duration(days: 3),
      maxResponseBodySize: 1024 * 512,
      enableInReleaseMode: false,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Monitor Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Dio _dio;
  late http.Client _httpClient;
  bool _isLoading = false;
  bool _isConcurrentLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeClients();
  }

  void _initializeClients() {
    _dio = Dio();
    _dio.interceptors.add(
      HttpMonitorDioInterceptor(logger: HttpMonitor.instance.logger),
    );

    _httpClient = HttpMonitorClient(
      client: http.Client(),
      logger: HttpMonitor.instance.logger,
    );
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  void _openMonitor() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HttpMonitorWidget()));
  }

  Future<void> _makeGetRequest() async {
    setState(() => _isLoading = true);
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      _showSnack('GET request completed');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeConcurrentRequests() async {
    setState(() => _isConcurrentLoading = true);
    try {
      final stopwatch = Stopwatch()..start();

      // Test concurrent requests with Future.wait
      await Future.wait([
        _dio.get('https://jsonplaceholder.typicode.com/posts/1'),
        _dio.get('https://jsonplaceholder.typicode.com/posts/2'),
        _dio.get('https://jsonplaceholder.typicode.com/posts/3'),
        _dio.get('https://jsonplaceholder.typicode.com/posts/4'),
        _dio.get('https://jsonplaceholder.typicode.com/posts/5'),
        _dio.post('https://jsonplaceholder.typicode.com/posts', data: {
          'title': 'Test Post',
          'body': 'Test body',
          'userId': 1,
        }),
        _httpClient
            .get(Uri.parse('https://jsonplaceholder.typicode.com/users/1')),
        _httpClient
            .get(Uri.parse('https://jsonplaceholder.typicode.com/users/2')),
      ]);

      stopwatch.stop();

      _showSnack(
          'Concurrent requests completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _showSnack('Error in concurrent requests: $e');
    } finally {
      setState(() => _isConcurrentLoading = false);
    }
  }

  Future<void> _makeHighConcurrencyTest() async {
    setState(() => _isConcurrentLoading = true);
    try {
      final stopwatch = Stopwatch()..start();

      // High concurrency test with 50 requests
      final futures = <Future>[];

      for (int i = 1; i <= 50; i++) {
        futures.add(_dio.get('https://jsonplaceholder.typicode.com/posts/$i'));
      }

      await Future.wait(futures);

      stopwatch.stop();

      _showSnack(
          '50 concurrent requests completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _showSnack('Error in high concurrency test: $e');
    } finally {
      setState(() => _isConcurrentLoading = false);
    }
  }

  Future<void> _showQueueStatus() async {
    final queueLength = HttpMonitor.instance.logger.queueLength;
    final pendingCount = await HttpMonitor.instance.logger.pendingRequestCount;

    _showSnack('Queue: $queueLength, Pending: $pendingCount');
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Monitor Example'),
        actions: [
          IconButton(
            onPressed: _showQueueStatus,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show Queue Status',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Single request button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _makeGetRequest,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label:
                    Text(_isLoading ? 'Loading...' : 'Make GET Request (Dio)'),
              ),

              const SizedBox(height: 16),

              // Concurrent requests button
              ElevatedButton.icon(
                onPressed:
                    _isConcurrentLoading ? null : _makeConcurrentRequests,
                icon: _isConcurrentLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isConcurrentLoading
                    ? 'Loading...'
                    : 'Test Concurrent Requests (8 requests)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // High concurrency test button
              ElevatedButton.icon(
                onPressed:
                    _isConcurrentLoading ? null : _makeHighConcurrencyTest,
                icon: _isConcurrentLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on),
                label: Text(_isConcurrentLoading
                    ? 'Loading...'
                    : 'High Concurrency Test (50 requests)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Test concurrent request handling\nwith HTTP Monitor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingMonitorButton(
        onPressed: _openMonitor,
        childBuilder: (size) => Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: const Icon(Icons.monitor, color: Colors.white),
        ),
      ),
    );
  }
}
