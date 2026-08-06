import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../providers/epub_provider.dart';
import '../../models/book.dart';

/// The EPUB reader screen with page view, controls, bookmarks, and highlights.
class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  double _fontSize = 18.0;
  bool _showControls = true;
  bool _isBookmarked = false;
  Timer? _controlsTimer;
  String _selectedText = '';
  final List<_Highlight> _highlights = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  void _saveProgress() {
    final epub = ref.read(epubLoaderProvider).epub;
    final totalPages = epub?.chapters.length ?? 0;
    ref.read(bookProvider.notifier).updateProgress(
          bookId: widget.bookId,
          currentPage: _currentPage,
          totalPages: totalPages,
          progress: totalPages > 0 ? _currentPage / totalPages : 0.0,
        );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (_isBookmarked) {
      final epub = ref.read(epubLoaderProvider).epub;
      ref.read(bookProvider.notifier).addBookmark(
            bookId: widget.bookId,
            page: _currentPage,
            chapter: epub?.chapterTitle(_currentPage) ?? '',
            text: 'Lesezeichen auf Kapitel ${_currentPage + 1}',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesezeichen gesetzt'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _goToChapter(int index) {
    final total = ref.read(epubLoaderProvider).epub?.chapters.length ?? 0;
    if (index >= 0 && index < total) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = index);
      _saveProgress();
    }
  }

  void _showChapterPicker() {
    final epub = ref.read(epubLoaderProvider).epub;
    if (epub == null || epub.chapters.isEmpty) return;
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
                  'Kapitel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NovaColors.deepBrown,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: epub.chapters.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          index == _currentPage
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: NovaColors.warmGold,
                        ),
                        title: Text(
                          epub.chapterTitle(index),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: index == _currentPage
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: NovaColors.deepBrown,
                          ),
                        ),
                        trailing: index == _currentPage
                            ? const Icon(Icons.check, color: NovaColors.warmGold)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _goToChapter(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = ref.watch(bookByIdProvider(widget.bookId));
    final epubState = ref.watch(epubLoaderProvider);

    // Trigger loading when the book is available and not yet loaded.
    if (book != null && epubState.epub == null && !epubState.isLoading) {
      ref.read(epubLoaderProvider.notifier).load(book);
    }

    return Scaffold(
      backgroundColor: NovaColors.parchment,
      body: _buildBody(theme, book, epubState),
    );
  }

  Widget _buildBody(
      ThemeData theme, Book? book, EpubLoadState epubState) {
    // Loading state
    if (epubState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: NovaColors.warmGold),
      );
    }

    // Error state
    if (epubState.error != null) {
      return _buildErrorState(theme, epubState.error!);
    }

    // No book found
    if (book == null) {
      return _buildErrorState(theme, 'Buch nicht gefunden.');
    }

    final epub = epubState.epub;
    if (epub == null || epub.chapters.isEmpty) {
      return _buildErrorState(theme, 'Dieses Buch enthält keine lesbaren Kapitel.');
    }

    final totalPages = epub.chapters.length;

    return GestureDetector(
      onTap: () {
        _showControlsTemporarily();
      },
      onTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < width * 0.3) {
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else if (details.localPosition.dx > width * 0.7) {
          if (_currentPage < totalPages - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      child: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              _saveProgress();
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: kToolbarHeight + 60,
                  bottom: 100,
                ),
                child: _buildPageContent(index, epub),
              );
            },
          ),

          // Top bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(theme, epub, totalPages),
            ),

          // Bottom bar
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(theme, totalPages),
            ),

          // Text selection toolbar
          if (_selectedText.isNotEmpty)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: _buildSelectionToolbar(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book,
                size: 56, color: NovaColors.mediumBrown),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: NovaColors.deepBrown,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zurück zur Bibliothek'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int pageIndex, LoadedEpub epub) {
    final hasHighlight = _highlights.any((h) => h.page == pageIndex);
    final body = epub.chapterBody(pageIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter title
        Text(
          epub.chapterTitle(pageIndex),
          style: TextStyle(
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold,
            color: NovaColors.deepBrown,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 8),
        // Page number
        Text(
          'Kapitel ${pageIndex + 1} von ${epub.chapters.length}',
          style: TextStyle(
            fontSize: _fontSize - 4,
            color: NovaColors.lightBrown,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        // Body text
        SelectableText(
          body.isEmpty ? 'Dieses Kapitel enthält keinen Text.' : body,
          style: TextStyle(
            fontSize: _fontSize,
            color: NovaColors.charcoal,
            fontFamily: 'Georgia',
            height: 1.6,
          ),
          onSelectionChanged: (selection, cause) {
            if (cause == SelectionChangedCause.longPress &&
                selection.start < selection.end) {
              setState(() {
                _selectedText = body.substring(
                  selection.start.clamp(0, body.length),
                  selection.end.clamp(0, body.length),
                );
              });
            }
          },
        ),
        if (hasHighlight)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NovaColors.softGold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: NovaColors.warmGold.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '✏️ Markiert',
              style: TextStyle(
                fontSize: _fontSize - 4,
                color: NovaColors.deepBrown,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(ThemeData theme, LoadedEpub epub, int totalPages) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NovaColors.deepBrown.withValues(alpha: 0.95),
            NovaColors.deepBrown.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: NovaColors.paleGold),
              onPressed: () {
                _saveProgress();
                context.pop();
              },
              tooltip: 'Zurück',
            ),
            Expanded(
              child: GestureDetector(
                onTap: _showChapterPicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      epub.chapterTitle(_currentPage),
                      style: const TextStyle(
                        color: NovaColors.paleGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Kapitel ${_currentPage + 1} von $totalPages',
                      style: const TextStyle(
                        color: NovaColors.tan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked
                    ? NovaColors.warmGold
                    : NovaColors.paleGold,
              ),
              onPressed: _toggleBookmark,
              tooltip: 'Lesezeichen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, int totalPages) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NovaColors.deepBrown.withValues(alpha: 0.0),
            NovaColors.deepBrown.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: NovaColors.warmGold,
                inactiveTrackColor: NovaColors.tan.withValues(alpha: 0.5),
                thumbColor: NovaColors.warmGold,
                overlayColor: NovaColors.warmGold.withValues(alpha: 0.12),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _currentPage.toDouble(),
                min: 0,
                max: (totalPages - 1).clamp(0, 1 << 30).toDouble(),
                onChanged: (value) {
                  final page = value.round();
                  _pageController.animateToPage(
                    page,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentPage = page);
                },
                onChangeEnd: (_) => _saveProgress(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Font size controls
                IconButton(
                  icon: const Icon(Icons.text_decrease,
                      color: NovaColors.paleGold, size: 20),
                  onPressed: () {
                    setState(() {
                      _fontSize = (_fontSize - 2).clamp(12.0, 32.0);
                    });
                  },
                  tooltip: 'Schrift verkleinern',
                ),
                Text(
                  '${_fontSize.toInt()}pt',
                  style: const TextStyle(
                    color: NovaColors.paleGold,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase,
                      color: NovaColors.paleGold, size: 20),
                  onPressed: () {
                    setState(() {
                      _fontSize = (_fontSize + 2).clamp(12.0, 32.0);
                    });
                  },
                  tooltip: 'Schrift vergrößern',
                ),
                const VerticalDivider(
                  color: NovaColors.tan,
                  width: 1,
                ),
                // Chapter navigation
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: NovaColors.paleGold, size: 20),
                  onPressed: () {
                    if (_currentPage > 0) {
                      _goToChapter(_currentPage - 1);
                    }
                  },
                  tooltip: 'Vorheriges Kapitel',
                ),
                IconButton(
                  icon: const Icon(Icons.list,
                      color: NovaColors.paleGold, size: 20),
                  onPressed: _showChapterPicker,
                  tooltip: 'Kapitelübersicht',
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: NovaColors.paleGold, size: 20),
                  onPressed: () {
                    if (_currentPage < totalPages - 1) {
                      _goToChapter(_currentPage + 1);
                    }
                  },
                  tooltip: 'Nächstes Kapitel',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NovaColors.deepBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: NovaColors.charcoal.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SelectionAction(
            icon: Icons.highlight,
            label: 'Markieren',
            color: NovaColors.warmGold,
            onTap: () {
              setState(() {
                _highlights.add(_Highlight(
                  text: _selectedText,
                  page: _currentPage,
                  color: '#F4D03F',
                ));
                _selectedText = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Text markiert'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _SelectionAction(
            icon: Icons.copy,
            label: 'Kopieren',
            color: NovaColors.paleGold,
            onTap: () {
              setState(() => _selectedText = '');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Text kopiert'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _SelectionAction(
            icon: Icons.close,
            label: 'Schließen',
            color: NovaColors.lightBrown,
            onTap: () {
              setState(() => _selectedText = '');
            },
          ),
        ],
      ),
    );
  }
}

/// A small action button in the selection toolbar.
class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          Text(
            label,
            style: const TextStyle(
              color: NovaColors.paleGold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal highlight data class.
class _Highlight {
  final String text;
  final int page;
  final String color;

  const _Highlight({
    required this.text,
    required this.page,
    required this.color,
  });
}
