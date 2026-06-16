import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/family_profile.dart';
import '../models/health_profile.dart';
import '../services/api_service.dart';

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
        backgroundColor: const Color(0xFF1A1A2E),
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
  String _relation = 'anak';
  String _ageGroup = 'child';
  final List<String> _allergies = [];
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _relation = widget.existing!.relation;
      _ageGroup = widget.existing!.ageGroup;
      _allergies.addAll(widget.existing!.allergyList);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final conditions = <String, dynamic>{'allergies': _allergies};
      if (widget.existing == null) {
        await ApiService().addFamilyProfile(
          name: _nameCtrl.text.trim(),
          relation: _relation,
          ageGroup: _ageGroup,
          conditions: conditions,
        );
      } else {
        await ApiService().updateFamilyProfile(widget.existing!.id, {
          'name': _nameCtrl.text.trim(),
          'relation': _relation,
          'ageGroup': _ageGroup,
          'conditions': conditions,
        });
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textQuaternary(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
                    color: selected ? const Color(0xFFFFAD00) : Colors.white54,
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
