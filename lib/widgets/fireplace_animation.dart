import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single spark particle in the fireplace particle system.
class _Spark {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  double size;
  double brightness;

  _Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    this.size = 2.0,
    this.brightness = 1.0,
  });

  bool get isAlive => life > 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy -= 80 * dt; // gravity pulling sparks up (negative y)
    life -= dt;
    final lifeRatio = life / maxLife;
    brightness = lifeRatio.clamp(0.0, 1.0);
    size = 1.0 + lifeRatio * 2.0;
  }
}

/// Configuration for the fireplace animation.
class FireplaceConfig {
  /// Intensity of the flames (0.0 - 1.0).
  final double flameIntensity;

  /// Color of the flame core (hottest part).
  final Color flameCoreColor;

  /// Color of the flame mid-section.
  final Color flameMidColor;

  /// Color of the flame tips.
  final Color flameTipColor;

  /// Color of the sparks.
  final Color sparkColor;

  /// Color of the logs.
  final Color logColor;

  /// Color of the glowing embers on logs.
  final Color emberColor;

  /// Background glow color.
  final Color glowColor;

  /// Number of flame segments drawn.
  final int flameSegments;

  /// Maximum number of sparks.
  final int maxSparks;

  const FireplaceConfig({
    this.flameIntensity = 0.8,
    this.flameCoreColor = const Color(0xFFFFF8E1),
    this.flameMidColor = const Color(0xFFFFB300),
    this.flameTipColor = const Color(0xFFE65100),
    this.sparkColor = const Color(0xFFFFD54F),
    this.logColor = const Color(0xFF3E2723),
    this.emberColor = const Color(0xFFFF6F00),
    this.glowColor = const Color(0xFFFF8F00),
    this.flameSegments = 5,
    this.maxSparks = 30,
  });

  /// A low-intensity, cozy fire config.
  factory FireplaceConfig.cozy() => const FireplaceConfig(
        flameIntensity: 0.5,
        flameCoreColor: Color(0xFFFFF8E1),
        flameMidColor: Color(0xFFFFB300),
        flameTipColor: Color(0xFFE65100),
        sparkColor: Color(0xFFFFD54F),
        logColor: Color(0xFF3E2723),
        emberColor: Color(0xFFFF6F00),
        glowColor: Color(0xFFFF8F00),
        maxSparks: 15,
      );

  /// A roaring, high-intensity fire config.
  factory FireplaceConfig.roaring() => const FireplaceConfig(
        flameIntensity: 1.0,
        flameCoreColor: Color(0xFFFFFDE7),
        flameMidColor: Color(0xFFFFC107),
        flameTipColor: Color(0xFFD84315),
        sparkColor: Color(0xFFFFD54F),
        logColor: Color(0xFF2C1810),
        emberColor: Color(0xFFFF6F00),
        glowColor: Color(0xFFFF8F00),
        flameSegments: 7,
        maxSparks: 40,
      );
}

/// A mesmerizing fireplace animation widget with animated flames,
/// particle sparks, glowing logs, and a warm ambient glow effect.
class FireplaceAnimation extends StatefulWidget {
  /// Configuration for the fireplace.
  final FireplaceConfig config;

  /// Width of the fireplace area.
  final double width;

  /// Height of the fireplace area.
  final double height;

  /// Whether the animation is running.
  final bool isActive;

  const FireplaceAnimation({
    super.key,
    this.config = const FireplaceConfig(),
    this.width = 300,
    this.height = 250,
    this.isActive = true,
  });

  @override
  State<FireplaceAnimation> createState() => _FireplaceAnimationState();
}

