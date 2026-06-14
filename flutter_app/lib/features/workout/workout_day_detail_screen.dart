import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/workout_controller.dart';
import '../../models/workout_model.dart';
import 'workout_active_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

enum ExerciseStatus { completed, current, upcoming }

class WorkoutExercise {
  final String name;
  final String duration;
  final String imagePath;
  final ExerciseStatus status;

  const WorkoutExercise({
    required this.name,
    required this.duration,
    required this.imagePath,
    required this.status,
  });
}

class WorkoutDayDetailScreen extends StatefulWidget {
  final String? dayId;
  final int day;
  final String workoutName;
  final String workoutSub;
  final String subtitle;
  final String duration;
  final String kcal;
  final int exerciseCount;
  final double progress;
  final String heroImage;
  final List<WorkoutExercise> exercises;

  const WorkoutDayDetailScreen({
    super.key,
    this.dayId,
    required this.day,
    required this.workoutName,
    required this.workoutSub,
    required this.subtitle,
    required this.duration,
    required this.kcal,
    required this.exerciseCount,
    required this.progress,
    required this.heroImage,
    required this.exercises,
  });

  @override
  State<WorkoutDayDetailScreen> createState() => _WorkoutDayDetailScreenState();
}

class _WorkoutDayDetailScreenState extends State<WorkoutDayDetailScreen> {
  double? _activeProgress;
  WorkoutController? _wc;

  @override
  void initState() {
    super.initState();
    if (widget.dayId != null) {
      _wc = Get.isRegistered<WorkoutController>()
          ? Get.find<WorkoutController>()
          : Get.put(WorkoutController());
      _wc!.loadExercises(widget.dayId!);
    }
  }

  int _parseDuration(String d) {
    final parts = d.split(':');
    if (parts.length == 2) return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return 30;
  }

  List<ActiveExercise> _buildActiveExercises() {
    if (_wc != null && _wc!.dayExercises.isNotEmpty) {
      return _wc!.dayExercises
          .map((e) => ActiveExercise(
                name: e.name,
                imagePath: e.gifUrl ?? e.imageUrl ?? '',
                durationSeconds: e.durationSeconds,
              ))
          .toList();
    }
    return widget.exercises
        .map((e) => ActiveExercise(
              name: e.name,
              imagePath: e.imagePath,
              durationSeconds: _parseDuration(e.duration),
            ))
        .toList();
  }

  void _launchActive() {
    Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutActiveScreen(
          totalKcal: 128,
          day: widget.day,
          dayId: widget.dayId,
          exercises: _buildActiveExercises(),
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() => _activeProgress = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  _buildHeroSection(),
                  _buildProgressCircle(),
                  const SizedBox(height: 28),
                  _buildExercisesSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _activeProgress != null
                  ? _buildTwoButtons()
                  : _buildSingleButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: _darkText),
              ),
            ),
          ),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Day ',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              TextSpan(
                text: '${widget.day}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _pink,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── HERO SECTION ───────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: 10,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4EF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              widget.heroImage,
              width: 260,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, __, ___) => Container(
                width: 240,
                color: Colors.transparent,
                child: const Icon(Icons.fitness_center,
                    size: 80, color: Color(0xFFFFB6D0)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 30,
            right: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workoutName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                    height: 1.2,
                  ),
                ),
                Text(
                  widget.workoutSub,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _pink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _iconStat(Icons.access_time_rounded,
                        const Color(0xFF6C5DD3), widget.duration),
                    const SizedBox(width: 12),
                    _emojiStat('🔥', widget.kcal),
                    const SizedBox(width: 12),
                    _emojiStat('🏃',
                        '${_wc != null && _wc!.dayExercises.isNotEmpty ? _wc!.dayExercises.length : widget.exerciseCount} Exercises'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconStat(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _emojiStat(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  // ─── PROGRESS CIRCLE ────────────────────────────────────────────────────────

  Widget _buildProgressCircle() {
    final pct = _activeProgress ?? widget.progress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 140,
        height: 140,
        child: CustomPaint(
          painter: _ArcPainter(progress: pct),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(pct * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _pink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── EXERCISES SECTION ──────────────────────────────────────────────────────

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Exercises',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800, color: _darkText),
          ),
        ),
        const SizedBox(height: 14),
        if (_wc != null)
          Obx(() {
            if (_wc!.loadingExercises.value) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _pink)),
              );
            }
            if (_wc!.dayExercises.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('No exercises found.',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              );
            }
            return Column(
              children: _wc!.dayExercises.map(_buildApiExerciseCard).toList(),
            );
          })
        else
          ...widget.exercises.map(_buildExerciseCard),
      ],
    );
  }

  Widget _buildApiExerciseCard(ExerciseModel ex) {
    final label = ex.reps != null
        ? '${ex.sets ?? 1}×${ex.reps} reps'
        : '${ex.durationSeconds}s';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ex.gifUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(ex.gifUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fitness_center, size: 28, color: _pink)),
                  )
                : const Icon(Icons.fitness_center, size: 28, color: _pink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ex.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _darkText)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(label,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    if (ex.rest != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.pause_circle_outline, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text('${ex.rest}s rest',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise ex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              ex.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0EC),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ex.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(ex.duration,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          _buildExerciseStatus(ex.status),
        ],
      ),
    );
  }

  Widget _buildExerciseStatus(ExerciseStatus status) {
    switch (status) {
      case ExerciseStatus.completed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF22C55E), size: 22),
        );
      case ExerciseStatus.current:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: _pink, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('Current',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _pink,
                  )),
            ],
          ),
        );
      case ExerciseStatus.upcoming:
        return const SizedBox.shrink();
    }
  }

  // ─── BOTTOM BUTTONS ─────────────────────────────────────────────────────────

  Widget _buildSingleButton() {
    return _bottomShell(
      child: _pinkButton(
        onTap: _launchActive,
        child: Text(
          'Continue Workout',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoButtons() {
    final pct = ((_activeProgress ?? 0) * 100).toInt();
    return _bottomShell(
      child: Row(
        children: [
          // Restart — outlined
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeProgress = null);
                _launchActive();
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        size: 20, color: _darkText),
                    const SizedBox(width: 6),
                    Text(
                      'Restart',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Continue — pink
          Expanded(
            child: _pinkButton(
              onTap: _launchActive,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$pct% completed',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
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

  Widget _bottomShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pinkButton({required VoidCallback onTap, required Widget child}) {
    return Container(
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
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─── ARC PAINTER ────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _pink.withValues(alpha: 0.12)
        ..strokeWidth = 12
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
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
