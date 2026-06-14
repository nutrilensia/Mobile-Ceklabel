import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_profile.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;
  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _calorieCtrl;
  late bool _hasDiabetes;
  late bool _hasHypertension;
  late bool _hasHighCholesterol;
  late bool _isVegetarian;
  late List<String> _allergies;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final hp = widget.user.healthProfile ?? const HealthProfile();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _calorieCtrl = TextEditingController(text: hp.dailyCalorieTarget.toString());
    _hasDiabetes = hp.hasDiabetes;
    _hasHypertension = hp.hasHypertension;
    _hasHighCholesterol = hp.hasHighCholesterol;
    _isVegetarian = hp.isVegetarian;
    _allergies = List.from(hp.allergies);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email tidak boleh kosong'),
            backgroundColor: Color(0xFFFF6B6B)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final hp = HealthProfile(
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        hasHighCholesterol: _hasHighCholesterol,
        isVegetarian: _isVegetarian,
        allergies: _allergies,
        dailyCalorieTarget: int.tryParse(_calorieCtrl.text) ?? 2000,
      );
      await ApiService().updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        healthProfile: hp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil disimpan',
                style: GoogleFonts.inter(color: Colors.black)),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFFF6B6B)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: Text('Edit Profil',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Color(0xFF4ECDC4), strokeWidth: 2))
                : Text('Simpan',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4ECDC4), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Informasi Akun', [
              _buildTextField(_nameCtrl, 'Nama', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildTextField(_emailCtrl, 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 24),
            _buildSection('Target Kalori Harian', [
              _buildTextField(_calorieCtrl, 'Kalori (kkal)',
                  Icons.local_fire_department_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 6),
              Text('Pria dewasa ~2500 kkal • Wanita dewasa ~2000 kkal',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white30)),
            ]),
            const SizedBox(height: 24),
            _buildSection('Kondisi Kesehatan', [
              _buildToggle('Diabetes', 'Pantau kadar gula lebih ketat',
                  Icons.monitor_heart_outlined, _hasDiabetes,
                  (v) => setState(() => _hasDiabetes = v)),
              const Divider(color: Colors.white10, height: 20),
              _buildToggle('Hipertensi', 'Batasi asupan sodium',
                  Icons.favorite_border_rounded, _hasHypertension,
                  (v) => setState(() => _hasHypertension = v)),
              const Divider(color: Colors.white10, height: 20),
              _buildToggle('Kolesterol Tinggi', 'Pantau lemak jenuh & trans',
                  Icons.bloodtype_outlined, _hasHighCholesterol,
                  (v) => setState(() => _hasHighCholesterol = v)),
              const Divider(color: Colors.white10, height: 20),
              _buildToggle('Vegetarian', 'Tandai produk berbahan hewani',
                  Icons.eco_outlined, _isVegetarian,
                  (v) => setState(() => _isVegetarian = v)),
            ]),
            const SizedBox(height: 24),
            _buildSection('Alergi Makanan', [
              Wrap(
                spacing: 8, runSpacing: 8,
                children: kAllergyOptions.map((a) {
                  final selected = _allergies.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) _allergies.add(a);
                      else _allergies.remove(a);
                    }),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFFFF6B6B),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: selected ? const Color(0xFFFF6B6B) : Colors.white54,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, IconData icon, bool value,
      void Function(bool) onChanged) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18,
              color: value ? const Color(0xFF4ECDC4) : Colors.white38),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: value ? Colors.white : Colors.white70,
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  )),
              Text(subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4ECDC4),
          activeTrackColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }
}
