import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Metadata for an EPUB book.
class EpubMetadata {
  final String title;
  final String author;
  final String? publisher;
  final String? description;
  final String? language;
  final DateTime? publicationDate;
  final List<String> subjects;
  final String? coverImagePath;

  const EpubMetadata({
    required this.title,
    required this.author,
    this.publisher,
    this.description,
    this.language = 'en',
    this.publicationDate,
    this.subjects = const [],
    this.coverImagePath,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'publisher': publisher,
        'description': description,
        'language': language,
        'publicationDate': publicationDate?.toIso8601String(),
        'subjects': subjects,
        'coverImagePath': coverImagePath,
      };
}

/// A chapter in the EPUB being generated.
class EpubChapter {
  final String title;
  final String content;
  final int level;

  const EpubChapter({
    required this.title,
    required this.content,
    this.level = 1,
  });
}

/// Result of an EPUB generation operation.
class EpubGenerationResult {
  final String filePath;
  final String title;
  final int chapterCount;
  final int totalWords;

  const EpubGenerationResult({
    required this.filePath,
    required this.title,
    required this.chapterCount,
    required this.totalWords,
  });
}

/// Result of reading an existing EPUB file.
class EpubReadResult {
  final String title;
  final String author;
  final String? coverImagePath;
  final List<EpubChapter> chapters;
  final String rawContent;

  const EpubReadResult({
    required this.title,
    required this.author,
    this.coverImagePath,
    required this.chapters,
    required this.rawContent,
  });
}

/// A comprehensive EPUB service for the Nova Reader app.
///
/// Generates EPUB files from text content, OCR text, and PDF text.
/// Reads existing EPUB files using the epubx package.
/// Supports metadata, chapter splitting, CSS styling, and cover images.
class EpubService {
  final Uuid _uuid = const Uuid();

  /// Default CSS styling for generated EPUBs.
  static const String _defaultCss = '''
@namespace epub "http://www.idpf.org/2007/ops";

body {
  font-family: Georgia, "Times New Roman", serif;
  line-height: 1.6;
  margin: 0;
  padding: 0;
  color: #333;
  background-color: #FFFBF0;
}

h1 {
  font-family: Georgia, serif;
  font-size: 1.8em;
  font-weight: bold;
  text-align: center;
  margin-top: 2em;
  margin-bottom: 1em;
  color: #3E2723;
  page-break-before: always;
}

h2 {
  font-family: Georgia, serif;
  font-size: 1.4em;
  font-weight: bold;
  margin-top: 1.5em;
  margin-bottom: 0.8em;
  color: #5D4037;
}

h3 {
  font-family: Georgia, serif;
  font-size: 1.2em;
  font-weight: bold;
  margin-top: 1.2em;
  margin-bottom: 0.6em;
  color: #795548;
}

p {
  text-indent: 1.5em;
  margin: 0.5em 0;
  text-align: justify;
}

p.first {
  text-indent: 0;
}

.chapter-title {
  text-align: center;
  font-size: 2em;
  font-weight: bold;
  margin-top: 3em;
  margin-bottom: 2em;
  color: #3E2723;
  text-indent: 0;
}

.cover-page {
  text-align: center;
  margin-top: 30%;
}

.cover-title {
  font-size: 2.5em;
  font-weight: bold;
  color: #3E2723;
  margin-bottom: 0.5em;
  text-indent: 0;
}

.cover-author {
  font-size: 1.3em;
  color: #795548;
  text-indent: 0;
}

.page-break {
  page-break-before: always;
}

.center {
  text-align: center;
  text-indent: 0;
}

.italic {
  font-style: italic;
}

.bold {
  font-weight: bold;
}
''';

  /// Generates an EPUB file from text content.
  ///
  /// [title] is the book title.
  /// [author] is the book author.
  /// [content] is the full text content.
  /// [metadata] provides additional EPUB metadata.
  /// [coverImagePath] is an optional path to a cover image.
  /// [chapterSplitPattern] is a regex pattern used to split content into chapters.
  ///   Defaults to splitting on common chapter headings.
  Future<EpubGenerationResult> generateFromText({
    required String title,
    required String author,
    required String content,
    EpubMetadata? metadata,
    String? coverImagePath,
    String chapterSplitPattern = r'(?:^|\n)(?:Chapter|CHAPTER|Ch\.|Chapter\s+\d+|CHAPTER\s+\d+|\d+\.)\s*[^\n]*',
  }) async {
    final chapters = _splitIntoChapters(content, title, chapterSplitPattern);
    return _buildEpub(
      title: title,
      author: author,
      chapters: chapters,
      metadata: metadata,
      coverImagePath: coverImagePath,
    );
  }

