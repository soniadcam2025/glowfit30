import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_day_detail_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

enum _DayStatus { completed, inProgress, locked }

class _WorkoutDay {
  final int day;
  final String dayLabel;
  final String name;
  final String duration;
  final String kcal;
  final String imagePath;
  final _DayStatus status;
  final double progress;

  const _WorkoutDay({
    required this.day,
    required this.dayLabel,
    required this.name,
    required this.duration,
    required this.kcal,
    required this.imagePath,
    required this.status,
    this.progress = 0,
  });
}

class _WeekSection {
  final int week;
  final String level;
  final String range;
  final Color dot;
  final Color rangeColor;
  final List<_WorkoutDay> days;

  const _WeekSection({
    required this.week,
    required this.level,
    required this.range,
    required this.dot,
    required this.rangeColor,
    required this.days,
  });
}

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final Set<int> _expanded = {1};

  static final List<_WeekSection> _weeks = [
    _WeekSection(
      week: 1,
      level: 'Beginner',
      range: '1-7 Days',
      dot: const Color(0xFF6C5DD3),
      rangeColor: _pink,
      days: [
        _WorkoutDay(
          day: 1,
          dayLabel: 'DAY',
          name: 'Full Body Activation',
          duration: '30 Ses',
          kcal: '280 kcal',
          imagePath: 'assets/images/workout_day_1.png',
          status: _DayStatus.completed,
        ),
        _WorkoutDay(
          day: 2,
          dayLabel: 'DAY',
          name: 'Upper Body Strength',
          duration: '40 min',
          kcal: '320 kcal',
          imagePath: 'assets/images/workout_day_2.png',
          status: _DayStatus.completed,
        ),
        _WorkoutDay(
          day: 3,
          dayLabel: 'DAY',
          name: 'Lower Body Strength',
          duration: '45 min',
          kcal: '350 kcal',
          imagePath: 'assets/images/workout_day_3.png',
          status: _DayStatus.inProgress,
          progress: 0.30,
        ),
        _WorkoutDay(
          day: 4,
          dayLabel: 'Mon',
          name: 'Core & Abs Blast',
          duration: '30 min',
          kcal: '220 kcal',
          imagePath: 'assets/images/workout_day_4.png',
          status: _DayStatus.locked,
        ),
        _WorkoutDay(
          day: 5,
          dayLabel: 'DAY',
          name: 'HIIT Cardio',
          duration: '30 min',
          kcal: '300 kcal',
          imagePath: 'assets/images/workout_day_5.png',
          status: _DayStatus.locked,
        ),
        _WorkoutDay(
          day: 6,
          dayLabel: 'DAY',
          name: 'Active Recovery',
          duration: '25 min',
          kcal: '180 kcal',
          imagePath: 'assets/images/workout_day_6.png',
          status: _DayStatus.locked,
        ),
        _WorkoutDay(
          day: 7,
          dayLabel: 'DAY',
          name: 'Full Body Power',
          duration: '45 min',
          kcal: '360 kcal',
          imagePath: 'assets/images/workout_day_7.png',
          status: _DayStatus.locked,
        ),
      ],
    ),
    _WeekSection(
      week: 2,
      level: 'Intermediate',
      range: '8-14 Days',
      dot: const Color(0xFFFF9500),
      rangeColor: const Color(0xFFFF9500),
      days: [],
    ),
    _WeekSection(
      week: 3,
      level: 'Advanced',
      range: '15-21 Days',
      dot: const Color(0xFFFF3B30),
      rangeColor: const Color(0xFFFF3B30),
      days: [],
    ),
    _WeekSection(
      week: 4,
      level: 'Advanced +',
      range: '22-30 Days',
      dot: const Color(0xFF1A1A2E),
      rangeColor: const Color(0xFF1A1A2E),
      days: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 20),
                    ..._weeks.map(_buildWeekSection),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: _darkText),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '30-Day ',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  TextSpan(
                    text: 'Workout Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ]),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Stay consistent. ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextSpan(
                    text: 'Stronger',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _pink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' every day. 💪',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HERO CARD ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      height: 170,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Pink accent background on right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 160,
              child: Container(color: const Color(0xFFFCE4EF)),
            ),
            // Woman image
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/workout_plan_hero.png',
                width: 160,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  color: const Color(0xFFFFB6D0),
                  child: const Icon(Icons.fitness_center,
                      size: 48, color: Colors.white),
                ),
              ),
            ),
            // Circular progress + label
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _ArcProgressPainter(progress: 1 / 30),
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                              text: '1',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _pink,
                              ),
                            ),
                            TextSpan(
                              text: '\n/30',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Days Completed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEEK SECTION ───────────────────────────────────────────────────────────

  Widget _buildWeekSection(_WeekSection week) {
    final isExpanded = _expanded.contains(week.week);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header row
        GestureDetector(
          onTap: () => setState(() {
            if (isExpanded) {
              _expanded.remove(week.week);
            } else {
              _expanded.add(week.week);
            }
          }),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  'Week ${week.week}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: week.dot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  week.level,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: week.dot,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  week.range,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: week.rangeColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: week.rangeColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          ...week.days.map(_buildDayCard),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // ─── DAY CARD ───────────────────────────────────────────────────────────────

  Widget _buildDayCard(_WorkoutDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Day number
            SizedBox(
              width: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.day.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: day.status == _DayStatus.locked
                          ? Colors.grey[400]
                          : _pink,
                      height: 1,
                    ),
                  ),
                  Text(
                    day.dayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Workout thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                day.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFFFE0EC),
                  child: const Icon(Icons.fitness_center,
                      size: 28, color: _pink),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: day.status == _DayStatus.locked
                          ? Colors.grey[500]
                          : _darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFF6C5DD3)),
                      const SizedBox(width: 3),
                      Text(
                        day.duration,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 2),
                      Text(
                        day.kcal,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (day.status == _DayStatus.inProgress) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: day.progress,
                              backgroundColor: Colors.grey[200],
                              color: _pink,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(day.progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _pink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status icon
            day.status == _DayStatus.inProgress
                ? GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDayDetailScreen(
                          day: day.day,
                          workoutName: day.name.split(' ').first,
                          workoutSub: day.name.split(' ').skip(1).join(' '),
                          subtitle: 'Boost energy & improve mobility.',
                          duration: day.duration,
                          kcal: day.kcal,
                          exerciseCount: 6,
                          progress: day.progress,
                          heroImage: day.imagePath,
                          exercises: const [
                            WorkoutExercise(
                              name: 'Standing Hip Circle',
                              duration: '00:20',
                              imagePath: 'assets/images/exercise_hip_circle.png',
                              status: ExerciseStatus.completed,
                            ),
                            WorkoutExercise(
                              name: 'Squats',
                              duration: '00:30',
                              imagePath: 'assets/images/exercise_squats.png',
                              status: ExerciseStatus.current,
                            ),
                            WorkoutExercise(
                              name: 'Cat Cow Pose',
                              duration: '00:30',
                              imagePath: 'assets/images/exercise_cat_cow.png',
                              status: ExerciseStatus.upcoming,
                            ),
                            WorkoutExercise(
                              name: 'Plank',
                              duration: '00:30',
                              imagePath: 'assets/images/exercise_plank.png',
                              status: ExerciseStatus.upcoming,
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: _buildStatusIcon(day.status),
                  )
                : _buildStatusIcon(day.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(_DayStatus status) {
    switch (status) {
      case _DayStatus.completed:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        );
      case _DayStatus.inProgress:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded, color: _pink, size: 20),
        );
      case _DayStatus.locked:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_rounded, color: Colors.grey[400], size: 16),
        );
    }
  }
}

// ─── ARC PROGRESS PAINTER ───────────────────────────────────────────────────

class _ArcProgressPainter extends CustomPainter {
  final double progress;
  const _ArcProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = _pink.withValues(alpha: 0.12)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = _pink
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
