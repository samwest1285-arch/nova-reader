import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Time-of-day based greeting categories.
enum ButlerGreetingType {
  morning,
  afternoon,
  evening,
  night,
}

/// Configuration for the butler's color theme.
class ButlerColorTheme {
  final Color suitColor;
  final Color hatColor;
  final Color skinColor;
  final Color monocleColor;
  final Color bowtieColor;
  final Color speechBubbleColor;
  final Color speechBubbleTextColor;

  const ButlerColorTheme({
    this.suitColor = const Color(0xFF2C1810),
    this.hatColor = const Color(0xFF1A0F0A),
    this.skinColor = const Color(0xFFF5D6B8),
    this.monocleColor = const Color(0xFFFFD700),
    this.bowtieColor = const Color(0xFF8B0000),
    this.speechBubbleColor = const Color(0xFFFFF8E1),
    this.speechBubbleTextColor = const Color(0xFF3E2723),
  });

  /// A warm, cozy theme for evening/night.
  factory ButlerColorTheme.cozy() => const ButlerColorTheme(
        suitColor: Color(0xFF3E2723),
        hatColor: Color(0xFF1A0F0A),
        skinColor: Color(0xFFF5D6B8),
        monocleColor: Color(0xFFFFD700),
        bowtieColor: Color(0xFF8B0000),
        speechBubbleColor: Color(0xFFFFF3E0),
        speechBubbleTextColor: Color(0xFF3E2723),
      );

  /// A lighter theme for morning.
  factory ButlerColorTheme.morning() => const ButlerColorTheme(
        suitColor: Color(0xFF5D4037),
        hatColor: Color(0xFF3E2723),
        skinColor: Color(0xFFFFE0B2),
        monocleColor: Color(0xFFFFC107),
        bowtieColor: Color(0xFFD32F2F),
        speechBubbleColor: Color(0xFFFFF8E1),
        speechBubbleTextColor: Color(0xFF3E2723),
      );

  /// A festive theme for special occasions.
  factory ButlerColorTheme.festive() => const ButlerColorTheme(
        suitColor: Color(0xFF1B5E20),
        hatColor: Color(0xFF0D3B0F),
        skinColor: Color(0xFFF5D6B8),
        monocleColor: Color(0xFFFFD700),
        bowtieColor: Color(0xFFB71C1C),
        speechBubbleColor: Color(0xFFFFF8E1),
        speechBubbleTextColor: Color(0xFF1B5E20),
      );
}

/// A widget that displays a cute butler character with a speech bubble
/// and book recommendation. The butler is drawn with [CustomPainter] and
/// features a subtle idle bob animation.
class ButlerGreeting extends StatefulWidget {
  /// Custom greeting text. If null, a random time-appropriate greeting is used.
  final String? greeting;

  /// Book recommendation text shown below the butler.
  final String? recommendation;

  /// Color theme for the butler.
  final ButlerColorTheme colorTheme;

  /// Height of the butler character area.
  final double butlerHeight;

  /// Width of the butler character area.
  final double butlerWidth;

  /// Whether to show the speech bubble.
  final bool showSpeechBubble;

  /// Whether to show the recommendation text.
  final bool showRecommendation;

  /// Callback when the butler is tapped.
  final VoidCallback? onTap;

  const ButlerGreeting({
    super.key,
    this.greeting,
    this.recommendation,
    this.colorTheme = const ButlerColorTheme(),
    this.butlerHeight = 200,
    this.butlerWidth = 160,
    this.showSpeechBubble = true,
    this.showRecommendation = true,
    this.onTap,
  });

  @override
  State<ButlerGreeting> createState() => _ButlerGreetingState();
}

