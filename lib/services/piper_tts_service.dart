import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Piper TTS via sherpa_onnx — lokales, neuronales TTS mit natürlicher
/// deutscher Stimme (Thorsten). Läuft komplett offline, kostenlos.
class PiperTtsService {
  OfflineTts? _tts;
  bool _initialized = false;
  String? _error;
  String _modelPath = '';
  String _tokensPath = '';
  String _dataDir = '';

  bool get isInitialized => _initialized;
  String? get error => _error;
  String get modelPath => _modelPath;
  String get tokensPath => _tokensPath;
  String get dataDir => _dataDir;

  /// Kopiert die Modell-Dateien aus den Assets in den App-Speicher.
  Future<String> _copyAssetToFile(String assetPath, String destPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final file = File(destPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
    return destPath;
  }

  /// Initialisiert Piper TTS (lädt das deutsche Modell).
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      final dir = await getApplicationSupportDirectory();
      final piperDir = Directory('${dir.path}/piper');
      await piperDir.create(recursive: true);

      // Modell + Tokens kopieren
      final modelPath = await _copyAssetToFile(
        'assets/piper/de_DE-thorsten-medium.onnx',
        '${piperDir.path}/de_DE-thorsten-medium.onnx',
      );
      final tokensPath = await _copyAssetToFile(
        'assets/piper/tokens.txt',
        '${piperDir.path}/tokens.txt',
      );
      _modelPath = modelPath;
      _tokensPath = tokensPath;

      // espeak-ng-Daten kopieren
      final espeakDir = Directory('${piperDir.path}/espeak-ng-data');
      await espeakDir.create(recursive: true);
      final espeakFiles = [
        'de_dict', 'phontab', 'phondata', 'phondata-manifest',
        'phonindex', 'intonations',
      ];
      for (final f in espeakFiles) {
        await _copyAssetToFile(
          'assets/piper/espeak-ng-data/$f',
          '${espeakDir.path}/$f',
        );
      }
      // lang/gmw/de
      final langDir = Directory('${espeakDir.path}/lang/gmw');
      await langDir.create(recursive: true);
      await _copyAssetToFile(
        'assets/piper/espeak-ng-data/lang/gmw/de',
        '${langDir.path}/de',
      );
      // voices/de
      final voicesDir = Directory('${espeakDir.path}/voices');
      await voicesDir.create(recursive: true);
      await _copyAssetToFile(
        'assets/piper/espeak-ng-data/voices/de',
        '${voicesDir.path}/de',
      );
      _dataDir = espeakDir.path;

      // sherpa_onnx initialisieren
      initBindings();

      // TTS-Engine erstellen
      _tts = OfflineTts(OfflineTtsConfig(
        model: OfflineTtsModelConfig(
          vits: OfflineTtsVitsModelConfig(
            model: modelPath,
            tokens: tokensPath,
            dataDir: espeakDir.path,
            lengthScale: 1.0,
          ),
        ),
      ));

      _initialized = true;
      return true;
    } catch (e) {
      _error = 'Piper init fehlgeschlagen: $e';
      return false;
    }
  }

  /// Synthetisiert Text zu Audio und gibt die Samples zurück.
  GeneratedAudio? synthesize(String text, {double speed = 1.0}) {
    if (_tts == null) return null;
    try {
      return _tts!.generate(text: text, speed: speed);
    } catch (e) {
      _error = 'Synthese fehlgeschlagen: $e';
      return null;
    }
  }

  /// Konvertiert Float32-Samples in 16-bit PCM-WAV-Datei.
  Future<File> saveWav(GeneratedAudio audio, String path) async {
    final samples = audio.samples;
    final sampleRate = audio.sampleRate;
    final bytes = ByteData(44 + samples.length * 2);

    // WAV-Header
    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }
    writeString(0, 'RIFF');
    bytes.setUint32(4, 36 + samples.length * 2, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    bytes.setUint32(40, samples.length * 2, Endian.little);

    // PCM-Daten
    for (int i = 0; i < samples.length; i++) {
      final s = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }

    final file = File(path);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }

  void dispose() {
    _tts?.free();
    _tts = null;
    _initialized = false;
  }
}

/// Führt die Piper-Synthese in einem separaten Isolate aus, damit der
/// UI-Thread nicht blockiert wird (verhindert ANR/Crash bei langen Sätzen).
/// Gibt [samples, sampleRate] zurück oder null bei Fehler.
Future<List<double>?> synthesizeInIsolate({
  required String modelPath,
  required String tokensPath,
  required String dataDir,
  required String text,
  required double speed,
}) {
  return Isolate.run(() {
    try {
      initBindings();
      final tts = OfflineTts(OfflineTtsConfig(
        model: OfflineTtsModelConfig(
          vits: OfflineTtsVitsModelConfig(
            model: modelPath,
            tokens: tokensPath,
            dataDir: dataDir,
            lengthScale: 1.0,
          ),
        ),
      ));
      final audio = tts.generate(text: text, speed: speed);
      tts.free();
      if (audio.samples.isEmpty) return null;
      return audio.samples.toList();
    } catch (e) {
      return null;
    }
  });
}
