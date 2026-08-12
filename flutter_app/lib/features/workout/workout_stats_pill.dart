import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _pink = Color(0xFFFF136B);

/// The exercise/kcal counter that sits at the top of the workout screens.
///
/// Shared by the ready screen and the active screen so the header does not
/// change shape when the countdown ends and the workout starts — the two are
/// consecutive views of the same session, and the counter carrying straight
/// across is what makes them read that way.
class WorkoutStatsPill extends StatelessWidget {
  /// 1-based position of the current exercise.
  final int currentExercise;
  final int totalExercises;
  final int earnedKcal;
  final int totalKcal;

  const WorkoutStatsPill({
    super.key,
    required this.currentExercise,
    required this.totalExercises,
    required this.earnedKcal,
    required this.totalKcal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        // Translucent black rather than near-solid white. Both screens put
        // this over video, and a white slab read as a panel bolted on top of
        // the clip; a dark wash lets the frame show through and carries white
        // text, which stays legible over bright and dark frames alike.
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stat(
            icon: Icons.directions_run_rounded,
            value: '$currentExercise',
            total: '$totalExercises',
            label: 'Exercise',
          ),
          const SizedBox(width: 14),
          _stat(
            icon: Icons.local_fire_department_rounded,
            value: '$earnedKcal',
            total: '$totalKcal',
            label: 'Kcal Burned',
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String total,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE0EC),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: _pink),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' / $total',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
