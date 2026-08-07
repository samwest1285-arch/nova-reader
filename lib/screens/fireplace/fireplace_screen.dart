import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../services/tts_service.dart';

/// The cozy fireplace reading room with animated flames, TTS, and ambient sounds.
class FireplaceScreen extends ConsumerStatefulWidget {
  const FireplaceScreen({super.key});

  @override
  ConsumerState<FireplaceScreen> createState() => _FireplaceScreenState();
}

class _FireplaceScreenState extends ConsumerState<FireplaceScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _candleFlickerController;
  late AnimationController _butlerReadingController;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _readingSpeed = 0.4;
  double _ambientVolume = 0.5;
  int _currentPage = 1;
  int _totalPages = 45;
  int _currentChapter = 0;
  String _selectedVoice = 'Erzähler (tief)';
  AmbientSound _selectedSound = AmbientSound.fire;
  final TtsService _tts = TtsService();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  final List<String> _voices = [
    'Erzähler (tief)',
    'Erzählerin (warm)',
    'Alter Weiser',
    'Junge Heldin',
    'Butler (Jeeves)',
    'Flüsternd',
  ];

  final List<String> _chapters = [
    'Kapitel 1: Die Ankunft',
    'Kapitel 2: Der geheimnisvolle Brief',
    'Kapitel 3: Im Schatten des Waldes',
    'Kapitel 4: Die Begegnung',
  ];

  // Sample book text for fireplace reading
  final List<String> _pageTexts = [
    'Die Flammen tanzten im Kamin und warfen warme Schatten an die Wände des alten Herrenhauses. Draußen heulte der Wind, doch hier drinnen war es geborgen und still.\n\nDer alte Lord saß in seinem Ledersessel, eine Decke über den Knien, und blätterte in einem vergilbten Buch. Die Seiten raschelten leise, und der Duft von altem Papier und Leder erfüllte den Raum.',
    'Es war in jener stürmischen Nacht, als der Bote an die Tür klopfte. Drei Mal klopfte er, und jeder Schlag hallte durch die hallenden Gänge des Anwesens.\n\nDer Lord erhob sich mühsam und öffnete die schwere Eichentür. Draußen stand ein junger Mann, triefend vor Nässe, einen versiegelten Brief in der Hand.',
    '"Eine Nachricht von Ihrer Nichte, Mylord", sagte der Bote und reichte ihm das Schreiben. Das Siegel trug das Wappen der Familie - ein silberner Wolf auf blauem Grund.\n\nDer Lord brach das Siegel und begann zu lesen. Seine Miene wechselte von Neugier zu tiefer Besorgnis.',
    'Die Worte auf dem Papier erzählten von einer Entdeckung, die alles verändern würde. Ein verborgenes Zimmer, eine alte Karte, ein Geheimnis, das seit Generationen in der Familie gehütet wurde.\n\n"Kommen Sie schnell", stand am Ende des Briefes. "Die Zeit drängt."',
  ];

  // Particle system for flames
  final List<_FlameParticle> _flameParticles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _candleFlickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _butlerReadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Initialize flame particles
    for (int i = 0; i < 30; i++) {
      _flameParticles.add(_FlameParticle());
    }

    // Lade echte deutsche Systemstimmen für natürlicheren Klang
    _tts.loadAndSelectGermanVoices();

    // Update particles periodically
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {
          for (final particle in _flameParticles) {
            particle.update();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _flameController.dispose();
    _candleFlickerController.dispose();
    _butlerReadingController.dispose();
    _particleTimer?.cancel();
    _tts.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _tts.pause();
      setState(() => _isPlaying = false);
    } else {
      _startReading();
    }
  }

  /// Starts (or resumes) reading the current page text aloud.
  Future<void> _startReading() async {
    if (_pageTexts.isEmpty) return;
    final index = (_currentPage - 1).clamp(0, _pageTexts.length - 1);
    final text = _pageTexts[index];
    setState(() => _isPlaying = true);
    // Stimme anwenden (falls noch nicht geschehen)
    await _applyVoice(_selectedVoice);
    await _tts.setSpeed(_readingSpeed);
    await _tts.speak(text);
    // When speech finishes naturally, reset the play state.
    if (mounted) setState(() => _isPlaying = false);
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      if (_currentPage % 10 == 0 && _currentChapter < _chapters.length - 1) {
        setState(() => _currentChapter++);
      }
      // Restart reading if it was playing
      if (_isPlaying) _startReading();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      if (_currentPage % 10 == 0 && _currentChapter > 0) {
        setState(() => _currentChapter--);
      }
      // Restart reading if it was playing
      if (_isPlaying) _startReading();
    }
  }

  void _showVoicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
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
                const Text(
                  'Stimme auswählen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: NovaColors.paleGold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ..._voices.map((voice) {
                  return ListTile(
                    leading: Icon(
                      Icons.record_voice_over,
                      color: _selectedVoice == voice
                          ? NovaColors.warmGold
                          : NovaColors.lightBrown,
                    ),
                    title: Text(
                      voice,
                      style: TextStyle(
                        color: _selectedVoice == voice
                            ? NovaColors.paleGold
                            : NovaColors.tan,
                        fontWeight: _selectedVoice == voice
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _selectedVoice == voice
                        ? const Icon(Icons.check, color: NovaColors.warmGold)
                        : null,
                    onTap: () {
                      setState(() => _selectedVoice = voice);
                      _applyVoice(voice);
                      Navigator.pop(ctx);
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

  /// Applies the selected voice profile to the TTS service.
  Future<void> _applyVoice(String voice) async {
    switch (voice) {
      case 'Erzähler (tief)':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Narrator',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.4,
          defaultPitch: 0.85,
        ));
        break;
      case 'Erzählerin (warm)':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Narrator Female',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.4,
          defaultPitch: 1.15,
        ));
        break;
      case 'Alter Weiser':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Wise Sage',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.35,
          defaultPitch: 0.6,
        ));
        break;
      case 'Junge Heldin':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Young Heroine',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.45,
          defaultPitch: 1.35,
        ));
        break;
      case 'Butler (Jeeves)':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Butler',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.4,
          defaultPitch: 0.9,
        ));
        break;
      case 'Flüsternd':
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Whisper',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.3,
          defaultPitch: 1.1,
        ));
        break;
      default:
        await _tts.setVoiceProfile(const VoiceProfile(
          name: 'Narrator',
          language: 'de-DE',
          voiceId: '',
          defaultSpeed: 0.4,
          defaultPitch: 1.0,
        ));
    }
  }

  /// Selects an ambient sound and plays/stops it.
  Future<void> _selectAmbientSound(AmbientSound sound) async {
    setState(() => _selectedSound = sound);
    await _ambientPlayer.stop();

    if (sound == AmbientSound.none) {
      return;
    }

    final asset = _ambientAsset(sound);
    if (asset == null) {
      return;
    }

    try {
      await _ambientPlayer.setVolume(_ambientVolume);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Ambient sound error: $e');
    }
  }

  String? _ambientAsset(AmbientSound sound) {
    switch (sound) {
      case AmbientSound.fire:
        return 'audio/fire.wav';
      case AmbientSound.rain:
        return 'audio/rain.wav';
      case AmbientSound.wind:
        return 'audio/wind.wav';
      case AmbientSound.birds:
        return 'audio/birds.wav';
      case AmbientSound.none:
        return null;
    }
  }

  void _showAmbientSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
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
                const Text(
                  'Ambient Sound',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: NovaColors.paleGold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _AmbientSoundOption(
                  label: 'Keiner',
                  icon: Icons.volume_off,
                  isSelected: _selectedSound == AmbientSound.none,
                  onTap: () {
                    _selectAmbientSound(AmbientSound.none);
                    Navigator.pop(ctx);
                  },
                ),
                _AmbientSoundOption(
                  label: 'Kamin knistern',
                  icon: Icons.fireplace,
                  isSelected: _selectedSound == AmbientSound.fire,
                  onTap: () {
                    _selectAmbientSound(AmbientSound.fire);
                    Navigator.pop(ctx);
                  },
                ),
                _AmbientSoundOption(
                  label: 'Regen',
                  icon: Icons.water_drop,
                  isSelected: _selectedSound == AmbientSound.rain,
                  onTap: () {
                    _selectAmbientSound(AmbientSound.rain);
                    Navigator.pop(ctx);
                  },
                ),
                _AmbientSoundOption(
                  label: 'Wind',
                  icon: Icons.air,
                  isSelected: _selectedSound == AmbientSound.wind,
                  onTap: () {
                    _selectAmbientSound(AmbientSound.wind);
                    Navigator.pop(ctx);
                  },
                ),
                _AmbientSoundOption(
                  label: 'Vogelgesang',
                  icon: Icons.two_wheeler,
                  isSelected: _selectedSound == AmbientSound.birds,
                  onTap: () {
                    _selectAmbientSound(AmbientSound.birds);
                    Navigator.pop(ctx);
                  },
                ),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Dark room background with candlelight effect
            AnimatedBuilder(
              animation: _candleFlickerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 0.8 + _candleFlickerController.value * 0.05,
                      colors: [
                        const Color(0xFF3D2B1F).withValues(
                          alpha: 0.6 + _candleFlickerController.value * 0.1,
                        ),
                        const Color(0xFF1A1A1A),
                        const Color(0xFF0D0D0D),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Main content
            Column(
              children: [
                // Top bar
                _buildTopBar(theme),

                // Book text area
                Expanded(
                  child: _buildBookTextArea(theme),
                ),

                // Fireplace with flames
                SizedBox(
                  height: size.height * 0.3,
                  child: _buildFireplace(theme, size),
                ),

                // Controls
                _buildControls(theme),
              ],
            ),

            // Butler silhouette reading alongside
            Positioned(
              left: 16,
              bottom: 200,
              child: AnimatedBuilder(
                animation: _butlerReadingController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.4,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        sin(_butlerReadingController.value * pi * 2) * 2,
                      ),
                      child: CustomPaint(
                        size: const Size(40, 80),
                        painter: _ButlerSilhouettePainter(),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Candlelight overlay at edges
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF3D2B1F).withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: NovaColors.paleGold),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Zurück',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _chapters[_currentChapter],
                  style: const TextStyle(
                    color: NovaColors.paleGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Seite $_currentPage von $_totalPages',
                  style: const TextStyle(
                    color: NovaColors.tan,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: NovaColors.paleGold,
            ),
            onPressed: () => setState(() => _isMuted = !_isMuted),
            tooltip: _isMuted ? 'Stumm' : 'Laut',
          ),
        ],
      ),
    );
  }

  Widget _buildBookTextArea(ThemeData theme) {
    final pageIndex = (_currentPage - 1) % _pageTexts.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F1A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NovaColors.paleGold.withValues(alpha: 0.1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chapters[_currentChapter],
              style: const TextStyle(
                color: NovaColors.warmGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seite $_currentPage',
              style: const TextStyle(
                color: NovaColors.tan,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _pageTexts[pageIndex],
              style: TextStyle(
                color: NovaColors.paleGold.withValues(alpha: 0.9),
                fontSize: 16 + (_readingSpeed * 2),
                fontFamily: 'Georgia',
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFireplace(ThemeData theme, Size size) {
    return Stack(
      children: [
        // Fireplace structure
        CustomPaint(
          size: Size(size.width, size.height * 0.3),
          painter: _FireplacePainter(),
        ),
        // Animated flames
        AnimatedBuilder(
          animation: _flameController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(size.width, size.height * 0.3),
              painter: _FlamePainter(
                particles: _flameParticles,
                animation: _flameController.value,
              ),
            );
          },
        ),
        // Fireplace glow
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NovaColors.warmGold.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: NovaColors.paleGold.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Voice selection
                GestureDetector(
                  onTap: _showVoicePicker,
                  child: Column(
                    children: [
                      const Icon(Icons.record_voice_over,
                          color: NovaColors.paleGold, size: 22),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 56),
                        child: Text(
                          _selectedVoice.length > 10
                              ? '${_selectedVoice.substring(0, 10)}...'
                              : _selectedVoice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: NovaColors.tan,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Previous chapter
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: NovaColors.paleGold),
                  onPressed: _prevPage,
                  tooltip: 'Vorherige Seite',
                ),

                // Play/Pause
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NovaColors.terracotta,
                      boxShadow: [
                        BoxShadow(
                          color: NovaColors.terracotta.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: NovaColors.paleGold,
                      size: 28,
                    ),
                  ),
                ),

                // Next chapter
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: NovaColors.paleGold),
                  onPressed: _nextPage,
                  tooltip: 'Nächste Seite',
                ),

                // Ambient sound
                GestureDetector(
                  onTap: _showAmbientSoundPicker,
                  child: Column(
                    children: [
                      Icon(
                        _ambientSoundIcon(_selectedSound),
                        color: NovaColors.paleGold,
                        size: 22,
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 56),
                        child: Text(
                          _ambientSoundLabel(_selectedSound),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: NovaColors.tan,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Speed and volume controls
            Row(
              children: [
                const Icon(Icons.speed, color: NovaColors.tan, size: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: NovaColors.warmGold,
                      inactiveTrackColor: NovaColors.tan.withValues(alpha: 0.3),
                      thumbColor: NovaColors.warmGold,
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: _readingSpeed,
                      min: 0.2,
                      max: 1.0,
                      divisions: 8,
                      label: '${_readingSpeed.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() => _readingSpeed = value);
                        _tts.setSpeed(value);
                      },
                    ),
                  ),
                ),
                Text(
                  '${_readingSpeed.toStringAsFixed(1)}x',
                  style: const TextStyle(color: NovaColors.tan, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(
                  _selectedSound == AmbientSound.none
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: NovaColors.tan,
                  size: 16,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: NovaColors.warmGold,
                      inactiveTrackColor: NovaColors.tan.withValues(alpha: 0.3),
                      thumbColor: NovaColors.warmGold,
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: _ambientVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() => _ambientVolume = value);
                        _ambientPlayer.setVolume(value);
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_ambientVolume * 100).toInt()}%',
                  style: const TextStyle(color: NovaColors.tan, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _ambientSoundIcon(AmbientSound sound) {
    switch (sound) {
      case AmbientSound.none:
        return Icons.volume_off;
      case AmbientSound.fire:
        return Icons.fireplace;
      case AmbientSound.rain:
        return Icons.water_drop;
      case AmbientSound.wind:
        return Icons.air;
      case AmbientSound.birds:
        return Icons.two_wheeler;
    }
  }

  String _ambientSoundLabel(AmbientSound sound) {
    switch (sound) {
      case AmbientSound.none:
        return 'Keiner';
      case AmbientSound.fire:
        return 'Kamin';
      case AmbientSound.rain:
        return 'Regen';
      case AmbientSound.wind:
        return 'Wind';
      case AmbientSound.birds:
        return 'Vögel';
    }
  }
}

/// Paints the fireplace structure.
class _FireplacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height - 20;
    final fireplaceWidth = size.width * 0.5;
    final fireplaceHeight = size.height * 0.7;

    // Fireplace outer structure
    final outerPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.fill;

    final outerPath = Path()
      ..moveTo(centerX - fireplaceWidth / 2 - 20, baseY)
      ..lineTo(centerX - fireplaceWidth / 2 - 20, baseY - fireplaceHeight)
      ..lineTo(centerX - fireplaceWidth / 2, baseY - fireplaceHeight - 20)
      ..lineTo(centerX + fireplaceWidth / 2, baseY - fireplaceHeight - 20)
      ..lineTo(centerX + fireplaceWidth / 2 + 20, baseY - fireplaceHeight)
      ..lineTo(centerX + fireplaceWidth / 2 + 20, baseY)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    // Mantel
    final mantelPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - fireplaceWidth / 2 - 30,
        baseY - fireplaceHeight - 25,
        fireplaceWidth + 60,
        15,
      ),
      mantelPaint,
    );

    // Fireplace opening (dark interior)
    final interiorPaint = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..style = PaintingStyle.fill;

    final interiorPath = Path()
      ..moveTo(centerX - fireplaceWidth / 2 + 10, baseY)
      ..lineTo(centerX - fireplaceWidth / 2 + 10, baseY - fireplaceHeight + 20)
      ..quadraticBezierTo(
        centerX - fireplaceWidth / 2 + 10,
        baseY - fireplaceHeight - 10,
        centerX,
        baseY - fireplaceHeight - 10,
      )
      ..quadraticBezierTo(
        centerX + fireplaceWidth / 2 - 10,
        baseY - fireplaceHeight - 10,
        centerX + fireplaceWidth / 2 - 10,
        baseY - fireplaceHeight + 20,
      )
      ..lineTo(centerX + fireplaceWidth / 2 - 10, baseY)
      ..close();
    canvas.drawPath(interiorPath, interiorPaint);

    // Brick details
    final brickPaint = Paint()
      ..color = const Color(0xFF4E342E).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int row = 0; row < 6; row++) {
      final y = baseY - fireplaceHeight + 20 + row * 20;
      for (int col = 0; col < 8; col++) {
        final x = centerX - fireplaceWidth / 2 + 10 + col * 25;
        canvas.drawRect(
          Rect.fromLTWH(x, y, 22, 16),
          brickPaint,
        );
      }
    }

    // Hearth
    final hearthPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - fireplaceWidth / 2 - 10,
        baseY - 5,
        fireplaceWidth + 20,
        10,
      ),
      hearthPaint,
    );

    // Fireplace glow on the hearth
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          NovaColors.warmGold.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, baseY - fireplaceHeight * 0.5),
        radius: fireplaceWidth * 0.6,
      ));
    canvas.drawCircle(
      Offset(centerX, baseY - fireplaceHeight * 0.5),
      fireplaceWidth * 0.6,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A single flame particle.
class _FlameParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late double life;
  late double maxLife;
  final Random _rng = Random();

  _FlameParticle() {
    reset();
  }

  void reset() {
    x = _rng.nextDouble() * 120 - 60;
    y = _rng.nextDouble() * 20;
    vx = (_rng.nextDouble() - 0.5) * 0.5;
    vy = -(_rng.nextDouble() * 2 + 1);
    size = _rng.nextDouble() * 12 + 4;
    maxLife = _rng.nextDouble() * 60 + 40;
    life = maxLife;
  }

  void update() {
    x += vx;
    y += vy;
    vy -= 0.02; // acceleration upward
    vx += (_rng.nextDouble() - 0.5) * 0.1;
    life -= 1;
    size *= 0.995;

    if (life <= 0 || y < -100) {
      reset();
    }
  }
}

