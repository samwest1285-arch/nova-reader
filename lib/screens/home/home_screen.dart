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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
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
                    context.go(AppRoutes.butlerChat);
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
                    context.go(AppRoutes.fireplace);
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
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3E2723),
          title: const Text(
            'Lese-Timer',
            style: TextStyle(color: Color(0xFFFFE0B2)),
          ),
          content: const Text(
            'Stelle einen Timer für eine fokussierte Lese-Session ein.',
            style: TextStyle(color: Color(0xFFD7CCC8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Schließen',
                  style: TextStyle(color: Color(0xFFFFB74D))),
            ),
          ],
        );
      },
    );
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
              fit: BoxFit.cover,
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
          // Positionen basierend auf Bildanalyse (in % des Screens):
          //  Bücher: (0,0)-(50,100) | Kamin: (0,50)-(40,90)
          //  Katze:  (35,48)-(50,60) | Sessel: (50,40)-(80,70)
          //  Kaffeetasse: (62,60)-(70,65)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  children: [
                    // Bücher (linke Hälfte) — größte Zone, zuerst
                    _TapZone(
                      zone: TapZone.books,
                      left: w * 0.0,
                      top: h * 0.0,
                      width: w * 0.50,
                      height: h * 1.0,
                      glow: _glow,
                      onTap: () => _onTap(context, TapZone.books),
                    ),
                    // Kamin (links unten)
                    _TapZone(
                      zone: TapZone.fireplace,
                      left: w * 0.0,
                      top: h * 0.50,
                      width: w * 0.40,
                      height: h * 0.40,
                      glow: _glow,
                      onTap: () => _onTap(context, TapZone.fireplace),
                    ),
                    // Sessel (rechts mittig)
                    _TapZone(
                      zone: TapZone.armchair,
                      left: w * 0.50,
                      top: h * 0.40,
                      width: w * 0.30,
                      height: h * 0.30,
                      glow: _glow,
                      onTap: () => _onTap(context, TapZone.armchair),
                    ),
                    // Kaffeetasse (rechts unten) — über Sessel, zuletzt
                    _TapZone(
                      zone: TapZone.coffee,
                      left: w * 0.60,
                      top: h * 0.58,
                      width: w * 0.12,
                      height: h * 0.10,
                      glow: _glow,
                      onTap: () => _onTap(context, TapZone.coffee),
                    ),
                    // Katze (mittig) — ganz oben im Stack, wird zuerst getroffen
                    _TapZone(
                      zone: TapZone.cat,
                      left: w * 0.34,
                      top: h * 0.46,
                      width: w * 0.18,
                      height: h * 0.16,
                      glow: _glow,
                      onTap: () => _onTap(context, TapZone.cat),
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
enum TapZone { books, cat, coffee, fireplace, armchair, clock }

/// An invisible (or subtly glowing) interactive region over an object.
class _TapZone extends StatelessWidget {
  final TapZone zone;
  final double left;
  final double top;
  final double width;
  final double height;
  final Animation<double> glow;
  final VoidCallback onTap;

  const _TapZone({
    required this.zone,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.glow,
    required this.onTap,
  });

  String get _label {
    switch (zone) {
      case TapZone.books:
        return 'Bibliothek';
      case TapZone.cat:
        return 'Butler';
      case TapZone.coffee:
        return 'Caffè';
      case TapZone.fireplace:
        return 'Kaminzimmer';
      case TapZone.armchair:
        return 'Einstellungen';
      case TapZone.clock:
        return 'Timer';
    }
  }

  IconData get _icon {
    switch (zone) {
      case TapZone.books:
        return Icons.auto_stories;
      case TapZone.cat:
        return Icons.pets;
      case TapZone.coffee:
        return Icons.local_cafe;
      case TapZone.fireplace:
        return Icons.local_fire_department;
      case TapZone.armchair:
        return Icons.chair;
      case TapZone.clock:
        return Icons.schedule;
    }
  }

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
        child: AnimatedBuilder(
          animation: glow,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Subtiler Puls-Glow, damit man erkennt, dass es klickbar ist
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB74D)
                            .withOpacity(0.12 + glow.value * 0.15),
                        blurRadius: 30 + glow.value * 20,
                        spreadRadius: 5 + glow.value * 8,
                      ),
                    ],
                  ),
                ),
                // Kleines Icon + Label (dezent, über dem Objekt)
                Positioned(
                  bottom: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icon,
                        color: Colors.white.withOpacity(0.85),
                        size: 22,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black)
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