class _ButlerGreetingState extends State<ButlerGreeting>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;
  late String _currentGreeting;
  late ButlerGreetingType _greetingType;

  // Morning greetings
  static const _morningGreetings = [
    'Good morning! Ready for a new chapter?',
    'A fresh morning and a fresh page await!',
    'Rise and shine! Your books miss you.',
    'Morning coffee and a good book — perfection!',
    'The early reader catches the best stories!',
  ];

  // Afternoon greetings
  static const _afternoonGreetings = [
    'Good afternoon! Time for a reading break?',
    'The afternoon sun calls for a cozy read.',
    'Hope your day is as good as a bestseller!',
    'Afternoon delight — a book and a comfy chair.',
    'Half the day gone, but the best chapters remain!',
  ];

  // Evening greetings
  static const _eveningGreetings = [
    'Good evening! Time to unwind with a book.',
    'The fireplace is warm and your book awaits.',
    'Evening is the perfect time for stories.',
    'Settle in — the night is young for reading.',
    'Let the words carry you away this evening.',
  ];

  // Night greetings
  static const _nightGreetings = [
    'Good night! One more chapter before bed?',
    'The stars are out and your book is open.',
    'A quiet night and a gripping tale — perfect.',
    'Just one more page... you know you want to.',
    'Night owls and book lovers, unite!',
  ];

  // Book recommendations
  static const _recommendations = [
    'Have you tried "The Name of the Wind"?',
    '"The Hobbit" is always a good choice!',
    'How about some Sherlock Holmes tonight?',
    '"Pride and Prejudice" — a timeless classic.',
    'Try "Dune" for an epic adventure!',
    '"The Night Circus" has a magical atmosphere.',
    '"The Alchemist" is perfect for dreamers.',
    '"Jane Eyre" — a gothic masterpiece.',
    '"The House in the Cerulean Sea" is heartwarming.',
    '"Project Hail Mary" for sci-fi lovers.',
  ];

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _bobAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOutSine),
    );
    _greetingType = _getGreetingType();
    _currentGreeting = widget.greeting ?? _randomGreeting(_greetingType);
  }

  @override
  void didUpdateWidget(ButlerGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.greeting != null && widget.greeting != oldWidget.greeting) {
      _currentGreeting = widget.greeting!;
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  ButlerGreetingType _getGreetingType() {
    final now = TimeOfDay.now();
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return ButlerGreetingType.morning;
    if (hour >= 12 && hour < 17) return ButlerGreetingType.afternoon;
    if (hour >= 17 && hour < 21) return ButlerGreetingType.evening;
    return ButlerGreetingType.night;
  }

  String _randomGreeting(ButlerGreetingType type) {
    final random = math.Random();
    switch (type) {
      case ButlerGreetingType.morning:
        return _morningGreetings[random.nextInt(_morningGreetings.length)];
      case ButlerGreetingType.afternoon:
        return _afternoonGreetings[random.nextInt(_afternoonGreetings.length)];
      case ButlerGreetingType.evening:
        return _eveningGreetings[random.nextInt(_eveningGreetings.length)];
      case ButlerGreetingType.night:
        return _nightGreetings[random.nextInt(_nightGreetings.length)];
    }
  }

  String _randomRecommendation() {
    final random = math.Random();
    return _recommendations[random.nextInt(_recommendations.length)];
  }

  /// Refreshes the greeting and recommendation with new random values.
  void refresh() {
    setState(() {
      _greetingType = _getGreetingType();
      _currentGreeting = _randomGreeting(_greetingType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendation = widget.recommendation ?? _randomRecommendation();

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        refresh();
      },
      child: AnimatedBuilder(
        animation: _bobAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speech bubble
              if (widget.showSpeechBubble)
                _SpeechBubble(
                  text: _currentGreeting,
                  bubbleColor: widget.colorTheme.speechBubbleColor,
                  textColor: widget.colorTheme.speechBubbleTextColor,
                ),
              const SizedBox(height: 8),
              // Butler character
              SizedBox(
                width: widget.butlerWidth,
                height: widget.butlerHeight,
                child: Transform.translate(
                  offset: Offset(0, _bobAnimation.value),
                  child: CustomPaint(
                    size: Size(widget.butlerWidth, widget.butlerHeight),
                    painter: _ButlerPainter(
                      colorTheme: widget.colorTheme,
                    ),
                  ),
                ),
              ),
              // Recommendation text
              if (widget.showRecommendation) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    recommendation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A speech bubble widget with a tail pointing down.
class _SpeechBubble extends StatelessWidget {
  final String text;
  final Color bubbleColor;
  final Color textColor;

  const _SpeechBubble({
    required this.text,
    required this.bubbleColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        painter: _SpeechBubblePainter(bubbleColor: bubbleColor),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Georgia',
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Paints the speech bubble with a tail.
class _SpeechBubblePainter extends CustomPainter {
  final Color bubbleColor;

  _SpeechBubblePainter({required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 10),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, paint);

    // Draw the tail (triangle pointing down)
    final tailPath = Path()
      ..moveTo(size.width / 2 - 8, size.height - 10)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 8, size.height - 10)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Draw a subtle border
    final borderPaint = Paint()
      ..color = bubbleColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.bubbleColor != bubbleColor;
}

/// Custom painter that draws a cute stylized butler character.
class _ButlerPainter extends CustomPainter {
  final ButlerColorTheme colorTheme;

  _ButlerPainter({required this.colorTheme});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 160;

    // Draw the body (suit jacket)
    _drawBody(canvas, cx, cy, scale);

    // Draw the bowtie
    _drawBowtie(canvas, cx, cy, scale);

    // Draw the head
    _drawHead(canvas, cx, cy, scale);

    // Draw the top hat
    _drawTopHat(canvas, cx, cy, scale);

    // Draw the monocle
    _drawMonocle(canvas, cx, cy, scale);

    // Draw the eyes and face
    _drawFace(canvas, cx, cy, scale);
  }

  void _drawBody(Canvas canvas, double cx, double cy, double scale) {
    final bodyPaint = Paint()
      ..color = colorTheme.suitColor
      ..style = PaintingStyle.fill;

    // Main torso
    final bodyPath = Path()
      ..moveTo(cx - 30 * scale, cy - 10 * scale)
      ..quadraticBezierTo(
        cx - 35 * scale, cy + 20 * scale,
        cx - 28 * scale, cy + 50 * scale,
      )
      ..lineTo(cx + 28 * scale, cy + 50 * scale)
      ..quadraticBezierTo(
        cx + 35 * scale, cy + 20 * scale,
        cx + 30 * scale, cy - 10 * scale,
      )
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Collar / lapels
    final lapelPaint = Paint()
      ..color = colorTheme.suitColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final lapelPath = Path()
      ..moveTo(cx - 10 * scale, cy - 10 * scale)
      ..lineTo(cx, cy + 5 * scale)
      ..lineTo(cx + 10 * scale, cy - 10 * scale)
      ..close();
    canvas.drawPath(lapelPath, lapelPaint);

    // White shirt triangle
    final shirtPaint = Paint()
      ..color = const Color(0xFFF5F5F0)
      ..style = PaintingStyle.fill;

    final shirtPath = Path()
      ..moveTo(cx - 6 * scale, cy - 8 * scale)
      ..lineTo(cx, cy + 3 * scale)
      ..lineTo(cx + 6 * scale, cy - 8 * scale)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);
  }

  void _drawBowtie(Canvas canvas, double cx, double cy, double scale) {
    final bowPaint = Paint()
      ..color = colorTheme.bowtieColor
      ..style = PaintingStyle.fill;

    // Left wing
    final leftWing = Path()
      ..moveTo(cx, cy - 5 * scale)
      ..quadraticBezierTo(
        cx - 14 * scale, cy - 2 * scale,
        cx - 10 * scale, cy + 2 * scale,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(leftWing, bowPaint);

    // Right wing
    final rightWing = Path()
      ..moveTo(cx, cy - 5 * scale)
      ..quadraticBezierTo(
        cx + 14 * scale, cy - 2 * scale,
        cx + 10 * scale, cy + 2 * scale,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(rightWing, bowPaint);

    // Center knot
    canvas.drawCircle(
      Offset(cx, cy - 1 * scale),
      3 * scale,
      bowPaint,
    );
  }

  void _drawHead(Canvas canvas, double cx, double cy, double scale) {
    final headPaint = Paint()
      ..color = colorTheme.skinColor
      ..style = PaintingStyle.fill;

    // Oval head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 28 * scale),
        width: 44 * scale,
        height: 50 * scale,
      ),
      headPaint,
    );

    // Ears
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 22 * scale, cy - 28 * scale),
        width: 10 * scale,
        height: 16 * scale,
      ),
      headPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 22 * scale, cy - 28 * scale),
        width: 10 * scale,
        height: 16 * scale,
      ),
      headPaint,
    );
  }

  void _drawTopHat(Canvas canvas, double cx, double cy, double scale) {
    final hatPaint = Paint()
      ..color = colorTheme.hatColor
      ..style = PaintingStyle.fill;

    // Hat brim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 50 * scale),
        width: 50 * scale,
        height: 10 * scale,
      ),
      hatPaint,
    );

    // Hat body
    final hatBody = Path()
      ..moveTo(cx - 18 * scale, cy - 50 * scale)
      ..lineTo(cx - 18 * scale, cy - 72 * scale)
      ..quadraticBezierTo(
        cx, cy - 76 * scale,
        cx + 18 * scale, cy - 72 * scale,
      )
      ..lineTo(cx + 18 * scale, cy - 50 * scale)
      ..close();
    canvas.drawPath(hatBody, hatPaint);

    // Hat band
    final bandPaint = Paint()
      ..color = colorTheme.bowtieColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        cx - 18 * scale,
        cy - 54 * scale,
        cx + 18 * scale,
        cy - 50 * scale,
      ),
      bandPaint,
    );
  }

  void _drawMonocle(Canvas canvas, double cx, double cy, double scale) {
    final monoclePaint = Paint()
      ..color = colorTheme.monocleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    // Monocle ring
    canvas.drawCircle(
      Offset(cx + 8 * scale, cy - 30 * scale),
      10 * scale,
      monoclePaint,
    );

    // Chain
    final chainPaint = Paint()
      ..color = colorTheme.monocleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;

    final chainPath = Path()
      ..moveTo(cx + 8 * scale, cy - 20 * scale)
      ..quadraticBezierTo(
        cx + 20 * scale, cy - 10 * scale,
        cx + 15 * scale, cy,
      );
    canvas.drawPath(chainPath, chainPaint);

    // Monocle glass (subtle tint)
    final glassPaint = Paint()
      ..color = colorTheme.monocleColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cx + 8 * scale, cy - 30 * scale),
      10 * scale,
      glassPaint,
    );
  }

  void _drawFace(Canvas canvas, double cx, double cy, double scale) {
    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawCircle(
      Offset(cx - 8 * scale, cy - 30 * scale),
      2.5 * scale,
      eyePaint,
    );

    // Right eye (behind monocle, slightly larger)
    canvas.drawCircle(
      Offset(cx + 8 * scale, cy - 30 * scale),
      2.5 * scale,
      eyePaint,
    );

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    final leftBrow = Path()
      ..moveTo(cx - 14 * scale, cy - 36 * scale)
      ..quadraticBezierTo(
        cx - 8 * scale, cy - 40 * scale,
        cx - 3 * scale, cy - 36 * scale,
      );
    canvas.drawPath(leftBrow, browPaint);

    final rightBrow = Path()
      ..moveTo(cx + 3 * scale, cy - 36 * scale)
      ..quadraticBezierTo(
        cx + 8 * scale, cy - 40 * scale,
        cx + 14 * scale, cy - 36 * scale,
      );
    canvas.drawPath(rightBrow, browPaint);

    // Nose
    final nosePaint = Paint()
      ..color = colorTheme.skinColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final nosePath = Path()
      ..moveTo(cx, cy - 24 * scale)
      ..quadraticBezierTo(
        cx + 3 * scale, cy - 20 * scale,
        cx, cy - 18 * scale,
      )
      ..quadraticBezierTo(
        cx - 3 * scale, cy - 20 * scale,
        cx, cy - 24 * scale,
      )
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..moveTo(cx - 8 * scale, cy - 18 * scale)
      ..quadraticBezierTo(
        cx, cy - 14 * scale,
        cx + 8 * scale, cy - 18 * scale,
      );
    canvas.drawPath(smilePath, smilePaint);

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFAB91).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx - 14 * scale, cy - 22 * scale),
      5 * scale,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(cx + 14 * scale, cy - 22 * scale),
      5 * scale,
      cheekPaint,
    );

    // Mustache
    final mustachePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    final mustachePath = Path()
      ..moveTo(cx - 10 * scale, cy - 20 * scale)
      ..quadraticBezierTo(
        cx - 5 * scale, cy - 22 * scale,
        cx, cy - 20 * scale,
      )
      ..quadraticBezierTo(
        cx + 5 * scale, cy - 22 * scale,
        cx + 10 * scale, cy - 20 * scale,
      );
    canvas.drawPath(mustachePath, mustachePaint);
  }

  @override
  bool shouldRepaint(covariant _ButlerPainter oldDelegate) =>
      oldDelegate.colorTheme != colorTheme;
}
