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

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Monitor Example')),
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _makeGetRequest,
                    icon: const Icon(Icons.download),
                    label: const Text('Make GET Request (Dio)'),
                  ),
          ),
          FloatingMonitorButton(
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
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.monitor, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
