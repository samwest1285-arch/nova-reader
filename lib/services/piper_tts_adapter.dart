import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'piper_tts_service.dart';

/// Adapter, der die TtsService-Schnittstelle nachbildet, aber intern
/// Piper TTS (sherpa_onnx) + audioplayers nutzt — für natürliche Stimme.
class PiperTtsAdapter {
  final PiperTtsService _piper = PiperTtsService();
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  Future<bool>? _initFuture;
  double _speed = 1.0;
  bool _isPlaying = false;
  Completer<void>? _completion;

  bool get isPlaying => _isPlaying;

  /// Initialisiert Piper (lädt das deutsche Modell) — nur einmal, mit Cache.
  Future<bool> init() {
    if (_initialized) return Future.value(true);
    // Verhindert Doppel-Init (Race Condition beim schnellen Tippen auf Play)
    return _initFuture ??= _doInit();
  }

  Future<bool> _doInit() async {
    try {
      _initialized = await _piper.init();
      return _initialized;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }

  /// Setzt die Sprechgeschwindigkeit (0.5 - 2.0).
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
  }

  /// Setzt die Stimme (Piper hat nur eine deutsche Stimme, aber wir
  /// variieren die Geschwindigkeit leicht für verschiedene "Charaktere").
  Future<void> setVoiceProfile(Object profile) async {
    // Piper nutzt eine feste Stimme — hier nur Speed-Variation
  }

  /// Spricht den Text mit Piper und spielt das Audio ab.
  /// Die Synthese läuft in einem Isolate, damit der UI-Thread nicht blockiert
  /// wird (verhindert ANR/Crash bei langen Sätzen).
  Future<void> speak(String text) async {
    await stop();
    if (!_initialized) {
      final ok = await init();
      if (!ok) {
        _isPlaying = false;
        return;
      }
    }

    _isPlaying = true;
    _completion = Completer<void>();

    // Text in Sätze aufteilen und einzeln synthetisieren/abspielen
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    for (final sentence in sentences) {
      if (!_isPlaying) break;

      // Synthese im Isolate (blockiert den UI-Thread nicht)
      final samples = await synthesizeInIsolate(
        modelPath: _piper.modelPath,
        tokensPath: _piper.tokensPath,
        dataDir: _piper.dataDir,
        text: sentence,
        speed: _speed,
      );
      if (samples == null || samples.isEmpty) continue;

      // WAV in Temp-Datei schreiben und abspielen
      final dir = await getTemporaryDirectory();
      final wavPath = '${dir.path}/piper_tts_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _writeWav(samples, 22050, wavPath);

      await _player.stop();
      await _player.play(DeviceFileSource(wavPath));
      // Warten bis fertig
      await _player.onPlayerComplete.first;
      // Temp-Datei aufräumen
      try { File(wavPath).delete(); } catch (_) {}
    }

    _isPlaying = false;
    _completion?.complete();
    _completion = null;
  }

  /// Schreibt Float32-Samples als 16-bit PCM WAV-Datei.
  Future<void> _writeWav(List<double> samples, int sampleRate, String path) async {
    final bytes = ByteData(44 + samples.length * 2);
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
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    bytes.setUint32(40, samples.length * 2, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      final s = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    final file = File(path);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }

  /// Pausiert die Wiedergabe.
  Future<void> pause() async {
    if (_isPlaying) {
      _isPlaying = false;
      await _player.pause();
    }
  }

  /// Stoppt die Wiedergabe.
  Future<void> stop() async {
    _isPlaying = false;
    await _player.stop();
    if (_completion != null && !_completion!.isCompleted) {
      _completion!.complete();
    }
    _completion = null;
  }

  /// Gibt Ressourcen frei.
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    _piper.dispose();
  }
}
