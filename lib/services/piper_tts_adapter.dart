import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'piper_tts_service.dart';

/// Adapter, der die TtsService-Schnittstelle nachbildet, aber intern
/// Piper TTS (sherpa_onnx) + audioplayers nutzt — für natürliche Stimme.
class PiperTtsAdapter {
  final PiperTtsService _piper = PiperTtsService();
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  double _speed = 1.0;
  bool _isPlaying = false;
  Completer<void>? _completion;

  bool get isPlaying => _isPlaying;

  /// Initialisiert Piper (lädt das deutsche Modell).
  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _piper.init();
    return _initialized;
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
      final audio = _piper.synthesize(sentence, speed: _speed);
      if (audio == null || audio.samples.isEmpty) continue;

      // WAV in Temp-Datei schreiben und abspielen
      final dir = await getTemporaryDirectory();
      final wavPath = '${dir.path}/piper_tts_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _piper.saveWav(audio, wavPath);

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
