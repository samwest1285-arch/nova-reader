import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

/// File converter screen for PDF and images to EPUB.
class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  bool _fileSelected = false;
  bool _isConverting = false;
  bool _conversionComplete = false;
  double _conversionProgress = 0.0;
  String _selectedFileName = '';
  String _fileType = '';
  int _fileSize = 0;
  int _pageRangeStart = 1;
  int _pageRangeEnd = 100;
  bool _usePageRange = false;
  String _selectedLanguage = 'Deutsch';
  Timer? _conversionTimer;
  String _resultPreview = '';

  final List<String> _languages = [
    'Deutsch',
    'English',
    'Français',
    'Español',
    'Italiano',
    'Nederlands',
  ];

  @override
  void dispose() {
    _conversionTimer?.cancel();
    super.dispose();
  }

  void _pickFile() {
    // Simulate file picker
    setState(() {
      _fileSelected = true;
      _selectedFileName = 'Dokument_2024.pdf';
      _fileType = 'PDF';
      _fileSize = 2450000; // 2.45 MB
      _pageRangeEnd = 45;
      _conversionComplete = false;
      _resultPreview = '';
    });
  }

  void _startConversion() {
    setState(() {
      _isConverting = true;
      _conversionProgress = 0.0;
      _conversionComplete = false;
    });

    _conversionTimer?.cancel();
    _conversionTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _conversionProgress += 0.03;
          if (_conversionProgress >= 1.0) {
            _conversionProgress = 1.0;
            _isConverting = false;
            _conversionComplete = true;
            timer.cancel();
            _resultPreview =
                'Konvertierung erfolgreich!\n\n'
                'Datei: ${_selectedFileName.replaceAll('.pdf', '.epub')}\n'
                'Seiten: ${_usePageRange ? "$_pageRangeStart - $_pageRangeEnd" : "Alle"}\n'
                'Sprache: $_selectedLanguage\n\n'
                'Das EPUB wurde erfolgreich erstellt und kann in Ihre Bibliothek übernommen werden.';
          }
        });
      }
    });
  }

  void _saveToLibrary() {
    ref.read(bookProvider.notifier).addBook(
          title: _selectedFileName.replaceAll('.pdf', ''),
          author: 'Unbekannt',
          filePath: '/books/${_selectedFileName.replaceAll('.pdf', '.epub')}',
          format: BookFormat.epub,
          totalPages: _usePageRange
              ? _pageRangeEnd - _pageRangeStart + 1
              : _pageRangeEnd,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buch wurde in der Bibliothek gespeichert'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _fileSelected = false;
      _conversionComplete = false;
      _resultPreview = '';
      _selectedFileName = '';
    });
  }

  void _reset() {
    setState(() {
      _fileSelected = false;
      _isConverting = false;
      _conversionComplete = false;
      _conversionProgress = 0.0;
      _selectedFileName = '';
      _resultPreview = '';
    });
    _conversionTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF2E1B12),
      appBar: AppBar(
        title: const Text('PDF/Photo zu EPUB'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: NovaColors.paleGold,
        actions: [
          if (_fileSelected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Zurücksetzen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File selection area
            _buildFileSelection(theme),

            if (_fileSelected) ...[
              const SizedBox(height: 24),

              // File preview
              _buildFilePreview(theme),

              const SizedBox(height: 24),

              // Conversion options
              _buildConversionOptions(theme),

              const SizedBox(height: 24),

              // Convert button / progress
              _buildConversionSection(theme),

              if (_conversionComplete) ...[
                const SizedBox(height: 24),

                // Result preview
                _buildResultPreview(theme),

                const SizedBox(height: 16),

                // Save to library
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveToLibrary,
                    icon: const Icon(Icons.library_add),
                    label: const Text('In Bibliothek speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NovaColors.deepGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection(ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: _fileSelected ? null : _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: _fileSelected
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: NovaColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: NovaColors.terracotta,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fileType.toUpperCase()} · ${(_fileSize / 1000000).toStringAsFixed(1)} MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: NovaColors.mediumBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _reset,
                      color: NovaColors.lightBrown,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: NovaColors.mediumBrown.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PDF oder Bild auswählen',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: NovaColors.mediumBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tippen Sie hier, um eine Datei auszuwählen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NovaColors.lightBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Datei auswählen'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vorschau',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: NovaColors.deepBrown,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: NovaColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NovaColors.tan.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _fileType == 'PDF'
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  size: 48,
                  color: NovaColors.mediumBrown.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vorschau für $_selectedFileName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NovaColors.mediumBrown,
                  ),
                ),
                Text(
                  'Seite 1 von ${_usePageRange ? _pageRangeEnd : _pageRangeEnd}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: NovaColors.lightBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konvertierungsoptionen',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: NovaColors.deepBrown,
          ),
        ),
        const SizedBox(height: 12),

        // Page range toggle
        SwitchListTile(
          secondary: const Icon(Icons.pageview, color: NovaColors.mediumBrown),
          title: const Text('Seitenbereich'),
          subtitle: Text(
            _usePageRange
                ? 'Seite $_pageRangeStart bis $_pageRangeEnd'
                : 'Alle Seiten',
          ),
          value: _usePageRange,
          onChanged: (value) {
            setState(() => _usePageRange = value);
          },
          activeColor: NovaColors.warmGold,
        ),

        if (_usePageRange) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Von',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: _pageRangeStart.toString()),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _pageRangeStart = parsed);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('bis'),
                ),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Bis',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: _pageRangeEnd.toString()),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _pageRangeEnd = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Language selection
        ListTile(
          leading: const Icon(Icons.language, color: NovaColors.mediumBrown),
          title: const Text('Sprache'),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: NovaColors.warmWhite,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sprache auswählen',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: NovaColors.deepBrown,
                          ),
                        ),
                      ),
                      ..._languages.map((lang) {
                        return ListTile(
                          title: Text(lang),
                          trailing: _selectedLanguage == lang
                              ? const Icon(Icons.check,
                                  color: NovaColors.warmGold)
                              : null,
                          onTap: () {
                            setState(() => _selectedLanguage = lang);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isConverting) ...[
          LinearProgressIndicator(
            value: _conversionProgress,
            backgroundColor: NovaColors.tan,
            valueColor:
                const AlwaysStoppedAnimation<Color>(NovaColors.warmGold),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            'Konvertiere... ${(_conversionProgress * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: NovaColors.mediumBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seite ${(_conversionProgress * (_usePageRange ? (_pageRangeEnd - _pageRangeStart + 1) : _pageRangeEnd)).toInt()} von ${_usePageRange ? (_pageRangeEnd - _pageRangeStart + 1) : _pageRangeEnd}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: NovaColors.lightBrown,
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fileSelected && !_conversionComplete
                  ? _startConversion
                  : null,
              icon: const Icon(Icons.transform),
              label: Text(
                _conversionComplete
                    ? 'Konvertierung abgeschlossen'
                    : 'Konvertierung starten',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle,
                color: NovaColors.deepGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ergebnis',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: NovaColors.deepGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NovaColors.paleGreen.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NovaColors.deepGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _resultPreview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NovaColors.charcoal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: NovaColors.mediumBrown, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_usePageRange ? (_pageRangeEnd - _pageRangeStart + 1) : _pageRangeEnd} Seiten · EPUB-Format',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NovaColors.mediumBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
