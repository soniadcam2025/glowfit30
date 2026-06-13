import 'package:flutter/material.dart';

class AppDecorations {
  AppDecorations._();

  // Default gradient colors: #FF146B (right/strong) → #FFAACC (left/soft)
  static const _gradientColors = [Color(0xFFFF146B), Color(0xFFFFAACC)];
  static const _glowShadows = [
    BoxShadow(
      color: Color(0x33FF136B),
      blurRadius: 20,
      spreadRadius: 4,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1AFF136B),
      blurRadius: 40,
      spreadRadius: 10,
      offset: Offset(0, 0),
    ),
  ];

  /// Wraps [child] with a gradient border (left: #FFAACC → right: #FF146B)
  /// and a pink glow shadow. Use for selected card states.
  static Widget selectedCard({
    required Widget child,
    double? height,
    double borderRadius = 12,
    double borderWidth = 1.5,
    List<Color> colors = _gradientColors,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
        ),
        boxShadow: _glowShadows,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }

  /// Plain card decoration for unselected state.
  static BoxDecoration unselectedCard({double borderRadius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
