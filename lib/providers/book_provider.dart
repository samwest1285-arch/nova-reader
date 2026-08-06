import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../models/bookmark.dart';

/// State for the book collection.
class BookCollectionState {
  final List<Book> books;
  final List<Bookmark> bookmarks;
  final bool isLoading;
  final String? error;

  const BookCollectionState({
    this.books = const [],
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookCollectionState copyWith({
    List<Book>? books,
    List<Bookmark>? bookmarks,
    bool? isLoading,
    String? error,
  }) {
    return BookCollectionState(
      books: books ?? this.books,
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing the book collection and bookmarks.
class BookProvider extends StateNotifier<BookCollectionState> {
  final Uuid _uuid = const Uuid();

  BookProvider() : super(const BookCollectionState()) {
    _loadFromPrefs();
  }

  static const _booksPrefsKey = 'nova_reader_books';
  static const _bookmarksPrefsKey = 'nova_reader_bookmarks';

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Loads books and bookmarks from SharedPreferences.
  Future<void> _loadFromPrefs() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load books
      final booksJson = prefs.getString(_booksPrefsKey);
      final List<Book> books = [];
      if (booksJson != null) {
        final decoded = jsonDecode(booksJson) as List<dynamic>;
        for (final item in decoded) {
          books.add(Book.fromJson(item as Map<String, dynamic>));
        }
      }

      // Load bookmarks
      final bookmarksJson = prefs.getString(_bookmarksPrefsKey);
      final List<Bookmark> bookmarks = [];
      if (bookmarksJson != null) {
        final decoded = jsonDecode(bookmarksJson) as List<dynamic>;
        for (final item in decoded) {
          bookmarks.add(Bookmark.fromJson(item as Map<String, dynamic>));
        }
      }

      state = BookCollectionState(
        books: books,
        bookmarks: bookmarks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load library: $e',
      );
    }
  }

  /// Persists books to SharedPreferences.
  Future<void> _saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.books.map((b) => b.toJson()).toList());
      await prefs.setString(_booksPrefsKey, json);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save books: $e');
    }
  }

  /// Persists bookmarks to SharedPreferences.
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          jsonEncode(state.bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_bookmarksPrefsKey, json);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save bookmarks: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Book operations
  // ---------------------------------------------------------------------------

  /// Adds a new book to the library.
  Future<void> addBook({
    required String title,
    required String author,
    String? coverPath,
    required String filePath,
    required BookFormat format,
    int totalPages = 0,
  }) async {
    final book = Book(
      id: _uuid.v4(),
      title: title,
      author: author,
      coverPath: coverPath,
      filePath: filePath,
      format: format,
      totalPages: totalPages,
    );

    state = state.copyWith(
      books: [...state.books, book],
    );
    await _saveBooks();
  }

  /// Removes a book from the library by its ID.
  Future<void> removeBook(String bookId) async {
    state = state.copyWith(
      books: state.books.where((b) => b.id != bookId).toList(),
      bookmarks:
          state.bookmarks.where((bm) => bm.bookId != bookId).toList(),
    );
    await _saveBooks();
    await _saveBookmarks();
  }

  /// Updates the reading progress for a book.
  Future<void> updateProgress({
    required String bookId,
    int? currentPage,
    int? totalPages,
    double? progress,
  }) async {
    final index = state.books.indexWhere((b) => b.id == bookId);
    if (index == -1) return;

    final book = state.books[index];
    final updatedBook = book.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      progress: progress,
      lastRead: DateTime.now(),
    );

