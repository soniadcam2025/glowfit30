import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_rest_screen.dart';
import 'workout_complete_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class ActiveExercise {
  final String name;
  final String imagePath;
  final int durationSeconds;

  const ActiveExercise({
    required this.name,
    required this.imagePath,
    required this.durationSeconds,
  });
}

class WorkoutActiveScreen extends StatefulWidget {
  final List<ActiveExercise> exercises;
  final int totalKcal;
  final int day;
  final String? dayId;

  const WorkoutActiveScreen({
    super.key,
    required this.exercises,
    required this.totalKcal,
    this.day = 3,
    this.dayId,
  });

  @override
  State<WorkoutActiveScreen> createState() => _WorkoutActiveScreenState();
}

class _WorkoutActiveScreenState extends State<WorkoutActiveScreen> {
  int _currentIndex = 0;
  late int _secondsLeft;
  bool _isPaused = false;
  Timer? _timer;
  int _earnedKcal = 12;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.exercises[_currentIndex].durationSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
          _earnedKcal = ((_currentIndex * widget.exercises[_currentIndex].durationSeconds +
                      (widget.exercises[_currentIndex].durationSeconds - _secondsLeft)) /
                  (widget.exercises.length * widget.exercises[_currentIndex].durationSeconds) *
                  widget.totalKcal)
              .clamp(0, widget.totalKcal)
              .toInt();
        });
      } else {
        _timer?.cancel();
        _onExerciseComplete();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = true);
    _showPauseSheet();
  }

  void _showLeaveDialog() {
    final elapsed = widget.exercises[_currentIndex].durationSeconds - _secondsLeft
        + _currentIndex * (widget.exercises.isNotEmpty ? widget.exercises[0].durationSeconds : 0);
    final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsed % 60).toString().padLeft(2, '0');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _LeaveWorkoutDialog(
        completedPercent: (_progress * 100).toInt(),
        timeElapsed: '$mm:$ss',
        onContinue: () {
          Navigator.pop(context);
          setState(() => _isPaused = false);
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context, _progress);
        },
      ),
    );
  }

  void _showPauseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PauseSheet(
        onResume: () {
          Navigator.pop(context);
          setState(() => _isPaused = false);
        },
        onRestart: () {
          Navigator.pop(context);
          setState(() {
            _currentIndex = 0;
            _secondsLeft = widget.exercises[0].durationSeconds;
            _isPaused = false;
          });
        },
        onSkip: () {
          Navigator.pop(context);
          _goNext();
        },
        onQuit: () {
          Navigator.pop(context); // close sheet
          _showLeaveDialog();
        },
      ),
    ).then((_) => setState(() => _isPaused = false));
  }

  void _onExerciseComplete() {
    final isLast = _currentIndex >= widget.exercises.length - 1;
    if (isLast) {
      _navigateToComplete();
      return;
    }
    final next = widget.exercises[_currentIndex + 1];
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutRestScreen(
          nextExerciseName: next.name,
          nextExerciseImage: next.imagePath,
          nextExerciseDuration: next.durationSeconds >= 60
              ? '${next.durationSeconds ~/ 60} Min'
              : '${next.durationSeconds} Sec',
          nextExerciseKcal:
              '${(widget.totalKcal / widget.exercises.length).toInt()} kcal',
          exerciseNumber: _currentIndex + 2,
          totalExercises: widget.exercises.length,
        ),
      ),
    ).then((proceed) {
      if (proceed == true && mounted) _goNext();
    });
  }

  void _navigateToComplete() {
    final totalSecs = widget.exercises
        .fold(0, (sum, e) => sum + e.durationSeconds);
    final mm = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSecs % 60).toString().padLeft(2, '0');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCompleteScreen(
          day: widget.day,
          dayId: widget.dayId,
          caloriesBurned: widget.totalKcal,
          totalTime: '$mm:$ss',
          durationMin: totalSecs ~/ 60,
          exercisesCompleted: widget.exercises.length,
          totalExercises: widget.exercises.length,
        ),
      ),
    );
  }

  void _goNext() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _secondsLeft = widget.exercises[_currentIndex].durationSeconds;
        _isPaused = false;
      });
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _secondsLeft = widget.exercises[_currentIndex].durationSeconds;
        _isPaused = false;
      });
    }
  }

  double get _progress {
    final total = widget.exercises[_currentIndex].durationSeconds;
    return (total - _secondsLeft) / total;
  }

  String get _timeFormatted {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, exercise.name),
            _buildProgressDots(),
            _buildExerciseImage(exercise.imagePath),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 32),
            _buildControls(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _progress),
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
          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.music_note_rounded, color: _pink, size: 26),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.settings_outlined,
                color: Colors.grey[500], size: 24),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS DOTS ────────────────────────────────────────────────────────

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.exercises.length, (i) {
          final isDone = i < _currentIndex;
          final isCurrent = i == _currentIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isDone || isCurrent ? 22 : 10,
              height: 6,
              decoration: BoxDecoration(
                color: isDone || isCurrent ? _pink : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── EXERCISE IMAGE ───────────────────────────────────────────────────────

  Widget _buildExerciseImage(String path) {
    return Expanded(
      child: Image.asset(
        path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFFF8C00),
          child: const Center(
            child: Icon(Icons.fitness_center, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _buildStat(
            primary: '${_currentIndex + 1}',
            secondary: '/ ${widget.exercises.length}',
            label: 'Exercise',
          )),
          _divider(),
          Expanded(child: _buildStat(
            primary: _timeFormatted,
            secondary: '',
            label: 'Time Left',
            primaryColor: _darkText,
          )),
          _divider(),
          Expanded(child: _buildStat(
            primary: '$_earnedKcal',
            secondary: '/${widget.totalKcal}',
            label: 'kcal',
          )),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String primary,
    required String secondary,
    required String label,
    Color primaryColor = _pink,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: primary,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            if (secondary.isNotEmpty)
              TextSpan(
                text: ' $secondary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
          ]),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.grey[200],
    );
  }

  // ─── CONTROLS ─────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildControlButton(
          onTap: _goPrev,
          icon: Icons.skip_previous_rounded,
          label: 'Previous',
          size: 50,
        ),
        _buildPauseButton(),
        _buildControlButton(
          onTap: _goNext,
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          size: 50,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: _darkText),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(progress: _progress),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPaused ? 'Resume' : 'Pause',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LEAVE WORKOUT DIALOG ─────────────────────────────────────────────────

class _LeaveWorkoutDialog extends StatelessWidget {
  final int completedPercent;
  final String timeElapsed;
  final VoidCallback onContinue;
  final VoidCallback onExit;

  const _LeaveWorkoutDialog({
    required this.completedPercent,
    required this.timeElapsed,
    required this.onContinue,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _pink, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave Workout?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your current workout progress\nwill be lost.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                color: Colors.grey[400], size: 20),
                            const SizedBox(height: 4),
                            Text('Completed',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey[500])),
                            Text('$completedPercent%',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _pink,
                                )),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(
                        width: 1, thickness: 1, color: Colors.grey[200]),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: Colors.grey[400], size: 20),
                            const SizedBox(height: 4),
                            Text('Time Elapsed',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey[500])),
                            Text(timeElapsed,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _pink,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Continue button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onContinue,
                  child: Center(
                    child: Text(
                      'Continue Workout',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Exit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onExit,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Exit Workout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _pink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  'Your progress will not be saved',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAUSE SHEET ──────────────────────────────────────────────────────────

class _PauseSheet extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSkip;
  final VoidCallback onQuit;

  const _PauseSheet({
    required this.onResume,
    required this.onRestart,
    required this.onSkip,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            icon: Icons.play_arrow_rounded,
            title: 'Resume Workout',
            subtitle: 'Continue where you left off',
            onTap: onResume,
            showChevron: false,
          ),
          _buildDivider(),
          _buildOption(
            icon: Icons.refresh_rounded,
            title: 'Restart Workout',
            subtitle: 'Start this workout from beginning',
            onTap: onRestart,
            showChevron: false,
          ),
          _buildDivider(),
          _buildOption(
            icon: Icons.fast_forward_rounded,
            title: 'Skip Exercise',
            subtitle: 'Skip to next exercise',
            onTap: onSkip,
            showChevron: false,
          ),
          _buildDivider(),
          _buildOption(
            icon: Icons.logout_rounded,
            title: 'Quit Workout',
            subtitle: 'End this workout session',
            onTap: onQuit,
            showChevron: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showChevron,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _pink, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[100]);
}

// ─── RING PAINTER ─────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bgPaint = Paint()
      ..color = _pink.withValues(alpha: 0.15)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = _pink
      ..strokeWidth = 5
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
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
