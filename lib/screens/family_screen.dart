import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/family_profile.dart';
import '../models/health_profile.dart';
import '../services/api_service.dart';
import '../widgets/handle_bar.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late Future<List<FamilyProfile>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final f = ApiService().getFamilyProfiles(forceRefresh: true);
    setState(() { _future = f; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text(
          'Anggota Keluarga',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(null),
          ),
        ],
      ),
      body: FutureBuilder<List<FamilyProfile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
          }
          if (snap.hasError) {
            return _buildError(snap.error.toString());
          }
          final profiles = snap.data!;
          if (profiles.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: profiles.length,
            itemBuilder: (_, i) => _buildProfileCard(profiles[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildProfileCard(FamilyProfile p) {
    final allergies = p.allergyList;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: const Color(0xFF4ECDC4),
            ),
          ),
        ),
        title: Text(
          p.name,
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.relationLabel} • ${p.ageGroupLabel}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            // kondisi kesehatan aktif
            Builder(builder: (context) {
              final chips = <String>[];
              if (p.conditions['hasDiabetes'] == true) chips.add('Diabetes');
              if (p.conditions['hasHypertension'] == true) chips.add('Hipertensi');
              if (p.conditions['hasHighCholesterol'] == true) chips.add('Kolesterol');
              if (p.conditions['isVegetarian'] == true) chips.add('Vegetarian');
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Wrap(
                  spacing: 5, runSpacing: 4,
                  children: chips.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.25)),
                    ),
                    child: Text(c,
                        style: GoogleFonts.inter(
                            fontSize: 10, color: const Color(0xFF4ECDC4),
                            fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              );
            }),
            // batas kalori custom
            if (p.effectiveDailyLimits?['calories'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '🔥 Target: ${p.effectiveDailyLimits!['calories']} kkal/hari',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
              ),
            ],
            if (allergies.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Alergi: ${allergies.join(', ')}',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFFFAD00)),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surface(context),
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textTertiary(context)),
          onSelected: (val) {
            if (val == 'edit') _showAddEditDialog(p);
            if (val == 'delete') _confirmDelete(p);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Text('Edit', style: GoogleFonts.inter(color: AppColors.textBody(context))),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus',
                  style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(FamilyProfile? existing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyFormSheet(existing: existing),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _confirmDelete(FamilyProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBg(context),
        title: Text('Hapus ${p.name}?',
            style: GoogleFonts.poppins(color: AppColors.textPrimary(context))),
        content: Text(
          'Data anggota keluarga ini akan dihapus.',
          style: GoogleFonts.inter(color: AppColors.textBody(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService().deleteFamilyProfile(p.id);
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFFF6B6B)),
          );
        }
      }
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.family_restroom_rounded,
                  size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada anggota keluarga',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan profil keluarga untuk\nmendapat rekomendasi yang lebih personal',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary(context), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4), foregroundColor: Colors.black,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyFormSheet extends StatefulWidget {
  final FamilyProfile? existing;

  const _FamilyFormSheet({this.existing});

  @override
  State<_FamilyFormSheet> createState() => _FamilyFormSheetState();
}