  /// Generates an EPUB file from OCR text (multiple pages).
  ///
  /// [title] is the book title.
  /// [author] is the book author.
  /// [pages] is a list of OCR page texts.
  /// [metadata] provides additional EPUB metadata.
  /// [coverImagePath] is an optional path to a cover image.
  Future<EpubGenerationResult> generateFromOcr({
    required String title,
    required String author,
    required List<String> pages,
    EpubMetadata? metadata,
    String? coverImagePath,
  }) async {
    // Each OCR page becomes a chapter
    final chapters = <EpubChapter>[];
    for (int i = 0; i < pages.length; i++) {
      final pageText = pages[i].trim();
      if (pageText.isNotEmpty) {
        chapters.add(EpubChapter(
          title: 'Page ${i + 1}',
          content: _wrapInParagraphs(pageText),
          level: 1,
        ));
      }
    }

    if (chapters.isEmpty) {
      chapters.add(EpubChapter(
        title: title,
        content: '<p>No content available.</p>',
      ));
    }

    return _buildEpub(
      title: title,
      author: author,
      chapters: chapters,
      metadata: metadata,
      coverImagePath: coverImagePath,
    );
  }

  /// Generates an EPUB file from PDF text content.
  ///
  /// [title] is the book title.
  /// [author] is the book author.
  /// [pdfText] is the extracted text from a PDF.
  /// [metadata] provides additional EPUB metadata.
  /// [coverImagePath] is an optional path to a cover image.
  Future<EpubGenerationResult> generateFromPdf({
    required String title,
    required String author,
    required String pdfText,
    EpubMetadata? metadata,
    String? coverImagePath,
  }) async {
    // PDF text often has page markers; try to split by pages
    final pagePattern = RegExp(r'(?:Page\s+\d+|--+\s*\d*\s*--+|\f)', multiLine: true);
    final pageTexts = pdfText.split(pagePattern).where((p) => p.trim().isNotEmpty).toList();

    if (pageTexts.length <= 1) {
      // If no clear page breaks, split by content size
      return generateFromText(
        title: title,
        author: author,
        content: pdfText,
        metadata: metadata,
        coverImagePath: coverImagePath,
      );
    }

    return generateFromOcr(
      title: title,
      author: author,
      pages: pageTexts,
      metadata: metadata,
      coverImagePath: coverImagePath,
    );
  }

  /// Reads an existing EPUB file and returns its content.
  Future<EpubReadResult> readEpub(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('EPUB file not found', filePath);
    }

    final bytes = await file.readAsBytes();
    final epubBookRef = await epubx.EpubReader.openBook(bytes);

    final title = epubBookRef.Title ?? 'Unknown Title';
    final author = (epubBookRef.AuthorList?.isNotEmpty ?? false)
        ? epubBookRef.AuthorList!.join(', ')
        : 'Unknown Author';

    // Extract cover image if available (defensive: some EPUBs have no cover).
    String? coverImagePath;
    try {
      final cover = await epubBookRef.readCover();
      if (cover != null) {
        final coverDir = await _getCoverDirectory();
        final coverFile = File('${coverDir.path}/${_uuid.v4()}.jpg');
        final encoded = cover.getBytes();
        await coverFile.writeAsBytes(encoded);
        coverImagePath = coverFile.path;
      }
    } catch (_) {
      // Cover extraction is optional
    }

    // Extract chapters
    final chapters = <EpubChapter>[];
    final contentBuffer = StringBuffer();

    final chapterRefs = await epubBookRef.getChapters();
    if (chapterRefs.isNotEmpty) {
      for (final chapterRef in chapterRefs) {
        final chapterTitle = chapterRef.Title ?? 'Untitled';
        final chapterContent = await _extractChapterContent(chapterRef);

        chapters.add(EpubChapter(
          title: chapterTitle,
          content: chapterContent,
          level: 1,
        ));

        contentBuffer.writeln('# $chapterTitle');
        contentBuffer.writeln(_stripHtml(chapterContent));
        contentBuffer.writeln();
      }
    }

