import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

/// Camera scanner screen with text recognition, capture, and gallery import.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCameraActive = false;
  bool _isProcessing = false;
  bool _isConverting = false;
  String _capturedText = '';
  double _conversionProgress = 0.0;
  Timer? _processingTimer;
  Timer? _conversionTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _processingTimer?.cancel();
    _conversionTimer?.cancel();
    super.dispose();
  }

  void _startCamera() {
    setState(() {
      _isCameraActive = true;
      _capturedText = '';
    });
    // Simulate camera activation
    _processingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = true;
        });
      }
    });
  }

  void _stopCamera() {
    setState(() {
      _isCameraActive = false;
      _isProcessing = false;
    });
    _processingTimer?.cancel();
  }

  void _captureImage() {
    setState(() {
      _isProcessing = true;
    });
    // Simulate text recognition
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _capturedText =
              'Dies ist ein erfasster Text aus der Kamera.\n\n'
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.\n\n'
              'Seite 1 von 3';
          _isProcessing = false;
        });
      }
    });
  }

  void _importFromGallery() {
    setState(() {
      _isProcessing = true;
    });
    // Simulate gallery import
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _capturedText =
              'Text aus der Galerie importiert.\n\n'
              'Dies ist ein Beispieltext, der aus einem Bild in der Galerie '
              'extrahiert wurde. Die Texterkennung hat folgende Zeilen gefunden:\n\n'
              '1. Erster Absatz des erkannten Textes\n'
              '2. Zweiter Absatz mit weiteren Informationen\n'
              '3. Dritter Absatz - Ende der Erkennung';
          _isProcessing = false;
        });
      }
    });
  }

  void _convertToEpub() {
    setState(() {
      _isConverting = true;
      _conversionProgress = 0.0;
    });

    _conversionTimer?.cancel();
    _conversionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _conversionProgress += 0.05;
          if (_conversionProgress >= 1.0) {
            _conversionProgress = 1.0;
            _isConverting = false;
            timer.cancel();
            _showConversionComplete();
          }
        });
      }
    });
  }

  void _showConversionComplete() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Konvertierung abgeschlossen'),
          content: const Text(
            'Das EPUB wurde erfolgreich erstellt und in Ihrer Bibliothek gespeichert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera-Scan'),
        actions: [
          if (_isCameraActive)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopCamera,
              tooltip: 'Kamera schließen',
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview area
          Expanded(
            flex: 3,
            child: _isCameraActive
                ? _buildCameraPreview(theme)
                : _buildCameraOff(theme),
          ),
          // Captured text area
          if (_capturedText.isNotEmpty)
            Expanded(
              flex: 2,
              child: _buildCapturedTextArea(theme),
            ),
          // Action buttons
          _buildActionBar(theme),
        ],
      ),
    );
  }

  Widget _buildCameraOff(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 80,
            color: NovaColors.mediumBrown.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Kamera bereit',
            style: theme.textTheme.titleLarge?.copyWith(
              color: NovaColors.mediumBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippen Sie auf Start, um Text zu scannen',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NovaColors.lightBrown,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera starten'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _importFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Aus Galerie importieren'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(ThemeData theme) {
    return Stack(
      children: [
        // Simulated camera view
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E2E2E),
                const Color(0xFF1B1B1B),
                const Color(0xFF2E2E2E),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scanning frame
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 250 * _pulseAnimation.value,
                      height: 200 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NovaColors.warmGold.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                                color: NovaColors.warmGold,
                              )
                            : const Icon(
                                Icons.text_fields,
                                size: 48,
                                color: NovaColors.warmGold,
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _isProcessing
                      ? 'Erkennung läuft...'
                      : 'Text im Rahmen platzieren',
                  style: const TextStyle(
                    color: NovaColors.paleGold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Camera controls overlay
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gallery button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NovaColors.charcoal.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.photo_library,
                      color: NovaColors.paleGold, size: 22),
                  onPressed: _importFromGallery,
                  tooltip: 'Aus Galerie',
                ),
              ),
              const SizedBox(width: 40),
              // Capture button
              GestureDetector(
                onTap: _isProcessing ? null : _captureImage,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 72 * _pulseAnimation.value,
                      height: 72 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NovaColors.paleGold,
                        border: Border.all(
                          color: NovaColors.warmWhite,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NovaColors.paleGold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: NovaColors.deepBrown,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 40),
              // Close button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NovaColors.charcoal.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: NovaColors.paleGold, size: 22),
                  onPressed: _stopCamera,
                  tooltip: 'Schließen',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedTextArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NovaColors.cream,
        border: Border(
          top: BorderSide(
            color: NovaColors.tan.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet,
                  color: NovaColors.mediumBrown, size: 20),
              const SizedBox(width: 8),
              Text(
                'Erfasster Text',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: NovaColors.deepBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_capturedText.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _capturedText = ''),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Löschen'),
                  style: TextButton.styleFrom(
                    foregroundColor: NovaColors.terracotta,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _capturedText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NovaColors.charcoal,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NovaColors.warmWhite,
        border: Border(
          top: BorderSide(
            color: NovaColors.tan.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConverting) ...[
              LinearProgressIndicator(
                value: _conversionProgress,
                backgroundColor: NovaColors.tan,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    NovaColors.warmGold),
              ),
              const SizedBox(height: 8),
              Text(
                'Konvertiere zu EPUB... ${(_conversionProgress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: NovaColors.mediumBrown,
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _capturedText.isEmpty ? null : _convertToEpub,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Zu EPUB konvertieren'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