/// Paints animated flames using the particle system.
class _FlamePainter extends CustomPainter {
  final List<_FlameParticle> particles;
  final double animation;

  _FlamePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height - 30;

    // Draw each particle as a flame
    for (final particle in particles) {
      final lifeRatio = particle.life / particle.maxLife;
      final alpha = lifeRatio * 0.8;

      // Flame color gradient from yellow to orange to red
      final color = Color.lerp(
        const Color(0xFFFF4500), // Red-orange
        const Color(0xFFFFD700), // Gold
        lifeRatio,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // Draw flame teardrop shape
      final flamePath = Path();
      final px = centerX + particle.x;
      final py = baseY + particle.y;

      flamePath.moveTo(px, py);
      flamePath.quadraticBezierTo(
        px - particle.size * 0.5,
        py - particle.size * 0.5,
        px,
        py - particle.size,
      );
      flamePath.quadraticBezierTo(
        px + particle.size * 0.5,
        py - particle.size * 0.5,
        px,
        py,
      );
      flamePath.close();

      canvas.drawPath(flamePath, paint);

      // Inner bright core
      final corePaint = Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(px, py - particle.size * 0.4),
        particle.size * 0.2,
        corePaint,
      );
    }

    // Base glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          NovaColors.warmGold.withValues(alpha: 0.3 + animation * 0.1),
          NovaColors.warmGold.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, baseY),
        radius: size.width * 0.3,
      ));

    canvas.drawCircle(
      Offset(centerX, baseY),
      size.width * 0.3,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => true;
}