    // If no chapters found, try to get all text content
    if (chapters.isEmpty) {
      final allText = await _extractAllHtml(epubBookRef.Content);
      if (allText.isNotEmpty) {
        chapters.add(EpubChapter(
          title: title,
          content: allText,
        ));
        contentBuffer.writeln(_stripHtml(allText));
      }
    }

    return EpubReadResult(
      title: title,
      author: author,
      coverImagePath: coverImagePath,
      chapters: chapters,
      rawContent: contentBuffer.toString(),
    );
  }

  /// Concatenates all HTML content files in the EPUB.
  Future<String> _extractAllHtml(Object? content) async {
    if (content == null) return '';
    final html = (content as dynamic).Html as Map<String, dynamic>?;
    if (html == null) return '';
    final buffer = StringBuffer();
    for (final file in html.values) {
      try {
        final text = await (file as dynamic).readContentAsText();
        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      } catch (_) {
        // Skip unreadable content files
      }
    }
    return buffer.toString();
  }

  /// Extracts the HTML content from an EpubChapterRef recursively.
  Future<String> _extractChapterContent(epubx.EpubChapterRef chapter) async {
    final buffer = StringBuffer();

    try {
      final content = await chapter.readHtmlContent();
      if (content.isNotEmpty) {
        buffer.writeln(content);
      }
    } catch (_) {
      // Some chapters may not have readable content
    }

    // Recursively extract sub-chapters
    if (chapter.SubChapters != null) {
      for (final sub in chapter.SubChapters!) {
        final subContent = await _extractChapterContent(sub);
        if (subContent.isNotEmpty) {
          buffer.writeln(subContent);
        }
      }
    }

    return buffer.toString();
  }

  /// Strips HTML tags from content, returning plain text.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Splits text content into chapters based on a pattern.
  List<EpubChapter> _splitIntoChapters(
    String content,
    String defaultTitle,
    String splitPattern,
  ) {
    final chapters = <EpubChapter>[];
    final regex = RegExp(splitPattern, multiLine: true);

    // Find all chapter headings
    final matches = regex.allMatches(content).toList();

    if (matches.isEmpty) {
      // No chapter headings found; treat entire content as one chapter
      chapters.add(EpubChapter(
        title: defaultTitle,
        content: _wrapInParagraphs(content),
      ));
      return chapters;
    }

    // Split content by chapter headings
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final chapterHeading = matches[i].group(0)?.trim() ?? 'Chapter ${i + 1}';
      final chapterContent = content.substring(start, end).trim();

      // Clean the chapter heading
      final cleanHeading = chapterHeading
          .replaceAll(RegExp(r'^[\s\n]+'), '')
          .replaceAll(RegExp(r'[\s\n]+$'), '');

      chapters.add(EpubChapter(
        title: cleanHeading,
        content: _wrapInParagraphs(chapterContent),
      ));
    }

