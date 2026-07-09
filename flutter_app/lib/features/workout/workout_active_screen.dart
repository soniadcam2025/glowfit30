import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/exercise_video_player.dart';
import 'music_settings_screen.dart';
import 'workout_rest_screen.dart';
import 'workout_settings_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class ActiveExercise {
  final String name;
  final String imagePath;
  final String? videoUrl;
  final int durationSeconds;

  const ActiveExercise({
    required this.name,
    required this.imagePath,
    this.videoUrl,
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
  bool _showMoreOptions = false;

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
          _earnedKcal = ((_currentIndex *
                          widget.exercises[_currentIndex].durationSeconds +
                      (widget.exercises[_currentIndex].durationSeconds -
                          _secondsLeft)) /
                  (widget.exercises.length *
                      widget.exercises[_currentIndex].durationSeconds) *
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

  void _openSettings(Widget screen) {
    setState(() {
      _isPaused = true;
      _showMoreOptions = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) setState(() => _isPaused = false);
    });
  }

  void _showLeaveDialog() {
    final elapsed = widget.exercises[_currentIndex].durationSeconds -
        _secondsLeft +
        _currentIndex *
            (widget.exercises.isNotEmpty
                ? widget.exercises[0].durationSeconds
                : 0);
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
          Navigator.pop(context, _currentIndex);
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
          Navigator.pop(context); // close sheet
          Navigator.pop(context, 0); // back to the workout day detail screen
        },
        onSkip: () {
          Navigator.pop(context); // close sheet
          _timer?.cancel();
          _onExerciseComplete();
        },
        onQuit: () {
          Navigator.pop(context); // close sheet
          _showLeaveDialog();
        },
      ),
    );
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

  void _goPrevWithRestScreen() {
    if (_currentIndex <= 0) return;
    _timer?.cancel();
    final prevIndex = _currentIndex - 1;
    final prev = widget.exercises[prevIndex];
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutRestScreen(
          nextExerciseName: prev.name,
          nextExerciseImage: prev.imagePath,
          nextExerciseDuration: prev.durationSeconds >= 60
              ? '${prev.durationSeconds ~/ 60} Min'
              : '${prev.durationSeconds} Sec',
          nextExerciseKcal:
              '${(widget.totalKcal / widget.exercises.length).toInt()} kcal',
          exerciseNumber: prevIndex + 1,
          totalExercises: widget.exercises.length,
        ),
      ),
    ).then((proceed) {
      if (proceed == true && mounted) _goPrev();
    });
  }

  void _navigateToComplete() {
    // Pop all the way back to the Workout Day Detail screen (same chain the
    // Quit flow already uses) instead of pushReplacement, which would resolve
    // WorkoutReadyScreen's awaited push and cause it to immediately pop the
    // freshly-shown Complete screen right back off.
    Navigator.pop(context, widget.exercises.length);
  }

  void _goNext() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _secondsLeft = widget.exercises[_currentIndex].durationSeconds;
        _isPaused = false;
      });
      _startTimer();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _secondsLeft = widget.exercises[_currentIndex].durationSeconds;
        _isPaused = false;
      });
      _startTimer();
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
      body: Column(
        children: [
          _buildExerciseImage(exercise.imagePath, exercise.videoUrl),
          _buildProgressBar(),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  exercise.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 26,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _pink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimer(),
                const SizedBox(height: 28),
                _buildControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EXERCISE IMAGE (with overlay controls) ──────────────────────────────

  Widget _buildExerciseImage(String path, String? videoUrl) {
    final isNetworkImage = path.startsWith('http');

    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          isNetworkImage
              ? Image.network(
                  path,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageFallback(),
                )
              : (path.isEmpty
                  ? _imageFallback()
                  : Image.asset(
                      path,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )),
          if (videoUrl != null && videoUrl.isNotEmpty)
            ExerciseVideoPlayer(videoUrl: videoUrl, playing: !_isPaused),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _roundIconButton(
                    color: Colors.black38,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.white),
                    onTap: _togglePause,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statBox('🚴', '${_currentIndex + 1}',
                              '${widget.exercises.length}', 'Exercise'),
                          const SizedBox(width: 8),
                          _statBox('🔥', '$_earnedKcal', '${widget.totalKcal}',
                              'Kcal Burned'),
                        ],
                      ),
                    ),
                  ),
                  _buildMoreOptionsColumn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFFF8C00),
      child: const Center(
        child: Icon(Icons.fitness_center, size: 80, color: Colors.white),
      ),
    );
  }

  // ─── OVERLAY WIDGETS ──────────────────────────────────────────────────────

  Widget _roundIconButton({
    required Color color,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildMoreOptionsColumn() {
    return Column(
      children: [
        _roundIconButton(
          color: Colors.white.withValues(alpha: 0.85),
          icon: const Icon(Icons.more_vert_rounded, size: 20, color: _darkText),
          onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
        ),
        if (_showMoreOptions) ...[
          const SizedBox(height: 8),
          _roundIconButton(
            color: Colors.white.withValues(alpha: 0.85),
            icon: const Icon(Icons.music_note_rounded, size: 18, color: _pink),
            onTap: () => _openSettings(const MusicSettingsScreen()),
          ),
          const SizedBox(height: 8),
          _roundIconButton(
            color: Colors.white.withValues(alpha: 0.85),
            icon: Icon(Icons.settings_outlined,
                size: 18, color: Colors.grey[600]),
            onTap: () => _openSettings(const WorkoutSettingsScreen()),
          ),
        ],
      ],
    );
  }

  Widget _statBox(String emoji, String value, String total, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0EC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
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
                      fontSize: 15,
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
                      color: Colors.white70,
                      height: 1,
                    ),
                  ),
                ]),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS BAR ─────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      height: 4,
      color: Colors.grey[200],
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _progress.clamp(0, 1),
        child: Container(color: _pink),
      ),
    );
  }

  // ─── TIMER ────────────────────────────────────────────────────────────────

  Widget _buildTimer() {
    final parts = _timeFormatted.split(':');
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: parts[0],
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        TextSpan(
          text: ' : ',
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: _darkText,
          ),
        ),
        TextSpan(
          text: parts[1],
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: _pink,
          ),
        ),
      ]),
    );
  }

  // ─── CONTROLS ─────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildControlButton(
          onTap: _goPrevWithRestScreen,
          icon: Icons.skip_previous_rounded,
          label: 'Previous',
          size: 50,
        ),
        _buildPauseButton(),
        _buildControlButton(
          onTap: () {
            _timer?.cancel();
            _onExerciseComplete();
          },
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
