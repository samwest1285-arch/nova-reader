import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';

/// The main menu screen. Uses the cozy reading-room artwork as a background
/// and overlays invisible, interactive tap zones on the objects in the scene.
///
/// Tap targets (position in % of screen width/height):
///  - Bookshelf / Books  -> Library (Bücher auswählen)
///  - Cat                -> Butler / Vorlesen Auswahl
///  - Coffee cup         -> Caffè (Spenden)
///  - Fireplace          -> Kaminzimmer (Vorlesen)
///  - Armchair           -> Einstellungen / Lesemodus
///  - Clock              -> Lese-Timer
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Guten Morgen!';
    if (hour >= 12 && hour < 17) return 'Guten Tag!';
    if (hour >= 17 && hour < 21) return 'Guten Abend!';
    return 'Gute Nacht!';
  }

  void _onTap(BuildContext context, TapZone zone) {
    switch (zone) {
      case TapZone.books:
        context.push(AppRoutes.library);
        break;
      case TapZone.cat:
        _showButlerChoice(context);
        break;
      case TapZone.coffee:
        context.push(AppRoutes.cafe);
        break;
      case TapZone.fireplace:
        context.push(AppRoutes.fireplace);
        break;
      case TapZone.armchair:
        context.push(AppRoutes.settings);
        break;
      case TapZone.clock:
        _showTimerDialog(context);
        break;
      case TapZone.camera:
        context.push(AppRoutes.scanner);
        break;
    }
  }

  void _showButlerChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF3E2723),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Was möchtest du?',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFFFE0B2),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _ChoiceButton(
                  icon: Icons.support_agent,
                  label: 'Butler brauchen',
                  subtitle: 'Fragen, Empfehlungen, Hilfe',
                  color: const Color(0xFF6D4C41),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.butlerChat);
                  },
                ),
                const SizedBox(height: 12),
                _ChoiceButton(
                  icon: Icons.record_voice_over,
                  label: 'Vorlesen lassen',
                  subtitle: 'Geschichte im Kaminzimmer',
                  color: const Color(0xFFBF360C),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.fireplace);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimerDialog(BuildContext context) {
    int minutes = 10;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3E2723),
              title: const Text(
                'Lese-Timer',
                style: TextStyle(color: Color(0xFFFFE0B2)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Stelle einen Timer für eine fokussierte Lese-Session ein.',
                    style: TextStyle(color: Color(0xFFD7CCC8)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$minutes Minuten',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Color(0xFFFFB74D)),
                        onPressed: () {
                          if (minutes > 1) {
                            setDialogState(() => minutes -= 5);
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFFFFB74D)),
                        onPressed: () {
                          if (minutes < 120) {
                            setDialogState(() => minutes += 5);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Abbrechen',
                      style: TextStyle(color: Color(0xFFD7CCC8))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startReadingTimer(minutes);
                  },
                  child: const Text('Start',
                      style: TextStyle(color: Color(0xFFFFB74D))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Starts a countdown reading timer with live display and sound signal.
  void _startReadingTimer(int minutes) {
    _countdownTimer?.cancel();
    _remainingSeconds = minutes * 60;

    // Live-Countdown-Dialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CountdownDialog(
        getRemaining: () => _remainingSeconds,
        onClose: () {
          _countdownTimer?.cancel();
        },
      ),
    );

    // Countdown jede Sekunde
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Ton-Signal abspielen
        _playTimerSignal();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏰ Lese-Session beendet! Gut gemacht.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  /// Spielt ein kurzes Signal-Ton ab (über SystemSound).
  void _playTimerSignal() {
    SystemSound.play(SystemSoundType.alert);
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final isNight = hour >= 21 || hour < 5;

    return Scaffold(
      backgroundColor: const Color(0xFF2E1B12),
      body: Stack(
        children: [
          // ── Hintergrundbild (das gemütliche Lesezimmer) ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_background.png',
              fit: BoxFit.contain,
            ),
          ),

          // ── Leichter Abdunklungs-Overlay bei Nacht ──
          if (isNight)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),

          // ── Interaktive Tap-Zonen ──
          // Aufteilung in Arbeitsbereiche nach Nutzer-Vorgabe:
          //  Links oben: Kaminzimmer (Kamin) + Bibliothek (verkleinert)
          //  Rechts oben: Kamera-Scan + Timer
          //  Rechts unten: Kaffeespenden + Butler + Settings
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  children: [
                    // Kaminzimmer — auf dem Kamin (links unten)
                    _TapZone(
                      zone: TapZone.fireplace,
                      left: w * 0.10,
                      top: h * 0.70,
                      width: w * 0.25,
                      height: h * 0.30,
                      onTap: () => _onTap(context, TapZone.fireplace),
                    ),
                    // Bibliothek — links oben, zentral, um 3/4 verkleinert
                    _TapZone(
                      zone: TapZone.books,
                      left: w * 0.05,
                      top: h * 0.25,
                      width: w * 0.10,
                      height: h * 0.15,
                      onTap: () => _onTap(context, TapZone.books),
                    ),
                    // Settings — rechts unten, unterhalb Butler
                    _TapZone(
                      zone: TapZone.armchair,
                      left: w * 0.60,
                      top: h * 0.72,
                      width: w * 0.20,
                      height: h * 0.13,
                      onTap: () => _onTap(context, TapZone.armchair),
                    ),
                    // Kaffeespenden — rechts unten, rechte obere Ecke
                    _TapZone(
                      zone: TapZone.coffee,
                      left: w * 0.72,
                      top: h * 0.58,
                      width: w * 0.12,
                      height: h * 0.10,
                      onTap: () => _onTap(context, TapZone.coffee),
                    ),
                    // Butler — links neben Kaffee, mit Abstand (auf der Katze)
                    _TapZone(
                      zone: TapZone.cat,
                      left: w * 0.48,
                      top: h * 0.55,
                      width: w * 0.18,
                      height: h * 0.13,
                      onTap: () => _onTap(context, TapZone.cat),
                    ),
                    // Timer — rechts oben, dezentral, leicht nach links unten
                    _TapZone(
                      zone: TapZone.clock,
                      left: w * 0.50,
                      top: h * 0.12,
                      width: w * 0.18,
                      height: h * 0.15,
                      onTap: () => _onTap(context, TapZone.clock),
                    ),
                    // Kamera-Scan — rechts oben, rechte untere Ecke
                    _TapZone(
                      zone: TapZone.camera,
                      left: w * 0.78,
                      top: h * 0.30,
                      width: w * 0.12,
                      height: h * 0.15,
                      onTap: () => _onTap(context, TapZone.camera),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Kopfzeile mit Begrüßung ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      color: Color(0xFFFFE0B2),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Hinweis unten ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tippe auf die Objekte im Zimmer',
                    style: TextStyle(
                      color: const Color(0xFFFFE0B2).withOpacity(0.9),
                      fontSize: 13,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The different interactive zones in the scene.
enum TapZone { books, cat, coffee, fireplace, armchair, clock, camera }

/// An invisible interactive region over an object in the scene.
class _TapZone extends StatelessWidget {
  final TapZone zone;
  final double left;
  final double top;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _TapZone({
    required this.zone,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Unsichtbare Tap-Zone — die Objekte im Bild sind die Buttons.
        // Kein sichtbarer Glow/Icon/Label, damit das Bild sauber bleibt.
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// A choice button used in the butler bottom sheet.
class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFE0B2), size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFFFFE0B2).withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFFFE0B2), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live-Countdown-Dialog für den Lese-Timer.
class _CountdownDialog extends StatefulWidget {
  final int Function() getRemaining;
  final VoidCallback onClose;

  const _CountdownDialog({
    required this.getRemaining,
    required this.onClose,
  });

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Aktualisiert die Anzeige jede Sekunde
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.getRemaining();
    final done = remaining <= 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF3E2723),
      title: Text(
        done ? 'Fertig!' : 'Lese-Timer',
        style: const TextStyle(color: Color(0xFFFFE0B2)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            done ? '⏰ Zeit vorbei!' : _format(remaining),
            style: const TextStyle(
              color: Color(0xFFFFB74D),
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done ? 'Gut gemacht!' : 'Noch ${_format(remaining)} übrig',
            style: const TextStyle(color: Color(0xFFD7CCC8)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClose();
            Navigator.pop(context);
          },
          child: const Text('Schließen',
              style: TextStyle(color: Color(0xFFFFB74D))),
        ),
      ],
    );
  }
}
