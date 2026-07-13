import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
const _dietStyles = ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Balanced'];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  String _fitnessLevel = _fitnessLevels.first;
  String _dietStyle = _dietStyles.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await Get.find<ApiService>().getProfile();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = (profile?['name'] as String?) ?? '';
      final height = (profile?['height'] as num?)?.toDouble();
      final weight = (profile?['weight'] as num?)?.toDouble();
      final targetWeight = (profile?['targetWeight'] as num?)?.toDouble();
      _heightCtrl.text = height != null ? height.toStringAsFixed(0) : '';
      _weightCtrl.text = weight != null ? weight.toStringAsFixed(0) : '';
      _targetWeightCtrl.text =
          targetWeight != null ? targetWeight.toStringAsFixed(0) : '';
      final fl = profile?['fitnessLevel'] as String?;
      if (fl != null && _fitnessLevels.contains(fl)) _fitnessLevel = fl;
      final ds = profile?['dietStyle'] as String?;
      if (ds != null && _dietStyles.contains(ds)) _dietStyle = ds;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'fitnessLevel': _fitnessLevel,
      'dietStyle': _dietStyle,
    };
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final targetWeight = double.tryParse(_targetWeightCtrl.text.trim());
    if (height != null && height > 0) payload['height'] = height;
    if (weight != null && weight > 0) payload['weight'] = weight;
    if (targetWeight != null && targetWeight > 0) {
      payload['targetWeight'] = targetWeight;
    }

    final result = await Get.find<ApiService>().patchProfile(payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Try again.')),
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
                          _label('Name'),
                          _textField(_nameCtrl, hint: 'Your name'),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Height (cm)'),
                                    _textField(_heightCtrl,
                                        hint: '165', numeric: true),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Current Weight (kg)'),
                                    _textField(_weightCtrl,
                                        hint: '64', numeric: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _label('Target Weight (kg)'),
                          _textField(_targetWeightCtrl, hint: '55', numeric: true),
                          const SizedBox(height: 18),
                          _label('Fitness Level'),
                          _pillSelector(_fitnessLevels, _fitnessLevel,
                              (v) => setState(() => _fitnessLevel = v)),
                          const SizedBox(height: 18),
                          _label('Diet Style'),
                          _pillSelector(_dietStyles, _dietStyle,
                              (v) => setState(() => _dietStyle = v)),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _saving ? null : _save,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
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
            'Edit Profile',
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
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );

  Widget _textField(TextEditingController ctrl,
      {required String hint, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 14, color: _darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF7F0F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

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
