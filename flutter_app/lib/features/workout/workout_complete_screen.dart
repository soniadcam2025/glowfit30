import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_pages.dart';
import '../../services/api_service.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class WorkoutCompleteScreen extends StatefulWidget {
  final int day;
  final String? dayId;
  final int caloriesBurned;
  final String totalTime;
  final int durationMin;
  final int exercisesCompleted;
  final int totalExercises;
  final int streakDays;
  // Overrides for standalone (non-30-day-program) workouts, e.g. library
  // workouts, where "Day X Complete!" / "Continue to Day X+1" don't apply.
  final String? programLabel;
  final String? continueLabel;

  const WorkoutCompleteScreen({
    super.key,
    required this.day,
    this.dayId,
    required this.caloriesBurned,
    required this.totalTime,
    this.durationMin = 0,
    required this.exercisesCompleted,
    required this.totalExercises,
    this.streakDays = 7,
    this.programLabel,
    this.continueLabel,
  });

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> {
  String get _dayLabel => widget.programLabel ?? 'Day ${widget.day}';

  @override
  void initState() {
    super.initState();
    if (widget.dayId != null) {
      Get.find<ApiService>().logProgress(
        workoutDayId: widget.dayId!,
        caloriesBurned: widget.caloriesBurned,
        durationMin: widget.durationMin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                    const SizedBox(height: 14),
                    _buildStreakCard(),
                    // Day-based diet plan only applies to the 30-day program.
                    if (widget.programLabel == null) ...[
                      const SizedBox(height: 14),
                      _buildDietCard(),
                    ],
                    const SizedBox(height: 20),
                    _buildContinueButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _iconCircle(Icons.arrow_back_ios_new),
          ),
          const Spacer(),
          _iconCircle(Icons.upload_rounded),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Get.offAllNamed(Routes.home),
            child: _iconCircle(Icons.home_outlined),
          ),
        ],
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 17, color: _darkText),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$_dayLabel Complete! ',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const TextSpan(text: '🎉', style: TextStyle(fontSize: 20)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: _pink.withValues(alpha: 0.15),
                    color: _pink,
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '100%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great Job!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _darkText,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "You've completed",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      _dayLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _pink,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Keep going, your best self is on the way! ',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const TextSpan(
                            text: '💪', style: TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
              // Badge
              _buildBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.asset(
            'assets/images/workout_complete_badge.png',
            width: 130,
            errorBuilder: (_, __, ___) => SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _pink.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_dayLabel.toUpperCase()} COMPLETE',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS GRID ───────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFFFFE0EC),
                  iconColor: _pink,
                  value: '${widget.caloriesBurned}',
                  unit: 'kcal',
                  label: 'Calories\nBurned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                  value: widget.totalTime,
                  unit: 'min',
                  label: 'Total Time',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.open_in_full_rounded,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                  value:
                      '${widget.exercisesCompleted}/${widget.totalExercises}',
                  unit: '',
                  label: 'Exercises\nCompleted',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  icon: Icons.emoji_events_rounded,
                  iconBg: const Color(0xFFFFF3CD),
                  iconColor: const Color(0xFFEAB308),
                  value: '100%',
                  unit: '',
                  label: 'Workout\nCompleted',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500]),
                ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── STREAK CARD ──────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  Text(
                    '${widget.streakDays}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep it up!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                Text(
                  "You're on a ${widget.streakDays} day streak",
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(days.length, (i) {
              final done = widget.streakDays >= 7 || i < widget.streakDays;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            done ? const Color(0xFF22C55E) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 11, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days[i],
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: done ? _darkText : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── DIET CARD ────────────────────────────────────────────────────────────

  Widget _buildDietCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Image.asset(
              'assets/images/diet_food_bowl.png',
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                color: const Color(0xFFE8F5E9),
                child: const Icon(Icons.restaurant,
                    size: 36, color: Color(0xFF81C784)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _pink.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded,
                            color: _pink, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Day ${widget.day} Diet Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check out your personalized\nmeal plan for today.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Get.toNamed(
                      Routes.diet,
                      arguments: {'day': widget.day},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Diet Plan',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CONTINUE BUTTON ──────────────────────────────────────────────────────

  Widget _buildContinueButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.continueLabel ?? 'Continue to Day ${widget.day + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
