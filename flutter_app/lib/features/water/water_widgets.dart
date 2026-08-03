import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const waterPink = Color(0xFFFF136B);
const waterPinkSoft = Color(0xFFFFD3E2);
const waterBlue = Color(0xFF3BA9F4);
const waterDark = Color(0xFF1A1A2E);
const waterBg = Color(0xFFFDF6F8);

/// Asset paths. Each render site falls back to an icon when the file is absent,
/// so the screens work before the artwork is supplied.
const kWaterGlassIcon = 'assets/icons/water_glass.png';
const kWaterDropIcon = 'assets/icons/water_drop.png';
const kWaterGoalCompleteArt = 'assets/illustrations/water_goal_complete.png';
const kWaterSmartTipArt = 'assets/illustrations/water_smart_tip.png';

/// Blue glass icon used by the quick-add tiles and the intake list.
class WaterGlassIcon extends StatelessWidget {
  final double size;
  const WaterGlassIcon({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kWaterGlassIcon,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.local_drink_rounded, size: size, color: waterBlue),
    );
  }
}

class WaterDropIcon extends StatelessWidget {
  final double size;
  const WaterDropIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kWaterDropIcon,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.water_drop_rounded, size: size, color: waterBlue),
    );
  }
}

/// Circular progress ring with the litre total in the middle.
///
/// Painted rather than composed from a CircularProgressIndicator so the track
/// and the progress arc can carry different weights and rounded caps, and so the
/// arc starts at 12 o'clock.
class WaterRing extends StatelessWidget {
  final double progress; // 0..1
  final String consumedLabel;
  final String goalLabel;
  final int percent;
  final double size;

  const WaterRing({
    super.key,
    required this.progress,
    required this.consumedLabel,
    required this.goalLabel,
    required this.percent,
    this.size = 230,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TweenAnimationBuilder so the arc grows when water is logged rather
          // than snapping to the new value.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WaterDropIcon(size: 26),
              const SizedBox(height: 2),
              Text(
                consumedLabel,
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: waterDark,
                  height: 1.05,
                ),
              ),
              Text(
                'of $goalLabel Goal',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: waterPinkSoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: waterPink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..color = waterPinkSoft.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = waterPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start at the top
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Rounded white card used throughout both screens.
class WaterCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  const WaterCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E6EB)),
      ),
      child: child,
    );
  }
}

/// Circular icon badge in a tinted disc — the leading element on every settings
/// row and the tip cards.
class WaterIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const WaterIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.45, color: color),
    );
  }
}

/// Pill selector used for goal presets and reminder intervals.
class WaterPillGroup extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  const WaterPillGroup({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected ? waterPink : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: i == selected ? waterPink : const Color(0xFFE8E0E4),
                  ),
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: i == selected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

/// Pink gradient CTA used at the foot of both screens.
class WaterPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const WaterPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [waterPink, Color(0xFFFF5C8A)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: waterPink.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular back / settings button in the screen headers.
class WaterCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const WaterCircleButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: waterDark),
      ),
    );
  }
}
