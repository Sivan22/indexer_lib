import 'package:indexer_lib/indexer_lib.dart';
import 'package:test/test.dart';

void main() {
  group('IndexerLib FFI Tests', () {
    late IndexerLib indexer;

    setUp(() {
      // Create a new instance for each test
      indexer = IndexerLib();
    });

    test('Library loads successfully', () {
      expect(indexer, isNotNull);
    });

    test('SearchResult can be created', () {
      final result = SearchResult(docId: 1, matchCount: 5);
      expect(result.docId, equals(1));
      expect(result.matchCount, equals(5));
    });

    test('SearchResult toString works', () {
      final result = SearchResult(docId: 1, matchCount: 5);
      expect(result.toString(), equals('SearchResult(docId: 1, matchCount: 5)'));
    });

    test('createIndex returns a value', () {
      // This will fail without proper setup, but should not crash
      final result = indexer.createIndex('test_documents', '.txt', memoryUsage: 1);
      expect(result, isA<int>());
    });
  });
}