class _FamilyFormSheetState extends State<_FamilyFormSheet> {
  final _nameCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();
  String _relation = 'anak';
  String _ageGroup = 'child';
  final List<String> _allergies = [];
  bool _hasDiabetes = false;
  bool _hasHypertension = false;
  bool _hasHighCholesterol = false;
  bool _isVegetarian = false;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _relation = e.relation;
      _ageGroup = e.ageGroup;
      _allergies.addAll(e.allergyList);
      final c = e.conditions;
      _hasDiabetes = c['hasDiabetes'] == true;
      _hasHypertension = c['hasHypertension'] == true;
      _hasHighCholesterol = c['hasHighCholesterol'] == true;
      _isVegetarian = c['isVegetarian'] == true;
      // tampilkan custom calorie jika ada
      final cal = e.effectiveDailyLimits?['calories'];
      if (cal != null) _calorieCtrl.text = cal.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final conditions = <String, dynamic>{
        'allergies': _allergies,
        if (_hasDiabetes) 'hasDiabetes': true,
        if (_hasHypertension) 'hasHypertension': true,
        if (_hasHighCholesterol) 'hasHighCholesterol': true,
        if (_isVegetarian) 'isVegetarian': true,
      };
      final cal = int.tryParse(_calorieCtrl.text.trim());
      final customLimits = cal != null && cal > 0 ? {'calories': cal} : null;

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'relation': _relation,
        'ageGroup': _ageGroup,
        'conditions': conditions,
        if (customLimits != null) 'customLimits': customLimits,
      };

      if (widget.existing == null) {
        await ApiService().addFamilyProfile(
          name: payload['name'] as String,
          relation: payload['relation'] as String,
          ageGroup: payload['ageGroup'] as String,
          conditions: conditions,
          customLimits: customLimits,
        );
      } else {
        await ApiService().updateFamilyProfile(widget.existing!.id, payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bottomSheet(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const HandleBar(),
            const SizedBox(height: 20),
            Text(
              widget.existing == null ? 'Tambah Anggota' : 'Edit Anggota',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameCtrl, 'Nama'),
            const SizedBox(height: 16),
            _buildDropdown('Hubungan', _relation, kRelationLabels, (v) {
              if (v != null) setState(() => _relation = v);
            }),
            const SizedBox(height: 16),
            _buildDropdown('Kelompok Usia', _ageGroup, kAgeGroupLabels, (v) {
              if (v != null) setState(() => _ageGroup = v);
            }),
            const SizedBox(height: 16),
            // ── Kondisi Kesehatan ───────────────────────────────────────────
            Text('Kondisi Kesehatan',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                children: [
                  _buildConditionTile('Diabetes', Icons.monitor_heart_outlined,
                      _hasDiabetes, (v) => setState(() => _hasDiabetes = v)),
                  Divider(height: 1, color: AppColors.divider(context)),
                  _buildConditionTile('Hipertensi', Icons.favorite_border_rounded,
                      _hasHypertension, (v) => setState(() => _hasHypertension = v)),
                  Divider(height: 1, color: AppColors.divider(context)),
                  _buildConditionTile('Kolesterol Tinggi', Icons.bloodtype_outlined,
                      _hasHighCholesterol, (v) => setState(() => _hasHighCholesterol = v)),
                  Divider(height: 1, color: AppColors.divider(context)),
                  _buildConditionTile('Vegetarian', Icons.eco_outlined,
                      _isVegetarian, (v) => setState(() => _isVegetarian = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Target Kalori Harian ────────────────────────────────────────
            Text('Target Kalori Harian (opsional)',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
            const SizedBox(height: 6),
            TextField(
              controller: _calorieCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppColors.textPrimary(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Kosongkan = gunakan AKG default',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textQuaternary(context)),
                prefixIcon: Icon(Icons.local_fire_department_outlined,
                    color: AppColors.textTertiary(context), size: 20),
                suffixText: 'kkal',
                suffixStyle: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 13),
                filled: true,
                fillColor: AppColors.cardBorder(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Alergi',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: kAllergyOptions.map((a) {
                final selected = _allergies.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) { _allergies.add(a); } else { _allergies.remove(a); }
                  }),
                  backgroundColor: AppColors.cardBg(context),
                  selectedColor: const Color(0xFFFFAD00).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFFFFAD00),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: selected ? const Color(0xFFFFAD00) : AppColors.textSecondary(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFFFAD00).withValues(alpha: 0.4)
                          : AppColors.cardBorder(context),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF6B6B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        'Simpan',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionTile(
      String label, IconData icon, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.12)
                  : AppColors.scaffold(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16,
                color: value ? const Color(0xFF4ECDC4) : AppColors.textTertiary(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: value ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                )),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4ECDC4),
            activeTrackColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.switchInactiveThumb(context),
            inactiveTrackColor: AppColors.switchInactiveTrack(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: AppColors.textPrimary(context), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBorder(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBorder(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.dropdownBg(context),
              style: GoogleFonts.inter(color: AppColors.textPrimary(context), fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary(context)),
              onChanged: onChanged,
              items: options.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
