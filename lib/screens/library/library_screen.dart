import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

/// Sort options for the library.
enum LibrarySort {
  titleAsc,
  titleDesc,
  authorAsc,
  authorDesc,
  lastRead,
  dateAdded,
}

/// The book library screen with grid view, search, sort/filter, and empty state.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LibrarySort _currentSort = LibrarySort.lastRead;
  bool _showSearch = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _getSortedBooks(List<Book> books) {
    List<Book> sorted = List.from(books);

    switch (_currentSort) {
      case LibrarySort.titleAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case LibrarySort.titleDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
      case LibrarySort.authorAsc:
        sorted.sort((a, b) => a.author.compareTo(b.author));
        break;
      case LibrarySort.authorDesc:
        sorted.sort((a, b) => b.author.compareTo(a.author));
        break;
      case LibrarySort.lastRead:
        sorted.sort((a, b) => b.lastRead.compareTo(a.lastRead));
        break;
      case LibrarySort.dateAdded:
        sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return sorted;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NovaColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sortieren nach',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NovaColors.deepBrown,
                      ),
                ),
                const SizedBox(height: 16),
                _SortOption(
                  label: 'Titel (A-Z)',
                  icon: Icons.sort_by_alpha,
                  isSelected: _currentSort == LibrarySort.titleAsc,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.titleAsc);
                    Navigator.pop(ctx);
                  },
                ),
                _SortOption(
                  label: 'Titel (Z-A)',
                  icon: Icons.sort_by_alpha,
                  isSelected: _currentSort == LibrarySort.titleDesc,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.titleDesc);
                    Navigator.pop(ctx);
                  },
                ),
                _SortOption(
                  label: 'Autor (A-Z)',
                  icon: Icons.person,
                  isSelected: _currentSort == LibrarySort.authorAsc,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.authorAsc);
                    Navigator.pop(ctx);
                  },
                ),
                _SortOption(
                  label: 'Autor (Z-A)',
                  icon: Icons.person,
                  isSelected: _currentSort == LibrarySort.authorDesc,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.authorDesc);
                    Navigator.pop(ctx);
                  },
                ),
                _SortOption(
                  label: 'Zuletzt gelesen',
                  icon: Icons.history,
                  isSelected: _currentSort == LibrarySort.lastRead,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.lastRead);
                    Navigator.pop(ctx);
                  },
                ),
                _SortOption(
                  label: 'Hinzugefügt',
                  icon: Icons.add_circle_outline,
                  isSelected: _currentSort == LibrarySort.dateAdded,
                  onTap: () {
                    setState(() => _currentSort = LibrarySort.dateAdded);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteBook(Book book) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Buch entfernen'),
          content: Text(
            'Möchten Sie "${book.title}" wirklich aus Ihrer Bibliothek entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(bookProvider.notifier).removeBook(book.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${book.title}" wurde entfernt'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NovaColors.terracotta,
              ),
              child: const Text('Entfernen'),
            ),
          ],
        );
      },
    );
  }

  /// Opens the file picker, copies the selected book into app storage, and
  /// adds it to the library.
  Future<void> _importBook() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final sourcePath = file.path;
      if (sourcePath == null) {
        _showSnack('Datei konnte nicht gelesen werden.');
        return;
      }

      final source = File(sourcePath);
      if (!await source.exists()) {
        _showSnack('Die ausgewählte Datei existiert nicht mehr.');
        return;
      }

      // Copy the file into app storage so it survives and is stable.
      final docs = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${docs.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }
      final ext = sourcePath.split('.').last.toLowerCase();
      final destPath =
          '${booksDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await source.copy(destPath);

      final format = ext == 'pdf' ? BookFormat.pdf : BookFormat.epub;

      // Derive a title from the file name (without extension).
      final fileName = file.name.split('.').first;
      final title = fileName.isEmpty ? 'Unbenanntes Buch' : fileName;

      await ref.read(bookProvider.notifier).addBook(
            title: title,
            author: 'Unbekannter Autor',
            filePath: destPath,
            format: format,
          );

      if (!mounted) return;
      _showSnack('"$title" wurde zur Bibliothek hinzugefügt.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider);
    final theme = Theme.of(context);

    // Filter and sort books
    List<Book> displayBooks = bookState.books;
    if (_searchQuery.isNotEmpty) {
      displayBooks = ref.read(bookProvider.notifier).searchBooks(_searchQuery);
    }
    displayBooks = _getSortedBooks(displayBooks);

    return Scaffold(
      backgroundColor: const Color(0xFF2E1B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: NovaColors.paleGold,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: NovaColors.paleGold),
                decoration: const InputDecoration(
                  hintText: 'Suche nach Titel oder Autor...',
                  hintStyle: TextStyle(color: NovaColors.tan),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Bibliothek'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            tooltip: _showSearch ? 'Suche schließen' : 'Suchen',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sortieren',
          ),
        ],
      ),
      body: bookState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayBooks.isEmpty
              ? _buildEmptyState(theme)
              : _buildBookGrid(displayBooks, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _importBook,
        child: _isImporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NovaColors.paleGold,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Butler character (simplified)
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: NovaColors.charcoal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.smart_toy,
                    size: 40,
                    color: NovaColors.paleGold,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: NovaColors.terracotta,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: NovaColors.cream,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: NovaColors.deepBrown.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Ihre Bibliothek ist noch leer, mein Herr.\nMöchten Sie ein neues Buch hinzufügen?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NovaColors.deepBrown,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importBook,
              icon: const Icon(Icons.add),
              label: const Text('Buch hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<Book> books, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh would reload from prefs
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return _BookGridTile(
            book: books[index],
            onTap: () {
              context.push('/reader/${books[index].id}');
            },
            onLongPress: () {
              _confirmDeleteBook(books[index]);
            },
          );
        },
      ),
    );
  }
}

/// A single book tile in the grid.
class _BookGridTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookGridTile({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getCoverColor(book.title),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: book.coverPath != null
                      ? DecorationImage(
                          image: FileImage(
                            // ignore: undefined_prefixed
                            File(book.coverPath!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: book.coverPath == null
                    ? Center(
                        child: Icon(
                          Icons.auto_stories,
                          size: 48,
                          color: NovaColors.paleGold.withValues(alpha: 0.7),
                        ),
                      )
                    : null,
              ),
            ),
            // Book info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NovaColors.mediumBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.progress > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: 4,
                        backgroundColor: NovaColors.tan,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          NovaColors.warmGold,
                        ),
                      ),
                    ),
                    Text(
                      '${(book.progress * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: NovaColors.mediumBrown,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCoverColor(String title) {
    final colors = [
      const Color(0xFF5D4037),
      const Color(0xFF2E7D32),
      const Color(0xFFBF360C),
      const Color(0xFF4E342E),
      const Color(0xFF795548),
      const Color(0xFF1B5E20),
      const Color(0xFFE65100),
      const Color(0xFF3E2723),
    ];
    return colors[title.length % colors.length];
  }
}

/// A sort option row in the bottom sheet.
class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? NovaColors.warmGold : NovaColors.mediumBrown,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? NovaColors.deepBrown : NovaColors.charcoal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: NovaColors.warmGold)
          : null,
      onTap: onTap,
    );
  }
}
