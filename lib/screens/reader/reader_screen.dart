import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../providers/book_provider.dart';

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
  int _totalPages = 100;
  double _fontSize = 18.0;
  bool _showControls = true;
  bool _isBookmarked = false;
  Timer? _controlsTimer;
  String _selectedText = '';
  final List<_Highlight> _highlights = [];
  final List<String> _chapters = [
    'Kapitel 1: Der Beginn',
    'Kapitel 2: Die Reise',
    'Kapitel 3: Die Entdeckung',
    'Kapitel 4: Das Geheimnis',
    'Kapitel 5: Die Rückkehr',
  ];
  int _currentChapter = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadBookProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  void _loadBookProgress() {
    final book = ref.read(bookProvider.notifier).getBookById(widget.bookId);
    if (book != null) {
      setState(() {
        _currentPage = book.currentPage;
        _totalPages = book.totalPages > 0 ? book.totalPages : 100;
        _fontSize = 18.0;
      });
      _pageController = PageController(initialPage: _currentPage);
    }
  }

  void _saveProgress() {
    ref.read(bookProvider.notifier).updateProgress(
          bookId: widget.bookId,
          currentPage: _currentPage,
          totalPages: _totalPages,
          progress: _totalPages > 0 ? _currentPage / _totalPages : 0.0,
        );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (_isBookmarked) {
      ref.read(bookProvider.notifier).addBookmark(
            bookId: widget.bookId,
            page: _currentPage,
            chapter: _chapters[_currentChapter],
            text: 'Lesezeichen auf Seite ${_currentPage + 1}',
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
    final targetPage = index * 20;
    if (targetPage < _totalPages) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentChapter = index;
        _currentPage = targetPage;
      });
      _saveProgress();
    }
  }

  void _showChapterPicker() {
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
                ...List.generate(_chapters.length, (index) {
                  return ListTile(
                    leading: Icon(
                      index == _currentChapter
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: NovaColors.warmGold,
                    ),
                    title: Text(
                      _chapters[index],
                      style: TextStyle(
                        fontWeight: index == _currentChapter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: NovaColors.deepBrown,
                      ),
                    ),
                    trailing: index == _currentChapter
                        ? const Icon(Icons.check, color: NovaColors.warmGold)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToChapter(index);
                    },
                  );
                }),
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

    return Scaffold(
      backgroundColor: NovaColors.parchment,
      body: GestureDetector(
        onTap: () {
          _showControlsTemporarily();
        },
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width * 0.3) {
            // Tap left edge - previous page
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else if (details.localPosition.dx > width * 0.7) {
            // Tap right edge - next page
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Stack(
          children: [
            // Page view
            PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                  _currentChapter = (page / 20).floor().clamp(0, 4);
                });
                _saveProgress();
              },
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: kToolbarHeight + 60,
                    bottom: 100,
                  ),
                  child: _buildPageContent(index),
                );
              },
            ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(theme),
              ),

            // Bottom bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(theme),
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
      ),
    );
  }

  Widget _buildPageContent(int pageIndex) {
    final hasHighlight = _highlights.any((h) => h.page == pageIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter title
        Text(
          _chapters[(pageIndex / 20).floor().clamp(0, 4)],
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
          'Seite ${pageIndex + 1}',
          style: TextStyle(
            fontSize: _fontSize - 4,
            color: NovaColors.lightBrown,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        // Body text
        SelectableText(
          _getPageBody(pageIndex),
          style: TextStyle(
            fontSize: _fontSize,
            color: NovaColors.charcoal,
            fontFamily: 'Georgia',
            height: 1.6,
          ),
          onSelectionChanged: (selection, cause) {
            if (cause == SelectionChangedCause.longPress) {
              setState(() {
                _selectedText = _getPageBody(pageIndex)
                    .substring(selection.start, selection.end);
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

  String _getPageBody(int pageIndex) {
    return 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n'
        'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n'
        'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.\n\n'
        'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.';
  }

  Widget _buildTopBar(ThemeData theme) {
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
                      _chapters[_currentChapter],
                      style: const TextStyle(
                        color: NovaColors.paleGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Seite ${_currentPage + 1} von $_totalPages',
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

  Widget _buildBottomBar(ThemeData theme) {
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
                max: _totalPages.toDouble() - 1,
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
                    if (_currentChapter > 0) {
                      _goToChapter(_currentChapter - 1);
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
                    if (_currentChapter < _chapters.length - 1) {
                      _goToChapter(_currentChapter + 1);
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
              // In a real app, use Clipboard.setData
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
