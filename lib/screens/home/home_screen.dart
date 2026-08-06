import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Time-of-day background colors for the home screen.
class _TimeOfDayColors {
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color accentGlow;
  final String greeting;

  const _TimeOfDayColors({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.accentGlow,
    required this.greeting,
  });

  static _TimeOfDayColors fromHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return const _TimeOfDayColors(
        backgroundTop: Color(0xFF8D6E63),
        backgroundBottom: Color(0xFFA1887F),
        accentGlow: Color(0xFFFFB300),
        greeting: 'Guten Morgen!',
      );
    } else if (hour >= 12 && hour < 17) {
      return const _TimeOfDayColors(
        backgroundTop: Color(0xFF6D4C41),
        backgroundBottom: Color(0xFF795548),
        accentGlow: Color(0xFFFF8F00),
        greeting: 'Guten Tag!',
      );
    } else if (hour >= 17 && hour < 21) {
      return const _TimeOfDayColors(
        backgroundTop: Color(0xFF4E342E),
        backgroundBottom: Color(0xFF5D4037),
        accentGlow: Color(0xFFBF360C),
        greeting: 'Guten Abend!',
      );
    } else {
      return const _TimeOfDayColors(
        backgroundTop: Color(0xFF1B1B1B),
        backgroundBottom: Color(0xFF2E2E2E),
        accentGlow: Color(0xFF2E7D32),
        greeting: 'Gute Nacht!',
      );
    }
  }
}

/// Butler greetings that change based on time of day.
final List<String> _morningGreetings = [
  'Ein neuer Tag, ein neues Abenteuer!',
  'Die besten Geschichten warten auf Sie.',
  'Kaffee ist fertig, und die Bücher auch!',
  'Ein gemütlicher Morgen zum Lesen.',
  'Die Vögel singen, die Seiten warten.',
];

final List<String> _afternoonGreetings = [
  'Ein ruhiger Nachmittag mit einem guten Buch.',
  'Die Sonne scheint, die Geschichten leben.',
  'Zeit für eine Lesepause?',
  'Ich habe ein paar Empfehlungen für Sie.',
  'Der Tee ist serviert, mein Herr.',
];

final List<String> _eveningGreetings = [
  'Der Abend ist perfekt zum Lesen.',
  'Die Kerzen sind angezündet.',
  'Ein Glas Wein und ein gutes Buch?',
  'Die Sterne funkeln, die Seiten rascheln.',
  'Willkommen zurück in Ihrer Bibliothek.',
];

final List<String> _nightGreetings = [
  'Die Nacht ist jung und die Geschichten warten.',
  'Nur noch ein Kapitel...',
  'Der Kamin brennt, die Welt ruht.',
  'Stille Nacht, perfekt zum Lesen.',
  'Ich passe auf, während Sie lesen.',
];

final List<String> _bookRecommendations = [
  'Der Alchimist – Paulo Coelho',
  'Die unerträgliche Leichtigkeit des Seins – Milan Kundera',
  'Der kleine Prinz – Antoine de Saint-Exupéry',
  'Hundert Jahre Einsamkeit – Gabriel García Márquez',
  'Die Bücherdiebin – Markus Zusak',
  'Der Name des Windes – Patrick Rothfuss',
  'Stolz und Vorurteil – Jane Austen',
  '1984 – George Orwell',
  'Der Herr der Ringe – J.R.R. Tolkien',
  'Die Verwandlung – Franz Kafka',
];

