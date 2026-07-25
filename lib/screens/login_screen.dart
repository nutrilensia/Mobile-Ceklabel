import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/handle_bar.dart';


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

  Future<void> _showForgotPassword() async {
    final emailCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 0; // 0=email, 1=token+newpass
    String? resetToken;
    String? stepError;
    bool loading = false;
    bool obscureNewPass = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bottomSheet(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HandleBar(),
                  const SizedBox(height: 20),
                  Text(
                    step == 0 ? 'Lupa Kata Sandi' : 'Buat Password Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step == 0
                        ? 'Masukkan email akun kamu untuk mendapatkan kode reset.'
                        : 'Masukkan kode reset dan password baru kamu.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 20),
                  if (step == 0) ...[
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary(context)),
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textTertiary(context), size: 20),
                        filled: true,
                        fillColor: AppColors.cardBorder(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: tokenCtrl,
                      style: GoogleFonts.inter(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Kode Reset',
                        labelStyle: GoogleFonts.inter(color: AppColors.textTertiary(context)),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.textTertiary(context), size: 20),
                        hintText: resetToken ?? '',
                        hintStyle: GoogleFonts.inter(color: AppColors.textQuaternary(context), fontSize: 11),
                        filled: true,
                        fillColor: AppColors.cardBorder(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (_, setInner) => TextField(
                        controller: newPassCtrl,
                        obscureText: obscureNewPass,
                        style: GoogleFonts.inter(color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          labelStyle: GoogleFonts.inter(color: AppColors.textTertiary(context)),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textTertiary(context), size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setInner(() => obscureNewPass = !obscureNewPass),
                            child: Icon(obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textTertiary(context), size: 20),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBorder(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.5)),
                        ),
                      ),
                    ),
                  ],
                  if (stepError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(stepError!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF6B6B)))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        setSheetState(() { loading = true; stepError = null; });
                        try {
                          if (step == 0) {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setSheetState(() { stepError = 'Masukkan email yang valid'; loading = false; });
                              return;
                            }
                            final token = await ApiService().forgotPassword(email);
                            setSheetState(() { resetToken = token.isNotEmpty ? token : null; step = 1; loading = false; });
                          } else {
                            final token = tokenCtrl.text.trim().isEmpty ? (resetToken ?? '') : tokenCtrl.text.trim();
                            final pass = newPassCtrl.text;
                            if (token.isEmpty) { setSheetState(() { stepError = 'Masukkan kode reset'; loading = false; }); return; }
                            if (pass.length < 8) { setSheetState(() { stepError = 'Password minimal 8 karakter'; loading = false; }); return; }
                            if (!pass.contains(RegExp(r'[A-Z]'))) { setSheetState(() { stepError = 'Password harus ada huruf kapital'; loading = false; }); return; }
                            if (!pass.contains(RegExp(r'[0-9]'))) { setSheetState(() { stepError = 'Password harus ada angka'; loading = false; }); return; }
                            final messenger = ScaffoldMessenger.of(context);
                            await ApiService().resetPassword(token, pass);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              messenger.showSnackBar(SnackBar(
                                content: Text('Password berhasil direset! Silakan login.', style: GoogleFonts.inter()),
                                backgroundColor: const Color(0xFF4ECDC4),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ));
                            }
                          }
                        } on ApiException catch (e) {
                          setSheetState(() { stepError = e.message; loading = false; });
                        } catch (_) {
                          setSheetState(() { stepError = 'Terjadi kesalahan. Coba lagi.'; loading = false; });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                          : Text(step == 0 ? 'Kirim Kode Reset' : 'Reset Password',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    emailCtrl.dispose();
    tokenCtrl.dispose();
    newPassCtrl.dispose();
  }

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
                        child: const AppLogo(size: 26),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'NutriLens',
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
                      unselectedLabelColor: AppColors.textSecondary(context),
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
                        if (!_isRegister) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPassword,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'Lupa Kata Sandi?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF4ECDC4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
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
