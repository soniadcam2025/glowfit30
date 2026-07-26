import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
const _goals = ['Loss weight', 'Lift & tone', 'Lose belly fat', 'Build muscles'];
const _focusAreaOptions = ['Firm abs', 'Toned legs', 'Bubble butt', 'Slim arms', 'Full body'];

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;

  String _fitnessLevel = _fitnessLevels.first;
  String _goal = _goals.first;
  final Set<String> _focusAreas = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await Get.find<ApiService>().getProfile();
    if (!mounted) return;
    setState(() {
      final fl = profile?['fitnessLevel'] as String?;
      if (fl != null && _fitnessLevels.contains(fl)) _fitnessLevel = fl;
      final g = profile?['goal'] as String?;
      if (g != null && _goals.contains(g)) _goal = g;
      final areas = (profile?['focusAreas'] as List?)?.cast<String>() ?? [];
      _focusAreas
        ..clear()
        ..addAll(areas.where(_focusAreaOptions.contains));
      _loading = false;
    });
  }

  void _toggleFocusArea(String area) {
    setState(() {
      if (_focusAreas.contains(area)) {
        _focusAreas.remove(area);
      } else if (_focusAreas.length < 3) {
        _focusAreas.add(area);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose up to 3 focus areas.')),
        );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await Get.find<ApiService>().patchProfile({
      'fitnessLevel': _fitnessLevel,
      'goal': _goal,
      'focusAreas': _focusAreas.toList(),
    });
    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout preferences updated.')),
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
                          _label('Fitness Level'),
                          _pillSelector(_fitnessLevels, _fitnessLevel,
                              (v) => setState(() => _fitnessLevel = v)),
                          const SizedBox(height: 22),
                          _label('Main Goal'),
                          _pillSelector(
                              _goals, _goal, (v) => setState(() => _goal = v)),
                          const SizedBox(height: 22),
                          _label('Focus Areas (up to 3)'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _focusAreaOptions.map((a) {
                              final selected = _focusAreas.contains(a);
                              return GestureDetector(
                                onTap: () => _toggleFocusArea(a),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _pink
                                        : const Color(0xFFF7F0F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    a,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
            'Workout Preferences',
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

  Widget _pillSelector(
      List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _pink : const Color(0xFFF7F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
