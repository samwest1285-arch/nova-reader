import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of an OCR operation on a single page.
class OcrPageResult {
  /// The raw recognized text.
  final String rawText;

  /// The cleaned and formatted text.
  final String cleanedText;

  /// Detected language code (e.g., 'en', 'fr').
  final String detectedLanguage;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Page number (1-indexed).
  final int pageNumber;

  /// Bounding boxes of recognized text blocks.
  final List<Rect> textBlocks;

  const OcrPageResult({
    required this.rawText,
    required this.cleanedText,
    required this.detectedLanguage,
    required this.confidence,
    required this.pageNumber,
    this.textBlocks = const [],
  });
}

/// Result of a multi-page OCR operation.
class OcrResult {
  /// Results for each page.
  final List<OcrPageResult> pages;

  /// Combined text from all pages.
  final String combinedText;

  /// Total number of pages processed.
  final int pageCount;

  /// Overall confidence.
  final double overallConfidence;

  const OcrResult({
    required this.pages,
    required this.combinedText,
    required this.pageCount,
    required this.overallConfidence,
  });
}

/// Configuration for the OCR service.
class OcrConfig {
  /// Whether to enable language detection.
  final bool enableLanguageDetection;

  /// Whether to clean and format the recognized text.
  final bool enableTextCleaning;

  /// Whether to detect page boundaries automatically.
  final bool autoPageDetection;

  /// Minimum confidence threshold for text recognition (0.0 - 1.0).
  final double confidenceThreshold;

  /// The text recognition script to use.
  final TextRecognitionScript script;

  const OcrConfig({
    this.enableLanguageDetection = true,
    this.enableTextCleaning = true,
    this.autoPageDetection = true,
    this.confidenceThreshold = 0.3,
    this.script = TextRecognitionScript.latin,
  });
}

/// A comprehensive OCR service for the Nova Reader app.
///
/// Uses Google ML Kit Text Recognition to process camera images and image files
/// into text. Supports language detection, text cleaning, and page detection
/// for multi-page documents.
class OcrService {
  final OcrConfig _config;
  late TextRecognizer _recognizer;

  OcrService({OcrConfig? config})
      : _config = config ?? const OcrConfig() {
    _recognizer = TextRecognizer(script: _config.script);
  }

  /// Updates the OCR configuration.
  void updateConfig(OcrConfig config) {
    _recognizer.close();
    _recognizer = TextRecognizer(script: config.script);
  }

  /// Processes a camera image (as [InputImage]) and returns recognized text.
  ///
  /// [inputImage] should be created from a camera frame.
  /// [pageNumber] is the page number for this image (1-indexed).
  Future<OcrPageResult> processCameraImage({
    required InputImage inputImage,
    int pageNumber = 1,
  }) async {
    try {
      final recognizedText = await _recognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final blocks = recognizedText.blocks;

      // Calculate confidence
      double totalConfidence = 0;
      int confidenceCount = 0;
      final List<Rect> textBlocks = [];

      for (final block in blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            totalConfidence += element.confidence;
            confidenceCount++;
          }
        }
        textBlocks.add(block.boundingBox);
      }

      final confidence = confidenceCount > 0
          ? totalConfidence / confidenceCount
          : 0.0;

      // Detect language
      String detectedLanguage = 'en';
      if (_config.enableLanguageDetection) {
        detectedLanguage = _detectLanguage(rawText);
      }

      // Clean text
      String cleanedText = rawText;
      if (_config.enableTextCleaning) {
        cleanedText = _cleanText(rawText);
      }