    final books = [...state.books];
    books[index] = updatedBook;
    state = state.copyWith(books: books);
    await _saveBooks();
  }

  /// Updates a book's metadata.
  Future<void> updateBook(Book updatedBook) async {
    final index = state.books.indexWhere((b) => b.id == updatedBook.id);
    if (index == -1) return;

    final books = [...state.books];
    books[index] = updatedBook;
    state = state.copyWith(books: books);
    await _saveBooks();
  }

  /// Gets a book by its ID.
  Book? getBookById(String bookId) {
    try {
      return state.books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// Searches books by title or author.
  List<Book> searchBooks(String query) {
    if (query.trim().isEmpty) return state.books;

    final lowerQuery = query.toLowerCase();
    return state.books.where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
          book.author.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Returns books sorted by last read time (most recent first).
  List<Book> getRecentlyReadBooks({int limit = 10}) {
    final sorted = List<Book>.from(state.books)
      ..sort((a, b) => b.lastRead.compareTo(a.lastRead));
    return sorted.take(limit).toList();
  }

  /// Returns books sorted by added date (newest first).
  List<Book> getNewestBooks({int limit = 10}) {
    final sorted = List<Book>.from(state.books)
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return sorted.take(limit).toList();
  }

  /// Returns books that are currently in progress (0 < progress < 1).
  List<Book> getInProgressBooks() {
    return state.books
        .where((b) => b.progress > 0.0 && b.progress < 1.0)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Bookmark operations
  // ---------------------------------------------------------------------------

  /// Adds a bookmark to a book.
  Future<void> addBookmark({
    required String bookId,
    required int page,
    String chapter = '',
    required String text,
    String? note,
    String color = '#8B4513',
  }) async {
    final bookmark = Bookmark(
      id: _uuid.v4(),
      bookId: bookId,
      page: page,
      chapter: chapter,
      text: text,
      note: note,
      color: color,
    );

    state = state.copyWith(
      bookmarks: [...state.bookmarks, bookmark],
    );
    await _saveBookmarks();
  }

  /// Removes a bookmark by its ID.
  Future<void> removeBookmark(String bookmarkId) async {
    state = state.copyWith(
      bookmarks: state.bookmarks.where((bm) => bm.id != bookmarkId).toList(),
    );
    await _saveBookmarks();
  }

  /// Updates an existing bookmark.
  Future<void> updateBookmark(Bookmark updatedBookmark) async {
    final index =
        state.bookmarks.indexWhere((bm) => bm.id == updatedBookmark.id);
    if (index == -1) return;

    final bookmarks = [...state.bookmarks];
    bookmarks[index] = updatedBookmark;
    state = state.copyWith(bookmarks: bookmarks);
    await _saveBookmarks();
  }

  /// Gets all bookmarks for a specific book.
  List<Bookmark> getBookmarksForBook(String bookId) {
    return state.bookmarks
        .where((bm) => bm.bookId == bookId)
        .toList()
      ..sort((a, b) => a.page.compareTo(b.page));
  }

  /// Gets a bookmark by its ID.
  Bookmark? getBookmarkById(String bookmarkId) {
    try {
      return state.bookmarks.firstWhere((bm) => bm.id == bookmarkId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Import / Export
  // ---------------------------------------------------------------------------

  /// Exports all bookmarks as a JSON string.
  String exportBookmarksAsJson() {
    final data = state.bookmarks.map((bm) => bm.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports bookmarks for a specific book as a JSON string.
  String exportBookmarksForBookAsJson(String bookId) {
    final bookmarks = getBookmarksForBook(bookId);
    final data = bookmarks.map((bm) => bm.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Imports bookmarks from a JSON string.
  /// Returns the number of bookmarks imported.
  Future<int> importBookmarksFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final imported = decoded
          .map((item) => Bookmark.fromJson(item as Map<String, dynamic>))
          .toList();

      // Avoid duplicates by checking existing IDs
      final existingIds = state.bookmarks.map((bm) => bm.id).toSet();
      final newBookmarks =
          imported.where((bm) => !existingIds.contains(bm.id)).toList();

      if (newBookmarks.isNotEmpty) {
        state = state.copyWith(
          bookmarks: [...state.bookmarks, ...newBookmarks],
        );
        await _saveBookmarks();
      }

      return newBookmarks.length;
    } catch (e) {
      state = state.copyWith(error: 'Failed to import bookmarks: $e');
      return 0;
    }
  }

  /// Exports the entire library (books + bookmarks) as a JSON string.
  String exportLibraryAsJson() {
    final data = {
      'books': state.books.map((b) => b.toJson()).toList(),
      'bookmarks': state.bookmarks.map((bm) => bm.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Imports a library from a JSON string.
  /// Returns a map with counts of imported books and bookmarks.
  Future<Map<String, int>> importLibraryFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import books
      final booksData = decoded['books'] as List<dynamic>? ?? [];
      final existingBookIds = state.books.map((b) => b.id).toSet();
      final newBooks = booksData
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .where((b) => !existingBookIds.contains(b.id))
          .toList();

      // Import bookmarks
      final bookmarksData = decoded['bookmarks'] as List<dynamic>? ?? [];
      final existingBookmarkIds = state.bookmarks.map((bm) => bm.id).toSet();
      final newBookmarks = bookmarksData
          .map((item) => Bookmark.fromJson(item as Map<String, dynamic>))
          .where((bm) => !existingBookmarkIds.contains(bm.id))
          .toList();

      state = state.copyWith(
        books: [...state.books, ...newBooks],
        bookmarks: [...state.bookmarks, ...newBookmarks],
      );

      await _saveBooks();
      await _saveBookmarks();

      return {
        'books': newBooks.length,
        'bookmarks': newBookmarks.length,
      };
    } catch (e) {
      state = state.copyWith(error: 'Failed to import library: $e');
      return {'books': 0, 'bookmarks': 0};
    }
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for the book collection.
final bookProvider =
    StateNotifierProvider<BookProvider, BookCollectionState>((ref) {
  return BookProvider();
});

/// Provider that returns a book by its ID.
final bookByIdProvider = Provider.family<Book?, String>((ref, bookId) {
  final state = ref.watch(bookProvider);
  try {
    return state.books.firstWhere((b) => b.id == bookId);
  } catch (_) {
    return null;
  }
});

/// Provider that returns bookmarks for a specific book.
final bookmarksForBookProvider =
    Provider.family<List<Bookmark>, String>((ref, bookId) {
  final state = ref.watch(bookProvider);
  return state.bookmarks
      .where((bm) => bm.bookId == bookId)
      .toList()
    ..sort((a, b) => a.page.compareTo(b.page));
});

/// Provider that returns recently read books.
final recentlyReadBooksProvider = Provider<List<Book>>((ref) {
  final state = ref.watch(bookProvider);
  final sorted = List<Book>.from(state.books)
    ..sort((a, b) => b.lastRead.compareTo(a.lastRead));
  return sorted.take(10).toList();
});

/// Provider that returns in-progress books.
final inProgressBooksProvider = Provider<List<Book>>((ref) {
  final state = ref.watch(bookProvider);
  return state.books
      .where((b) => b.progress > 0.0 && b.progress < 1.0)
      .toList();
});
