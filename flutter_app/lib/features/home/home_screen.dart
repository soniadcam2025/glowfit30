import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../routes/app_pages.dart';
import '../workout/workout_plan_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(HomeController());
  }

  HomeController get _c => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildHeroBanner(),
              const SizedBox(height: 20),
              _buildTodaysProgress(),
              const SizedBox(height: 20),
              _build30DayJourney(),
              const SizedBox(height: 20),
              _buildDietPlanCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Obx(() => Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFFD6E7),
              child: ClipOval(
                child: _c.photoUrl.value.isNotEmpty
                    ? Image.network(
                        _c.photoUrl.value,
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28, color: _pink),
                      )
                    : Image.asset(
                        'assets/images/profile_avatar.png',
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28, color: _pink),
                      ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_c.userName.value} ',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: _pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/double_heart_solid.svg',
                    height: 18,
                    width: 18,
                    colorFilter: const ColorFilter.mode(
                      _pink,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildStatChip('🔥', _c.streak.value.toString(), 'Day Streak'),
        const SizedBox(width: 8),
        _buildStatChip('💧', '2.3L', 'of 3L'),
      ],
    ));
  }

  Widget _buildStatChip(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO BANNER ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    // Stack layers (back→front): background → girl → content column
    // The content Padding (non-Positioned, last child) drives the Stack height.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // ── 1. Pink background (fill adapts to content height) ───────
          Positioned.fill(
            child: Container(color: const Color(0xFFFCE4EF)),
          ),

          // ── 2. Girl image — behind content ───────────────────────────
          Positioned(
            right: 0,
            top: 10,
            bottom: 0,
            child: Image.asset(
              'assets/images/home_banner_woman.png',
              width: 140,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  Container(width: 140, color: const Color(0xFFFFB6D0)),
            ),
          ),

          // ── 3. All content (non-Positioned → defines Stack height) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // DAY pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Obx(() => RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'DAY ${_c.currentDay.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _pink,
                        ),
                      ),
                      TextSpan(
                        text: '/${_c.totalDays.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _darkText,
                        ),
                      ),
                    ]),
                  )),
                ),
                const SizedBox(height: 6),
                Obx(() => Text(
                  _c.goalText.value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                    height: 1.1,
                  ),
                )),
                Text(
                  'IN 30 DAYS',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _pink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                // Workout card
                FractionallySizedBox(
                  widthFactor: 0.65,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE0EC),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/gym.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  _pink, BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Today's Workout",
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey[600]),
                            ),
                            Obx(() => Text(
                              _c.workoutTitle.value,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _pink,
                              ),
                            )),
                            const SizedBox(height: 4),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Level',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: Colors.grey[700])),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF6C5DD3),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Obx(() => Text(
                                _c.workoutLevel.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6C5DD3),
                                ),
                              )),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 3 stat boxes — grouped together with 2px gaps
                Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildStatBox('🔥', '${_c.todayKcal.value} kcal', 'Burned'),
                    const SizedBox(width: 2),
                    _buildStatBox('⏱', '${_c.todayMinutes.value} min', 'Total Time'),
                    const SizedBox(width: 2),
                    _buildStatBox('🏃', '${_c.exerciseCount.value}', 'Exercises'),
                  ],
                )),
                const SizedBox(height: 10),
                // Gradient CTA button
                FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF136B), Color(0xFFFF5590)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF136B).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutPlanScreen(),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue Workout',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TODAY'S PROGRESS ────────────────────────────────────────────────────────

  Widget _buildTodaysProgress() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Workout – circular progress
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Overall Workout',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Obx(() => SizedBox(
                          width: 68,
                          height: 68,
                          child: CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: _c.progressPercent,
                              color: _pink,
                            ),
                            child: Center(
                              child: Text(
                                '${(_c.progressPercent * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _darkText,
                                ),
                              ),
                            ),
                          ),
                        )),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  'Great Job!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Calories Burned
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Calories Burned',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(() => RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_c.todayKcal.value}',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _darkText,
                                ),
                              ),
                              TextSpan(
                                text: ' kcal',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 4),
                        Obx(() {
                          final pct = (_c.progressPercent * 100).toInt();
                          return Text(
                            '$pct% of goal',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF22C55E),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        Obx(() => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _c.progressPercent.clamp(0, 1),
                            backgroundColor: Colors.green[100],
                            color: const Color(0xFF22C55E),
                            minHeight: 6,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Workout Time
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workout Time',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(() => RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_c.todayMinutes.value}',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _darkText,
                                ),
                              ),
                              TextSpan(
                                text: ' min',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 4),
                        Obx(() {
                          final pct = (_c.progressPercent * 100).toInt();
                          return Text(
                            '$pct% completed',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF4F8EF7),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        Obx(() => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _c.progressPercent.clamp(0, 1),
                            backgroundColor: Colors.blue[100],
                            color: const Color(0xFF4F8EF7),
                            minHeight: 6,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 30-DAY JOURNEY ──────────────────────────────────────────────────────────

  Widget _build30DayJourney() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your 30-Day Journey',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Calendar',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _pink,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: _pink),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(() {
          final todayNum = _c.currentDay.value;
          final total = _c.totalDays.value > 0 ? _c.totalDays.value : 30;
          final visible = total.clamp(1, 30);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(visible, (i) {
                final dayNum = i + 1;
                final _DayStatus status;
                if (dayNum < todayNum) {
                  status = _DayStatus.done;
                } else if (dayNum == todayNum) {
                  status = _DayStatus.today;
                } else {
                  status = _DayStatus.locked;
                }
                return Padding(
                  padding: EdgeInsets.only(right: i < visible - 1 ? 10 : 0),
                  child: _buildDayCircle(dayNum, status),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCircle(int day, _DayStatus status) {
    final isToday = status == _DayStatus.today;
    final isDone = status == _DayStatus.done;
    final isLocked = status == _DayStatus.locked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? _pink : Colors.white,
            border: Border.all(
              color: isLocked ? Colors.grey[300]! : _pink,
              width: 2,
            ),
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, size: 18, color: Colors.grey[400])
                : isDone
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _pink,
                            ),
                          ),
                          const Icon(Icons.check, color: _pink, size: 14),
                        ],
                      )
                    : Text(
                        '$day',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isToday
              ? 'Today'
              : isDone
                  ? 'Done'
                  : 'Locked',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday
                ? _pink
                : isLocked
                    ? Colors.grey[400]!
                    : Colors.grey[600]!,
          ),
        ),
      ],
    );
  }

  // ─── DIET PLAN CARD ──────────────────────────────────────────────────────────

  Widget _buildDietPlanCard() {
    return SizedBox(
      height: 215,
      child: Container(
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
            // Food image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/diet_food_bowl.png',
                width: 140,
                height: 215,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 140,
                  height: 215,
                  color: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.restaurant,
                      size: 48, color: Color(0xFF81C784)),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0EC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🍽️', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            "TODAY'S DIET PLAN",
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: _pink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'High Protein\nFat Loss',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildDietStat('🔥', '1650', 'kcal'),
                        const SizedBox(width: 8),
                        _buildDietStat('🍴', '4', 'Meals'),
                        const SizedBox(width: 8),
                        _buildDietStat('☀️', 'Breakfast', 'Ready'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed(Routes.diet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Full Diet Plan',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietStat(String emoji, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ─── BOTTOM NAV ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      _NavItem(svg: 'assets/icons/nav_home.svg', label: 'Home'),
      _NavItem(svg: 'assets/icons/nav_workout.svg', label: 'Workout'),
      _NavItem(svg: 'assets/icons/nav_diet.svg', label: 'Diet'),
      _NavItem(svg: 'assets/icons/nav_progress.svg', label: 'Progress'),
      _NavItem(png: 'assets/icons/glowfit_ico_selected.png', label: 'GlowFit'),
    ];

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
              final selected = i == _selectedIndex;
              final color = selected ? _pink : Colors.grey[500]!;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);
                  if (i == 2) Get.toNamed(Routes.diet);
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

// ─── HELPERS ─────────────────────────────────────────────────────────────────

enum _DayStatus { done, today, locked }

class _NavItem {
  final String? svg;
  final String? png;
  final String label;
  _NavItem({this.svg, this.png, required this.label});
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

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
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
