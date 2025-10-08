/// Filter model for querying HTTP logs
library;

/// Filter criteria for querying HTTP logs
class HttpLogFilter {
  /// Filter by HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
  final List<String>? methods;

  /// Filter by status code groups (2xx, 3xx, 4xx, 5xx)
  final List<String>? statusGroups;

  /// Search term to filter URLs
  final String? searchTerm;

  /// Filter logs created after this date
  final DateTime? startDate;

  /// Filter logs created before this date
  final DateTime? endDate;

  /// Maximum number of results to return
  final int? limit;

  /// Number of results to skip (for pagination)
  final int? offset;

  /// Creates a new HttpLogFilter instance
  const HttpLogFilter({
    this.methods,
    this.statusGroups,
    this.searchTerm,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
  });

  /// Creates an empty filter (returns all logs)
  const HttpLogFilter.empty()
      : methods = null,
        statusGroups = null,
        searchTerm = null,
        startDate = null,
        endDate = null,
        limit = null,
        offset = null;

  /// Converts the filter to query parameters for database queries
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (methods != null && methods!.isNotEmpty) {
      params['methods'] = methods;
    }

    if (statusGroups != null && statusGroups!.isNotEmpty) {
      params['statusGroups'] = statusGroups;
    }

    if (searchTerm != null && searchTerm!.isNotEmpty) {
      params['searchTerm'] = searchTerm;
    }

    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String();
    }

    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String();
    }

    if (limit != null) {
      params['limit'] = limit;
    }

    if (offset != null) {
      params['offset'] = offset;
    }

    return params;
  }

  /// Returns true if this filter has any active criteria
  bool get hasActiveFilters {
    return (methods != null && methods!.isNotEmpty) ||
        (statusGroups != null && statusGroups!.isNotEmpty) ||
        (searchTerm != null && searchTerm!.isNotEmpty) ||
        startDate != null ||
        endDate != null;
  }

  /// Returns true if this filter is empty (no criteria)
  bool get isEmpty => !hasActiveFilters;

  /// Creates a copy of this filter with the given fields replaced
  HttpLogFilter copyWith({
    List<String>? methods,
    List<String>? statusGroups,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    return HttpLogFilter(
      methods: methods ?? this.methods,
      statusGroups: statusGroups ?? this.statusGroups,
      searchTerm: searchTerm ?? this.searchTerm,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Creates a copy of this filter with nullable fields
  HttpLogFilter copyWithNullable({
    List<String>? methods,
    List<String>? statusGroups,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    bool clearMethods = false,
    bool clearStatusGroups = false,
    bool clearSearchTerm = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearLimit = false,
    bool clearOffset = false,
  }) {
    return HttpLogFilter(
      methods: clearMethods ? null : (methods ?? this.methods),
      statusGroups:
          clearStatusGroups ? null : (statusGroups ?? this.statusGroups),
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      limit: clearLimit ? null : (limit ?? this.limit),
      offset: clearOffset ? null : (offset ?? this.offset),
    );
  }

  @override
  String toString() {
    return 'HttpLogFilter(methods: $methods, statusGroups: $statusGroups, searchTerm: $searchTerm, startDate: $startDate, endDate: $endDate, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HttpLogFilter &&
        _listEquals(other.methods, methods) &&
        _listEquals(other.statusGroups, statusGroups) &&
        other.searchTerm == searchTerm &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return Object.hash(
      methods,
      statusGroups,
      searchTerm,
      startDate,
      endDate,
      limit,
      offset,
    );
  }

  // Helper method for list comparison
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

