import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'workout_active_screen.dart';
import 'workout_complete_screen.dart';
import 'workout_ready_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class DetailTag {
  final String emoji;
  final String label;
  final Color background;
  final Color foreground;

  const DetailTag({
    required this.emoji,
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory DetailTag.fromJson(Map<String, dynamic> j) => DetailTag(
        emoji: j['emoji'] as String? ?? '🔥',
        label: j['label'] as String? ?? '',
        background: _colorFromHex(j['background'] as String?) ??
            const Color(0xFFFFE0EC),
        foreground: _colorFromHex(j['foreground'] as String?) ?? _pink,
      );
}

class DetailExercise {
  final String name;
  final int durationSeconds;
  final String? imageUrl;
  final String? videoUrl;

  const DetailExercise({
    required this.name,
    required this.durationSeconds,
    this.imageUrl,
    this.videoUrl,
  });

  factory DetailExercise.fromJson(Map<String, dynamic> j) => DetailExercise(
        name: j['name'] as String? ?? '',
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 30,
        imageUrl: j['imageUrl'] as String?,
        videoUrl: j['videoUrl'] as String?,
      );
}

Color? _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Loaded/parsed content for a single library workout, fetched from the
/// admin-managed /workout-library API.
class _LibraryWorkout {
  final String category;
  final String titleLine1;
  final String titleScript;
  final String description;
  final String? heroImageUrl;
  final List<DetailTag> tags;
  final int durationMinutes;
  final String kcalLabel;
  final String focusLabel;
  final List<DetailExercise> exercises;

  const _LibraryWorkout({
    required this.category,
    required this.titleLine1,
    required this.titleScript,
    required this.description,
    required this.heroImageUrl,
    required this.tags,
    required this.durationMinutes,
    required this.kcalLabel,
    required this.focusLabel,
    required this.exercises,
  });

  factory _LibraryWorkout.fromJson(Map<String, dynamic> j) => _LibraryWorkout(
        category: j['category'] as String? ?? '',
        titleLine1: j['titleLine1'] as String? ?? '',
        titleScript: j['titleScript'] as String? ?? '',
        description: j['description'] as String? ?? '',
        heroImageUrl: j['heroImageUrl'] as String?,
        tags: ((j['tags'] as List?) ?? [])
            .map((t) => DetailTag.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        kcalLabel: j['kcalLabel'] as String? ?? '',
        focusLabel: j['focusLabel'] as String? ?? '',
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) =>
                DetailExercise.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class WorkoutDetailScreen extends StatefulWidget {
  final String itemId;
  final int trackedKcal;

  const WorkoutDetailScreen({
    super.key,
    required this.itemId,
    this.trackedKcal = 140,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  _LibraryWorkout? _workout;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final json = await Get.find<ApiService>().getWorkoutLibraryItem(widget.itemId);
    if (!mounted) return;
    if (json == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    setState(() {
      _workout = _LibraryWorkout.fromJson(json);
      _loading = false;
    });
  }

  List<ActiveExercise> _buildActiveExercises() {
    return (_workout?.exercises ?? [])
        .map((e) => ActiveExercise(
              name: e.name,
              imagePath: e.imageUrl ?? '',
              videoUrl: e.videoUrl,
              durationSeconds: e.durationSeconds,
            ))
        .toList();
  }

  void _launchActive() {
    final activeExercises = _buildActiveExercises();
    if (activeExercises.isEmpty) return;
    Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutReadyScreen(
          totalKcal: widget.trackedKcal,
          day: 0,
          exercises: activeExercises,
        ),
      ),
    ).then((result) {
      if (result == null || !mounted) return;
      if (result >= activeExercises.length) {
        _showCompleteScreen(activeExercises);
      }
    });
  }

  void _showCompleteScreen(List<ActiveExercise> exercises) {
    final totalSecs = exercises.fold(0, (sum, e) => sum + e.durationSeconds);
    final mm = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSecs % 60).toString().padLeft(2, '0');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCompleteScreen(
          day: 0,
          programLabel: '${_workout!.titleLine1} ${_workout!.titleScript}',
          continueLabel: 'Back to Library',
          caloriesBurned: widget.trackedKcal,
          totalTime: '$mm:$ss',
          durationMin: totalSecs ~/ 60,
          exercisesCompleted: exercises.length,
          totalExercises: exercises.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _pink)),
      );
    }
    if (_error || _workout == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "Couldn't load this workout.",
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final workout = _workout!;
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
                  _buildAppBar(),
                  _buildHero(workout),
                  const SizedBox(height: 18),
                  _buildTagRow(workout),
                  const SizedBox(height: 18),
                  _buildStatsGrid(workout),
                  const SizedBox(height: 24),
                  _buildExercisesSection(workout),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStartButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
          _circleButton(icon: Icons.bookmark_border_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 17, color: _darkText),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────────────

  Widget _buildHero(_LibraryWorkout workout) {
    final heroUrl = workout.heroImageUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          top: 10,
          child: (heroUrl == null || heroUrl.isEmpty)
              ? _heroFallback()
              : Image.network(
                  heroUrl,
                  width: 190,
                  fit: BoxFit.contain,
                  alignment: Alignment.topRight,
                  errorBuilder: (_, __, ___) => _heroFallback(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 170, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.track_changes_rounded,
                      size: 13, color: _pink),
                  const SizedBox(width: 4),
                  Text(
                    workout.category.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                workout.titleLine1,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _darkText,
                  height: 1.05,
                ),
              ),
              Text(
                workout.titleScript,
                style: GoogleFonts.dancingScript(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: _pink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workout.description,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroFallback() {
    return SizedBox(
      width: 160,
      height: 200,
      child: Icon(Icons.self_improvement_rounded,
          size: 70, color: _pink.withValues(alpha: 0.25)),
    );
  }

  // ─── TAG ROW ──────────────────────────────────────────────────────────────

  Widget _buildTagRow(_LibraryWorkout workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: workout.tags.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  t.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.foreground,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STATS GRID ───────────────────────────────────────────────────────────

  Widget _buildStatsGrid(_LibraryWorkout workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.access_time_rounded,
              iconColor: _pink,
              iconBg: const Color(0xFFFFE0EC),
              value: '${workout.durationMinutes}',
              unit: 'min',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFFF8C00),
              iconBg: const Color(0xFFFFEEDD),
              value: workout.kcalLabel,
              unit: 'kcal',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFF2196F3),
              iconBg: const Color(0xFFE3F2FD),
              value: '${workout.exercises.length}',
              unit: 'Exercises',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFFE7F9EC),
              value: workout.focusLabel,
              unit: 'Focus Area',
              small: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String unit,
    bool small = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5EBF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: small ? 12 : 15,
              fontWeight: FontWeight.w800,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── EXERCISES ────────────────────────────────────────────────────────────

  Widget _buildExercisesSection(_LibraryWorkout workout) {
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
        const SizedBox(height: 12),
        if (workout.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Exercises for this workout are coming soon.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (int i = 0; i < workout.exercises.length; i++) ...[
                  _buildExerciseRow(workout.exercises[i]),
                  if (i != workout.exercises.length - 1)
                    Divider(height: 24, color: Colors.grey[200]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (workout.exercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All ${workout.exercises.length} Exercises',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _pink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: _pink),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseRow(DetailExercise e) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: (e.imageUrl == null || e.imageUrl!.isEmpty)
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        e.imageUrl!,
                        width: 90,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
            ),
            if (e.videoUrl != null && e.videoUrl!.isNotEmpty)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
                  Text(
                    '${e.durationSeconds} sec',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── START BUTTON ─────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
      child: GestureDetector(
        onTap: _launchActive,
        child: Container(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    size: 18, color: _pink),
              ),
              const SizedBox(width: 10),
              Text(
                'Start Workout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
