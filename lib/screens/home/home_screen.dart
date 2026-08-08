import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

  /// Starts a countdown reading timer and shows a snackbar when done.
  void _startReadingTimer(int minutes) {
    final duration = Duration(minutes: minutes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lese-Timer gestartet: $minutes Minuten'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Countdown im Hintergrund
    Future.delayed(duration, () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Lese-Session beendet! Gut gemacht.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
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
          // Positionen basierend auf Bildanalyse (GPT-4o-mini, in %):
          //  Kamin: (10,60)-(30,90) | Bücherregal: (0,30)-(30,60)
          //  Katze: (50,65)-(65,80) | Sessel: (45,55)-(80,90)
          //  Kaffeetasse: (75,65)-(85,75) | Lampe: (75,50)-(85,65)
          //  Fenster: (30,0)-(70,30) | Tisch: (60,70)-(80,90)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  children: [
                    // Kamin (links unten) — Piper TTS Vorlesen
                    _TapZone(
                      zone: TapZone.fireplace,
                      left: w * 0.10,
                      top: h * 0.60,
                      width: w * 0.20,
                      height: h * 0.30,
                      onTap: () => _onTap(context, TapZone.fireplace),
                    ),
                    // Bücherregal (links) — Bibliothek
                    _TapZone(
                      zone: TapZone.books,
                      left: w * 0.0,
                      top: h * 0.30,
                      width: w * 0.30,
                      height: h * 0.30,
                      onTap: () => _onTap(context, TapZone.books),
                    ),
                    // Sessel (rechts) — Einstellungen
                    _TapZone(
                      zone: TapZone.armchair,
                      left: w * 0.45,
                      top: h * 0.55,
                      width: w * 0.35,
                      height: h * 0.35,
                      onTap: () => _onTap(context, TapZone.armchair),
                    ),
                    // Kaffeetasse (rechts unten) — Caffè
                    _TapZone(
                      zone: TapZone.coffee,
                      left: w * 0.75,
                      top: h * 0.65,
                      width: w * 0.10,
                      height: h * 0.10,
                      onTap: () => _onTap(context, TapZone.coffee),
                    ),
                    // Katze (auf dem Sessel) — Butler — ganz oben im Stack
                    _TapZone(
                      zone: TapZone.cat,
                      left: w * 0.50,
                      top: h * 0.65,
                      width: w * 0.15,
                      height: h * 0.15,
                      onTap: () => _onTap(context, TapZone.cat),
                    ),
                    // Fenster (oben) — Timer
                    _TapZone(
                      zone: TapZone.clock,
                      left: w * 0.30,
                      top: h * 0.0,
                      width: w * 0.40,
                      height: h * 0.30,
                      onTap: () => _onTap(context, TapZone.clock),
                    ),
                    // Lampe (rechts oben) — Kamera-Scan
                    _TapZone(
                      zone: TapZone.camera,
                      left: w * 0.75,
                      top: h * 0.50,
                      width: w * 0.10,
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