class _FireplaceAnimationState extends State<FireplaceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Spark> _sparks = [];
  final math.Random _random = math.Random();
  late double _lastTime;
  double _flamePhase = 0;

  // Flame noise offsets for organic movement
  final List<double> _flameOffsets = List.generate(7, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _lastTime = DateTime.now().microsecondsSinceEpoch / 1000000.0;

    // Initialize some sparks
    for (int i = 0; i < widget.config.maxSparks ~/ 3; i++) {
      _addSpark();
    }

    _controller.addListener(_updateAnimation);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateAnimation);
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    if (!widget.isActive) return;

    final now = DateTime.now().microsecondsSinceEpoch / 1000000.0;
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    _flamePhase += dt * 3.0;

    // Update flame offsets for organic movement
    for (int i = 0; i < _flameOffsets.length; i++) {
      _flameOffsets[i] = math.sin(_flamePhase + i * 1.2) * 0.3 +
          math.cos(_flamePhase * 0.7 + i * 0.8) * 0.2;
    }

    // Update sparks
    for (final spark in _sparks) {
      spark.update(dt);
    }
    _sparks.removeWhere((s) => !s.isAlive);

    // Add new sparks
    final spawnRate = (widget.config.flameIntensity * 8).toInt() + 2;
    if (_random.nextDouble() < spawnRate * dt) {
      _addSpark();
    }

    setState(() {});
  }

  void _addSpark() {
    final cx = widget.width / 2;
    final baseY = widget.height * 0.7;
    final intensity = widget.config.flameIntensity;

    _sparks.add(_Spark(
      x: cx + (_random.nextDouble() - 0.5) * 40 * intensity,
      y: baseY - _random.nextDouble() * 20,
      vx: (_random.nextDouble() - 0.5) * 60 * intensity,
      vy: -(80 + _random.nextDouble() * 120) * intensity,
      life: 0.5 + _random.nextDouble() * 1.5,
      maxLife: 2.0,
      size: 1.0 + _random.nextDouble() * 2.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _FireplacePainter(
          config: widget.config,
          flamePhase: _flamePhase,
          flameOffsets: _flameOffsets,
          sparks: _sparks,
          random: _random,
        ),
      ),
    );
  }
}

/// Custom painter for the fireplace animation.
class _FireplacePainter extends CustomPainter {
  final FireplaceConfig config;
  final double flamePhase;
  final List<double> flameOffsets;
  final List<_Spark> sparks;
  final math.Random random;

