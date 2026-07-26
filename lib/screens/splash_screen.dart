import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _seq;
  late final AnimationController _ambient;

  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSettle;
  late final Animation<double> _wordReveal;
  late final Animation<double> _shimmer;
  late final Animation<double> _taglineFade;

  static const _leaf = Color(0xFF3DAA52);
  static const _ink = Color(0xFF2B2D42);

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _seq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    Animation<double> seg(double a, double b, Curve c) => CurvedAnimation(
          parent: _seq,
          curve: Interval(a, b, curve: c),
        );

    _bgFade      = seg(0.00, 0.20, Curves.easeOut);
    _logoFade    = seg(0.05, 0.40, Curves.easeOut);
    _logoScale   = seg(0.05, 0.50, Curves.elasticOut);
    _logoSettle  = seg(0.55, 0.74, Curves.easeOutBack);
    _wordReveal  = seg(0.62, 0.86, Curves.easeOutCubic);
    _shimmer     = seg(0.78, 1.00, Curves.easeInOut);
    _taglineFade = seg(0.84, 1.00, Curves.easeOut);

    _seq.forward();
    _seq.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, a, b) => widget.next,
        transitionsBuilder: (_, anim, c, child) {
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween(begin: 1.04, end: 1.0).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _seq.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : _ink;
    final bgTop = isDark ? const Color(0xFF0B130E) : const Color(0xFFF5F8F5);
    final bgBottom = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFE6F0E8);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_seq, _ambient]),
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(bgBottom, bgTop, _bgFade.value)!,
                  Color.lerp(bgTop, bgBottom, _bgFade.value)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: _bgFade.value * (isDark ? 0.5 : 0.7),
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        t: _ambient.value,
                        color: _leaf,
                        dark: isDark,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, (1 - _logoSettle.value) * -10),
                        child: _buildLogo(isDark),
                      ),
                      const SizedBox(height: 34),
                      _buildWordmark(ink),
                      const SizedBox(height: 14),
                      _buildTagline(ink),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    final pulse = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
    final rawScale = 0.7 + 0.3 * _logoScale.value;
    final scale = rawScale.clamp(0.0, 1.3);
    return Opacity(
      opacity: _logoFade.value.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _leaf.withValues(
                          alpha: (0.18 + 0.12 * pulse) *
                              _logoFade.value.clamp(0, 1)),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark(Color ink) {
    final v = _wordReveal.value;
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, (1 - v) * 18),
        child: ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final p = _shimmer.value;
            final cx = -0.4 + p * 1.8;
            return LinearGradient(
              begin: Alignment(cx - 0.35, 0),
              end: Alignment(cx + 0.35, 0),
              colors: [ink, _leaf, ink],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.quicksand(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: ink,
              ),
              children: const [
                TextSpan(text: 'nutri'),
                TextSpan(
                  text: 'Lensia',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(Color ink) {
    return Opacity(
      opacity: _taglineFade.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _taglineFade.value) * 10),
        child: Text(
          'Pindai · Pahami · Pilih Sehat',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: ink.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Color color;
  final bool dark;
  _ParticlePainter({required this.t, required this.color, required this.dark});

  static const _seeds = [
    [0.12, 0.30, 0.9], [0.82, 0.22, 1.3], [0.50, 0.15, 0.7],
    [0.25, 0.70, 1.1], [0.70, 0.62, 0.8], [0.90, 0.48, 1.0],
    [0.08, 0.55, 1.2], [0.40, 0.85, 0.9], [0.62, 0.92, 1.4],
    [0.33, 0.45, 0.6], [0.78, 0.80, 1.0], [0.18, 0.88, 0.8],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: dark ? 0.22 : 0.16);
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final phase = (t + i / _seeds.length) % 1.0;
      final dx = s[0] * size.width +
          math.sin((phase + s[2]) * 2 * math.pi) * 14;
      final baseY = s[1] * size.height;
      final dy = baseY - phase * size.height * 0.25;
      final radius = (2.0 + s[2] * 2.2) *
          (0.6 + 0.4 * math.sin(phase * math.pi));
      final fade = math.sin(phase * math.pi);
      paint.color = color.withValues(
          alpha: (dark ? 0.22 : 0.16) * fade.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