/// Paints the butler silhouette reading.
class _ButlerSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NovaColors.charcoal.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 15),
        width: 18,
        height: 20,
      ),
      paint,
    );

    // Top hat
    final hatPath = Path()
      ..moveTo(size.width / 2 - 12, 12)
      ..lineTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2 + 8, 0)
      ..lineTo(size.width / 2 + 12, 12)
      ..close();
    canvas.drawPath(hatPath, paint);

    // Body
    final bodyPath = Path()
      ..moveTo(size.width / 2 - 12, 25)
      ..lineTo(size.width / 2 - 14, 60)
      ..lineTo(size.width / 2 + 14, 60)
      ..lineTo(size.width / 2 + 12, 25)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Book in hands
    final bookPaint = Paint()
      ..color = NovaColors.darkGray.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2 + 16, 40),
          width: 8,
          height: 12,
        ),
        const Radius.circular(1),
      ),
      bookPaint,
    );

    // Arm holding book
    final armPaint = Paint()
      ..color = NovaColors.charcoal.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2 + 12, 35),
      Offset(size.width / 2 + 18, 38),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// An ambient sound option row.
class _AmbientSoundOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmbientSoundOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? NovaColors.warmGold : NovaColors.lightBrown,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? NovaColors.paleGold : NovaColors.tan,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: NovaColors.warmGold)
          : null,
      onTap: onTap,
    );
  }
}
