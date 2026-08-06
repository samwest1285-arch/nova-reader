import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which sides of the screen the tree border appears on.
class TreeBorderSides {
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const TreeBorderSides({
    this.top = false,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  /// Trees on all sides.
  static const all = TreeBorderSides(
    top: true,
    bottom: true,
    left: true,
    right: true,
  );

  /// Trees only on the bottom (like a forest floor).
  static const bottom = TreeBorderSides(bottom: true);

  /// Trees on left and right (like a forest path).
  static const sides = TreeBorderSides(left: true, right: true);
}

/// The shape of a tree silhouette.
enum TreeShape {
  pine,
  oak,
  willow,
}

/// Configuration for the tree border decoration.
class TreeBorderConfig {
  /// Which sides to show trees on.
  final TreeBorderSides sides;

  /// Density of trees (0.0 - 1.0). Higher = more trees.
  final double density;

  /// Speed of the sway animation (0.0 - 1.0).
  final double swaySpeed;

  /// Amplitude of the sway (0.0 - 10.0 pixels).
  final double swayAmplitude;

  /// Color of the tree silhouettes.
  final Color silhouetteColor;

  /// Opacity of the silhouettes (0.0 - 1.0).
  final double opacity;

  /// Height of the tree border area as a fraction of the widget size.
  final double borderHeightFraction;

  /// The tree shapes to use. If empty, all shapes are used.
  final List<TreeShape> shapes;

  const TreeBorderConfig({
    this.sides = const TreeBorderSides(bottom: true, left: true, right: true),
    this.density = 0.6,
    this.swaySpeed = 0.5,
    this.swayAmplitude = 3.0,
    this.silhouetteColor = const Color(0xFF1A1A1A),
    this.opacity = 0.8,
    this.borderHeightFraction = 0.15,
    this.shapes = const [TreeShape.pine, TreeShape.oak, TreeShape.willow],
  });

  /// A dense forest configuration.
  factory TreeBorderConfig.denseForest() => const TreeBorderConfig(
        sides: TreeBorderSides.all,
        density: 0.9,
        swaySpeed: 0.3,
        swayAmplitude: 2.0,
        borderHeightFraction: 0.2,
      );

  /// A light, sparse border.
  factory TreeBorderConfig.light() => const TreeBorderConfig(
        sides: TreeBorderSides.bottom,
        density: 0.3,
        swaySpeed: 0.7,
        swayAmplitude: 4.0,
        borderHeightFraction: 0.1,
      );
}

/// A decorative widget that draws tree silhouettes along the edges
/// with a gentle sway animation.
class TreeBorder extends StatefulWidget {
  /// Configuration for the tree border.
  final TreeBorderConfig config;

  /// The child widget to place inside the tree border.
  final Widget? child;

  /// Width of the widget. If null, fills the parent.
  final double? width;

  /// Height of the widget. If null, fills the parent.
  final double? height;

  const TreeBorder({
    super.key,
    this.config = const TreeBorderConfig(),
    this.child,
    this.width,
    this.height,
  });

  @override
  State<TreeBorder> createState() => _TreeBorderState();
}

class _TreeBorderState extends State<TreeBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _time;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _time = 0;
    _controller.addListener(() {
      _time += 0.016; // ~60fps
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          if (widget.child != null) widget.child!,
          Positioned.fill(
            child: CustomPaint(
              painter: _TreeBorderPainter(
                config: widget.config,
                time: _time,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws tree silhouettes.
class _TreeBorderPainter extends CustomPainter {
  final TreeBorderConfig config;
  final double time;

  _TreeBorderPainter({
    required this.config,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = config.silhouetteColor.withValues(alpha: config.opacity)
      ..style = PaintingStyle.fill;

    final swaySpeed = config.swaySpeed * 2.0;
    final swayAmp = config.swayAmplitude;

    if (config.sides.bottom) {
      _drawBottomTrees(canvas, size, paint, swaySpeed, swayAmp);
    }
    if (config.sides.top) {
      _drawTopTrees(canvas, size, paint, swaySpeed, swayAmp);
    }
    if (config.sides.left) {
      _drawLeftTrees(canvas, size, paint, swaySpeed, swayAmp);
    }
    if (config.sides.right) {
      _drawRightTrees(canvas, size, paint, swaySpeed, swayAmp);
    }
  }

  void _drawBottomTrees(
    Canvas canvas,
    Size size,
    Paint paint,
    double swaySpeed,
    double swayAmp,
  ) {
    final treeHeight = size.height * config.borderHeightFraction;
    final spacing = (size.width / (config.density * 15 + 5)).clamp(20.0, 80.0);
    final random = math.Random(42); // Fixed seed for consistent placement

    double x = -spacing;
    while (x < size.width + spacing) {
      final treeType = config.shapes[random.nextInt(config.shapes.length)];
      final heightVariation = 0.7 + random.nextDouble() * 0.6;
      final widthVariation = 0.8 + random.nextDouble() * 0.4;
      final sway = math.sin(time * swaySpeed + x * 0.05) * swayAmp;

      _drawTree(
        canvas,
        Offset(x + sway, size.height - treeHeight * heightVariation),
        treeHeight * heightVariation,
        spacing * 0.6 * widthVariation,
        treeType,
        paint,
        swaySpeed,
      );

      x += spacing * (0.5 + random.nextDouble() * 0.8);
    }
  }

  void _drawTopTrees(
    Canvas canvas,
    Size size,
    Paint paint,
    double swaySpeed,
    double swayAmp,
  ) {
    final treeHeight = size.height * config.borderHeightFraction;
    final spacing = (size.width / (config.density * 15 + 5)).clamp(20.0, 80.0);
    final random = math.Random(137);

    double x = -spacing;
    while (x < size.width + spacing) {
      final treeType = config.shapes[random.nextInt(config.shapes.length)];
      final heightVariation = 0.7 + random.nextDouble() * 0.6;
      final widthVariation = 0.8 + random.nextDouble() * 0.4;
      final sway = math.sin(time * swaySpeed + x * 0.05 + 1.0) * swayAmp;

      canvas.save();
      canvas.scale(1, -1);
      canvas.translate(0, -size.height);

      _drawTree(
        canvas,
        Offset(x + sway, 0),
        treeHeight * heightVariation,
        spacing * 0.6 * widthVariation,
        treeType,
        paint,
        swaySpeed,
      );

      canvas.restore();
      x += spacing * (0.5 + random.nextDouble() * 0.8);
    }
  }

  void _drawLeftTrees(
    Canvas canvas,
    Size size,
    Paint paint,
    double swaySpeed,
    double swayAmp,
  ) {
    final treeHeight = size.width * config.borderHeightFraction;
    final spacing = (size.height / (config.density * 12 + 4)).clamp(20.0, 80.0);
    final random = math.Random(73);

    double y = -spacing;
    while (y < size.height + spacing) {
      final treeType = config.shapes[random.nextInt(config.shapes.length)];
      final heightVariation = 0.7 + random.nextDouble() * 0.6;
      final widthVariation = 0.8 + random.nextDouble() * 0.4;
      final sway = math.sin(time * swaySpeed + y * 0.05 + 2.0) * swayAmp;

      canvas.save();
      canvas.rotate(-math.pi / 2);
      canvas.translate(-size.height, 0);

      _drawTree(
        canvas,
        Offset(y + sway, 0),
        treeHeight * heightVariation,
        spacing * 0.5 * widthVariation,
        treeType,
        paint,
        swaySpeed,
      );

      canvas.restore();
      y += spacing * (0.5 + random.nextDouble() * 0.8);
    }
  }

  void _drawRightTrees(
    Canvas canvas,
    Size size,
    Paint paint,
    double swaySpeed,
    double swayAmp,
  ) {
    final treeHeight = size.width * config.borderHeightFraction;
    final spacing = (size.height / (config.density * 12 + 4)).clamp(20.0, 80.0);
    final random = math.Random(199);

    double y = -spacing;
    while (y < size.height + spacing) {
      final treeType = config.shapes[random.nextInt(config.shapes.length)];
      final heightVariation = 0.7 + random.nextDouble() * 0.6;
      final widthVariation = 0.8 + random.nextDouble() * 0.4;
      final sway = math.sin(time * swaySpeed + y * 0.05 + 3.0) * swayAmp;

      canvas.save();
      canvas.rotate(math.pi / 2);
      canvas.translate(0, -size.width);

      _drawTree(
        canvas,
        Offset(y + sway, 0),
        treeHeight * heightVariation,
        spacing * 0.5 * widthVariation,
        treeType,
        paint,
        swaySpeed,
      );

      canvas.restore();
      y += spacing * (0.5 + random.nextDouble() * 0.8);
    }
  }

  void _drawTree(
    Canvas canvas,
    Offset position,
    double height,
    double width,
    TreeShape shape,
    Paint paint,
    double swaySpeed,
  ) {
    switch (shape) {
      case TreeShape.pine:
        _drawPine(canvas, position, height, width, paint, swaySpeed);
        break;
      case TreeShape.oak:
        _drawOak(canvas, position, height, width, paint, swaySpeed);
        break;
      case TreeShape.willow:
        _drawWillow(canvas, position, height, width, paint, swaySpeed);
        break;
    }
  }

  void _drawPine(
    Canvas canvas,
    Offset pos,
    double height,
    double width,
    Paint paint,
    double swaySpeed,
  ) {
    final path = Path();
    final layers = 4;
    final layerHeight = height / layers;

    // Trunk
    path.addRect(Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + height * 0.1),
      width: width * 0.15,
      height: height * 0.2,
    ));

    // Triangular layers
    for (int i = 0; i < layers; i++) {
      final layerY = pos.dy + (layers - 1 - i) * layerHeight;
      final layerWidth = width * (1.0 - i * 0.2);
      final layerH = layerHeight * 1.2;

      final layerSway = math.sin(time * swaySpeed * 0.5 + i * 1.5) * 2;

      path.moveTo(pos.dx + layerSway, layerY);
      path.lineTo(pos.dx + layerWidth / 2 + layerSway, layerY + layerH);
      path.lineTo(pos.dx - layerWidth / 2 + layerSway, layerY + layerH);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  void _drawOak(
    Canvas canvas,
    Offset pos,
    double height,
    double width,
    Paint paint,
    double swaySpeed,
  ) {
    final path = Path();

    // Trunk
    final trunkWidth = width * 0.2;
    final trunkHeight = height * 0.4;
    path.addRect(Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + trunkHeight * 0.5),
      width: trunkWidth,
      height: trunkHeight,
    ));

    // Main branches
    final branchSway = math.sin(time * swaySpeed * 0.3) * 3;
    final branchPath = Path()
      ..moveTo(pos.dx, pos.dy + trunkHeight * 0.3)
      ..quadraticBezierTo(
        pos.dx - width * 0.3 + branchSway,
        pos.dy + trunkHeight * 0.1,
        pos.dx - width * 0.5 + branchSway * 1.5,
        pos.dy,
      )
      ..moveTo(pos.dx, pos.dy + trunkHeight * 0.3)
      ..quadraticBezierTo(
        pos.dx + width * 0.3 - branchSway,
        pos.dy + trunkHeight * 0.1,
        pos.dx + width * 0.5 - branchSway * 1.5,
        pos.dy,
      );
    canvas.drawPath(branchPath, paint);

    // Foliage (multiple overlapping circles)
    final foliagePaint = Paint()
      ..color = config.silhouetteColor.withValues(alpha: config.opacity)
      ..style = PaintingStyle.fill;

    final sway = math.sin(time * swaySpeed * 0.4) * 2;
    final foliageCenters = [
      Offset(pos.dx + sway, pos.dy - height * 0.1),
      Offset(pos.dx - width * 0.3 + sway * 0.5, pos.dy + height * 0.05),
      Offset(pos.dx + width * 0.3 + sway * 0.5, pos.dy + height * 0.05),
      Offset(pos.dx - width * 0.15 + sway, pos.dy - height * 0.25),
      Offset(pos.dx + width * 0.15 + sway, pos.dy - height * 0.25),
    ];

    for (final center in foliageCenters) {
      canvas.drawCircle(
        center,
        width * 0.35,
        foliagePaint,
      );
    }

    // Extra foliage on top
    canvas.drawCircle(
      Offset(pos.dx + sway * 0.3, pos.dy - height * 0.35),
      width * 0.25,
      foliagePaint,
    );
  }

  void _drawWillow(
    Canvas canvas,
    Offset pos,
    double height,
    double width,
    Paint paint,
    double swaySpeed,
  ) {
    final path = Path();

    // Trunk (wider at base, tapering)
    final trunkWidth = width * 0.25;
    final trunkHeight = height * 0.35;
    path.moveTo(pos.dx - trunkWidth / 2, pos.dy + trunkHeight);
    path.quadraticBezierTo(
      pos.dx - trunkWidth * 0.3,
      pos.dy + trunkHeight * 0.3,
      pos.dx - trunkWidth * 0.1,
      pos.dy,
    );
    path.quadraticBezierTo(
      pos.dx + trunkWidth * 0.1,
      pos.dy + trunkHeight * 0.3,
      pos.dx + trunkWidth / 2,
      pos.dy + trunkHeight,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Foliage canopy (rounded top)
    final canopyPaint = Paint()
      ..color = config.silhouetteColor.withValues(alpha: config.opacity)
      ..style = PaintingStyle.fill;

    final sway = math.sin(time * swaySpeed * 0.3) * 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + sway * 0.5, pos.dy - height * 0.15),
        width: width * 1.2,
        height: height * 0.5,
      ),
      canopyPaint,
    );

    // Drooping branches (willow fronds)
    final frondPaint = Paint()
      ..color = config.silhouetteColor.withValues(alpha: config.opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi - math.pi / 2;
      final frondSway = math.sin(time * swaySpeed * 0.5 + i * 0.8) * 5;
      final baseX = pos.dx + math.cos(angle) * width * 0.4 + sway;
      final baseY = pos.dy - height * 0.1;

      final frondPath = Path()
        ..moveTo(baseX, baseY)
        ..quadraticBezierTo(
          baseX + math.cos(angle + 0.3) * width * 0.3 + frondSway,
          baseY + height * 0.2,
          baseX + math.cos(angle + 0.5) * width * 0.2 + frondSway * 1.5,
          baseY + height * 0.4,
        );
      canvas.drawPath(frondPath, frondPaint);
    }

    // Additional hanging fronds
    for (int i = 0; i < 5; i++) {
      final frondSway = math.sin(time * swaySpeed * 0.6 + i * 1.2) * 4;
      final x = pos.dx + (i - 2) * width * 0.15 + sway;

      final hangingPath = Path()
        ..moveTo(x, pos.dy - height * 0.1)
        ..quadraticBezierTo(
          x + frondSway,
          pos.dy + height * 0.15,
          x + frondSway * 1.5,
          pos.dy + height * 0.35,
        );
      canvas.drawPath(hangingPath, frondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeBorderPainter oldDelegate) => true;
}
