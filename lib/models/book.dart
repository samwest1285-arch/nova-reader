import 'package:equatable/equatable.dart';

/// Represents the format of a book.
enum BookFormat { epub, pdf }

/// Core model representing a book in the Nova Reader library.
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverPath;
  final String filePath;
  final BookFormat format;
  final int currentPage;
  final int totalPages;
  final List<String> bookmarks;
  final List<Highlight> highlights;
  final DateTime lastRead;
  final DateTime addedDate;
  final double progress;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverPath,
    required this.filePath,
    required this.format,
    this.currentPage = 0,
    this.totalPages = 0,
    this.bookmarks = const [],
    this.highlights = const [],
    DateTime? lastRead,
    DateTime? addedDate,
    this.progress = 0.0,
  })  : lastRead = lastRead ?? DateTime.now(),
        addedDate = addedDate ?? DateTime.now();

  /// Creates a copy of this book with the given fields replaced.
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverPath,
    String? filePath,
    BookFormat? format,
    int? currentPage,
    int? totalPages,
    List<String>? bookmarks,
    List<Highlight>? highlights,
    DateTime? lastRead,
    DateTime? addedDate,
    double? progress,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      lastRead: lastRead ?? this.lastRead,
      addedDate: addedDate ?? this.addedDate,
      progress: progress ?? this.progress,
    );
  }

  /// Serializes this book to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverPath': coverPath,
      'filePath': filePath,
      'format': format.name,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'bookmarks': bookmarks,
      'highlights': highlights.map((h) => h.toJson()).toList(),
      'lastRead': lastRead.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
      'progress': progress,
    };
  }

  /// Deserializes a book from a JSON map.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverPath: json['coverPath'] as String?,
      filePath: json['filePath'] as String,
      format: BookFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => BookFormat.epub,
      ),
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      bookmarks: (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => Highlight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastRead: DateTime.parse(json['lastRead'] as String),
      addedDate: DateTime.parse(json['addedDate'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        coverPath,
        filePath,
        format,
        currentPage,
        totalPages,
        bookmarks,
        highlights,
        lastRead,
        addedDate,
        progress,
      ];
}

/// Represents a highlighted passage within a book.
class Highlight extends Equatable {
  final String id;
  final String text;
  final String color;
  final int page;
  final String chapter;
  final DateTime createdDate;
  final String? note;

  Highlight({
    required this.id,
    required this.text,
    this.color = '#F4D03F',
    required this.page,
    this.chapter = '',
    DateTime? createdDate,
    this.note,
  }) : createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'color': color,
      'page': page,
      'chapter': chapter,
      'createdDate': createdDate.toIso8601String(),
      'note': note,
    };
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      text: json['text'] as String,
      color: json['color'] as String? ?? '#F4D03F',
      page: json['page'] as int? ?? 0,
      chapter: json['chapter'] as String? ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  Highlight copyWith({
    String? id,
    String? text,
    String? color,
    int? page,
    String? chapter,
    DateTime? createdDate,
    String? note,
  }) {
    return Highlight(
      id: id ?? this.id,
      text: text ?? this.text,
      color: color ?? this.color,
      page: page ?? this.page,
      chapter: chapter ?? this.chapter,
      createdDate: createdDate ?? this.createdDate,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        color,
        page,
        chapter,
        createdDate,
        note,
      ];
}