    return chapters;
  }

  /// Wraps text lines in HTML paragraph tags.
  String _wrapInParagraphs(String text) {
    final lines = text.split(RegExp(r'\n\s*\n'));
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if it looks like a heading
      if (line.startsWith('#') || line.startsWith('Chapter') || line.startsWith('CHAPTER')) {
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '');
        buffer.writeln('<h2>$headingText</h2>');
      } else {
        final cssClass = i == 0 ? ' class="first"' : '';
        buffer.writeln('<p$cssClass>${_escapeHtml(line)}</p>');
      }
    }

    return buffer.toString();
  }

  /// Escapes HTML special characters.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  /// Builds the EPUB file from chapters and metadata.
  Future<EpubGenerationResult> _buildEpub({
    required String title,
    required String author,
    required List<EpubChapter> chapters,
    EpubMetadata? metadata,
    String? coverImagePath,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final epubDir = Directory('${appDir.path}/epubs');
    if (!await epubDir.exists()) {
      await epubDir.create(recursive: true);
    }

    final fileName = '${_sanitizeFileName(title)}_${_uuid.v4().substring(0, 8)}.epub';
    final filePath = '${epubDir.path}/$fileName';

    // Build the EPUB as a ZIP archive
    final archive = Archive();

    // Add mimetype file (must be first, uncompressed)
    archive.addFile(ArchiveFile('mimetype', 20, utf8.encode('application/epub+zip')));

    // Add container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // Generate content files
    final bookId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final lang = metadata?.language ?? 'en';
    final publisher = metadata?.publisher ?? 'Nova Reader';
    final description = metadata?.description ?? 'Generated by Nova Reader';

    // Build chapter XHTML files
    final chapterFiles = <String>[];
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterId = 'chapter_${i + 1}';
      final chapterFileName = '$chapterId.xhtml';
      chapterFiles.add(chapterFileName);

      final chapterXhtml = _buildChapterXhtml(chapter, chapterId, i + 1);
      archive.addFile(ArchiveFile('OEBPS/$chapterFileName', chapterXhtml.length, utf8.encode(chapterXhtml)));
    }

    // Build navigation file (toc.ncx)
    final ncxContent = _buildNcx(title, author, bookId, chapters);
    archive.addFile(ArchiveFile('OEBPS/toc.ncx', ncxContent.length, utf8.encode(ncxContent)));

    // Build navigation document (nav.xhtml)
    final navXhtml = _buildNavXhtml(title, chapters);
    archive.addFile(ArchiveFile('OEBPS/nav.xhtml', navXhtml.length, utf8.encode(navXhtml)));

    // Build CSS
    archive.addFile(ArchiveFile('OEBPS/styles.css', _defaultCss.length, utf8.encode(_defaultCss)));

    // Build content.opf
    final opfContent = _buildOpf(
      title: title,
      author: author,
      bookId: bookId,
      lang: lang,
      publisher: publisher,
      description: description,
      now: now,
      chapterFiles: chapterFiles,
      chapters: chapters,
      coverImagePath: coverImagePath,
    );
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfContent.length, utf8.encode(opfContent)));

    // Add cover image if provided
    if (coverImagePath != null) {
      final coverFile = File(coverImagePath);
      if (await coverFile.exists()) {
        final coverBytes = await coverFile.readAsBytes();
        final ext = coverImagePath.endsWith('.png') ? 'png' : 'jpg';
        archive.addFile(ArchiveFile('OEBPS/cover.$ext', coverBytes.length, coverBytes));
      }
    }

    // Write the ZIP archive to disk
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw Exception('Failed to encode EPUB archive');
    }

    final outputFile = File(filePath);
    await outputFile.writeAsBytes(encoded);

    // Count total words
    int totalWords = 0;
    for (final chapter in chapters) {
      totalWords += _stripHtml(chapter.content).split(RegExp(r'\s+')).length;
    }

    return EpubGenerationResult(
      filePath: filePath,
      title: title,
      chapterCount: chapters.length,
      totalWords: totalWords,
    );
  }

  /// Builds an XHTML file for a single chapter.
  String _buildChapterXhtml(EpubChapter chapter, String chapterId, int chapterNumber) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <title>${_escapeHtml(chapter.title)}</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
  <h1 class="chapter-title">${_escapeHtml(chapter.title)}</h1>
  ${chapter.content}
