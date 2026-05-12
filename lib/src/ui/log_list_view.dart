/// Log list view component
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/http_log.dart';
import '../model/http_log_filter.dart';
import '../utils/curl_converter.dart';

/// Widget for displaying a list of HTTP logs
class LogListView extends StatefulWidget {
  /// List of HTTP logs to display
  final List<HttpLog> logs;

  /// Callback when a log is tapped
  final Function(HttpLog) onLogTap;

  /// Callback when filter is changed
  final Function(HttpLogFilter)? onFilterChanged;

  /// Callback for refresh action
  final Future<void> Function()? onRefresh;

  /// Whether the list is currently loading
  final bool isLoading;

  /// Widget to display when the list is empty
  final Widget? emptyStateWidget;

  /// Creates a new LogListView
  const LogListView({
    super.key,
    required this.logs,
    required this.onLogTap,
    this.onFilterChanged,
    this.onRefresh,
    this.isLoading = false,
    this.emptyStateWidget,
  });

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.logs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.logs.isEmpty) {
      return widget.emptyStateWidget ?? _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView.builder(
        itemCount: widget.logs.length,
        itemBuilder: (context, index) {
          final log = widget.logs[index];
          return _LogListItem(
            log: log,
            onTap: () => widget.onLogTap(log),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No HTTP logs yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make some HTTP requests to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual log item widget
class _LogListItem extends StatelessWidget {
  final HttpLog log;
  final VoidCallback onTap;

  const _LogListItem({
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Method and URL row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethodChip(),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _extractPath(log.url),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _copyCurl(context),
                    child: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status code and duration row
              Row(
                children: [
                  _buildStatusChip(),
                  const SizedBox(width: 8),
                  _buildDurationChip(),
                  const Spacer(),
                  _buildTimestamp(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyCurl(BuildContext context) async {
    try {
      final curl = CurlConverter.toCurlPretty(log);
      await Clipboard.setData(ClipboardData(text: curl));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied as cURL command'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _extractPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path;
    return path.isEmpty ? '/' : path;
  }

  String _extractHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Widget _buildMethodChip() {
    Color color;
    switch (log.method.toUpperCase()) {
      case 'GET':
        color = Colors.blue;
        break;
      case 'POST':
        color = Colors.green;
        break;
      case 'PUT':
        color = Colors.orange;
        break;
      case 'PATCH':
        color = Colors.purple;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        log.method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    // Pending state: response hasn't arrived yet
    if (log.statusCode == 0) {
      return IntrinsicWidth(
        child: Row(
          children: [
            _PendingDot(),
            const SizedBox(width: 4),
            const Text(
              'Pending...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    Color color;
    if (log.isSuccessful) {
      color = Colors.green;
    } else if (log.isClientError) {
      color = Colors.orange;
    } else if (log.isServerError) {
      color = Colors.red;
    } else if (log.isRedirect) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return IntrinsicWidth(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${log.statusCode}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip() {
    // Hide duration for pending requests
    if (log.statusCode == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${log.duration}ms',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(log.createdAt);

    String timeAgo;
    if (difference.inSeconds < 60) {
      timeAgo = '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    return Text(
      timeAgo,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }
}

/// Animated pulsing dot for pending request state
class _PendingDot extends StatefulWidget {
  @override
  State<_PendingDot> createState() => _PendingDotState();
}

class _PendingDotState extends State<_PendingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
