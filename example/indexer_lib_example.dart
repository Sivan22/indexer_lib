import 'package:indexer_lib/indexer_lib.dart';

void main() {
  print('=== IndexerLib FFI Example ===\n');

  try {
    final indexer = IndexerLib();

    // Example 1: Create an index
    print('Creating index...');
    final result = indexer.createIndex(
      'C:\\test_documents',
      '.txt,.pdf',
      memoryUsage: 10,
    );

    if (result == 0) {
      print('✅ Index created successfully!\n');
    } else {
      print('❌ Failed to create index\n');
      return;
    }

    // Example 2: Search the index
    print('Searching for "example query"...');
    final searchResults = indexer.search(
      'example query',
      adjacency: 2,
      maxResults: 10,
    );

    print('Found ${searchResults.length} results:');
    for (var result in searchResults) {
      print('  - DocId: ${result.docId}, Matches: ${result.matchCount}');
      
      // Get the document path
      final path = indexer.getDocPath(result.docId);
      if (path != null) {
        print('    Path: $path');
      }
      
      // Get a snippet
      final snippet = indexer.getSnippet(result.docId, 'example query');
      if (snippet != null) {
        print('    Snippet: $snippet');
      }
      print('');
    }

    print('✅ All operations completed successfully!');
  } catch (e) {
    print('❌ Error: $e');
    print('\nMake sure to:');
    print('  1. Build the C# library first (run build.bat or build.sh)');
    print('  2. Create an index before searching');
    print('  3. Use valid directory paths');
  }
}
