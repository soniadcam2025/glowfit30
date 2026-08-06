import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/exercise_video_player.dart';
import '../../models/media.dart';
import '../../services/media_preloader.dart';
import '../../widgets/glow_image.dart';
import 'music_settings_screen.dart';
import 'workout_active_screen.dart' show ActiveExercise;
import 'workout_rest_screen.dart';
import 'workout_settings_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

/// Alternate design of the active workout screen. Cloned from
/// [WorkoutActiveScreen] so it can be iterated on independently while the
/// original stays available to switch back to. Reuses the shared
/// [ActiveExercise] model from workout_active_screen.dart.
class WorkoutActiveScreenV2 extends StatefulWidget {
  final List<ActiveExercise> exercises;
  final int totalKcal;
  final int day;
  final String? dayId;

  const WorkoutActiveScreenV2({
    super.key,
    required this.exercises,
    required this.totalKcal,
    this.day = 3,
    this.dayId,
  });

  @override
  State<WorkoutActiveScreenV2> createState() => _WorkoutActiveScreenV2State();
}

class _WorkoutActiveScreenV2State extends State<WorkoutActiveScreenV2> {
  int _currentIndex = 0;
  late int _secondsLeft;
  bool _isPaused = false;
  Timer? _timer;
  int _earnedKcal = 12;
  bool _showMoreOptions = false;
  bool _isLocked = false;

  // Rebuilds the player sheet (if open) on every timer tick so its ring and
  // time stay live. Null whenever the sheet is closed.
  StateSetter? _sheetSetState;

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

