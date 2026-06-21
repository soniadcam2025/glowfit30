import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/diet_controller.dart';
import '../../controllers/home_controller.dart';

const _pink    = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);
const _green   = Color(0xFF22C55E);

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  late final DietController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(DietController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSubtitle(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  if (_c.isLoading.value) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator(color: _pink)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildPlanImageBanner(),
                      _buildDietTypeSelector(),
                      const SizedBox(height: 20),
                      _buildDayTimeline(),
                      const SizedBox(height: 20),
                      _buildFocusCard(),
                      const SizedBox(height: 16),
                      ..._c.meals.map(_buildMealCard),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 28),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _darkText),
            ),
          ),
          Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Day ${_c.currentDay.value} Diet Plan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          )),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border_rounded, size: 22, color: _darkText),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUBTITLE ────────────────────────────────────────────────────────────────

  Widget _buildSubtitle() {
    return Obx(() => Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "You're on day ${_c.currentDay.value} of your 30-day journey",
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          const Text('🌱', style: TextStyle(fontSize: 14)),
        ],
      ),
    ));
  }

  // ─── DIET TYPE SELECTOR ───────────────────────────────────────────────────────

  Widget _buildPlanImageBanner() {
    return Obx(() {
      final url = _c.planImageUrl.value;
      if (url.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            url,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(color: _pink)),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildDietTypeSelector() {
    return Center(
      child: Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green[300]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_c.dietEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              _c.dietStyle.value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _darkText,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey[600]),
          ],
        ),
      )),
    );
  }

  // ─── DAY TIMELINE ────────────────────────────────────────────────────────────

  Widget _buildDayTimeline() {
    return Obx(() {
      final today   = _c.currentDay.value;
      const visible = [1, 2, 3, 4, 5, 30];
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(visible.length, (i) {
            final day = visible[i];
            final bool isDone    = day < today;
            final bool isToday   = day == today;
            final bool isLocked  = day > today;
            final bool showDots  = i == visible.length - 2;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTimelineItem(day, isDone, isToday, isLocked),
                if (i < visible.length - 1) ...[
                  if (showDots) ...[
                    _buildConnectorLine(isDone),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text('...', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ),
                    _buildConnectorLine(false),
                  ] else
                    _buildConnectorLine(isDone || isToday),
                ],
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildConnectorLine(bool active) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: active ? _pink : Colors.grey[300],
    );
  }

  Widget _buildTimelineItem(int day, bool isDone, bool isToday, bool isLocked) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? Colors.white
                : isDone
                    ? Colors.white
                    : Colors.grey[100],
            border: Border.all(
              color: isLocked ? Colors.grey[300]! : (isToday ? _green : _pink),
              width: 2,
            ),
            boxShadow: isToday
                ? [BoxShadow(color: _green.withValues(alpha: 0.2), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, size: 16, color: Colors.grey[400])
                : Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: isToday ? _green : _pink,
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'DAY $day',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isToday ? _green : _darkText,
          ),
        ),
        Text(
          isToday ? 'Current' : isDone ? 'Done' : 'Locked',
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: isToday
                ? _green
                : isDone
                    ? Colors.grey[500]
                    : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  // ─── FOCUS CARD ──────────────────────────────────────────────────────────────

  Widget _buildFocusCard() {
    return Obx(() => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 165,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F4), Color(0xFFFFD6E7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Text content
            Positioned(
              left: 16,
              top: 18,
              right: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${_c.currentDay.value} Focus',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _pink,
                    ),
                  ),
                  Text(
                    _c.goal.value,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _focusTag('🔥', '${_c.caloriesTarget.value} kcal', 'Target'),
                      _focusTag('💪', 'High Protein', 'Focus'),
                      _focusTag('✨', _c.goal.value, 'Friendly'),
                    ],
                  ),
                ],
              ),
            ),
            // Woman image
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 155,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/diet_focus_woman.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD6E7), Color(0xFFFFA0C0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: Text('🥗', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _focusTag(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _darkText)),
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 9, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MEAL CARD ───────────────────────────────────────────────────────────────

  Widget _buildMealCard(MealSlot meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE7FF), Color(0xFFD5C8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(meal.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meal.desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Food image + kcal + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Food image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  meal.image,
                  width: 62,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 62,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.pink[50]!, Colors.pink[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(meal.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${meal.kcal}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _pink,
                      ),
                    ),
                    TextSpan(
                      text: '\nkcal',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: _pink, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
              Text(
                meal.time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY CARD ────────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Water intake
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('💧', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water Intake',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600])),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_c.waterCurrent.value.toStringAsFixed(1)} L',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00BCD4),
                            ),
                          ),
                          TextSpan(
                            text: ' / ${_c.waterTarget.value.toStringAsFixed(0)} L',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('Stay Hydrated',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),

          Container(width: 1, height: 55, color: Colors.grey[200]),

          // Calories target
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Calories Target',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600])),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_c.caloriesTarget.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _pink,
                            ),
                          ),
                          TextSpan(
                            text: ' kcal',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('Daily Target',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
