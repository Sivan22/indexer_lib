import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Structure to receive search results from C#
base class SearchResultItem extends Struct {
  @Int32()
  external int docId;
  
  @Int32()
  external int matchCount;
}

// Type definitions for the C# functions
typedef CreateIndexNative = Int32 Function(Pointer<Char> directory, Pointer<Char> extensions, Int32 memoryUsage);
typedef CreateIndexDart = int Function(Pointer<Char> directory, Pointer<Char> extensions, int memoryUsage);

typedef SearchNative = Int32 Function(Pointer<Char> query, Int16 adjacency, Pointer<SearchResultItem> resultsBuffer, Int32 maxResults);
typedef SearchDart = int Function(Pointer<Char> query, int adjacency, Pointer<SearchResultItem> resultsBuffer, int maxResults);

typedef GetDocPathNative = Pointer<Char> Function(Int32 docId);
typedef GetDocPathDart = Pointer<Char> Function(int docId);

typedef GetSnippetNative = Pointer<Char> Function(Int32 docId, Pointer<Char> query);
typedef GetSnippetDart = Pointer<Char> Function(int docId, Pointer<Char> query);

typedef FreeStringNative = Void Function(Pointer<Char> ptr);
typedef FreeStringDart = void Function(Pointer<Char> ptr);

/// Wrapper class for IndexerLib FFI bindings
class IndexerLib {
  late final DynamicLibrary _lib;
  late final CreateIndexDart _createIndex;
  late final SearchDart _search;
  late final GetDocPathDart _getDocPath;
  late final GetSnippetDart _getSnippet;
  late final FreeStringDart _freeString;

  IndexerLib() {
    // Load the C# DLL (Native AOT compiled)
    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('csharp_lib/bin/Release/net8.0/win-x64/publish/IndexerLibWrapper.dll');
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open('csharp_lib/bin/Release/net8.0/linux-x64/publish/IndexerLibWrapper.so');
    } else if (Platform.isMacOS) {
      _lib = DynamicLibrary.open('csharp_lib/bin/Release/net8.0/osx-x64/publish/IndexerLibWrapper.dylib');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Bind the functions
    _createIndex = _lib.lookupFunction<CreateIndexNative, CreateIndexDart>('indexer_create_index');
    _search = _lib.lookupFunction<SearchNative, SearchDart>('indexer_search');
    _getDocPath = _lib.lookupFunction<GetDocPathNative, GetDocPathDart>('indexer_get_doc_path');
    _getSnippet = _lib.lookupFunction<GetSnippetNative, GetSnippetDart>('indexer_get_snippet');
    _freeString = _lib.lookupFunction<FreeStringNative, FreeStringDart>('indexer_free_string');
  }

  /// Creates an index for the specified directory
  /// 
  /// [directory] - The directory to index
  /// [extensions] - Comma-separated list of file extensions (e.g., ".txt,.pdf")
  /// [memoryUsage] - Memory usage limit in MB (default: 10)
  /// 
  /// Returns 0 on success, -1 on error
  int createIndex(String directory, String extensions, {int memoryUsage = 10}) {
    final directoryPtr = directory.toNativeUtf8();
    final extensionsPtr = extensions.toNativeUtf8();
    
    try {
      return _createIndex(directoryPtr.cast(), extensionsPtr.cast(), memoryUsage);
    } finally {
      malloc.free(directoryPtr);
      malloc.free(extensionsPtr);
    }
  }

  /// Searches the index for the given query
  /// 
  /// [query] - The search query
  /// [adjacency] - Maximum word distance between query terms (default: 2)
  /// [maxResults] - Maximum number of results to return (default: 100)
  /// 
  /// Returns a list of search results
  List<SearchResult> search(String query, {int adjacency = 2, int maxResults = 100}) {
    final queryPtr = query.toNativeUtf8();
    final resultsBuffer = malloc<SearchResultItem>(maxResults);
    
    try {
      final resultCount = _search(queryPtr.cast(), adjacency, resultsBuffer, maxResults);
      
      if (resultCount < 0) {
        throw Exception('Search failed');
      }
      
      if (resultCount == 0) {
        return [];
      }
      
      final results = <SearchResult>[];
      for (int i = 0; i < resultCount; i++) {
        final item = resultsBuffer.elementAt(i).ref;
        results.add(SearchResult(
          docId: item.docId,
          matchCount: item.matchCount,
        ));
      }
      
      return results;
    } finally {
      malloc.free(queryPtr);
      malloc.free(resultsBuffer);
    }
  }

  /// Gets the file path for a document ID
  /// 
  /// [docId] - The document ID
  /// 
  /// Returns the file path or null if not found
  String? getDocPath(int docId) {
    final ptr = _getDocPath(docId);
    
    if (ptr == nullptr) {
      return null;
    }
    
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      _freeString(ptr);
    }
  }

  /// Gets a snippet of text around the query terms
  /// 
  /// [docId] - The document ID
  /// [query] - The search query
  /// 
  /// Returns a snippet or null if not found
  String? getSnippet(int docId, String query) {
    final queryPtr = query.toNativeUtf8();
    
    try {
      final ptr = _getSnippet(docId, queryPtr.cast());
      
      if (ptr == nullptr) {
        return null;
      }
      
      try {
        return ptr.cast<Utf8>().toDartString();
      } finally {
        _freeString(ptr);
      }
    } finally {
      malloc.free(queryPtr);
    }
  }
}

/// Represents a search result
class SearchResult {
  final int docId;
  final int matchCount;

  SearchResult({
    required this.docId,
    required this.matchCount,
  });

  @override
  String toString() => 'SearchResult(docId: $docId, matchCount: $matchCount)';
}
