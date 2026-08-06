import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../services/epub_service.dart';

/// Holds the parsed content of a single EPUB book.
class LoadedEpub {
  final String title;
  final String author;
  final String? coverImagePath;
  final List<EpubChapter> chapters;
  final String rawContent;

  const LoadedEpub({
    required this.title,
    required this.author,
    this.coverImagePath,
    required this.chapters,
    required this.rawContent,
  });

  /// Returns the plain-text body of a chapter (HTML stripped).
  String chapterBody(int index) {
    if (index < 0 || index >= chapters.length) return '';
    return _stripHtml(chapters[index].content);
  }

  String chapterTitle(int index) {
    if (index < 0 || index >= chapters.length) return '';
    return chapters[index].title;
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// State for loading a book's EPUB content.
class EpubLoadState {
  final bool isLoading;
  final LoadedEpub? epub;
  final String? error;

  const EpubLoadState({
    this.isLoading = false,
    this.epub,
    this.error,
  });

  EpubLoadState copyWith({
    bool? isLoading,
    LoadedEpub? epub,
    String? error,
  }) {
    return EpubLoadState(
      isLoading: isLoading ?? this.isLoading,
      epub: epub ?? this.epub,
      error: error,
    );
  }
}

/// Loads and caches EPUB content for a given book.
class EpubLoader extends StateNotifier<EpubLoadState> {
  final EpubService _service;

  EpubLoader(this._service) : super(const EpubLoadState());

  Future<void> load(Book book) async {
    if (book.format != BookFormat.epub) {
      state = EpubLoadState(
        error: 'Dieses Format wird vom Reader noch nicht unterstützt.',
      );
      return;
    }

    // Already loaded.
    if (state.epub != null) return;

    state = const EpubLoadState(isLoading: true);
    try {
      final result = await _service.readEpub(book.filePath);
      state = EpubLoadState(
        epub: LoadedEpub(
          title: result.title,
          author: result.author,
          coverImagePath: result.coverImagePath,
          chapters: result.chapters,
          rawContent: result.rawContent,
        ),
      );
    } catch (e) {
      state = EpubLoadState(error: 'Buch konnte nicht geladen werden: $e');
    }
  }

  void reset() {
    state = const EpubLoadState();
  }
}

/// Provider that loads EPUB content for a book by its ID.
final epubLoaderProvider =
    StateNotifierProvider.autoDispose<EpubLoader, EpubLoadState>((ref) {
  return EpubLoader(EpubService());
});
