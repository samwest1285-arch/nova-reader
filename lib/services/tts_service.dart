import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// A voice profile for the TTS service.
class VoiceProfile {
  final String name;
  final String language;
  final String voiceId;
  final double defaultSpeed;
  final double defaultPitch;

  const VoiceProfile({
    required this.name,
    required this.language,
    required this.voiceId,
    this.defaultSpeed = 1.0,
    this.defaultPitch = 1.0,
  });

  /// The narrator voice — warm and clear, slow and natural.
  static const narrator = VoiceProfile(
    name: 'Narrator',
    language: 'de-DE',
    voiceId: '',
    defaultSpeed: 0.5,
    defaultPitch: 1.0,
  );

  /// A character voice for older, wise characters.
  static const character1 = VoiceProfile(
    name: 'Wise Sage',
    language: 'de-DE',
    voiceId: '',
    defaultSpeed: 0.45,
    defaultPitch: 0.8,
  );

  /// A character voice for younger, energetic characters.
  static const character2 = VoiceProfile(
    name: 'Young Adventurer',
    language: 'de-DE',
    voiceId: '',
    defaultSpeed: 0.55,
    defaultPitch: 1.3,
  );

  /// A character voice for mysterious characters.
  static const character3 = VoiceProfile(
    name: 'Mysterious Stranger',
    language: 'de-DE',
    voiceId: '',
    defaultSpeed: 0.4,
    defaultPitch: 0.6,
  );

  /// A character voice for cheerful characters.
  static const character4 = VoiceProfile(
    name: 'Cheerful Friend',
    language: 'de-DE',
    voiceId: '',
    defaultSpeed: 0.55,
    defaultPitch: 1.2,
  );

  /// All available voice profiles.
  static const List<VoiceProfile> all = [
    narrator,
    character1,
    character2,
    character3,
    character4,
  ];

  /// Find a voice profile by name.
  static VoiceProfile? byName(String name) {
    try {
      return all.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }
}

/// A segment of text to be spoken, with optional voice profile override.
class TtsSegment {
  final String text;
  final VoiceProfile? voiceProfile;
  final double? speedOverride;
  final double? pitchOverride;

  const TtsSegment({
    required this.text,
    this.voiceProfile,
    this.speedOverride,
    this.pitchOverride,
  });
}

/// A chapter in the TTS queue.
class TtsChapter {
  final String title;
  final List<TtsSegment> segments;
  final int index;

  const TtsChapter({
    required this.title,
    required this.segments,
    required this.index,
  });
}

/// Tracks the current word being spoken for visual highlighting.
class WordPosition {
  final String word;
  final int startIndex;
  final int endIndex;

  const WordPosition({
    required this.word,
    required this.startIndex,
    required this.endIndex,
  });
}

/// State of the TTS service.
enum TtsState { stopped, playing, paused }

/// Callback types for TTS events.
typedef OnWordCallback = void Function(WordPosition position);
typedef OnChapterCallback = void Function(int chapterIndex);
typedef OnStateChangeCallback = void Function(TtsState state);
typedef OnErrorCallback = void Function(String message);

/// A comprehensive text-to-speech service for the Nova Reader app.
///
/// Supports multiple voice profiles, speed/pitch control, SSML for character
/// voices, word tracking for visual highlighting, and chapter queue management.
class TtsService {
  final FlutterTts _flutterTts;
  TtsState _state = TtsState.stopped;
  VoiceProfile _currentProfile = VoiceProfile.narrator;
  double _speed = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  // Chapter queue
  final List<TtsChapter> _chapterQueue = [];
  int _currentChapterIndex = -1;

  // Current text being spoken
  String _currentText = '';
  List<String> _words = [];
  int _currentWordIndex = -1;

  // Callbacks
  OnWordCallback? onWord;
  OnChapterCallback? onChapterStart;
  OnChapterCallback? onChapterEnd;
  OnStateChangeCallback? onStateChange;
  OnErrorCallback? onError;

  // Completer for when speech finishes
  Completer<void>? _speechCompleter;

