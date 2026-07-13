import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);
const _purple = Color(0xFF8B5CF6);
const _green = Color(0xFF22C55E);

class _Completion {
  final DateTime completedAt;
  final String title;
  final String? imageUrl;
  final int calories;
  final int minutes;

  _Completion({
    required this.completedAt,
    required this.title,
    this.imageUrl,
    required this.calories,
    required this.minutes,
  });

  factory _Completion.fromJson(Map<String, dynamic> j) {
    final wd = j['workoutDay'] as Map<String, dynamic>?;
    final workout = wd?['workout'] as Map<String, dynamic>?;
    return _Completion(
      completedAt:
          DateTime.tryParse(j['completedAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      title: (wd?['title'] as String?) ??
          (workout?['title'] as String?) ??
          'Workout',
      imageUrl: wd?['imageUrl'] as String?,
      calories: (j['caloriesBurned'] as num?)?.toInt() ?? 0,
      minutes: (j['durationMin'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get day =>
      DateTime(completedAt.year, completedAt.month, completedAt.day);
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;

  int _totalWorkouts = 0;
  int _totalCalories = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  List<_Completion> _completions = [];

  double? _weight;
  double? _targetWeight;
  double? _height;

  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([api.getProgress(), api.getProfile()]);
    final progress = results[0] as Map<String, dynamic>?;
    final profile = results[1] as Map<String, dynamic>?;
    if (!mounted) return;

    final stats = progress?['stats'] as Map<String, dynamic>?;
    final completionsJson = (progress?['completions'] as List?) ?? [];

    setState(() {
      _totalWorkouts = (stats?['totalSessions'] as num?)?.toInt() ?? 0;
      _totalCalories = (stats?['totalCalories'] as num?)?.toInt() ?? 0;
      _totalMinutes = (stats?['totalMinutes'] as num?)?.toInt() ?? 0;
      _streak = (stats?['streak'] as num?)?.toInt() ?? 0;
      _completions = completionsJson
          .map((e) => _Completion.fromJson(e as Map<String, dynamic>))
          .toList();
      _weight = (profile?['weight'] as num?)?.toDouble();
      _targetWeight = (profile?['targetWeight'] as num?)?.toDouble();
      _height = (profile?['height'] as num?)?.toDouble();
      _loading = false;
    });
  }

  double? get _bmi {
    if (_weight == null || _height == null || _height == 0) return null;
    final hM = _height! / 100;
    return _weight! / (hM * hM);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF2F80ED);
    if (bmi < 25) return _green;
    if (bmi < 30) return const Color(0xFFF2994A);
    return const Color(0xFFEB5757);
  }

  bool _hasCompletionOn(DateTime day) =>
      _completions.any((c) => c.day == DateTime(day.year, day.month, day.day));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : RefreshIndicator(
                color: _pink,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildOverviewCard(),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildStreakCard()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildBmiCard()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildWeightProgressCard(),
                      const SizedBox(height: 14),
                      _buildWeeklyActivityCard(),
                      const SizedBox(height: 20),
                      _buildWorkoutHistorySection(),
                      const SizedBox(height: 20),
                      _buildStreakCalendarSection(),
                      const SizedBox(height: 14),
                      _buildBodyMetricsCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your journey, celebrate every win! 🎉',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.calendar_today_rounded,
              size: 18, color: _pink),
        ),
      ],
    );
  }

  // ─── OVERVIEW ─────────────────────────────────────────────────────────────

