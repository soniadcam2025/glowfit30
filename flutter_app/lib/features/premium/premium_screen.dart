import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);
const _purple = Color(0xFF8B5CF6);
const _green = Color(0xFF22C55E);
const _orange = Color(0xFFFF9800);

class _Plan {
  final String title;
  final String subtitle;
  final String price;
  final String? strikePrice;
  final String perMonth;
  final String? discountLabel;
  final String? saveLabel;
  final IconData icon;
  final Color iconColor;

  const _Plan({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.perMonth,
    required this.icon,
    required this.iconColor,
    this.strikePrice,
    this.discountLabel,
    this.saveLabel,
  });
}

const _plans = [
  _Plan(
    title: '1 Year Plan',
    subtitle: 'Best value',
    price: '₹499',
    strikePrice: '₹1,199',
    perMonth: '₹41.6 / month',
    discountLabel: '60% OFF',
    saveLabel: 'Save 60%',
    icon: Icons.card_giftcard_rounded,
    iconColor: _pink,
  ),
  _Plan(
    title: '6 Months Plan',
    subtitle: 'Great choice',
    price: '₹469',
    strikePrice: '₹699',
    perMonth: '₹78.1 / month',
    discountLabel: '33% OFF',
    saveLabel: 'Save 33%',
    icon: Icons.eco_rounded,
    iconColor: _green,
  ),
  _Plan(
    title: '1 Month Plan',
    subtitle: 'Try it now',
    price: '₹199',
    perMonth: '₹199 / month',
    icon: Icons.eco_rounded,
    iconColor: _green,
  ),
];

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selected = 0;

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 28),
                    _buildWhyGoPremium(),
                    const SizedBox(height: 24),
                    ..._plans.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPlanCard(e.key, e.value),
                          ),
                        ),
                    const SizedBox(height: 8),
                    _buildGuaranteeRow(),
                  ],
                ),
              ),
            ),
            _buildBottomCta(),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text(
                'Premium',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Unlock everything for the best results',
                style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[500]),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 38,
                height: 38,
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
                    size: 15, color: _darkText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    const checklist = [
      'Watch all premium videos',
      'Unlock all solutions',
      'Personalized routine plan',
      'Ad-free experience',
      'Priority customer support',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEAF3), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Premium',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _pink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get Unlimited access & faster results',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                ...checklist.map(_checklistItem),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(flex: 5, child: _buildHeroImage()),
        ],
      ),
    );
  }

  Widget _checklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: _green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _darkText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/glow_hero.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD6E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.spa_rounded, size: 40, color: _pink),
                ),
              ),
            ),
          ),
          Positioned(top: -6, left: -10, child: _floatingBadge(Icons.description_rounded, _purple)),
          Positioned(top: 4, right: -12, child: _tagBadge('🌿', 'Ayurvedic')),
          Positioned(right: -14, top: 56, child: _tagBadge('🧑‍⚕️', 'Expert\nGuide')),
          Positioned(
            bottom: -14,
            left: 0,
            right: 0,
            child: Center(child: _premiumBatchBadge()),
          ),
        ],
      ),
    );
  }

  Widget _floatingBadge(IconData icon, Color color) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }

  Widget _tagBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: _darkText, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _premiumBatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8B94B), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👑', style: TextStyle(fontSize: 16)),
          Text(
            'PREMIUM',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB8860B),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'BATCH',
            style: GoogleFonts.poppins(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB8860B),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── WHY GO PREMIUM ─────────────────────────────────────────────────────────

  Widget _buildWhyGoPremium() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Why Go Premium?',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _darkText),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _whyItem(
                bg: const Color(0xFFFCE4EC),
                iconColor: _pink,
                icon: Icons.play_circle_fill_rounded,
                title: 'All Premium\nVideos',
                subtitle: 'Watch all locked videos',
              ),
            ),
            Expanded(
              child: _whyItem(
                bg: const Color(0xFFE3F5E7),
                iconColor: _green,
                icon: Icons.eco_rounded,
                title: 'All Solutions\nUnlocked',
                subtitle: 'Access every natural remedy',
              ),
            ),
            Expanded(
              child: _whyItem(
                bg: const Color(0xFFEDE7FB),
                iconColor: _purple,
                icon: Icons.assignment_rounded,
                title: 'Personalized\nRoutine',
                subtitle: 'Get routines tailored for you',
              ),
            ),
            Expanded(
              child: _whyItem(
                bg: const Color(0xFFFFEBD6),
                iconColor: _orange,
                icon: Icons.block_rounded,
                title: 'Ad-free\nExperience',
                subtitle: 'Enjoy without interruptions',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _whyItem({
    required Color bg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                  child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _darkText, height: 1.2),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey[500], height: 1.2),
          ),
        ],
      ),
    );
  }

  // ─── PRICING CARDS ──────────────────────────────────────────────────────────

  Widget _buildPlanCard(int index, _Plan plan) {
    final isSelected = _selected == index;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF0F6) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? _pink : Colors.grey[200]!,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                _radio(isSelected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w800, color: _darkText),
                      ),
                      const SizedBox(height: 3),
                      if (plan.saveLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F5E7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plan.saveLabel!,
                            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: _green),
                          ),
                        )
                      else
                        Text(
                          plan.subtitle,
                          style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (plan.strikePrice != null) ...[
                          Text(
                            plan.strikePrice!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          plan.price,
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: _darkText),
                        ),
                      ],
                    ),
                    Text(
                      plan.perMonth,
                      style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (plan.discountLabel != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFFF4757), shape: BoxShape.circle),
                    child: Text(
                      plan.discountLabel!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                    ),
                  )
                else
                  Icon(plan.icon, size: 20, color: plan.iconColor),
              ],
            ),
          ),
          if (index == 0)
            Positioned(
              top: -8,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Most Popular',
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _pink : Colors.grey[300]!, width: 2),
        color: selected ? _pink : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.circle, size: 8, color: Colors.white)
          : null,
    );
  }

  // ─── GUARANTEE ──────────────────────────────────────────────────────────────

  Widget _buildGuaranteeRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('7-day money-back guarantee',
              style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[500])),
          const SizedBox(width: 12),
          Container(width: 1, height: 12, color: Colors.grey[300]),
          const SizedBox(width: 12),
          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('Cancel anytime',
              style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ─── BOTTOM CTA ─────────────────────────────────────────────────────────────

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _notImplemented('Checkout'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF4E8D), _pink]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(color: _pink.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Go Premium Now',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _notImplemented('Restore Purchase'),
            child: Text(
              'Restore Purchase',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: _pink),
            ),
          ),
        ],
      ),
    );
  }
}
