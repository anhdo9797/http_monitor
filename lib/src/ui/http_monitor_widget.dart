/// Main HTTP monitor widget
library;

import 'package:flutter/material.dart';
import '../core/http_monitor_core.dart';
import '../model/http_log.dart';
import '../model/http_log_filter.dart';
import '../model/http_monitor_config.dart';
import 'log_list_view.dart';
import 'log_detail_view.dart';
import 'filter_component.dart';

/// Main widget for HTTP monitoring interface
class HttpMonitorWidget extends StatefulWidget {
  /// Configuration for the HTTP monitor
  final HttpMonitorConfig? config;

  /// Custom empty state widget
  final Widget? emptyStateWidget;

  /// Custom theme data
  final ThemeData? theme;

  /// Creates a new HttpMonitorWidget
  const HttpMonitorWidget({
    super.key,
    this.config,
    this.emptyStateWidget,
    this.theme,
  });

  @override
  State<HttpMonitorWidget> createState() => _HttpMonitorWidgetState();
}

class _HttpMonitorWidgetState extends State<HttpMonitorWidget> {
  List<HttpLog> _logs = [];
  HttpLogFilter _currentFilter = const HttpLogFilter();
  bool _isLoading = false;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await HttpMonitor.instance.getLogs(filter: _currentFilter);
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onFilterChanged(HttpLogFilter filter) async {
    setState(() {
      _currentFilter = filter;
    });
    await _loadLogs();
  }

  Future<void> _onRefresh() async {
    await _loadLogs();
  }

  void _onLogTap(HttpLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LogDetailView(
          log: log,
          onDelete: () => _deleteLog(log),
        ),
      ),
    );
  }

  Future<void> _deleteLog(HttpLog log) async {
    if (log.id == null) return;

    try {
      await HttpMonitor.instance.deleteLog(log.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log deleted'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all logs? This action cannot be undone.'),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HttpMonitor.instance.clearAllLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All logs cleared'),
              duration: Duration(seconds: 2),
            ),
          );
          await _loadLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear logs: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? Theme.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HTTP Monitor'),
          actions: [
            // Filter toggle button
            IconButton(
              icon: Icon(_showFilter ? Icons.filter_list_off : Icons.filter_list),
              tooltip: _showFilter ? 'Hide Filters' : 'Show Filters',
              onPressed: () {
                setState(() {
                  _showFilter = !_showFilter;
                });
              },
            ),
            // Clear all button
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All Logs',
              onPressed: _logs.isEmpty ? null : _clearAllLogs,
            ),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _onRefresh,
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter component
            if (_showFilter)
              FilterComponent(
                filter: _currentFilter,
                onFilterChanged: _onFilterChanged,
              ),

            // Log list
            Expanded(
              child: LogListView(
                logs: _logs,
                onLogTap: _onLogTap,
                onRefresh: _onRefresh,
                isLoading: _isLoading,
                emptyStateWidget: widget.emptyStateWidget,
              ),
            ),
          ],
        ),
        // Log count indicator
        bottomNavigationBar: _logs.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(8),
                color: theme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  '${_logs.length} log${_logs.length == 1 ? '' : 's'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