</body>
</html>''';
  }

  /// Builds the NCX navigation file.
  String _buildNcx(String title, String author, String bookId, List<EpubChapter> chapters) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">');
    buffer.writeln('<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
    buffer.writeln('  <head>');
    buffer.writeln('    <meta name="dtb:uid" content="$bookId"/>');
    buffer.writeln('    <meta name="dtb:depth" content="1"/>');
    buffer.writeln('    <meta name="dtb:totalPageCount" content="0"/>');
    buffer.writeln('    <meta name="dtb:maxPageNumber" content="0"/>');
    buffer.writeln('  </head>');
    buffer.writeln('  <docTitle><text>${_escapeHtml(title)}</text></docTitle>');
    buffer.writeln('  <docAuthor><text>${_escapeHtml(author)}</text></docAuthor>');
    buffer.writeln('  <navMap>');

    for (int i = 0; i < chapters.length; i++) {
      final playOrder = i + 1;
      buffer.writeln('    <navPoint id="chapter_${i + 1}" playOrder="$playOrder">');
      buffer.writeln('      <navLabel><text>${_escapeHtml(chapters[i].title)}</text></navLabel>');
      buffer.writeln('      <content src="chapter_${i + 1}.xhtml"/>');
      buffer.writeln('    </navPoint>');
    }

    buffer.writeln('  </navMap>');
    buffer.writeln('</ncx>');
    return buffer.toString();
  }

  /// Builds the navigation XHTML document.
  String _buildNavXhtml(String title, List<EpubChapter> chapters) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>${_escapeHtml(title)}</title>');
    buffer.writeln('  <link rel="stylesheet" type="text/css" href="styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <nav epub:type="toc">');
    buffer.writeln('    <h1>Table of Contents</h1>');
    buffer.writeln('    <ol>');

    for (int i = 0; i < chapters.length; i++) {
      buffer.writeln('      <li><a href="chapter_${i + 1}.xhtml">${_escapeHtml(chapters[i].title)}</a></li>');
    }

    buffer.writeln('    </ol>');
    buffer.writeln('  </nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  /// Builds the content.opf file.
  String _buildOpf({
    required String title,
    required String author,
    required String bookId,
    required String lang,
    required String publisher,
    required String description,
    required String now,
    required List<String> chapterFiles,
    required List<EpubChapter> chapters,
    String? coverImagePath,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="BookId">');
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">');
    buffer.writeln('    <dc:identifier id="BookId">urn:uuid:$bookId</dc:identifier>');
    buffer.writeln('    <dc:title>${_escapeHtml(title)}</dc:title>');
    buffer.writeln('    <dc:creator>${_escapeHtml(author)}</dc:creator>');
    buffer.writeln('    <dc:language>$lang</dc:language>');
    buffer.writeln('    <dc:publisher>${_escapeHtml(publisher)}</dc:publisher>');
    buffer.writeln('    <dc:description>${_escapeHtml(description)}</dc:description>');
    buffer.writeln('    <dc:date>$now</dc:date>');
    buffer.writeln('    <meta name="cover" content="cover-image"/>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <manifest>');

    // Add CSS
    buffer.writeln('    <item id="css" href="styles.css" media-type="text/css"/>');

    // Add NCX
    buffer.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');

    // Add NAV
    buffer.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');

    // Add cover image
    if (coverImagePath != null) {
      final ext = coverImagePath.endsWith('.png') ? 'png' : 'jpg';
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      buffer.writeln('    <item id="cover-image" href="cover.$ext" media-type="$mimeType"/>');
    }

    // Add chapters
    for (int i = 0; i < chapterFiles.length; i++) {
      buffer.writeln('    <item id="chapter_${i + 1}" href="${chapterFiles[i]}" media-type="application/xhtml+xml"/>');
    }

    buffer.writeln('  </manifest>');
    buffer.writeln('  <spine toc="ncx">');

    for (int i = 0; i < chapterFiles.length; i++) {
      buffer.writeln('    <itemref idref="chapter_${i + 1}"/>');
    }

    buffer.writeln('  </spine>');
    buffer.writeln('  <guide>');
    buffer.writeln('    <reference type="toc" title="Table of Contents" href="nav.xhtml"/>');

    if (coverImagePath != null) {
      buffer.writeln('    <reference type="cover" title="Cover" href="cover.${coverImagePath.endsWith('.png') ? 'png' : 'jpg'}"/>');
    }

    buffer.writeln('  </guide>');
    buffer.writeln('</package>');
    return buffer.toString();
  }

  /// Gets the directory for storing cover images.
  Future<Directory> _getCoverDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory('${appDir.path}/covers');
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }
    return coverDir;
  }

  /// Sanitizes a string for use as a file name.
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase()
        .substring(0, name.length.clamp(1, 50));
  }

  /// Lists all EPUB files in the app's documents directory.
  Future<List<String>> listEpubFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final epubDir = Directory('${appDir.path}/epubs');
    if (!await epubDir.exists()) {
      return [];
    }

    final files = await epubDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.epub'))
        .map((f) => f.path)
        .toList();
  }

  /// Deletes an EPUB file.
  Future<bool> deleteEpub(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