  /// The next two exercises, fetched while this one plays.
  ///
  /// This is the ideal moment for it: the user is committed to a fixed sequence
  /// and has 30 seconds of nothing to do, so by the time the transition happens
  /// the media is already on disk. Gated on Wi-Fi inside the preloader.
  void _preloadUpcoming() {
    MediaPreloader.instance.warmNext<ActiveExercise>(
      widget.exercises,
      _currentIndex,
      urlsOf: (e) => e.preloadUrls,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _preloadUpcoming();
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
        _sheetSetState?.call(() {});
      } else {
        _timer?.cancel();
        _onExerciseComplete();
      }
    });
  }

  // Ring tap: quick pause/resume only, no sheet.
  void _toggleRingPause() {
    if (_isLocked) return;
    setState(() => _isPaused = !_isPaused);
  }

  // Swipe-up (or the hint row) opens the full player sheet. The workout keeps
  // running behind it — the sheet has its own pause control.
  void _openControlSheet() {
    if (_isLocked) return;
    _showPauseSheet();
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
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
      barrierColor: Colors.black.withValues(alpha: 0.15),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          _sheetSetState = setSheetState;
          final next = _currentIndex < widget.exercises.length - 1
              ? widget.exercises[_currentIndex + 1]
              : null;
          return _PlayerSheet(
            exercise: widget.exercises[_currentIndex],
            nextExercise: next,
            timeFormatted: _timeFormatted,
            progress: _progress,
            isPaused: _isPaused,
            earnedKcal: _earnedKcal,
            onTogglePause: () {
              setState(() => _isPaused = !_isPaused);
              setSheetState(() {});
            },
            onPrevious: () {
              _sheetSetState = null;
              Navigator.pop(context); // close sheet
              _goPrevWithRestScreen();
            },
            onNext: () {
              _sheetSetState = null;
              Navigator.pop(context); // close sheet
              _timer?.cancel();
              _onExerciseComplete();
            },
            onResume: () {
              _sheetSetState = null;
              Navigator.pop(context);
              setState(() => _isPaused = false);
            },
            onRestart: () {
              _sheetSetState = null;
              Navigator.pop(context); // close sheet
              Navigator.pop(context, 0); // back to the workout day detail screen
            },
            onSkip: () {
              _sheetSetState = null;
              Navigator.pop(context); // close sheet
              _timer?.cancel();
              _onExerciseComplete();
            },
            onQuit: () {
              _sheetSetState = null;
              Navigator.pop(context); // close sheet
              _showLeaveDialog();
            },
          );
        },
      ),
    ).whenComplete(() => _sheetSetState = null);
  }

  void _onExerciseComplete() {
    // Close the player sheet first if it's open, so the rest screen (or the
    // complete flow) isn't stacked on top of a stale sheet.
    if (_sheetSetState != null) {
      _sheetSetState = null;
      Navigator.pop(context);
    }
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

  /// Whole-workout progress for the day, counted per exercise: each exercise
  /// is an equal slice of the bar (e.g. 10 exercises → each is 10%). Within the
  /// current exercise the slice fills by its timer. Reaches 100% only once all
  /// exercises for the day are complete.
  double get _overallProgress {
    final count = widget.exercises.length;
    if (count == 0) return 0;
    final currentFraction = _progress.clamp(0.0, 1.0);
    return ((_currentIndex + currentFraction) / count).clamp(0.0, 1.0);
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-bleed exercise video/image.
          Positioned.fill(
            child: _buildExerciseImage(exercise),
          ),
          // Top: overall workout progress bar + back / more controls.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),
          // Bottom: lock-screen-style media capsule + music/lock row.
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: _buildCapsule(),
                ),
                const SizedBox(height: 14),
                _buildHintRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP OVERLAY ───────────────────────────────────────────────────────────

  Widget _buildTopOverlay() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            _buildTopProgressBar(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _roundIconButton(
                  color: Colors.black38,
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: Colors.white),
                  onTap: _openControlSheet,
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Workout Progress  ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '${(_overallProgress * 100).round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _pink,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                _buildMoreOptionsColumn(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProgressBar() {
    return SizedBox(
      width: double.infinity,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.30)),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _overallProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9E), Color(0xFFFF136B)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOCK-SCREEN STYLE MEDIA CAPSULE ────────────────────────────────────────

  Widget _buildCapsule() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (_isLocked) return;
        if ((details.primaryVelocity ?? 0) < -200) _openControlSheet();
      },
      child: _GlassCapsule(
        radius: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _capsuleStat(emoji: '🔥', value: '$_earnedKcal', label: 'kcal'),
              _PressableScale(
                onTap: _isLocked ? () {} : _toggleRingPause,
                child: _buildRingTimer(),
              ),
              _capsuleStat(
                value: '${_currentIndex + 1}/${widget.exercises.length}',
                label: 'Exercise',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingTimer() {
    return _GradientRingTimer(
      size: 84,
      strokeWidth: 6,
      progress: _progress,
      label: _timeFormatted,
    );
  }

  Widget _capsuleStat({String? emoji, required String value, required String label}) {
    final valueText = Text(
      value,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.15,
      ),
    );
    final labelText = Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.6),
        height: 1.2,
      ),
    );

    if (emoji == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [valueText, labelText],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [valueText, labelText],
        ),
      ],
    );
  }

  // ─── MUSIC / SWIPE HINT / LOCK ROW ──────────────────────────────────────────

  Widget _buildHintRow() {
    return Row(
      children: [
        _PressableScale(
          onTap: _isLocked
              ? () {}
              : () => _openSettings(const MusicSettingsScreen()),
          child: _smallCircleButton(Icons.music_note_rounded),
        ),
        Expanded(
          child: Center(
            child: _PressableScale(
              onTap: _isLocked ? () {} : _openControlSheet,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    'Swipe up to open player',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        _PressableScale(
          onTap: _toggleLock,
          child: _smallCircleButton(
              _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
        ),
      ],
    );
  }

  Widget _smallCircleButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ─── EXERCISE IMAGE (with overlay controls) ──────────────────────────────

  Widget _buildExerciseImage(ActiveExercise exercise) {
    final path = exercise.imagePath;
    final videoUrl = exercise.videoUrl;
    final media = exercise.image;
    final isNetworkImage = path.startsWith('http');

    return Stack(
      fit: StackFit.expand,
      children: [
        isNetworkImage
            ? GlowImage(
                url: path,
                media: media,
                width: double.infinity,
                error: _imageFallback(),
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
          // Keyed to the clip: this screen rebuilds once a second for the
          // countdown, and the player must survive every one of those.
          ExerciseVideoPlayer(
            key: ValueKey(videoUrl),
            videoUrl: videoUrl,
            playing: !_isPaused,
            media: exercise.video,
          ),
      ],
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

}

// ─── PRESSABLE SCALE ──────────────────────────────────────────────────────
// Spring-like scale-down on tap for a premium, tactile button feel.

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        child: widget.child,
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

// ─── PLAYER SHEET ─────────────────────────────────────────────────────────
// Dark media-player style sheet shown when the user swipes up on the capsule.

class _PlayerSheet extends StatelessWidget {
  final ActiveExercise exercise;
  final ActiveExercise? nextExercise;
  final String timeFormatted;
  final double progress;
  final bool isPaused;
  final int earnedKcal;
  final VoidCallback onTogglePause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSkip;
  final VoidCallback onQuit;

  const _PlayerSheet({
    required this.exercise,
    required this.nextExercise,
    required this.timeFormatted,
    required this.progress,
    required this.isPaused,
    required this.earnedKcal,
    required this.onTogglePause,
    required this.onPrevious,
    required this.onNext,
    required this.onResume,
    required this.onRestart,
    required this.onSkip,
    required this.onQuit,
  });

  // Translucent white so the blurred video shows through the cards too.
  static const _cardBg = Color(0x16FFFFFF);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            // Glossy translucent black: a faint white sheen at the top edge
            // fading into smoky black, with the video still visible behind.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.52),
                Colors.black.withValues(alpha: 0.66),
              ],
              stops: const [0.0, 0.16, 1.0],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header: exercise icon + name ... kcal badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.accessibility_new_rounded,
                    color: _pink, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$earnedKcal',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white54,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meta row: duration | equipment | body focus
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _metaItem(Icons.timer_outlined,
                  exercise.durationSeconds >= 60
                      ? '${exercise.durationSeconds ~/ 60} min'
                      : '${exercise.durationSeconds} sec'),
              _metaDivider(),
              _metaItem(Icons.do_not_disturb_alt_rounded, 'No Equipment'),
              _metaDivider(),
              _metaItem(Icons.fitness_center_rounded, 'Full Body'),
            ],
          ),
          const SizedBox(height: 22),

          // Big timer ring
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _RingPainter(progress: progress, strokeWidth: 6),
                ),
                Text(
                  timeFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Previous / Pause / Next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _transportButton(
                icon: Icons.skip_previous_rounded,
                label: 'Previous',
                onTap: onPrevious,
              ),
              _PressableScale(
                onTap: onTogglePause,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9E), Color(0xFFFF136B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _pink.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPaused ? 'Resume' : 'Pause',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _pink,
                      ),
                    ),
                  ],
                ),
              ),
              _transportButton(
                icon: Icons.skip_next_rounded,
                label: 'Next',
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Up Next card
          if (nextExercise != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Up Next',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _pink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextExercise!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextExercise!.durationSeconds >= 60
                              ? '${nextExercise!.durationSeconds ~/ 60} min'
                              : '${nextExercise!.durationSeconds} sec',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 48,
                      child: nextExercise!.imagePath.startsWith('http')
                          ? GlowImage(
                              url: nextExercise!.imagePath,
                              media: nextExercise!.image,
                              error: _thumbFallback(),
                            )
                          : (nextExercise!.imagePath.isEmpty
                              ? _thumbFallback()
                              : Image.asset(
                                  nextExercise!.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _thumbFallback(),
                                )),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Bottom action row: resume / restart / skip / quit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionCircle(Icons.play_arrow_rounded, onResume),
              _actionCircle(Icons.refresh_rounded, onRestart),
              _actionCircle(Icons.fast_forward_rounded, onSkip),
              _actionCircle(Icons.logout_rounded, onQuit),
            ],
          ),
        ],
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _metaDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white24,
    );
  }

  Widget _transportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCircle(IconData icon, VoidCallback onTap) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _pink.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _pink, size: 22),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: _pink.withValues(alpha: 0.15),
      child: const Icon(Icons.fitness_center, color: _pink, size: 20),
    );
  }
}

