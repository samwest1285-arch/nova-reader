import 'package:flutter/material.dart';

/// A large circular menu button with icon, label, glow animation,
/// and press effect. Designed for the Nova Reader's cozy atmosphere.
class MenuButton extends StatefulWidget {
  /// The icon to display.
  final IconData icon;

  /// The label text below the icon.
  final String label;

  /// Background color of the button.
  final Color backgroundColor;

  /// Icon color.
  final Color iconColor;

  /// Label text color.
  final Color labelColor;

  /// Glow color for the pulse animation.
  final Color glowColor;

  /// Diameter of the circular button.
  final double size;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is enabled.
  final bool enabled;

  /// Elevation shadow color.
  final Color shadowColor;

  /// Elevation amount.
  final double elevation;

  /// The duration of the glow pulse animation.
  final Duration pulseDuration;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor = const Color(0xFF5D4037),
    this.iconColor = Colors.white,
    this.labelColor = const Color(0xFF3E2723),
    this.glowColor = const Color(0xFFFFB300),
    this.size = 80,
    this.onPressed,
    this.enabled = true,
    this.shadowColor = const Color(0xFF3E2723),
    this.elevation = 4.0,
    this.pulseDuration = const Duration(seconds: 2),
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.enabled
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _isPressed ? 0.92 : 1.0;
          final glowOpacity = 0.15 + _pulseAnimation.value * 0.25;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button with glow
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.backgroundColor,
                    boxShadow: [
                      // Glow pulse
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: glowOpacity),
                        blurRadius: 12 + _pulseAnimation.value * 8,
                        spreadRadius: 2 + _pulseAnimation.value * 3,
                      ),
                      // Main shadow
                      BoxShadow(
                        color: widget.shadowColor.withValues(alpha: 0.3),
                        blurRadius: widget.elevation * 2,
                        offset: Offset(0, widget.elevation),
                      ),
                      // Inner shadow for depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.backgroundColor,
                        widget.backgroundColor.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Opacity(
                    opacity: widget.enabled ? 1.0 : 0.5,
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: widget.size * 0.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                widget.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: widget.enabled
                      ? widget.labelColor
                      : widget.labelColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
