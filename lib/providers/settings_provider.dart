import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Available ambient sound options.
enum AmbientSound { none, fire, rain, wind, birds }

/// Settings state for the Nova Reader app.
class SettingsState {
  final String ttsVoice;
  final double ttsSpeed;
  final AmbientSound ambientSound;
  final double ambientVolume;
  final bool themeAuto;
  final double fontSize;
  final String fontFamily;
  final bool aiButlerEnabled;

  const SettingsState({
    this.ttsVoice = 'en-US-Standard-D',
    this.ttsSpeed = 1.0,
    this.ambientSound = AmbientSound.none,
    this.ambientVolume = 0.5,
    this.themeAuto = true,
    this.fontSize = 16.0,
    this.fontFamily = 'Georgia',
    this.aiButlerEnabled = true,
  });

  SettingsState copyWith({
    String? ttsVoice,
    double? ttsSpeed,
    AmbientSound? ambientSound,
    double? ambientVolume,
    bool? themeAuto,
    double? fontSize,
    String? fontFamily,
    bool? aiButlerEnabled,
  }) {
    return SettingsState(
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ambientSound: ambientSound ?? this.ambientSound,
      ambientVolume: ambientVolume ?? this.ambientVolume,
      themeAuto: themeAuto ?? this.themeAuto,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      aiButlerEnabled: aiButlerEnabled ?? this.aiButlerEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttsVoice': ttsVoice,
      'ttsSpeed': ttsSpeed,
      'ambientSound': ambientSound.name,
      'ambientVolume': ambientVolume,
      'themeAuto': themeAuto,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'aiButlerEnabled': aiButlerEnabled,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      ttsVoice: json['ttsVoice'] as String? ?? 'en-US-Standard-D',
      ttsSpeed: (json['ttsSpeed'] as num?)?.toDouble() ?? 1.0,
      ambientSound: AmbientSound.values.firstWhere(
        (a) => a.name == json['ambientSound'],
        orElse: () => AmbientSound.none,
      ),
      ambientVolume: (json['ambientVolume'] as num?)?.toDouble() ?? 0.5,
      themeAuto: json['themeAuto'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontFamily: json['fontFamily'] as String? ?? 'Georgia',
      aiButlerEnabled: json['aiButlerEnabled'] as bool? ?? true,
    );
  }
}

/// Provider for the settings state.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'nova_reader_settings';

  /// Loads settings from SharedPreferences.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = SettingsState.fromJson(json);
      }
    } catch (e) {
      // Fall back to default state if loading fails
      state = const SettingsState();
    }
  }

  /// Persists the current state to SharedPreferences.
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Silently fail on persistence errors
    }
  }

  /// Sets the TTS voice.
  Future<void> setTtsVoice(String voice) async {
    state = state.copyWith(ttsVoice: voice);
    await _saveToPrefs();
  }

  /// Sets the TTS speech speed (0.25 - 2.0).
  Future<void> setTtsSpeed(double speed) async {
    final clamped = speed.clamp(0.25, 2.0);
    state = state.copyWith(ttsSpeed: clamped);
    await _saveToPrefs();
  }

  /// Sets the ambient sound type.
  Future<void> setAmbientSound(AmbientSound sound) async {
    state = state.copyWith(ambientSound: sound);
    await _saveToPrefs();
  }

  /// Sets the ambient sound volume (0.0 - 1.0).
  Future<void> setAmbientVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(ambientVolume: clamped);
    await _saveToPrefs();
  }

  /// Toggles between auto and manual theme mode.
  Future<void> toggleThemeAuto() async {
    state = state.copyWith(themeAuto: !state.themeAuto);
    await _saveToPrefs();
  }

  /// Sets the theme mode to auto or manual.
  Future<void> setThemeAuto(bool auto) async {
    state = state.copyWith(themeAuto: auto);
    await _saveToPrefs();
  }

  /// Sets the reading font size (12 - 32).
  Future<void> setFontSize(double size) async {
    final clamped = size.clamp(12.0, 32.0);
    state = state.copyWith(fontSize: clamped);
    await _saveToPrefs();
  }

  /// Sets the reading font family.
  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _saveToPrefs();
  }

  /// Enables or disables the AI butler feature.
  Future<void> setAiButlerEnabled(bool enabled) async {
    state = state.copyWith(aiButlerEnabled: enabled);
    await _saveToPrefs();
  }

  /// Toggles the AI butler feature.
  Future<void> toggleAiButler() async {
    state = state.copyWith(aiButlerEnabled: !state.aiButlerEnabled);
    await _saveToPrefs();
  }

  /// Resets all settings to defaults.
  Future<void> resetToDefaults() async {
    state = const SettingsState();
    await _saveToPrefs();
  }
}

/// Riverpod provider for settings.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
