import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../theme/app_theme.dart';

/// Donation history entry.
class _DonationEntry {
  final DateTime date;
  final double amount;
  final String message;

  const _DonationEntry({
    required this.date,
    required this.amount,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
        'message': message,
      };

  factory _DonationEntry.fromJson(Map<String, dynamic> json) => _DonationEntry(
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        message: json['message'] as String? ?? '',
      );
}

/// The donation screen with coffee shop aesthetic and PayPal integration.
class CafeScreen extends ConsumerStatefulWidget {
  const CafeScreen({super.key});

  @override
  ConsumerState<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends ConsumerState<CafeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _coffeeSteamController;
  late AnimationController _heartbeatController;
  late Animation<double> _steamAnimation;
  late Animation<double> _heartAnimation;
  List<_DonationEntry> _donationHistory = [];
  bool _isLoading = true;

  // PayPal.Me link
  static const String _paypalMeUrl = 'https://paypal.me/NovaReader';

  @override
  void initState() {
    super.initState();

    _coffeeSteamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _steamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _coffeeSteamController,
        curve: Curves.easeInOut,
      ),
    );

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _heartAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    _loadDonationHistory();
  }

  @override
  void dispose() {
    _coffeeSteamController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  Future<void> _loadDonationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('nova_reader_donations');
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        setState(() {
          _donationHistory = decoded
              .map((e) => _DonationEntry.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        });
      }
    } catch (_) {
      // Ignore load errors
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveDonationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr =
          jsonEncode(_donationHistory.map((e) => e.toJson()).toList());
      await prefs.setString('nova_reader_donations', jsonStr);
    } catch (_) {
      // Ignore save errors
    }
  }

  void _addDonation(double amount) {
    final entry = _DonationEntry(
      date: DateTime.now(),
      amount: amount,
      message: 'Vielen Dank für Ihre Unterstützung! ☕',
    );
    setState(() {
      _donationHistory.insert(0, entry);
    });
    _saveDonationHistory();

    // Heartbeat animation
    _heartbeatController.forward().then((_) {
      _heartbeatController.reverse();
    });

    // Show thank you dialog
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NovaColors.warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.coffee, color: NovaColors.terracotta),
              SizedBox(width: 8),
              Text(
                'Vielen Dank!',
                style: TextStyle(color: NovaColors.deepBrown),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ihre Spende von \$${amount.toStringAsFixed(2)} '
                'hilft uns, Nova Reader noch besser zu machen!',
                style: const TextStyle(
                  color: NovaColors.charcoal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🙏',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mit herzlichem Dank,\nIhr Butler',
                style: TextStyle(
                  color: NovaColors.mediumBrown,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Gerne!'),
            ),
          ],
        );
      },
    );
  }

  void _openPayPal() {
    // In a real app, this would use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PayPal.Me würde geöffnet: $_paypalMeUrl'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Simulieren',
          onPressed: () {
            // Simulate a donation for demo purposes
            _addDonation(5.00);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        title: const Text('Caffè'),
        backgroundColor: const Color(0xFF3D2B1F),
        foregroundColor: NovaColors.paleGold,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Coffee shop header
            _buildHeader(theme),

            const SizedBox(height: 24),

            // Coffee cup animation
            _buildCoffeeCup(theme),

            const SizedBox(height: 24),

            // Donation message from butler
            _buildButlerMessage(theme),

            const SizedBox(height: 24),

            // Donation buttons
            _buildDonationButtons(theme),

            const SizedBox(height: 24),

            // PayPal button
            _buildPayPalButton(theme),

            const SizedBox(height: 24),

            // Donation history
            if (_donationHistory.isNotEmpty) _buildDonationHistory(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2B1F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NovaColors.deepBrown.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '☕',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'Buy me a Coffee',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: NovaColors.paleGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unterstützen Sie Nova Reader\nund genießen Sie eine Tasse Kaffee ☕',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NovaColors.tan,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeCup(ThemeData theme) {
    return AnimatedBuilder(
      animation: _steamAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 140),
          painter: _CoffeeCupPainter(
            steamValue: _steamAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildButlerMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NovaColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NovaColors.tan.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NovaColors.deepBrown.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Butler icon
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: NovaColors.charcoal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smart_toy,
                    color: NovaColors.paleGold, size: 32),
                SizedBox(height: 4),
                Icon(Icons.coffee,
                    color: NovaColors.terracotta, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ihr Butler sagt:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: NovaColors.mediumBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wenn Ihnen Nova Reader gefällt, '
                  'freue ich mich über eine kleine '
                  'Unterstützung. Jeder Kaffee zählt! ☕',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NovaColors.charcoal,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationButtons(ThemeData theme) {
    final amounts = [1.00, 3.00, 5.00, 10.00];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellspende',
          style: theme.textTheme.titleSmall?.copyWith(
            color: NovaColors.deepBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: amounts.map((amount) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => _addDonation(amount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                    foregroundColor: NovaColors.paleGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Kaffee',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPayPalButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openPayPal,
        icon: const Icon(Icons.payments),
        label: const Text('Mit PayPal spenden'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF003087),
          side: const BorderSide(color: Color(0xFF003087)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationHistory(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: NovaColors.mediumBrown, size: 20),
            const SizedBox(width: 8),
            Text(
              'Spendenhistorie',
              style: theme.textTheme.titleSmall?.copyWith(
                color: NovaColors.deepBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _donationHistory.length.clamp(0, 5),
          (index) {
            final entry = _donationHistory[index];
            final dateStr =
                '${entry.date.day}.${entry.date.month}.${entry.date.year}';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: NovaColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NovaColors.tan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.coffee,
                      color: NovaColors.terracotta, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${entry.amount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: NovaColors.deepBrown,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NovaColors.mediumBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartAnimation.value,
                        child: const Icon(
                          Icons.favorite,
                          color: NovaColors.terracotta,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        if (_donationHistory.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Show all history
                },
                child: const Text('Alle anzeigen'),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints a coffee cup with steam animation.
class _CoffeeCupPainter extends CustomPainter {
  final double steamValue;

  _CoffeeCupPainter({required this.steamValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height - 20;

    // Cup body
    final cupPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;

    final cupPath = Path()
      ..moveTo(centerX - 30, baseY)
      ..lineTo(centerX - 25, baseY - 50)
      ..lineTo(centerX + 25, baseY - 50)
      ..lineTo(centerX + 30, baseY)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Cup rim
    final rimPaint = Paint()
      ..color = const Color(0xFFA1887F)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 27, baseY - 55, 54, 8),
        const Radius.circular(4),
      ),
      rimPaint,
    );

    // Coffee surface
    final coffeePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, baseY - 50, 48, 6),
        const Radius.circular(3),
      ),
      coffeePaint,
    );

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(centerX + 30, baseY - 40)
      ..quadraticBezierTo(
        centerX + 45,
        baseY - 30,
        centerX + 30,
        baseY - 15,
      );
    canvas.drawPath(handlePath, handlePaint);

    // Saucer
    final saucerPaint = Paint()
      ..color = const Color(0xFFA1887F)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY + 5),
        width: 70,
        height: 10,
      ),
      saucerPaint,
    );

    // Steam wisps
    final steamPaint = Paint()
      ..color = NovaColors.cream.withValues(alpha: 0.4 * steamValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final offsetX = (i - 1) * 10.0;
      final steamPath = Path();
      final startX = centerX + offsetX;
      final startY = baseY - 55;

      steamPath.moveTo(startX, startY);
      steamPath.quadraticBezierTo(
        startX + 5 * steamValue + i * 2,
        startY - 15 * steamValue,
        startX + (i - 1) * 3 * steamValue,
        startY - 30 * steamValue,
      );

      canvas.drawPath(steamPath, steamPaint);
    }

    // Heart on the cup
    final heartPaint = Paint()
      ..color = NovaColors.terracotta
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    final heartX = centerX;
    final heartY = baseY - 30;

    heartPath.moveTo(heartX, heartY + 4);
    heartPath.cubicTo(
      heartX - 6,
      heartY - 2,
      heartX - 8,
      heartY - 6,
      heartX - 4,
      heartY - 8,
    );
    heartPath.cubicTo(
      heartX - 2,
      heartY - 9,
      heartX,
      heartY - 6,
      heartX,
      heartY - 4,
    );
    heartPath.cubicTo(
      heartX,
      heartY - 6,
      heartX + 2,
      heartY - 9,
      heartX + 4,
      heartY - 8,
    );
    heartPath.cubicTo(
      heartX + 8,
      heartY - 6,
      heartX + 6,
      heartY - 2,
      heartX,
      heartY + 4,
    );
    heartPath.close();

    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant _CoffeeCupPainter oldDelegate) {
    return oldDelegate.steamValue != steamValue;
  }
}