  _FireplacePainter({
    required this.config,
    required this.flamePhase,
    required this.flameOffsets,
    required this.sparks,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.7;
    final intensity = config.flameIntensity;

    // Draw the fireplace structure (brick arch)
    _drawFireplaceStructure(canvas, size, cx, baseY);

    // Draw the glow effect behind the flames
    _drawGlow(canvas, size, cx, baseY, intensity);

    // Draw the logs
    _drawLogs(canvas, size, cx, baseY);

    // Draw the flames
    _drawFlames(canvas, size, cx, baseY, intensity);

    // Draw the sparks
    _drawSparks(canvas, size);
  }

  void _drawFireplaceStructure(Canvas canvas, Size size, double cx, double baseY) {
    final brickPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;

    // Fireplace arch
    final archPath = Path()
      ..moveTo(cx - size.width * 0.4, baseY + size.height * 0.2)
      ..lineTo(cx - size.width * 0.4, baseY - size.height * 0.1)
      ..quadraticBezierTo(
        cx - size.width * 0.4, baseY - size.height * 0.4,
        cx, baseY - size.height * 0.45,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.4, baseY - size.height * 0.4,
        cx + size.width * 0.4, baseY - size.height * 0.1,
      )
      ..lineTo(cx + size.width * 0.4, baseY + size.height * 0.2)
      ..close();
    canvas.drawPath(archPath, brickPaint);

    // Brick texture (horizontal lines)
    final mortarPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = baseY - size.height * 0.35; y < baseY + size.height * 0.15; y += 12) {
      final lineWidth = (size.width * 0.8) * (1 - ((y - (baseY - size.height * 0.35)) / (size.height * 0.5)).abs());
      if (lineWidth > 10) {
        canvas.drawLine(
          Offset(cx - lineWidth / 2, y),
          Offset(cx + lineWidth / 2, y),
          mortarPaint,
        );
      }
    }

    // Fireplace hearth
    final hearthPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        cx - size.width * 0.42,
        baseY + size.height * 0.15,
        cx + size.width * 0.42,
        baseY + size.height * 0.25,
      ),
      hearthPaint,
    );

    // Hearth top edge
    final hearthTopPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        cx - size.width * 0.42,
        baseY + size.height * 0.15,
        cx + size.width * 0.42,
        baseY + size.height * 0.18,
      ),
      hearthTopPaint,
    );

    // Fireplace interior (dark void)
    final interiorPaint = Paint()
      ..color = const Color(0xFF1A0F0A)
      ..style = PaintingStyle.fill;

    final interiorPath = Path()
      ..moveTo(cx - size.width * 0.35, baseY + size.height * 0.15)
      ..lineTo(cx - size.width * 0.35, baseY - size.height * 0.05)
      ..quadraticBezierTo(
        cx - size.width * 0.35, baseY - size.height * 0.3,
        cx, baseY - size.height * 0.35,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.35, baseY - size.height * 0.3,
        cx + size.width * 0.35, baseY - size.height * 0.05,
      )
      ..lineTo(cx + size.width * 0.35, baseY + size.height * 0.15)
      ..close();
    canvas.drawPath(interiorPath, interiorPaint);
  }

  void _drawGlow(Canvas canvas, Size size, double cx, double baseY, double intensity) {
    // Radial gradient for the glow
    final glowGradient = RadialGradient(
      center: Alignment(cx / size.width - 0.5, baseY / size.height - 0.5),
      radius: 0.6,
      colors: [
        config.glowColor.withValues(alpha: 0.3 * intensity),
        config.glowColor.withValues(alpha: 0.1 * intensity),
        config.glowColor.withValues(alpha: 0.0),
      ],
    );

    final glowPaint = Paint()
      ..shader = glowGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      glowPaint,
    );

    // Additional bright glow near the flame base
    final coreGlowGradient = RadialGradient(
      center: const Alignment(0, 0.3),
      radius: 0.3,
      colors: [
        config.glowColor.withValues(alpha: 0.4 * intensity),
        config.glowColor.withValues(alpha: 0.0),
      ],
    );

    final coreGlowPaint = Paint()
      ..shader = coreGlowGradient.createShader(
        Rect.fromLTWH(cx - size.width * 0.3, baseY - size.height * 0.3, size.width * 0.6, size.height * 0.5),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRect(
      Rect.fromLTWH(cx - size.width * 0.3, baseY - size.height * 0.3, size.width * 0.6, size.height * 0.5),
      coreGlowPaint,
    );
  }

  void _drawLogs(Canvas canvas, Size size, double cx, double baseY) {
    // Draw 3 logs in a criss-cross pattern
    final logPositions = [
      {'x': -0.12, 'y': 0.05, 'angle': -0.15, 'length': 0.5},
      {'x': 0.08, 'y': 0.08, 'angle': 0.2, 'length': 0.45},
      {'x': -0.02, 'y': 0.0, 'angle': -0.05, 'length': 0.4},
    ];

    for (final log in logPositions) {
      final logX = cx + size.width * (log['x'] as double);
      final logY = baseY + size.height * (log['y'] as double);
      final angle = log['angle'] as double;
      final length = size.width * (log['length'] as double);

      _drawSingleLog(canvas, logX, logY, angle, length);
    }
  }

  void _drawSingleLog(Canvas canvas, double cx, double cy, double angle, double length) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final logPaint = Paint()
      ..color = config.logColor
      ..style = PaintingStyle.fill;

    // Log body (rounded rectangle)
    final logRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: length * 0.2,
      ),
      Radius.circular(length * 0.1),
    );
    canvas.drawRRect(logRect, logPaint);

    // Log grain lines
    final grainPaint = Paint()
      ..color = config.logColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = -3; i <= 3; i++) {
      final grainY = i * (length * 0.025);
      canvas.drawLine(
        Offset(-length * 0.4, grainY),
        Offset(length * 0.4, grainY),
        grainPaint,
      );
    }

    // Log end circles (cross-section)
    final endPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(-length / 2, 0),
      length * 0.1,
      endPaint,
    );
    canvas.drawCircle(
      Offset(length / 2, 0),
      length * 0.1,
      endPaint,
    );

    // Glowing embers on the log
    final emberGlow = math.sin(flamePhase * 2 + cx) * 0.3 + 0.5;
    final emberPaint = Paint()
      ..color = config.emberColor.withValues(alpha: 0.6 * emberGlow)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(length * 0.1, -length * 0.02),
      length * 0.03,
      emberPaint,
    );
    canvas.drawCircle(
      Offset(-length * 0.15, length * 0.02),
      length * 0.025,
      emberPaint,
    );

    // Ember glow blur
    final emberGlowPaint = Paint()
      ..color = config.emberColor.withValues(alpha: 0.2 * emberGlow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(length * 0.1, -length * 0.02),
      length * 0.08,
      emberGlowPaint,
    );
    canvas.drawCircle(
      Offset(-length * 0.15, length * 0.02),
      length * 0.06,
      emberGlowPaint,
    );

    canvas.restore();
  }

  void _drawFlames(Canvas canvas, Size size, double cx, double baseY, double intensity) {
    final numFlames = config.flameSegments;

    for (int i = 0; i < numFlames; i++) {
      final t = i / (numFlames - 1);
      final flameWidth = 20 + (1 - t) * 50;
      final flameHeight = 30 + (1 - t) * 80;
      final offsetX = flameOffsets[i % flameOffsets.length] * 15;

      // Interpolate flame color from core to tip
      final Color flameColor;
      if (t < 0.3) {
        flameColor = Color.lerp(config.flameCoreColor, config.flameMidColor, t / 0.3)!;
      } else if (t < 0.6) {
        flameColor = Color.lerp(config.flameMidColor, config.flameTipColor, (t - 0.3) / 0.3)!;
      } else {
        flameColor = Color.lerp(
          config.flameTipColor,
          config.flameTipColor.withValues(alpha: 0.0),
          (t - 0.6) / 0.4,
        )!;
      }

      final flamePaint = Paint()
        ..color = flameColor.withValues(alpha: (1 - t * 0.3) * intensity)
        ..style = PaintingStyle.fill;

      // Animated flame shape using sine waves
      final flamePath = Path();
      final baseX = cx + offsetX + (i - numFlames / 2) * 12;
      final baseYPos = baseY + 5;

      flamePath.moveTo(baseX - flameWidth / 2, baseYPos);

      // Left side of flame
      final leftPoints = 8;
      for (int j = 0; j <= leftPoints; j++) {
        final progress = j / leftPoints;
        final y = baseYPos - flameHeight * progress;
        final wobble = math.sin(flamePhase * 2 + i * 1.5 + j * 0.8) * 5 * (1 - progress * 0.5);
        final x = baseX - (flameWidth / 2) * (1 - progress) + wobble;
        flamePath.lineTo(x, y);
      }

      // Flame tip
      final tipWobble = math.sin(flamePhase * 3 + i * 2.0) * 3;
      flamePath.lineTo(baseX + tipWobble, baseYPos - flameHeight - 5);

      // Right side of flame
      for (int j = leftPoints; j >= 0; j--) {
        final progress = j / leftPoints;
        final y = baseYPos - flameHeight * progress;
        final wobble = math.sin(flamePhase * 2 + i * 1.5 + j * 0.8 + 1) * 5 * (1 - progress * 0.5);
        final x = baseX + (flameWidth / 2) * (1 - progress) + wobble;
        flamePath.lineTo(x, y);
      }

      flamePath.close();
      canvas.drawPath(flamePath, flamePaint);

      // Inner flame (brighter core)
      if (t < 0.4) {
        final innerPaint = Paint()
          ..color = config.flameCoreColor.withValues(alpha: 0.4 * intensity)
          ..style = PaintingStyle.fill;

        final innerPath = Path();
        final innerWidth = flameWidth * 0.4;
        final innerHeight = flameHeight * 0.5;

        innerPath.moveTo(baseX - innerWidth / 2, baseYPos);
        for (int j = 0; j <= 6; j++) {
          final progress = j / 6;
          final y = baseYPos - innerHeight * progress;
          final wobble = math.sin(flamePhase * 3 + i * 2.0 + j * 1.2) * 3 * (1 - progress);
          final x = baseX - (innerWidth / 2) * (1 - progress) + wobble;
          innerPath.lineTo(x, y);
        }
        innerPath.lineTo(baseX, baseYPos - innerHeight - 2);
        for (int j = 6; j >= 0; j--) {
          final progress = j / 6;
          final y = baseYPos - innerHeight * progress;
          final wobble = math.sin(flamePhase * 3 + i * 2.0 + j * 1.2 + 1) * 3 * (1 - progress);
          final x = baseX + (innerWidth / 2) * (1 - progress) + wobble;
          innerPath.lineTo(x, y);
        }
        innerPath.close();
        canvas.drawPath(innerPath, innerPaint);
      }
    }
  }

  void _drawSparks(Canvas canvas, Size size) {
    for (final spark in sparks) {
      final alpha = spark.brightness.clamp(0.0, 1.0);
      final sparkPaint = Paint()
        ..color = config.sparkColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(spark.x, spark.y),
        spark.size,
        sparkPaint,
      );

      // Spark glow
      if (spark.brightness > 0.3) {
        final glowPaint = Paint()
          ..color = config.sparkColor.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(
          Offset(spark.x, spark.y),
          spark.size * 2.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireplacePainter oldDelegate) => true;
}
