import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../routes/app_pages.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class _GoalItem {
  final String emoji;
  final Color bg;
  final String title;
  final String subtitle;
  const _GoalItem(
      {required this.emoji,
      required this.bg,
      required this.title,
      required this.subtitle});
}

const _goals = [
  _GoalItem(
      emoji: '🧖‍♀️',
      bg: Color(0xFFFCE4EC),
      title: 'Skin Care',
      subtitle: 'Healthy Skin'),
  _GoalItem(
      emoji: '💇‍♀️',
      bg: Color(0xFFFFF3D6),
      title: 'Hair Care',
      subtitle: 'Strong & Shiny'),
  _GoalItem(
      emoji: '⚖️',
      bg: Color(0xFFEAE3FA),
      title: 'Weight Loss',
      subtitle: 'Fit Lifestyle'),
  _GoalItem(
      emoji: '🥤',
      bg: Color(0xFFDCEEF3),
      title: 'Detox',
      subtitle: 'Clean & Light'),
  _GoalItem(
      emoji: '🏋️‍♀️',
      bg: Color(0xFFE3E9FB),
      title: 'Fitness',
      subtitle: 'Body & Mind'),
];

class _ReadItem {
  final String image;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final String title;
  final String minutes;
  const _ReadItem(
      {required this.image,
      required this.tag,
      required this.tagColor,
      required this.tagBg,
      required this.title,
      required this.minutes});
}

const _reads = [
  _ReadItem(
    image: 'assets/images/glow_read_serum.png',
    tag: 'SKINCARE',
    tagColor: Color(0xFFC4185A),
    tagBg: Color(0xFFFCE4EC),
    title: 'How to Choose Right Serum',
    minutes: '4 min read',
  ),
  _ReadItem(
    image: 'assets/images/glow_read_foods.png',
    tag: 'NUTRITION',
    tagColor: Color(0xFF1E8A3C),
    tagBg: Color(0xFFE1F3E5),
    title: 'Best Foods for Clear Skin',
    minutes: '5 min read',
  ),
  _ReadItem(
    image: 'assets/images/glow_read_routine.png',
    tag: 'ROUTINE',
    tagColor: Color(0xFF6C3EBE),
    tagBg: Color(0xFFEAE3FA),
    title: 'Night Skincare Routine',
    minutes: '7 min read',
  ),
];

class _ShortItem {
  final String image;
  final String duration;
  final String title;
  final String views;
  const _ShortItem(
      {required this.image,
      required this.duration,
      required this.title,
      required this.views});
}

const _shortBig = _ShortItem(
  image: 'assets/images/glow_short_detox.png',
  duration: '0:45',
  title: 'Morning Detox for Energy Boost',
  views: '10.2k views',
);
const _shortsSmall = [
  _ShortItem(
    image: 'assets/images/glow_short_massage.png',
    duration: '0:28',
    title: '3 Face Massage Tips for Glowing Skin',
    views: '10.2k views',
  ),
  _ShortItem(
    image: 'assets/images/glow_short_salad.png',
    duration: '0:31',
    title: 'Healthy Salad Tips for Clear Skin',
    views: '9.6k views',
  ),
];

class GlowScreen extends StatefulWidget {
  const GlowScreen({super.key});

  @override
  State<GlowScreen> createState() => _GlowScreenState();
}

