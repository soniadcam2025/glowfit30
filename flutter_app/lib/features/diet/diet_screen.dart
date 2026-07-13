import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/diet_controller.dart';
import '../../routes/app_pages.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);
const _green = Color(0xFF22C55E);
const _purple = Color(0xFF9B6BE3);
const _purpleBg = Color(0xFFF1E9FB);

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
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _pink));
          }
          return Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(child: _buildDietTypePill()),
                      const SizedBox(height: 20),
                      _buildDayStepper(),
                      const SizedBox(height: 22),
                      _buildFocusCard(),
                      const SizedBox(height: 18),
                      ..._c.meals.map(_buildMealCard),
                      const SizedBox(height: 6),
                      _buildSummaryCard(),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _circleButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Get.back(),
            ),
          ),
          Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Day ${_c.currentDay.value} Diet Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "You're on day ${_c.currentDay.value} of your "
                        '${_c.totalDays.value}-day journey ',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Text('💗', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              )),
          Align(
            alignment: Alignment.centerRight,
            child: _circleButton(
              icon: Icons.bookmark_border_rounded,
              onTap: () {},
            ),
          ),
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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: _darkText),
      ),
    );
  }

  // ─── DIET TYPE PILL ───────────────────────────────────────────────────────────

  Widget _buildDietTypePill() {
    return Obx(() => GestureDetector(
          onTap: _showDietTypeMenu,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _green.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_c.dietEmoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Text(
                  _c.dietStyle.value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkText,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ));
  }

  void _showDietTypeMenu() {
    const options = ['Vegetarian', 'Vegan', 'Non-Vegetarian'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ...options.map((o) => ListTile(
                  title: Text(o,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: _c.dietStyle.value == o
                      ? const Icon(Icons.check_rounded, color: _green)
                      : null,
                  onTap: () {
                    _c.dietStyle.value = o;
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── DAY STEPPER ──────────────────────────────────────────────────────────────

  Widget _buildDayStepper() {
    final current = _c.currentDay.value;
    final total = _c.totalDays.value;
    // Visible days: 1..5, then an ellipsis, then the final day.
    final visible = <int>[1, 2, 3, 4, 5];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          Expanded(child: _stepperDay(visible[i], current)),
          if (i < visible.length - 1)
            _stepperConnector(visible[i] < current),
        ],
        _stepperConnector(false),
        _stepperEllipsis(),
        _stepperConnector(false),
        Expanded(child: _stepperDay(total, current, lockedLabel: true)),
      ],
    );
  }

  Widget _stepperConnector(bool filled) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        width: 14,
        height: 2,
        color: filled ? _pink : Colors.grey[300],
      ),
    );
  }

  Widget _stepperEllipsis() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.grey[400]),
      ),
    );
  }

  Widget _stepperDay(int day, int current, {bool lockedLabel = false}) {
    final isCompleted = day < current;
    final isCurrent = day == current;
    final Color ringColor;
    final Widget inner;
    final String label;

    if (isCompleted) {
      ringColor = _pink;
      inner = const Icon(Icons.check_rounded, size: 18, color: _pink);
      label = 'Completed';
    } else if (isCurrent) {
      ringColor = _green;
      inner = Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
      label = 'Current';
    } else {
      ringColor = Colors.grey[300]!;
      inner = Icon(Icons.lock_rounded, size: 15, color: Colors.grey[400]);
      label = 'Locked';
    }

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isCurrent ? null : Border.all(color: ringColor, width: 2),
          ),
          child: inner,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'DAY $day',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isCurrent
                  ? _green
                  : (isCompleted ? _darkText : Colors.grey[500]),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isCurrent ? _green : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  // ─── FOCUS CARD ─────────────────────────────────────────────────────────────

  Widget _buildFocusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFDE8F0), Color(0xFFFCDCEA)],
          ),
        ),
        child: Stack(
          children: [
            // Focus woman photo on the right.
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 150,
              child: Image.asset(
                'assets/images/diet_focus_woman.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${_c.currentDay.value} Focus',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _pink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _c.goal.value,
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _focusMiniCard(i),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusMiniCard(int index) {
    const emojis = ['🔥', '🏋️', '🎀'];
    // focusTags come as "VALUE ... LABEL" (label = last word).
    String value = '';
    String label = '';
    if (index < _c.focusTags.length) {
      final parts = _c.focusTags[index].split(' ');
      if (parts.length > 1) {
        label = parts.last;
        value = parts.sublist(0, parts.length - 1).join(' ');
      } else {
        value = _c.focusTags[index];
      }
    }
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emojis[index], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── MEAL CARD ────────────────────────────────────────────────────────────────

  static const _mealIcons = <String, IconData>{
    'breakfast': Icons.wb_sunny_rounded,
    'mid_morning': Icons.emoji_food_beverage_rounded,
    'lunch': Icons.ramen_dining_rounded,
    'snack': Icons.auto_awesome_rounded,
    'dinner': Icons.room_service_rounded,
  };

  Widget _buildMealCard(MealSlot meal) {
    final icon = _mealIcons[meal.type] ?? Icons.restaurant_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _purpleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _purple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meal.desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[500],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              meal.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: _purpleBg,
                child: Icon(icon, color: _purple, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${meal.kcal}',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                  TextSpan(
                    text: ' kcal',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _pink,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                meal.time,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY CARD ─────────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _summaryCell(
                emoji: '💧',
                title: 'Water Intake',
                value:
                    '${_c.waterCurrent.value.toStringAsFixed(1)} L / ${_c.waterTarget.value.toStringAsFixed(0)} L',
                sub: 'Stay Hydrated',
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: Colors.grey[200]),
            Expanded(
              child: _summaryCell(
                emoji: '🔥',
                title: 'Calories Target',
                value: '${_c.caloriesTarget.value} kcal',
                sub: 'Daily Target',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCell({
    required String emoji,
    required String title,
    required String value,
    required String sub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _pink,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────────

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
    const dietIndex = 2;

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
              final selected = i == dietIndex;
              final color = selected ? _pink : Colors.grey[500]!;
              return GestureDetector(
                onTap: () {
                  if (i == dietIndex) return;
                  switch (i) {
                    case 0:
                      Get.offAllNamed(Routes.home);
                      break;
                    case 1:
                      Get.offAllNamed(Routes.workoutLibrary);
                      break;
                    case 3:
                      Get.offAllNamed(Routes.progress);
                      break;
                  }
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