  TtsService() : _flutterTts = FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_currentProfile.language);
    // Langsamere, natürlichere Standard-Sprachrate
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);

    // Set up word boundary callback
    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (word.isNotEmpty) {
        _currentWordIndex = _words.indexOf(word);
        onWord?.call(WordPosition(
          word: word,
          startIndex: startOffset,
          endIndex: endOffset,
        ));
      }
    });

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      _onSegmentComplete();
    });

    // Set up error handler
    _flutterTts.setErrorHandler((message) {
      _state = TtsState.stopped;
      onStateChange?.call(_state);
      onError?.call(message);
      _speechCompleter?.complete();
    });

    // Set up cancel handler
    _flutterTts.setCancelHandler(() {
      _state = TtsState.stopped;
      onStateChange?.call(_state);
      _speechCompleter?.complete();
    });
  }

  /// Returns the current TTS state.
  TtsState get state => _state;

  /// Returns the current voice profile.
  VoiceProfile get currentProfile => _currentProfile;

  /// Returns the current speech speed.
  double get speed => _speed;

  /// Returns the current speech pitch.
  double get pitch => _pitch;

  /// Returns the current volume.
  double get volume => _volume;

  /// Returns the current chapter index in the queue.
  int get currentChapterIndex => _currentChapterIndex;

  /// Returns the total number of chapters in the queue.
  int get chapterCount => _chapterQueue.length;

  /// Returns the current chapter, if any.
  TtsChapter? get currentChapter {
    if (_currentChapterIndex >= 0 && _currentChapterIndex < _chapterQueue.length) {
      return _chapterQueue[_currentChapterIndex];
    }
    return null;
  }

  /// Returns the current word index for visual highlighting.
  int get currentWordIndex => _currentWordIndex;

  /// Returns the list of words in the current text.
  List<String> get currentWords => _words;

  /// Sets the voice profile.
  Future<void> setVoiceProfile(VoiceProfile profile) async {
    _currentProfile = profile;
    await _flutterTts.setLanguage(profile.language);
    if (profile.voiceId.isNotEmpty) {
      await _flutterTts.setVoice({'name': profile.voiceId, 'locale': profile.language});
    }
    if (profile.defaultSpeed != 1.0) {
      await setSpeed(profile.defaultSpeed);
    }
    if (profile.defaultPitch != 1.0) {
      await setPitch(profile.defaultPitch);
    }
  }

  /// Loads the available system voices and picks the best German ones.
  /// This makes the TTS sound more natural by using real system voices
  /// instead of just pitch/speed variations.
  Future<List<dynamic>> loadAndSelectGermanVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        // Find German voices
        final germanVoices = voices.where((v) {
          final name = (v is Map ? v['name']?.toString() ?? '' : v.toString()).toLowerCase();
          final locale = (v is Map ? v['locale']?.toString() ?? '' : '').toLowerCase();
          return name.contains('de') || locale.contains('de') || name.contains('german');
        }).toList();

        if (germanVoices.isNotEmpty) {
          // Use the first German voice as the default narrator
          final firstVoice = germanVoices.first;
          if (firstVoice is Map) {
            final voiceMap = <String, String>{
              for (final entry in firstVoice.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            };
            if (voiceMap.isNotEmpty) {
              await _flutterTts.setVoice(voiceMap);
            }
          }
        }
      }
      return voices;
    } catch (e) {
      debugPrint('Voice loading error: $e');
      return [];
    }
  }

  /// Sets the speech speed (0.25 - 2.0).
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.25, 2.0);
    await _flutterTts.setSpeechRate(_speed);
  }

  /// Sets the speech pitch (0.5 - 2.0).
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  /// Sets the volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  /// Speaks a single string of text.
  Future<void> speak(String text) async {
    await stop();
    _currentText = text;
    _words = text.split(RegExp(r'\s+'));
    _currentWordIndex = -1;
    _state = TtsState.playing;
    onStateChange?.call(_state);

    _speechCompleter = Completer<void>();
    // Natürliche Pausen bei Satzzeichen einfügen
    final naturalText = _addNaturalPauses(text);
    await _flutterTts.speak(naturalText);
    return _speechCompleter!.future;
  }

  /// Adds natural pauses (SSML break tags) after sentence punctuation.
  String _addNaturalPauses(String text) {
    // Ersetze Satzenden durch SSML-Pausen für natürlicheren Rhythmus
    return text
        .replaceAll('. ', '.<break time="400ms"/> ')
        .replaceAll('! ', '!<break time="500ms"/> ')
        .replaceAll('? ', '?<break time="500ms"/> ')
        .replaceAll(', ', ',<break time="200ms"/> ')
        .replaceAll('.\n', '.<break time="600ms"/>\n')
        .replaceAll('.\n\n', '.<break time="800ms"/>\n\n');
  }

  /// Speaks a list of segments, each potentially with a different voice profile.
  Future<void> speakSegments(List<TtsSegment> segments) async {
    await stop();
    _state = TtsState.playing;
    onStateChange?.call(_state);

    for (int i = 0; i < segments.length; i++) {
      if (_state == TtsState.stopped) break;

      final segment = segments[i];

      // Apply voice profile if specified
      if (segment.voiceProfile != null) {
        await setVoiceProfile(segment.voiceProfile!);
      }
      if (segment.speedOverride != null) {
        await setSpeed(segment.speedOverride!);
      }
      if (segment.pitchOverride != null) {
        await setPitch(segment.pitchOverride!);
      }

      // Build SSML if voice profile is set
      String textToSpeak = segment.text;
      if (segment.voiceProfile != null) {
        textToSpeak = _buildSsml(segment.text, segment.voiceProfile!);
      }

      _currentText = segment.text;
      _words = segment.text.split(RegExp(r'\s+'));
      _currentWordIndex = -1;

      _speechCompleter = Completer<void>();
      await _flutterTts.speak(textToSpeak);
      await _speechCompleter!.future;
    }

    _state = TtsState.stopped;
    onStateChange?.call(_state);
  }

  /// Builds SSML markup for a character voice.
  String _buildSsml(String text, VoiceProfile profile) {
    final pitchStr = _pitch.toStringAsFixed(1);
    final rateStr = _speed.toStringAsFixed(1);

    return '''
<speak>
  <voice name="${profile.voiceId}">
    <prosody pitch="$pitchStr" rate="$rateStr">
      $text
    </prosody>
  </voice>
</speak>
''';
  }

  /// Pauses the current speech.
  Future<void> pause() async {
    if (_state == TtsState.playing) {
      _state = TtsState.paused;
      onStateChange?.call(_state);
      await _flutterTts.pause();
    }
  }

  /// Resumes the current speech.
  Future<void> resume() async {
    if (_state == TtsState.paused) {
      _state = TtsState.playing;
      onStateChange?.call(_state);
      await _flutterTts.speak('');
      // Re-speak from current position
      if (_currentText.isNotEmpty) {
        await _flutterTts.speak(_currentText);
      }
    }
  }

  /// Stops the current speech and clears the queue.
  Future<void> stop() async {
    _state = TtsState.stopped;
    onStateChange?.call(_state);
    await _flutterTts.stop();
    _speechCompleter?.complete();
    _speechCompleter = null;
  }

  /// Seeks to a specific word index in the current text.
  Future<void> seekToWord(int wordIndex) async {
    if (wordIndex < 0 || wordIndex >= _words.length) return;

    // Rebuild text from the target word onward
    final text = _words.sublist(wordIndex).join(' ');
    _currentWordIndex = wordIndex - 1;
    await speak(text);
  }

  // --- Chapter Queue Management ---

  /// Loads chapters into the queue.
  void loadChapters(List<TtsChapter> chapters) {
    _chapterQueue.clear();
    _chapterQueue.addAll(chapters);
    _currentChapterIndex = -1;
  }

  /// Adds a chapter to the end of the queue.
  void addChapter(TtsChapter chapter) {
    _chapterQueue.add(chapter);
  }

  /// Removes a chapter from the queue by index.
  void removeChapter(int index) {
    if (index >= 0 && index < _chapterQueue.length) {
      _chapterQueue.removeAt(index);
      if (_currentChapterIndex >= index) {
        _currentChapterIndex--;
      }
    }
  }

  /// Clears the chapter queue.
  void clearQueue() {
    _chapterQueue.clear();
    _currentChapterIndex = -1;
  }

  /// Plays a specific chapter from the queue.
  Future<void> playChapter(int index) async {
    if (index < 0 || index >= _chapterQueue.length) return;

    await stop();
    _currentChapterIndex = index;
    onChapterStart?.call(index);

    final chapter = _chapterQueue[index];
    await speakSegments(chapter.segments);

    onChapterEnd?.call(index);
  }

  /// Plays the next chapter in the queue.
  Future<void> playNextChapter() async {
    final nextIndex = _currentChapterIndex + 1;
    if (nextIndex < _chapterQueue.length) {
      await playChapter(nextIndex);
    }
  }

  /// Plays the previous chapter in the queue.
  Future<void> playPreviousChapter() async {
    final prevIndex = _currentChapterIndex - 1;
    if (prevIndex >= 0) {
      await playChapter(prevIndex);
    }
  }

  /// Returns whether there is a next chapter.
  bool get hasNextChapter => _currentChapterIndex + 1 < _chapterQueue.length;

  /// Returns whether there is a previous chapter.
  bool get hasPreviousChapter => _currentChapterIndex > 0;

  // --- Internal Handlers ---

  void _onSegmentComplete() {
    _speechCompleter?.complete();
    _speechCompleter = null;
  }

  /// Checks if the TTS engine is available.
  Future<bool> isAvailable() async {
    try {
      return await _flutterTts.isLanguageAvailable(_currentProfile.language);
    } catch (e) {
      return false;
    }
  }

  /// Gets the list of available voices from the system.
  Future<List<dynamic>> getAvailableVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      return [];
    }
  }

  /// Releases the TTS resources.
  Future<void> dispose() async {
    await stop();
    _flutterTts.setCompletionHandler(() {});
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {});
    _flutterTts.setErrorHandler((message) {});
    _flutterTts.setCancelHandler(() {});
  }
}