// ─── RING PAINTER ─────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  const _RingPainter({required this.progress, this.strokeWidth = 5});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2 - 1;

    final bgPaint = Paint()
      ..color = _pink.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = _pink
      ..strokeWidth = strokeWidth
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
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

// ─── GLASS CAPSULE (iOS 18 glassmorphism) ─────────────────────────────────
// Reusable frosted-glass pill: heavy backdrop blur, translucent black fill,
// top sheen gradient, hairline border and a soft bottom-only shadow. The
// content behind stays visible through the glass.

class _GlassCapsule extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCapsule({required this.child, this.radius = 34});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Vertical sheen: faint white at the top fading to nothing.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GRADIENT RING TIMER (Apple Fitness style) ────────────────────────────
// Custom-painted progress ring: gradient stroke with rounded caps, pink
// outer glow, dark inner disc and bold centered label.

class _GradientRingTimer extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double progress;
  final String label;

  const _GradientRingTimer({
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006A).withValues(alpha: 0.40),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark inner disc with a soft radial falloff.
          Container(
            margin: EdgeInsets.all(strokeWidth + 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF17171A).withValues(alpha: 0.92),
                  const Color(0xFF09090B).withValues(alpha: 0.96),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _GradientRingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
            ),
          ),
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
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: const [Color(0xFFFF4D95), Color(0xFFFF006A)],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
