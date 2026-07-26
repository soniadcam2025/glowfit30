import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../services/api_service.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _dietStyles = ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Balanced'];

class DietPreferencesScreen extends StatefulWidget {
  const DietPreferencesScreen({super.key});

  @override
  State<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends State<DietPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;

  String _dietStyle = _dietStyles.first;
  double _waterGoal = 3.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await Get.find<ApiService>().getProfile();
    if (!mounted) return;
    setState(() {
      final ds = profile?['dietStyle'] as String?;
      if (ds != null && _dietStyles.contains(ds)) _dietStyle = ds;
      _waterGoal = (profile?['waterGoalLiters'] as num?)?.toDouble() ?? 3.0;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await Get.find<ApiService>().patchProfile({
      'dietStyle': _dietStyle,
      'waterGoalLiters': _waterGoal,
    });
    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().waterGoalLiters(_waterGoal);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet preferences updated.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Diet Style'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dietStyles.map((o) {
                              final isSelected = o == _dietStyle;
                              return GestureDetector(
                                onTap: () => setState(() => _dietStyle = o),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _pink
                                        : const Color(0xFFF7F0F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    o,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 26),
                          _label('Daily Water Goal'),
                          Row(
                            children: [
                              _stepperButton(
                                icon: Icons.remove_rounded,
                                onTap: () => setState(() =>
                                    _waterGoal = (_waterGoal - 0.5).clamp(1.0, 6.0)),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${_waterGoal.toStringAsFixed(1)} L',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _darkText,
                                    ),
                                  ),
                                ),
                              ),
                              _stepperButton(
                                icon: Icons.add_rounded,
                                onTap: () => setState(() =>
                                    _waterGoal = (_waterGoal + 0.5).clamp(1.0, 6.0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Shown on your Home screen's water tracker goal.",
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _saving ? null : _save,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _pink,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _pink.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _saving ? 'Saving…' : 'Save Changes',
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _darkText),
          ),
          Text(
            'Diet Preferences',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: _darkText),
      ),
    );
  }
}