class _GlowScreenState extends State<GlowScreen> {
  HomeController get _c => Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 18),
              _buildHeroCard(),
              const SizedBox(height: 26),
              _buildSectionHeader('Explore by Goals'),
              const SizedBox(height: 14),
              _buildGoalsRow(),
              const SizedBox(height: 26),
              _buildSectionHeader('Glow Reads'),
              const SizedBox(height: 12),
              _buildReadsRow(),
              const SizedBox(height: 26),
              _buildSectionHeader('Shorts & Quick Tips'),
              const SizedBox(height: 12),
              _buildShortsRow(),
              const SizedBox(height: 22),
              _buildPremiumBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Obx(() => Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFFFD6E7),
                  child: ClipOval(
                    child: _c.photoUrl.value.isNotEmpty
                        ? Image.network(
                            _c.photoUrl.value,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person, size: 26, color: _pink),
                          )
                        : Image.asset(
                            'assets/images/profile_avatar.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person, size: 26, color: _pink),
                          ),
                  ),
                ),
                Positioned(
                  top: -6,
                  left: -6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning,',
                    style: GoogleFonts.dancingScript(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _pink,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    _c.userName.value.isEmpty ? 'Glow' : _c.userName.value,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                      height: 1.1,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Let's begin your glow journey ",
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: Colors.grey[500]),
                      ),
                      const Text('💫', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications is coming soon.')),
              ),
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
        ));
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.poppins(fontSize: 13.5, color: _darkText),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'Search skincare, haircare, tips, routines ...',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5, color: Colors.grey[400]),
                    ),
                  ),
                ),
                Icon(Icons.mic_none_rounded, color: _pink, size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
          child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
        ),
      ],
    );
  }

  // ─── HERO CARD ────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/glow_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _heroFallbackBg(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      "Today's Pick ✨",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _pink,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 220,
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'GLASS SKIN\n',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: _darkText,
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: 'in ',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: _darkText,
                              ),
                            ),
                            TextSpan(
                              text: '7 Days',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: _pink,
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 210,
                        child: Text(
                          'Simple steps for natural glowing skin at home.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Glass Skin guide is coming soon.')),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 17),
                            ],
                          ),
                        ),
                      ),
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

  Widget _heroFallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0EC), Color(0xFFFFC1DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.face_retouching_natural_rounded,
            size: 70, color: _pink.withValues(alpha: 0.4)),
      ),
    );
  }

  // ─── SECTION HEADER ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _darkText,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _pink,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _pink),
          ],
        ),
      ],
    );
  }

  // ─── EXPLORE BY GOALS ─────────────────────────────────────────────────────

  Widget _buildGoalsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (final g in _goals) _goalItem(g)],
    );
  }

  Widget _goalItem(_GoalItem g) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${g.title} is coming soon.')),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: g.bg, shape: BoxShape.circle),
            child: Center(
              child: Text(g.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            g.title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          Text(
            g.subtitle,
            style: GoogleFonts.poppins(fontSize: 8.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── GLOW READS ───────────────────────────────────────────────────────────

  Widget _buildReadsRow() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _reads.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _readCard(_reads[i]),
      ),
    );
  }

  Widget _readCard(_ReadItem r) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${r.title} is coming soon.')),
      ),
      child: Container(
        width: 150,
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    r.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [r.tagBg, r.tagColor.withValues(alpha: 0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(Icons.image_rounded,
                          color: r.tagColor.withValues(alpha: 0.5), size: 28),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.tagBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        r.tag,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: r.tagColor,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.bookmark_border_rounded,
                          size: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          r.minutes,
                          style: GoogleFonts.poppins(
                              fontSize: 9.5, color: Colors.grey[500]),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration:
                            const BoxDecoration(color: _pink, shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_right_rounded,
                            size: 13, color: Colors.white),
                      ),
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

  // ─── SHORTS & QUICK TIPS ──────────────────────────────────────────────────

  Widget _buildShortsRow() {
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _shortTile(_shortBig, big: true)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _shortTile(_shortsSmall[0])),
                const SizedBox(height: 10),
                Expanded(child: _shortTile(_shortsSmall[1])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortTile(_ShortItem s, {bool big = false}) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.title} is coming soon.')),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              s.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3A2E3D), Color(0xFF1A1A2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white38, size: 32),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.duration,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Align(
              alignment: big ? Alignment.center : const Alignment(0, -0.35),
              child: Container(
                width: big ? 44 : 28,
                height: big ? 44 : 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: _pink, size: big ? 26 : 15),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    maxLines: big ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: big ? 14 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_red_eye_outlined,
                          size: 10, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 3),
                      Text(
                        s.views,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
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

  // ─── GLOW PREMIUM BANNER ──────────────────────────────────────────────────

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Glow Premium is coming soon.')),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 176,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/glow_premium_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E7), Color(0xFFFFC1DA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Glow Premium',
                      style: GoogleFonts.dancingScript(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 190,
                      child: Text(
                        'Unlock exclusive content, personalized plans & more.',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _pink,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _pink.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Upgrade Now',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    const glowIndex = 4;

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
              final selected = i == glowIndex;
              final color = selected ? _pink : Colors.grey[500]!;
              return GestureDetector(
                onTap: () {
                  if (i == glowIndex) return;
                  switch (i) {
                    case 0:
                      Get.offAllNamed(Routes.home);
                      break;
                    case 1:
                      Get.offAllNamed(Routes.workoutLibrary);
                      break;
                    case 2:
                      Get.offAllNamed(Routes.diet);
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
