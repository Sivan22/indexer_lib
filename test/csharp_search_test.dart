import 'package:indexer_lib/indexer_lib.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('IndexerLib C# Search Tests', () {
    late IndexerLib indexer;
    final testDir = Directory('test_csharp_documents');
    final testFile = File('${testDir.path}/test.cs');

    setUp(() {
      // Create a directory and a dummy C# file for testing
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
      testDir.createSync();
      testFile.writeAsStringSync('''
        public class Test {
          public void HelloWorld() {
            Console.WriteLine("Hello from C#");
          }
        }
      ''');

      // Delete the database file before each test to ensure a clean state
      final dbFile = File('C:/TextIndexer.db');
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
      final indexDir = Directory('test_index');
      if (indexDir.existsSync()) {
        indexDir.deleteSync(recursive: true);
      }
      indexer = IndexerLib();
    });

    tearDown(() {
      // Clean up the created directory and file
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('Indexes and searches a C# file', () {
      // Step 1: Create index for the C# file
      final createResult = indexer.createIndex(
        testDir.path,
        '.cs',
        memoryUsage: 10
      );
      expect(createResult, equals(0), reason: 'Index creation should succeed');

      // Step 2: Search for "Hello"
      final searchResults = indexer.search(
        'Hello',
        adjacency: 2,
        maxResults: 10,
      );
      expect(searchResults, isNotEmpty, reason: 'Should find results for "Hello"');

      // Step 3: Verify search results
      final result = searchResults.first;
      final path = indexer.getDocPath(result.docId);
      expect(path, equals(testFile.absolute.path), reason: 'The document path should match the test file');

      final snippet = indexer.getSnippet(result.docId, 'Hello');
      expect(snippet, isNotNull, reason: 'Should have a snippet');
      expect(snippet!.toLowerCase(), contains('hello'), reason: 'Snippet should contain the search term');
    });
  });
}