  Widget _buildOverviewCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Overview'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _overviewStat(
                  icon: Icons.fitness_center_rounded,
                  iconBg: const Color(0xFFEAE3FA),
                  iconColor: const Color(0xFF6C3EBE),
                  value: '$_totalWorkouts',
                  label: 'Workouts',
                ),
              ),
              Expanded(
                child: _overviewStat(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFFFFF3D6),
                  iconColor: const Color(0xFFF2994A),
                  value: '$_totalCalories',
                  label: 'kcal Burned',
                ),
              ),
              Expanded(
                child: _overviewStat(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFFFE0EC),
                  iconColor: _pink,
                  value: '$_totalMinutes',
                  label: 'mins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewStat({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ─── DAY STREAK GOAL ──────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    const goal = 30;
    final progress = (_streak / goal).clamp(0.0, 1.0);
    final today = DateTime.now();
    final windowDays =
        List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Day Streak Goal',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
              ),
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(84, 84),
                      painter:
                          _RingPainter(progress: progress, color: _pink),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: const TextStyle(fontSize: 14)),
                        Text(
                          '$_streak',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _darkText,
                          ),
                        ),
                        Text(
                          'Day Streak',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Goal',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey[500])),
                    Text(
                      '$goal Days',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "You're doing amazing!\nKeep going and crush your goal.",
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in windowDays) _streakDayChip(d),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakDayChip(DateTime d) {
    final done = _hasCompletionOn(d);
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? _pink : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 3),
        Text(
          '${d.day}',
          style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ─── BMI ──────────────────────────────────────────────────────────────────

  Widget _buildBmiCard() {
    final bmi = _bmi;
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BMI',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
              ),
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 62,
            child: CustomPaint(
              size: const Size(double.infinity, 62),
              painter: _BmiGaugePainter(bmi: bmi ?? 22),
            ),
          ),
          Center(
            child: Text(
              bmi != null ? bmi.toStringAsFixed(1) : '--',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _darkText,
              ),
            ),
          ),
          Center(
            child: Text(
              bmi != null ? _bmiLabel(bmi) : 'Add weight & height',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: bmi != null ? _bmiColor(bmi) : Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bmi != null
                ? 'Your BMI is in the ${_bmiLabel(bmi).toLowerCase()} range.\nGreat job!'
                : 'Update your profile to see your BMI.',
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── WEIGHT PROGRESS ──────────────────────────────────────────────────────

  Widget _buildWeightProgressCard() {
    final current = _weight;
    final target = _targetWeight;
    final hasRealData = current != null && target != null;

    // Illustrative trend: we don't persist a weight-log history yet, so this
    // renders a smooth path from an assumed starting point down to the
    // current weight, ending with a dashed projection to the target.
    final double displayCurrent = current ?? 64.0;
    final double displayTarget = target ?? 55.0;
    final double starting = hasRealData
        ? displayCurrent + math.max(6.0, (displayCurrent - displayTarget) * 0.5)
        : 70.0;

    final spots = <FlSpot>[];
    for (int i = 0; i <= 6; i++) {
      final double t = i / 6;
      final double eased = 1 - math.pow(1 - t, 2).toDouble();
      spots.add(FlSpot(i.toDouble(), starting - (starting - displayCurrent) * eased));
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Weight Progress')),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weightBubble('Starting', starting, _pink),
              _weightBubble('Current', displayCurrent, _green),
              _weightBubble('Target', displayTarget, _purple),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: (displayTarget - 8).floorToDouble(),
                maxY: (starting + 6).ceilToDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 15,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, meta) {
                        const labels = {0: 'May 1', 3: 'June 1', 6: 'June 30'};
                        final label = labels[v.toInt()];
                        if (label == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                                fontSize: 8.5, color: Colors.grey[400]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _pink,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                        radius: i == spots.length - 1 ? 4 : 2.5,
                        color: _pink,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _pink.withValues(alpha: 0.18),
                          _pink.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      spots.last,
                      FlSpot(8, displayTarget),
                    ],
                    isCurved: false,
                    color: _pink.withValues(alpha: 0.6),
                    barWidth: 2,
                    dashArray: [5, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                        radius: i == 1 ? 4 : 0,
                        color: _purple,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasRealData) ...[
            const SizedBox(height: 6),
            Text(
              'Add your current & target weight in your profile to personalize this chart.',
              style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightBubble(String label, double kg, Color color) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(
          '${kg.toStringAsFixed(0)} kg',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── WEEKLY ACTIVITY ──────────────────────────────────────────────────────

  Widget _buildWeeklyActivityCard() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    final mins = days
        .map((d) => _completions
            .where((c) => c.day == DateTime(d.year, d.month, d.day))
            .fold<int>(0, (s, c) => s + c.minutes))
        .toList();
    final kcal = days
        .map((d) => _completions
            .where((c) => c.day == DateTime(d.year, d.month, d.day))
            .fold<int>(0, (s, c) => s + c.calories))
        .toList();

    final maxMin = (mins.isEmpty ? 0 : mins.reduce(math.max));
    final maxKcal = (kcal.isEmpty ? 0 : kcal.reduce(math.max));
    final minAxisMax = math.max(30, ((maxMin ~/ 30) + 1) * 30).toDouble();
    final kcalAxisMax = math.max(400, ((maxKcal ~/ 400) + 1) * 400).toDouble();
    final noActivityThisWeek = maxMin == 0 && maxKcal == 0;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Weekly Activity'),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(_pink, 'Workout Mins'),
              const SizedBox(width: 14),
              _legendDot(_purple, 'Calories Burned'),
            ],
          ),
          if (noActivityThisWeek) ...[
            const SizedBox(height: 4),
            Text(
              'No workouts logged this week yet.',
              style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[400]),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: minAxisMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: minAxisMax / 4,
                      getTitlesWidget: (v, meta) => Text(
                        (v / minAxisMax * kcalAxisMax).toInt().toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 8.5, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: minAxisMax / 4,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 8.5, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[i],
                            style: GoogleFonts.poppins(
                                fontSize: 9, color: Colors.grey[500]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(enabled: false),
                barGroups: [
                  for (int i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: mins[i].toDouble(),
                          color: _pink,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: (kcal[i] / kcalAxisMax) * minAxisMax,
                          color: _purple,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[600])),
      ],
    );
  }

  // ─── WORKOUT HISTORY ──────────────────────────────────────────────────────

  Widget _buildWorkoutHistorySection() {
    final recent = _completions.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Workout History')),
            Text(
              'View All',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _pink,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: _pink),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No workouts completed yet.\nFinish a workout to see it here!',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500]),
                ),
              ),
            ),
          )
        else
          for (final c in recent) _historyRow(c),
      ],
    );
  }

  Widget _historyRow(_Completion c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (c.imageUrl == null || c.imageUrl!.isEmpty)
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF4E8D), Color(0xFFFF136B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.fitness_center_rounded,
                          color: Colors.white54, size: 24),
                    )
                  : Image.network(
                      c.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFE0EC),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: _pink, size: 24),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(c.completedAt),
                  style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[400]),
                ),
                Text(
                  c.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text('${c.minutes} min', style: _metaStyle()),
                    const SizedBox(width: 10),
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text('${c.calories} kcal', style: _metaStyle()),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  TextStyle _metaStyle() => GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      );

  // ─── STREAK CALENDAR ──────────────────────────────────────────────────────

  Widget _buildStreakCalendarSection() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = (firstOfMonth.weekday - 1) % 7; // Monday-first grid
    final today = DateTime.now();

    final cells = <DateTime?>[];
    for (int i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(year, month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Streak Calendar'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                    _calendarMonth = DateTime(year, month - 1)),
                child: Icon(Icons.chevron_left_rounded, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMMM yyyy').format(_calendarMonth),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() =>
                    _calendarMonth = DateTime(year, month + 1)),
                child: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final l in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                SizedBox(
                  width: 32,
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int row = 0; row < cells.length ~/ 7; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int col = 0; col < 7; col++)
                    _calendarCell(cells[row * 7 + col], today),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _calendarLegend(_pink, filled: true, label: 'Completed'),
              const SizedBox(width: 14),
              _calendarLegend(Colors.grey[300]!, filled: false, label: 'Missed'),
              const SizedBox(width: 14),
              _calendarLegend(_green, filled: false, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarCell(DateTime? day, DateTime today) {
    if (day == null) {
      return const SizedBox(width: 32, height: 32);
    }
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final done = _hasCompletionOn(day);
    final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));

    Widget content;
    if (isToday) {
      content = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _green, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: GoogleFonts.poppins(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: _darkText),
        ),
      );
    } else if (done) {
      content = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    } else {
      content = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: isFuture ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }
    return content;
  }

  Widget _calendarLegend(Color color, {required bool filled, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: filled ? null : Border.all(color: color, width: 1.4),
          ),
          child: filled
              ? const Icon(Icons.check_rounded, size: 9, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  // ─── BODY METRICS ─────────────────────────────────────────────────────────

  Widget _buildBodyMetricsCard() {
    final bmi = _bmi;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Body Metrics'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _bodyMetric(
                  icon: Icons.monitor_weight_rounded,
                  iconBg: const Color(0xFFEAE3FA),
                  iconColor: const Color(0xFF6C3EBE),
                  value: _weight != null ? '${_weight!.toStringAsFixed(0)} kg' : '--',
                  label: 'Weight',
                ),
              ),
              Expanded(
                child: _bodyMetric(
                  icon: Icons.monitor_heart_rounded,
                  iconBg: const Color(0xFFE1F3E5),
                  iconColor: _green,
                  value: bmi != null ? bmi.toStringAsFixed(1) : '--',
                  label: 'BMI',
                  labelColor: bmi != null ? _bmiColor(bmi) : null,
                ),
              ),
              Expanded(
                child: _bodyMetric(
                  icon: Icons.percent_rounded,
                  iconBg: const Color(0xFFFFF3D6),
                  iconColor: const Color(0xFFF2994A),
                  value: '--',
                  label: 'Body Fat',
                ),
              ),
              Expanded(
                child: _bodyMetric(
                  icon: Icons.straighten_rounded,
                  iconBg: const Color(0xFFF0E2E6),
                  iconColor: const Color(0xFF8B5CF6),
                  value: '--',
                  label: 'Waist',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bodyMetric({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    Color? labelColor,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: labelColor ?? Colors.grey[500]),
        ),
      ],
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: _darkText,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      (svg: 'assets/icons/nav_home.svg', png: null, label: 'Home'),
      (svg: 'assets/icons/nav_workout.svg', png: null, label: 'Workout'),
      (svg: 'assets/icons/nav_diet.svg', png: null, label: 'Diet'),
      (svg: 'assets/icons/nav_progress.svg', png: null, label: 'Progress'),
      (
        svg: null,
        png: 'assets/icons/glowfit_ico_selected.png',
        label: 'GlowFit'
      ),
    ];
    const progressIndex = 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == progressIndex;
              final color = selected ? _pink : Colors.grey[500]!;
              return GestureDetector(
                onTap: () {
                  // Progress is the current screen; any other tab returns to
                  // Home (where the nav lives).
                  if (i != progressIndex) Get.back();
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.svg != null)
                      SvgPicture.asset(
                        item.svg!,
                        width: 26,
                        height: 26,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    else
                      Image.asset(
                        item.png!,
                        width: 26,
                        height: 26,
                        color: color,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.auto_awesome_rounded,
                          size: 26,
                          color: color,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── CUSTOM PAINTERS ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress.clamp(0.001, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _BmiGaugePainter extends CustomPainter {
  final double bmi;
  static const double _min = 12;
  static const double _max = 36;

  _BmiGaugePainter({required this.bmi});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2 - 4, size.height - 4);
    const startAngle = math.pi; // left
    const sweep = math.pi; // half circle to right

    final segments = <double, Color>{
      18.5: const Color(0xFF2F80ED), // underweight
      25.0: _green, // normal
      30.0: const Color(0xFFF2994A), // overweight
      _max: const Color(0xFFEB5757), // obese
    };

    double prev = _min;
    for (final entry in segments.entries) {
      final boundary = math.min(entry.key, _max);
      final startFrac = (prev - _min) / (_max - _min);
      final endFrac = (boundary - _min) / (_max - _min);
      final paint = Paint()
        ..color = entry.value
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweep * startFrac,
        sweep * (endFrac - startFrac),
        false,
        paint,
      );
      prev = boundary;
    }

    final clamped = bmi.clamp(_min, _max);
    final frac = (clamped - _min) / (_max - _min);
    final angle = startAngle + sweep * frac;
    final pointer = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final dotOuter = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = _darkText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(pointer, 6, dotOuter);
    canvas.drawCircle(pointer, 6, dotBorder);
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) =>
      oldDelegate.bmi != bmi;
}
