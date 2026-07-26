import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_pages.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'app_settings_screen.dart';
import 'diet_preferences_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'workout_preferences_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);
const _purple = Color(0xFF8B5CF6);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;

  String _name = '';
  String? _photoUrl;

  int _streak = 0;
  int _totalWorkouts = 0;
  int _totalCalories = 0;
  int _totalMinutes = 0;

  double? _weight;
  double? _targetWeight;
  int _workoutsThisWeek = 0;

  static const _weeklyGoalTarget = 4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([api.getProfile(), api.getProgress()]);
    final profile = results[0] as Map<String, dynamic>?;
    final progress = results[1] as Map<String, dynamic>?;
    if (!mounted) return;

    final stats = progress?['stats'] as Map<String, dynamic>?;
    final completions = (progress?['completions'] as List?) ?? [];

    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final daysThisWeek = <String>{};
    for (final c in completions) {
      final at = DateTime.tryParse(
              (c as Map<String, dynamic>)['completedAt'] as String? ?? '')
          ?.toLocal();
      if (at == null) continue;
      final day = DateTime(at.year, at.month, at.day);
      if (!day.isBefore(mondayDate)) {
        daysThisWeek.add('${day.year}-${day.month}-${day.day}');
      }
    }

    setState(() {
      _name = (profile?['name'] as String?) ?? '';
      _photoUrl = profile?['photoUrl'] as String?;
      _weight = (profile?['weight'] as num?)?.toDouble();
      _targetWeight = (profile?['targetWeight'] as num?)?.toDouble();
      _streak = (stats?['streak'] as num?)?.toInt() ?? 0;
      _totalWorkouts = (stats?['totalSessions'] as num?)?.toInt() ?? 0;
      _totalCalories = (stats?['totalCalories'] as num?)?.toInt() ?? 0;
      _totalMinutes = (stats?['totalMinutes'] as num?)?.toInt() ?? 0;
      _workoutsThisWeek = daysThisWeek.length;
      _loading = false;
    });
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    _load();
  }

  Future<void> _logout() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(Routes.welcome);
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildProfileCard(),
                    const SizedBox(height: 18),
                    _buildGoalsSection(),
                    const SizedBox(height: 20),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    _buildLogoutSection(),
                  ],
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
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 10, top: 2),
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
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _darkText),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Profile & ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  TextSpan(
                    text: 'Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your profile, goals & preferences ✨',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _comingSoon('Notifications'),
          child: Container(
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
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.notifications_none_rounded,
                      size: 20, color: _pink),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _pink, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── PROFILE CARD ─────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9F2), Color(0xFFFDF7F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                          BorderSide(color: _pink, width: 1.6)),
                    ),
                    child: ClipOval(
                      child: (_photoUrl == null || _photoUrl!.isEmpty)
                          ? Container(
                              color: const Color(0xFFFFD6E7),
                              child: const Icon(Icons.person_rounded,
                                  size: 40, color: _pink),
                            )
                          : Image.network(
                              _photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFFFD6E7),
                                child: const Icon(Icons.person_rounded,
                                    size: 40, color: _pink),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _comingSoon('Profile photo upload'),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 13, color: _darkText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.isEmpty ? 'Your Name' : _name,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            'Premium',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB8860B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stronger every day, glowing always ✨',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _statItem('🔥', '$_streak', 'Streak Days')),
              Expanded(
                  child: _statItem('💪', '$_totalWorkouts', 'Workouts')),
              Expanded(
                  child: _statItem('🔥', '$_totalCalories', 'Calories Burned')),
              Expanded(
                  child: _statItem('⏱', '$_totalMinutes', 'Minute')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ─── MY GOALS ─────────────────────────────────────────────────────────────

  Widget _buildGoalsSection() {
    final hasWeightData = _weight != null && _targetWeight != null;
    final current = _weight ?? 64.0;
    final target = _targetWeight ?? 55.0;
    final starting = hasWeightData
        ? current + math.max(6.0, (current - target) * 0.5)
        : 70.0;
    final weightPct = hasWeightData && starting != target
        ? (((starting - current) / (starting - target)) * 100)
            .clamp(0, 100)
            .toDouble()
        : 0.0;
    final workoutPct =
        ((_workoutsThisWeek / _weeklyGoalTarget) * 100).clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('My Goals')),
            Text(
              'View All Goals',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _goalCard(
                bg: const Color(0xFFFCEAF2),
                icon: Icons.monitor_weight_rounded,
                iconBg: Colors.white,
                iconColor: _pink,
                title: 'Weight Goal',
                leftLabel: 'Current',
                leftValue: '${current.toStringAsFixed(0)} kg',
                rightLabel: 'Goal',
                rightValue: '${target.toStringAsFixed(0)} kg',
                progress: weightPct / 100,
                progressColor: _pink,
                footer: hasWeightData
                    ? '${weightPct.toStringAsFixed(0)}% Completed'
                    : 'Add weight & goal in Edit Profile',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _goalCard(
                bg: const Color(0xFFF1EAFB),
                icon: Icons.fitness_center_rounded,
                iconBg: Colors.white,
                iconColor: _purple,
                title: 'Workout Goal',
                leftLabel: 'Target',
                leftValue: '$_weeklyGoalTarget days / week',
                rightLabel: 'Progress',
                rightValue: '${workoutPct.toStringAsFixed(0)}%',
                progress: workoutPct / 100,
                progressColor: _purple,
                footer: 'Keep it up! You\'re doing great!',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _goalCard({
    required Color bg,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    required double progress,
    required Color progressColor,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leftLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 9.5, color: Colors.grey[500])),
                    Text(
                      leftValue,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rightLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: Colors.grey[500])),
                  Text(
                    rightValue,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── SETTINGS LIST ────────────────────────────────────────────────────────

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Settings'),
        const SizedBox(height: 10),
        _settingsRow(
          icon: Icons.person_outline_rounded,
          title: 'Account & Profile',
          subtitle: 'Personal info, body measurements',
          onTap: _openEditProfile,
        ),
        _settingsRow(
          icon: Icons.fitness_center_rounded,
          title: 'Workout Preferences',
          subtitle: 'Fitness level, main goal & focus areas',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutPreferencesScreen()),
          ),
        ),
        _settingsRow(
          icon: Icons.restaurant_menu_rounded,
          title: 'Diet Preferences',
          subtitle: 'Diet type & daily water goal',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DietPreferencesScreen()),
          ),
        ),
        _settingsRow(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Manage push notifications',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _settingsRow(
          icon: Icons.settings_outlined,
          title: 'App Settings',
          subtitle: 'Language, privacy, appearance & more',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
          ),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: _pink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _darkText,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
          if (showDivider) Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────

  Widget _buildLogoutSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _logout,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, size: 22, color: _pink),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Are you sure you want to logout from your account?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4E8D), _pink],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _darkText,
      ),
    );
  }

}
