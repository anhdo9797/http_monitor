import 'package:flutter_test/flutter_test.dart';
import 'package:http_monitor/src/model/http_log_filter.dart';

void main() {
  group('HttpLogFilter', () {
    test('creates empty filter', () {
      const filter = HttpLogFilter.empty();

      expect(filter.methods, isNull);
      expect(filter.statusGroups, isNull);
      expect(filter.searchTerm, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.limit, isNull);
      expect(filter.offset, isNull);
    });

    test('creates filter with all fields', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);

      final filter = HttpLogFilter(
        methods: ['GET', 'POST'],
        statusGroups: ['2xx', '4xx'],
        searchTerm: 'api.example.com',
        startDate: startDate,
        endDate: endDate,
        limit: 100,
        offset: 0,
      );

      expect(filter.methods, ['GET', 'POST']);
      expect(filter.statusGroups, ['2xx', '4xx']);
      expect(filter.searchTerm, 'api.example.com');
      expect(filter.startDate, startDate);
      expect(filter.endDate, endDate);
      expect(filter.limit, 100);
      expect(filter.offset, 0);
    });

    test('toQueryParams includes only non-null fields', () {
      final filter = HttpLogFilter(
        methods: ['GET'],
        searchTerm: 'test',
        limit: 50,
      );

      final params = filter.toQueryParams();

      expect(params['methods'], ['GET']);
      expect(params['searchTerm'], 'test');
      expect(params['limit'], 50);
      expect(params.containsKey('statusGroups'), isFalse);
      expect(params.containsKey('startDate'), isFalse);
    });

    test('toQueryParams converts dates to ISO8601 strings', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);

      final filter = HttpLogFilter(
        startDate: startDate,
        endDate: endDate,
      );

      final params = filter.toQueryParams();

      expect(params['startDate'], startDate.toIso8601String());
      expect(params['endDate'], endDate.toIso8601String());
    });

    test('hasActiveFilters returns true when filters are set', () {
      final filter1 = HttpLogFilter(methods: ['GET']);
      final filter2 = HttpLogFilter(statusGroups: ['2xx']);
      final filter3 = HttpLogFilter(searchTerm: 'test');
      final filter4 = HttpLogFilter(startDate: DateTime.now());
      final filter5 = HttpLogFilter(endDate: DateTime.now());

      expect(filter1.hasActiveFilters, isTrue);
      expect(filter2.hasActiveFilters, isTrue);
      expect(filter3.hasActiveFilters, isTrue);
      expect(filter4.hasActiveFilters, isTrue);
      expect(filter5.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters returns false for empty filter', () {
      const filter = HttpLogFilter.empty();
      expect(filter.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters ignores limit and offset', () {
      final filter = HttpLogFilter(
        limit: 100,
        offset: 0,
      );

      expect(filter.hasActiveFilters, isFalse);
    });

    test('isEmpty returns true for empty filter', () {
      const filter = HttpLogFilter.empty();
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty returns false when filters are set', () {
      final filter = HttpLogFilter(methods: ['GET']);
      expect(filter.isEmpty, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = HttpLogFilter(
        methods: ['GET'],
        searchTerm: 'test',
        limit: 50,
      );

      final updated = original.copyWith(
        methods: ['POST'],
        limit: 100,
      );

      expect(updated.methods, ['POST']);
      expect(updated.limit, 100);
      expect(updated.searchTerm, 'test'); // unchanged
    });

    test('copyWithNullable can clear fields', () {
      final original = HttpLogFilter(
        methods: ['GET'],
        searchTerm: 'test',
        limit: 50,
      );

      final updated = original.copyWithNullable(
        clearMethods: true,
        clearSearchTerm: true,
      );

      expect(updated.methods, isNull);
      expect(updated.searchTerm, isNull);
      expect(updated.limit, 50); // unchanged
    });

    test('equality works correctly', () {
      final filter1 = HttpLogFilter(
        methods: ['GET', 'POST'],
        searchTerm: 'test',
      );

      final filter2 = HttpLogFilter(
        methods: ['GET', 'POST'],
        searchTerm: 'test',
      );

      final filter3 = HttpLogFilter(
        methods: ['GET'],
        searchTerm: 'test',
      );

      expect(filter1, equals(filter2));
      expect(filter1, isNot(equals(filter3)));
    });

    test('toString returns readable representation', () {
      final filter = HttpLogFilter(
        methods: ['GET'],
        searchTerm: 'test',
      );

      final str = filter.toString();

      expect(str, contains('HttpLogFilter'));
      expect(str, contains('GET'));
      expect(str, contains('test'));
    });

    test('handles empty lists correctly', () {
      final filter = HttpLogFilter(
        methods: [],
        statusGroups: [],
      );

      final params = filter.toQueryParams();

      expect(params.containsKey('methods'), isFalse);
      expect(params.containsKey('statusGroups'), isFalse);
    });

    test('handles empty search term correctly', () {
      final filter = HttpLogFilter(searchTerm: '');

      final params = filter.toQueryParams();

      expect(params.containsKey('searchTerm'), isFalse);
    });
  });
}