      return OcrPageResult(
        rawText: rawText,
        cleanedText: cleanedText,
        detectedLanguage: detectedLanguage,
        confidence: confidence,
        pageNumber: pageNumber,
        textBlocks: textBlocks,
      );
    } catch (e) {
      return OcrPageResult(
        rawText: '',
        cleanedText: '',
        detectedLanguage: 'en',
        confidence: 0.0,
        pageNumber: pageNumber,
      );
    }
  }

  /// Processes an image file and returns recognized text.
  ///
  /// [imagePath] is the path to the image file.
  /// [pageNumber] is the page number for this image (1-indexed).
  Future<OcrPageResult> processImageFile({
    required String imagePath,
    int pageNumber = 1,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return OcrPageResult(
          rawText: '',
          cleanedText: '',
          detectedLanguage: 'en',
          confidence: 0.0,
          pageNumber: pageNumber,
        );
      }

      final inputImage = InputImage.fromFile(file);
      return await processCameraImage(
        inputImage: inputImage,
        pageNumber: pageNumber,
      );
    } catch (e) {
      return OcrPageResult(
        rawText: '',
        cleanedText: '',
        detectedLanguage: 'en',
        confidence: 0.0,
        pageNumber: pageNumber,
      );
    }
  }

  /// Processes an image from bytes (e.g., from camera) and returns recognized text.
  ///
  /// [bytes] is the raw image data.
  /// [metadata] contains image dimensions and rotation.
  /// [pageNumber] is the page number for this image (1-indexed).
  Future<OcrPageResult> processImageBytes({
    required Uint8List bytes,
    required InputImageMetadata metadata,
    int pageNumber = 1,
  }) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      return await processCameraImage(
        inputImage: inputImage,
        pageNumber: pageNumber,
      );
    } catch (e) {
      return OcrPageResult(
        rawText: '',
        cleanedText: '',
        detectedLanguage: 'en',
        confidence: 0.0,
        pageNumber: pageNumber,
      );
    }
  }

  /// Processes multiple images and returns a combined result with page detection.
  ///
  /// [imagePaths] is a list of paths to image files.
  /// [autoDetectPages] if true, attempts to detect page boundaries automatically.
  Future<OcrResult> processMultipleImages({
    required List<String> imagePaths,
    bool? autoDetectPages,
  }) async {
    final detectPages = autoDetectPages ?? _config.autoPageDetection;
    final List<OcrPageResult> pages = [];
    double totalConfidence = 0;

    for (int i = 0; i < imagePaths.length; i++) {
      final result = await processImageFile(
        imagePath: imagePaths[i],
        pageNumber: i + 1,
      );
      pages.add(result);
      totalConfidence += result.confidence;
    }

    // If auto-detecting pages, try to split pages that contain multiple columns
    List<OcrPageResult> finalPages = pages;
    if (detectPages) {
      finalPages = _detectPages(pages);
    }

    // Combine all text
    final combinedText = finalPages
        .map((p) => p.cleanedText)
        .where((t) => t.isNotEmpty)
        .join('\n\n--- Page Break ---\n\n');

    return OcrResult(
      pages: finalPages,
      combinedText: combinedText,
      pageCount: finalPages.length,
      overallConfidence: finalPages.isNotEmpty
          ? totalConfidence / finalPages.length
          : 0.0,
    );
  }

  /// Processes multiple byte arrays (from camera frames) and returns combined result.
  Future<OcrResult> processMultipleByteImages({
    required List<Uint8List> imageBytesList,
    required InputImageMetadata metadata,
    bool? autoDetectPages,
  }) async {
    final detectPages = autoDetectPages ?? _config.autoPageDetection;
    final List<OcrPageResult> pages = [];
    double totalConfidence = 0;

    for (int i = 0; i < imageBytesList.length; i++) {
      final result = await processImageBytes(
        bytes: imageBytesList[i],
        metadata: metadata,
        pageNumber: i + 1,
      );
      pages.add(result);
      totalConfidence += result.confidence;
    }

    List<OcrPageResult> finalPages = pages;
    if (detectPages) {
      finalPages = _detectPages(pages);
    }

    final combinedText = finalPages
        .map((p) => p.cleanedText)
        .where((t) => t.isNotEmpty)
        .join('\n\n--- Page Break ---\n\n');

    return OcrResult(
      pages: finalPages,
      combinedText: combinedText,
      pageCount: finalPages.length,
      overallConfidence: finalPages.isNotEmpty
          ? totalConfidence / finalPages.length
          : 0.0,
    );
  }

  /// Detects language from text content using character frequency analysis.
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    // Simple character frequency-based detection for common languages
    final textLower = text.toLowerCase();
    final length = textLower.length;
    if (length == 0) return 'en';

    // Count language-specific character frequencies
    int enScore = 0;
    int frScore = 0;
    int deScore = 0;
    int esScore = 0;

    for (int i = 0; i < textLower.length && i < 500; i++) {
      final char = textLower[i];
      switch (char) {
        case 'a':
        case 'e':
        case 't':
        case 'o':
        case 'n':
          enScore++;
          break;
        case 'é':
        case 'è':
        case 'ê':
        case 'à':
        case 'ù':
        case 'ç':
          frScore += 3;
          break;
        case 'ä':
        case 'ö':
        case 'ü':
        case 'ß':
          deScore += 3;
          break;
        case 'ñ':
        case 'ó':
        case 'í':
        case 'ú':
          esScore += 3;
          break;
      }
    }

    // Also check common words
    if (textLower.contains(' the ') || textLower.contains(' and ')) enScore += 2;
    if (textLower.contains(' le ') || textLower.contains(' la ') || textLower.contains(' les ')) frScore += 2;
    if (textLower.contains(' der ') || textLower.contains(' die ') || textLower.contains(' das ')) deScore += 2;
    if (textLower.contains(' el ') || textLower.contains(' la ') || textLower.contains(' los ')) esScore += 2;

    // Return the language with the highest score
    final scores = {
      'en': enScore,
      'fr': frScore,
      'de': deScore,
      'es': esScore,
    };

    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Cleans and formats recognized text.
  String _cleanText(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Fix common OCR artifacts
    cleaned = cleaned.replaceAll('|', 'I');
    cleaned = cleaned.replaceAll('0', 'O'); // Common in some fonts
    cleaned = cleaned.replaceAll(RegExp(r'[«»""]'), '"');

    // Remove stray punctuation at line starts
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-\*•·]\s*'), '');

    // Fix spacing around punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\s+([.,!?;:])'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'([.,!?;:])(\w)'), r'$1 $2');

    // Remove non-printable characters
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E\xA0-\xFF\u0100-\uFFFF]'), '');

    // Normalize line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Capitalize first letter of sentences
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?:^|\.\s+)([a-z])'),
      (match) => match.group(0)!.toUpperCase(),
    );

    return cleaned.trim();
  }

  /// Attempts to detect page boundaries in a list of OCR results.
  ///
  /// This is a heuristic approach that looks for gaps, headers, and page numbers
  /// to split content into logical pages.
  List<OcrPageResult> _detectPages(List<OcrPageResult> pages) {
    if (pages.length <= 1) return pages;

    final List<OcrPageResult> detectedPages = [];

    for (final page in pages) {
      // If the page has very high confidence and substantial text, keep it as-is
      if (page.confidence > 0.7 && page.rawText.length > 200) {
        detectedPages.add(page);
        continue;
      }

      // Try to split by common page markers
      final text = page.rawText;
      final pageMarkers = [
        RegExp(r'---+\s*\d*\s*---*'),
        RegExp(r'Page\s+\d+'),
        RegExp(r'^\d+\s*$', multiLine: true),
        RegExp(r'\[Page\s+\d+\]'),
      ];

      List<String> segments = [text];
      for (final marker in pageMarkers) {
        final newSegments = <String>[];
        for (final segment in segments) {
          final parts = segment.split(marker);
          newSegments.addAll(parts.where((p) => p.trim().isNotEmpty));
        }
        if (newSegments.length > 1) {
          segments = newSegments;
          break;
        }
      }

      // If we found multiple segments, create separate pages
      if (segments.length > 1) {
        for (int i = 0; i < segments.length; i++) {
          final cleaned = _cleanText(segments[i]);
          if (cleaned.isNotEmpty) {
            detectedPages.add(OcrPageResult(
              rawText: segments[i],
              cleanedText: cleaned,
              detectedLanguage: page.detectedLanguage,
              confidence: page.confidence,
              pageNumber: detectedPages.length + 1,
            ));
          }
        }
      } else {
        detectedPages.add(page);
      }
    }

    return detectedPages;
  }

  /// Releases the recognizer resources.
  void dispose() {
    _recognizer.close();
  }
}
