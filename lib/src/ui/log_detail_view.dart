/// Log detail view component
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/http_log.dart';
import '../utils/json_formatter.dart';
import '../utils/curl_converter.dart';

/// Widget for displaying detailed HTTP log information
class LogDetailView extends StatefulWidget {
  /// The HTTP log to display
  final HttpLog log;

  /// Callback when copy as cURL is pressed
  final VoidCallback? onCopyAsCurl;

  /// Callback when delete is pressed
  final VoidCallback? onDelete;

  /// Creates a new LogDetailView
  const LogDetailView({
    super.key,
    required this.log,
    this.onCopyAsCurl,
    this.onDelete,
  });

  @override
  State<LogDetailView> createState() => _LogDetailViewState();
}

class _LogDetailViewState extends State<LogDetailView> {
  bool _showRawView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        actions: [
          // Copy as cURL button
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Copy as cURL',
            onPressed: _copyAsCurl,
          ),
          // Delete button
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          // Toggle raw view
          IconButton(
            icon: Icon(
                _showRawView ? Icons.format_align_left : Icons.data_object),
            tooltip: _showRawView ? 'Formatted View' : 'Raw View',
            onPressed: () {
              setState(() {
                _showRawView = !_showRawView;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request overview
            _buildOverviewCard(),
            const SizedBox(height: 16),

            // Request details
            _buildExpandableSection(
              title: 'Request Headers',
              content: JsonFormatter.formatHeaders(widget.log.headers),
              icon: Icons.http,
            ),
            const SizedBox(height: 8),

            _buildExpandableSection(
              title: 'Query Parameters',
              content: JsonFormatter.formatParams(widget.log.params),
              icon: Icons.link,
            ),
            const SizedBox(height: 8),

            _buildExpandableSection(
              title: 'Request Body',
              content: _formatContent(widget.log.body),
              icon: Icons.upload,
              copyable: true,
            ),
            const SizedBox(height: 8),

            // Response details
            _buildExpandableSection(
              title: 'Response Body',
              content: _formatContent(widget.log.response),
              icon: Icons.download,
              copyable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Method and Status
            Row(
              children: [
                _buildMethodChip(),
                const SizedBox(width: 8),
                _buildStatusChip(),
                const Spacer(),
                _buildDurationChip(),
              ],
            ),
            const SizedBox(height: 12),

            // URL
            const Text(
              'URL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              widget.log.url,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Timestamp
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(widget.log.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String content,
    required IconData icon,
    bool copyable = false,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: copyable
            ? IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(content, title),
              )
            : null,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip() {
    Color color;
    switch (widget.log.method.toUpperCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        widget.log.method.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    if (widget.log.isSuccessful) {
      color = Colors.green;
    } else if (widget.log.isClientError) {
      color = Colors.orange;
    } else if (widget.log.isServerError) {
      color = Colors.red;
    } else if (widget.log.isRedirect) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${widget.log.statusCode}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDurationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${widget.log.duration}ms',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatContent(dynamic content) {
    if (_showRawView) {
      return content?.toString() ?? 'No content';
    }
    return JsonFormatter.formatBody(content);
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _copyAsCurl() async {
    try {
      final curl = CurlConverter.toCurlPretty(widget.log);
      await Clipboard.setData(ClipboardData(text: curl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied as cURL command'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      widget.onCopyAsCurl?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String content, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