/// The main menu screen with earth-tone background, tree silhouettes,
/// circular menu buttons, and the butler character.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _treeSwayController;
  late AnimationController _glowController;
  late AnimationController _butlerBounceController;
  late Animation<double> _treeSwayAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _butlerBounceAnimation;
  String _currentGreeting = '';
  String _currentRecommendation = '';
  int _greetingIndex = 0;
  Timer? _greetingTimer;
  Timer? _recommendationTimer;
  int _hoveredButton = -1;

  @override
  void initState() {
    super.initState();

    // Tree sway animation
    _treeSwayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _treeSwayAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _treeSwayController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Butler bounce animation
    _butlerBounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _butlerBounceAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _butlerBounceController, curve: Curves.easeInOut),
    );

    _updateGreeting();
    _updateRecommendation();

    // Rotate greeting every 15 seconds
    _greetingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateGreeting();
    });

    // Rotate recommendation every 30 seconds
    _recommendationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateRecommendation();
    });
  }

  @override
  void dispose() {
    _treeSwayController.dispose();
    _glowController.dispose();
    _butlerBounceController.dispose();
    _greetingTimer?.cancel();
    _recommendationTimer?.cancel();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    List<String> pool;
    if (hour >= 5 && hour < 12) {
      pool = _morningGreetings;
    } else if (hour >= 12 && hour < 17) {
      pool = _afternoonGreetings;
    } else if (hour >= 17 && hour < 21) {
      pool = _eveningGreetings;
    } else {
      pool = _nightGreetings;
    }
    setState(() {
      _greetingIndex = (_greetingIndex + 1) % pool.length;
      _currentGreeting = pool[_greetingIndex];
    });
  }

  void _updateRecommendation() {
    final rng = Random();
    setState(() {
      _currentRecommendation =
          _bookRecommendations[rng.nextInt(_bookRecommendations.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final timeColors = _TimeOfDayColors.fromHour(hour);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [timeColors.backgroundTop, timeColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Tree silhouettes - left and right borders
              AnimatedBuilder(
                animation: _treeSwayAnimation,
                builder: (context, child) {
                  return Row(
                    children: [
                      // Left trees
                      SizedBox(
                        width: 60,
                        child: CustomPaint(
                          painter: _TreePainter(
                            side: _TreeSide.left,
                            sway: _treeSwayAnimation.value,
                            timeColors: timeColors,
                          ),
                          size: const Size(60, double.infinity),
                        ),
                      ),
                      // Center content
                      Expanded(
                        child: isLandscape
                            ? _buildLandscapeLayout(
                                size, timeColors, theme)
                            : _buildPortraitLayout(
                                size, timeColors, theme),
                      ),
                      // Right trees
                      SizedBox(
                        width: 60,
                        child: CustomPaint(
                          painter: _TreePainter(
                            side: _TreeSide.right,
                            sway: _treeSwayAnimation.value,
                            timeColors: timeColors,
                          ),
                          size: const Size(60, double.infinity),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Subtle ambient particles (fireflies/dust motes)
              ...List.generate(15, (index) {
                final rng = Random(index * 7);
                return _AmbientParticle(
                  x: rng.nextDouble() * size.width,
                  y: rng.nextDouble() * size.height,
                  size: rng.nextDouble() * 3 + 1,
                  color: timeColors.accentGlow.withValues(alpha: 0.3),
                  duration: Duration(seconds: rng.nextInt(8) + 6),
                  delay: Duration(seconds: rng.nextInt(10)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
      Size size, _TimeOfDayColors timeColors, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final buttonSize = size.width * 0.18;
        final topPadding = availableHeight * 0.04;

        return Stack(
          children: [
            // Title
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Nova Reader',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: NovaColors.paleGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: NovaColors.deepBrown.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ihre gemütliche Lesebegleitung',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NovaColors.tan,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Central menu buttons arranged in pentagon
            Positioned(
              top: topPadding + 60,
              left: 0,
              right: 0,
              bottom: 140,
              child: Center(
                child: _buildMenuButtons(
                    buttonSize, timeColors, theme, size),
              ),
            ),

            // Butler at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildButlerSection(timeColors, theme, size),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLandscapeLayout(
      Size size, _TimeOfDayColors timeColors, ThemeData theme) {
    final buttonSize = size.width * 0.1;

    return Row(
      children: [
        // Menu buttons on left
        Expanded(
          flex: 3,
          child: Center(
            child: _buildMenuButtons(
                buttonSize, timeColors, theme, size),
          ),
        ),
        // Butler on right
        Expanded(
          flex: 2,
          child: _buildButlerSection(timeColors, theme, size),
        ),
      ],
    );
  }

  Widget _buildMenuButtons(double buttonSize, _TimeOfDayColors timeColors,
      ThemeData theme, Size size) {
    final menuItems = [
      _MenuItem(
        icon: Icons.library_books,
        label: 'Bibliothek',
        route: '/library',
        color: const Color(0xFF5D4037),
      ),
      _MenuItem(
        icon: Icons.camera_alt,
        label: 'Kamera-Scan',
        route: '/scanner',
        color: const Color(0xFF2E7D32),
      ),
      _MenuItem(
        icon: Icons.picture_as_pdf,
        label: 'PDF/Photo\nto EPUB',
        route: '/converter',
        color: const Color(0xFFBF360C),
      ),
      _MenuItem(
        icon: Icons.fireplace,
        label: 'Kaminzimmer',
        route: '/fireplace',
        color: const Color(0xFFE65100),
      ),
      _MenuItem(
        icon: Icons.coffee,
        label: 'Caffè',
        route: '/cafe',
        color: const Color(0xFF795548),
      ),
    ];

    // Arrange in pentagon
    final angles = [
      -pi / 2, // top center (Bibliothek)
      -pi * 0.85, // upper left (Kamera-Scan)
      -pi * 0.15, // upper right (Converter)
      -pi * 0.6, // lower left (Kaminzimmer)
      -pi * 0.4, // lower right (Caffè)
    ];

    final radius = buttonSize * 2.2;

    return SizedBox(
      width: radius * 2 + buttonSize,
      height: radius * 2 + buttonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative circle behind buttons
          CustomPaint(
            size: Size(radius * 2 + buttonSize, radius * 2 + buttonSize),
            painter: _CircleGlowPainter(
              glowColor: timeColors.accentGlow,
              glowIntensity: _glowAnimation.value,
            ),
          ),
          // Menu buttons
          ...List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            final angle = angles[index];
            final x = radius * cos(angle) + radius + buttonSize / 2;
            final y = radius * sin(angle) + radius + buttonSize / 2;

            return Positioned(
              left: x - buttonSize / 2,
              top: y - buttonSize / 2,
              child: _MenuButton(
                item: item,
                size: buttonSize,
                isHovered: _hoveredButton == index,
                glowValue: _glowAnimation.value,
                onTap: () => context.push(item.route),
                onHover: (hovered) {
                  setState(() {
                    _hoveredButton = hovered ? index : -1;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildButlerSection(
      _TimeOfDayColors timeColors, ThemeData theme, Size size) {
    return AnimatedBuilder(
      animation: _butlerBounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _butlerBounceAnimation.value),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  timeColors.backgroundBottom.withValues(alpha: 0.0),
                  timeColors.backgroundBottom.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Speech bubble
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: NovaColors.cream,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: NovaColors.deepBrown.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentGreeting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: NovaColors.deepBrown,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📖 ${_currentRecommendation}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NovaColors.mediumBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Butler character (ASCII art style)
                _ButlerWidget(
                  timeColors: timeColors,
                  size: size,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Data class for menu items.
class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

/// A single menu button with glow animation.
class _MenuButton extends StatefulWidget {
  final _MenuItem item;
  final double size;
  final bool isHovered;
  final double glowValue;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _MenuButton({
    required this.item,
    required this.size,
    required this.isHovered,
    required this.glowValue,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glowRadius = widget.size * 0.6;
    final scale = _pressed ? 0.92 : (widget.isHovered ? 1.05 : 1.0);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: MouseRegion(
        onEnter: (_) => widget.onHover(true),
        onExit: (_) => widget.onHover(false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.item.color,
              boxShadow: [
                BoxShadow(
                  color: widget.item.color.withValues(
                    alpha: widget.isHovered ? 0.6 : 0.3,
                  ),
                  blurRadius: widget.isHovered ? glowRadius : glowRadius * 0.5,
                  spreadRadius: widget.isHovered ? 4 : 0,
                ),
                BoxShadow(
                  color: NovaColors.paleGold.withValues(
                    alpha: widget.glowValue * 0.3,
                  ),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: NovaColors.paleGold.withValues(
                  alpha: widget.isHovered ? 0.8 : 0.3,
                ),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  color: NovaColors.paleGold,
                  size: widget.size * 0.35,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: NovaColors.paleGold,
                    fontSize: widget.size * 0.12,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Which side of the screen the trees appear on.
enum _TreeSide { left, right }

/// Paints tree silhouettes along the left and right borders.
class _TreePainter extends CustomPainter {
  final _TreeSide side;
  final double sway;
  final _TimeOfDayColors timeColors;

  _TreePainter({
    required this.side,
    required this.sway,
    required this.timeColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NovaColors.deepBrown.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final treeCount = (size.height / 120).floor().clamp(3, 12);
    final treeSpacing = size.height / treeCount;

    for (int i = 0; i < treeCount; i++) {
      final baseY = i * treeSpacing + treeSpacing / 2;
      final swayOffset = sin(baseY * 0.05 + DateTime.now().millisecondsSinceEpoch * 0.001) * sway * 8;
      final xOffset = side == _TreeSide.left ? 0.0 : size.width;

      _drawTree(canvas, xOffset + swayOffset, baseY, paint, i);
    }
  }

  void _drawTree(Canvas canvas, double x, double y, Paint paint, int index) {
    final rng = Random(index * 13);
    final treeHeight = 80.0 + rng.nextDouble() * 40;
    final treeWidth = 30.0 + rng.nextDouble() * 15;

    final path = Path();

    // Trunk
    path.moveTo(x, y + treeHeight * 0.3);
    path.lineTo(x - 3, y + treeHeight * 0.3);
    path.lineTo(x - 2, y);
    path.lineTo(x + 2, y);
    path.lineTo(x + 3, y + treeHeight * 0.3);
    path.close();
    canvas.drawPath(path, paint);

    // Canopy - layered circles for pine/deciduous silhouette
    final canopyPaint = Paint()
      ..color = NovaColors.deepGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final canopyY = y - treeHeight * 0.1;
    final layerCount = 3 + rng.nextInt(2);

    for (int l = 0; l < layerCount; l++) {
      final layerY = canopyY + l * (treeHeight * 0.2);
      final layerWidth = treeWidth * (1.0 - l * 0.15);
      final layerHeight = treeHeight * 0.25;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, layerY),
          width: layerWidth,
          height: layerHeight,
        ),
        canopyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) {
    return oldDelegate.sway != sway;
  }
}

/// Paints a subtle glowing circle behind the menu buttons.
class _CircleGlowPainter extends CustomPainter {
  final Color glowColor;
  final double glowIntensity;

  _CircleGlowPainter({
    required this.glowColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;

    // Outer glow ring
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          glowColor.withValues(alpha: glowIntensity * 0.15),
          glowColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Inner subtle ring
    final ringPaint = Paint()
      ..color = NovaColors.paleGold.withValues(alpha: glowIntensity * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.9, ringPaint);
    canvas.drawCircle(center, radius * 1.1, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _CircleGlowPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}

/// The butler character widget (ASCII art style painted widget).
class _ButlerWidget extends StatelessWidget {
  final _TimeOfDayColors timeColors;
  final Size size;

  const _ButlerWidget({
    required this.timeColors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _ButlerPainter(timeColors: timeColors),
      ),
    );
  }
}

/// Paints the butler character.
class _ButlerPainter extends CustomPainter {
  final _TimeOfDayColors timeColors;

  _ButlerPainter({required this.timeColors});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height - 10;

    // Body (tuxedo silhouette)
    final bodyPaint = Paint()
      ..color = NovaColors.charcoal
      ..style = PaintingStyle.fill;

    // Torso
    final torsoPath = Path()
      ..moveTo(centerX - 15, baseY - 30)
      ..lineTo(centerX - 18, baseY - 5)
      ..lineTo(centerX + 18, baseY - 5)
      ..lineTo(centerX + 15, baseY - 30)
      ..close();
    canvas.drawPath(torsoPath, bodyPaint);

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY - 40),
        width: 22,
        height: 24,
      ),
      bodyPaint,
    );

    // Hair
    final hairPaint = Paint()
      ..color = NovaColors.darkGray
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY - 46),
        width: 24,
        height: 12,
      ),
      hairPaint,
    );

    // Bow tie
    final bowPaint = Paint()
      ..color = NovaColors.terracotta
      ..style = PaintingStyle.fill;
    final bowPath = Path()
      ..moveTo(centerX - 6, baseY - 28)
      ..lineTo(centerX, baseY - 26)
      ..lineTo(centerX + 6, baseY - 28)
      ..lineTo(centerX, baseY - 30)
      ..close();
    canvas.drawPath(bowPath, bowPaint);

    // Eyes (small white dots)
    final eyePaint = Paint()
      ..color = NovaColors.cream
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX - 4, baseY - 40), 2, eyePaint);
    canvas.drawCircle(Offset(centerX + 4, baseY - 40), 2, eyePaint);

    // Pupils
    final pupilPaint = Paint()
      ..color = NovaColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX - 4, baseY - 40), 1, pupilPaint);
    canvas.drawCircle(Offset(centerX + 4, baseY - 40), 1, pupilPaint);

    // Monocle
    final monoclePaint = Paint()
      ..color = NovaColors.paleGold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(centerX + 4, baseY - 40), 5, monoclePaint);
    canvas.drawLine(
      Offset(centerX + 9, baseY - 40),
      Offset(centerX + 12, baseY - 32),
      monoclePaint,
    );

    // Arms
    final armPaint = Paint()
      ..color = NovaColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Left arm (holding a book)
    canvas.drawLine(
      Offset(centerX - 15, baseY - 25),
      Offset(centerX - 30, baseY - 20),
      armPaint,
    );

    // Right arm (raised in greeting)
    canvas.drawLine(
      Offset(centerX + 15, baseY - 25),
      Offset(centerX + 28, baseY - 35),
      armPaint,
    );

    // Book in left hand
    final bookPaint = Paint()
      ..color = NovaColors.terracotta
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 32, baseY - 18),
          width: 10,
          height: 14,
        ),
        const Radius.circular(1),
      ),
      bookPaint,
    );

    // Legs
    canvas.drawLine(
      Offset(centerX - 8, baseY - 5),
      Offset(centerX - 10, baseY + 5),
      armPaint,
    );
    canvas.drawLine(
      Offset(centerX + 8, baseY - 5),
      Offset(centerX + 10, baseY + 5),
      armPaint,
    );

    // Shoes
    final shoePaint = Paint()
      ..color = NovaColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 10, baseY + 6),
        width: 10,
        height: 5,
      ),
      shoePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 10, baseY + 6),
        width: 10,
        height: 5,
      ),
      shoePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ButlerPainter oldDelegate) => false;
}

/// Floating ambient particle (firefly/dust mote).
class _AmbientParticle extends StatefulWidget {
  final double x;
  final double y;
  final double size;
  final Color color;
  final Duration duration;
  final Duration delay;

  const _AmbientParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.duration,
    required this.delay,
  });

  @override
  State<_AmbientParticle> createState() => _AmbientParticleState();
}

class _AmbientParticleState extends State<_AmbientParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _drift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _drift = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.x + _drift.value,
          top: widget.y + _drift.value * 0.5,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: widget.size * 2,
                    spreadRadius: widget.size * 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
