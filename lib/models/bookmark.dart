import 'package:equatable/equatable.dart';

/// Represents a bookmark placed by the user within a book.
class Bookmark extends Equatable {
  final String id;
  final String bookId;
  final int page;
  final String chapter;
  final String text;
  final String? note;
  final String color;
  final DateTime createdDate;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.page,
    this.chapter = '',
    required this.text,
    this.note,
    this.color = '#8B4513',
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  /// Serializes this bookmark to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'page': page,
      'chapter': chapter,
      'text': text,
      'note': note,
      'color': color,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  /// Deserializes a bookmark from a JSON map.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      page: json['page'] as int? ?? 0,
      chapter: json['chapter'] as String? ?? '',
      text: json['text'] as String? ?? '',
      note: json['note'] as String?,
      color: json['color'] as String? ?? '#8B4513',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
    );
  }

  /// Creates a copy of this bookmark with the given fields replaced.
  Bookmark copyWith({
    String? id,
    String? bookId,
    int? page,
    String? chapter,
    String? text,
    String? note,
    String? color,
    DateTime? createdDate,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      chapter: chapter ?? this.chapter,
      text: text ?? this.text,
      note: note ?? this.note,
      color: color ?? this.color,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        page,
        chapter,
        text,
        note,
        color,
        createdDate,
      ];
}
