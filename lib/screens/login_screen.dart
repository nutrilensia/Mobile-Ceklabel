import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isRegister => _tabController.index == 1;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isRegister) {
        await ApiService().register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      } else {
        await ApiService().login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B59B6).withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary(context), size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.eco_rounded, color: Color(0xFF4ECDC4), size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CekLabel',
                        style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      tabs: const [Tab(text: 'Masuk'), Tab(text: 'Daftar')],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isRegister) ...[
                          _buildField(
                            ctrl: _nameCtrl,
                            label: 'Nama',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          ctrl: _passwordCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textTertiary(context), size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                            if (_isRegister) {
                              if (v.length < 8) return 'Password minimal 8 karakter';
                              if (!v.contains(RegExp(r'[A-Z]'))) return 'Password harus ada huruf kapital';
                              if (!v.contains(RegExp(r'[0-9]'))) return 'Password harus ada angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFFF6B6B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13, color: const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ECDC4),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isRegister ? 'Buat Akun' : 'Masuk',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        if (_isRegister) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Password: min. 8 karakter, ada huruf kapital & angka',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.inter(color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textTertiary(context), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.cardBorder(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inputBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inputBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(color: const Color(0xFFFF6B6B), fontSize: 12),
      ),
      validator: validator,
    );
  }
}
