import 'package:indexer_lib/indexer_lib.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('IndexerLib End-to-End Tests', () {
    late IndexerLib indexer;

    setUp(() {
      indexer = IndexerLib();
    });

    test('Complete indexing and search workflow', () {
      print('\n=== End-to-End Test ===');
      
      // Step 1: Create index
      print('Step 1: Creating index for C:\\test_documents...');
      final createResult = indexer.createIndex(
        'C:\\test_documents',
        '.txt',
        memoryUsage: 10,
      );
      
      print('Create index result: $createResult');
      expect(createResult, equals(0), reason: 'Index creation should succeed');
      
      // Step 2: Search for "example query"
      print('\nStep 2: Searching for "example query"...');
      final searchResults = indexer.search(
        'example query',
        adjacency: 2,
        maxResults: 10,
      );
      
      print('Found ${searchResults.length} results');
      expect(searchResults, isNotEmpty, reason: 'Should find results for "example query"');
      
      // Step 3: Verify search results
      print('\nStep 3: Verifying search results...');
      for (var result in searchResults) {
        print('  - DocId: ${result.docId}, Matches: ${result.matchCount}');
        
        expect(result.docId, isPositive, reason: 'DocId should be positive');
        expect(result.matchCount, isPositive, reason: 'Match count should be positive');
        
        // Step 4: Get document path
        final path = indexer.getDocPath(result.docId);
        print('    Path: $path');
        expect(path, isNotNull, reason: 'Should have a valid document path');
        expect(File(path!).existsSync(), isTrue, reason: 'Document file should exist');
        
        // Step 5: Get snippet
        final snippet = indexer.getSnippet(result.docId, 'example query');
        print('    Snippet: $snippet');
        expect(snippet, isNotNull, reason: 'Should have a snippet');
        expect(snippet!.toLowerCase(), contains('example'), reason: 'Snippet should contain search term');
      }
      
      print('\n✅ All end-to-end tests passed!');
    });

    test('Search for non-existent term returns empty results', () {
      print('\n=== Testing Non-existent Search ===');
      
      // First ensure index exists
      indexer.createIndex('C:\\test_documents', '.txt', memoryUsage: 10);
      
      // Search for term that doesn't exist
      final results = indexer.search('xyznonexistent', adjacency: 2);
      
      print('Results for non-existent term: ${results.length}');
      expect(results, isEmpty, reason: 'Should return empty results for non-existent term');
    });

    test('Search for "test" finds documents', () {
      print('\n=== Testing "test" Search ===');
      
      // First ensure index exists
      indexer.createIndex('C:\\test_documents', '.txt', memoryUsage: 10);
      
      // Search for "test"
      final results = indexer.search('test', adjacency: 2);
      
      print('Results for "test": ${results.length}');
      expect(results, isNotEmpty, reason: 'Should find results for "test"');
      
      for (var result in results) {
        final path = indexer.getDocPath(result.docId);
        print('  Found in: $path');
      }
    });
  });
}
