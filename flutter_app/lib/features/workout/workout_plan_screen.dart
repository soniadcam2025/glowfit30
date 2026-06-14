import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/workout_controller.dart';
import 'workout_day_detail_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final Set<int> _expanded = {1};
  late final WorkoutController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<WorkoutController>()
        ? Get.find<WorkoutController>()
        : Get.put(WorkoutController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Obx(() {
                if (_c.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: _pink),
                  );
                }
                if (_c.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Could not load workout plan',
                            style: GoogleFonts.poppins(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _c.loadData,
                          style: ElevatedButton.styleFrom(backgroundColor: _pink),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final days = _c.dayStates;
                final completed = _c.completedCount.value;
                final total = _c.totalDays.value > 0 ? _c.totalDays.value : 30;

                // Group days into weeks of 7
                final Map<int, List<WorkoutDayState>> weeks = {};
                for (final s in days) {
                  final week = ((s.day.dayNumber - 1) ~/ 7) + 1;
                  weeks.putIfAbsent(week, () => []).add(s);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(completed, total),
                      const SizedBox(height: 20),
                      ...weeks.entries.map((e) => _buildWeekSection(e.key, e.value)),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }),
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
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _darkText),
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
                        fontSize: 20, fontWeight: FontWeight.w800, color: _darkText),
                  ),
                  TextSpan(
                    text: 'Workout Plan',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w800, color: _pink),
                  ),
                ]),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Stay consistent. ',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  TextSpan(
                    text: 'Stronger',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _pink, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' every day. 💪',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildHeroCard(int completed, int total) {
    final pct = total > 0 ? completed / total : 0.0;
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
            Positioned(
              right: 0, top: 0, bottom: 0, width: 160,
              child: Container(color: const Color(0xFFFCE4EF)),
            ),
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: Image.asset(
                'assets/images/workout_plan_hero.png',
                width: 160,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  color: const Color(0xFFFFB6D0),
                  child: const Icon(Icons.fitness_center, size: 48, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0, top: 0, bottom: 0, right: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _ArcProgressPainter(progress: pct),
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                              text: '$completed',
                              style: GoogleFonts.poppins(
                                  fontSize: 32, fontWeight: FontWeight.w800, color: _pink),
                            ),
                            TextSpan(
                              text: '\n/$total',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500]),
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
                        fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
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

  static const _weekMeta = [
    (level: 'Beginner',     range: '1-7 Days',   dot: Color(0xFF6C5DD3), rangeColor: _pink),
    (level: 'Intermediate', range: '8-14 Days',  dot: Color(0xFFFF9500), rangeColor: Color(0xFFFF9500)),
    (level: 'Advanced',     range: '15-21 Days', dot: Color(0xFFFF3B30), rangeColor: Color(0xFFFF3B30)),
    (level: 'Advanced +',   range: '22-30 Days', dot: Color(0xFF1A1A2E), rangeColor: Color(0xFF1A1A2E)),
  ];

  Widget _buildWeekSection(int week, List<WorkoutDayState> days) {
    final isExpanded = _expanded.contains(week);
    final meta = week <= _weekMeta.length ? _weekMeta[week - 1] : _weekMeta.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            if (isExpanded) { _expanded.remove(week); } else { _expanded.add(week); }
          }),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text('Week $week',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _darkText)),
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: meta.dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(meta.level,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: meta.dot, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(meta.range,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600, color: meta.rangeColor)),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: meta.rangeColor, size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          ...days.map(_buildDayCard),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // ─── DAY CARD ───────────────────────────────────────────────────────────────

  Widget _buildDayCard(WorkoutDayState state) {
    final day = state.day;
    final isInProgress = state.status == DayStatus.inProgress;
    final isLocked     = state.status == DayStatus.locked;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
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
                    day.dayNumber.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: isLocked ? Colors.grey[400] : _pink, height: 1,
                    ),
                  ),
                  Text('DAY',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Thumbnail placeholder
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[100] : const Color(0xFFFFE0EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.fitness_center, size: 28,
                  color: isLocked ? Colors.grey[300] : _pink),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isLocked ? Colors.grey[500] : _darkText,
                    ),
                  ),
                  if (day.focus != null) ...[
                    const SizedBox(height: 2),
                    Text(day.focus!,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded,
                          size: 12, color: Color(0xFF6C5DD3)),
                      const SizedBox(width: 3),
                      Text('${day.exerciseCount} exercises',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  if (isInProgress) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: state.progress,
                              backgroundColor: Colors.grey[200],
                              color: _pink,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${(state.progress * 100).toInt()}%',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _pink)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusIcon(state.status),
          ],
        ),
      ),
    );

    if (!isLocked) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDayDetailScreen(
              dayId: day.id,
              day: day.dayNumber,
              workoutName: day.title.split(' ').first,
              workoutSub: day.title.split(' ').skip(1).join(' '),
              subtitle: day.focus ?? 'Complete today\'s workout!',
              duration: '— min',
              kcal: '— kcal',
              exerciseCount: day.exerciseCount,
              progress: state.progress,
              heroImage: '',
              exercises: const [],
            ),
          ),
        ),
        child: card,
      );
    }
    return card;
  }

  Widget _buildStatusIcon(DayStatus status) {
    switch (status) {
      case DayStatus.completed:
        return Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        );
      case DayStatus.inProgress:
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: _pink, size: 20),
        );
      case DayStatus.locked:
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
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

    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = _pink.withValues(alpha: 0.12)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = _pink
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
