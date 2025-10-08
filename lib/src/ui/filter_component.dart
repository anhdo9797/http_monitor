/// Filter component for log filtering
library;

import 'package:flutter/material.dart';
import '../model/http_log_filter.dart';
import 'dart:async';

/// Widget for filtering HTTP logs
class FilterComponent extends StatefulWidget {
  /// Current filter
  final HttpLogFilter filter;

  /// Callback when filter changes
  final Function(HttpLogFilter) onFilterChanged;

  /// Creates a new FilterComponent
  const FilterComponent({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<FilterComponent> createState() => _FilterComponentState();
}

class _FilterComponentState extends State<FilterComponent> {
  late HttpLogFilter _currentFilter;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Available HTTP methods
  static const List<String> _availableMethods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  ];

  // Available status groups
  static const List<String> _availableStatusGroups = [
    '2xx',
    '3xx',
    '4xx',
    '5xx',
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _searchController.text = widget.filter.searchTerm ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateFilter(HttpLogFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    widget.onFilterChanged(newFilter);
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateFilter(_currentFilter.copyWithNullable(
        searchTerm: value.isEmpty ? null : value,
        clearSearchTerm: value.isEmpty,
      ));
    });
  }

  void _toggleMethod(String method) {
    final currentMethods = List<String>.from(_currentFilter.methods ?? []);

    if (currentMethods.contains(method)) {
      currentMethods.remove(method);
    } else {
      currentMethods.add(method);
    }

    _updateFilter(_currentFilter.copyWithNullable(
      methods: currentMethods.isEmpty ? null : currentMethods,
      clearMethods: currentMethods.isEmpty,
    ));
  }

  void _toggleStatusGroup(String statusGroup) {
    final currentGroups = List<String>.from(_currentFilter.statusGroups ?? []);

    if (currentGroups.contains(statusGroup)) {
      currentGroups.remove(statusGroup);
    } else {
      currentGroups.add(statusGroup);
    }

    _updateFilter(_currentFilter.copyWithNullable(
      statusGroups: currentGroups.isEmpty ? null : currentGroups,
      clearStatusGroups: currentGroups.isEmpty,
    ));
  }

  void _clearAllFilters() {
    _searchController.clear();
    _updateFilter(const HttpLogFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentFilter.hasActiveFilters)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Search input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search URL...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),

          // HTTP Methods filter
          const Text(
            'HTTP Methods',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMethods.map((method) {
              final isSelected =
                  _currentFilter.methods?.contains(method) ?? false;
              return FilterChip(
                label: Text(method),
                selected: isSelected,
                onSelected: (_) => _toggleMethod(method),
                selectedColor: _getMethodColor(method).withOpacity(0.2),
                checkmarkColor: _getMethodColor(method),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Status Groups filter
          const Text(
            'Status Code Groups',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStatusGroups.map((group) {
              final isSelected =
                  _currentFilter.statusGroups?.contains(group) ?? false;
              return FilterChip(
                label: Text(group),
                selected: isSelected,
                onSelected: (_) => _toggleStatusGroup(group),
                selectedColor: _getStatusGroupColor(group).withOpacity(0.2),
                checkmarkColor: _getStatusGroupColor(group),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusGroupColor(String group) {
    switch (group) {
      case '2xx':
        return Colors.green;
      case '3xx':
        return Colors.blue;
      case '4xx':
        return Colors.orange;
      case '5xx':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
