import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Splash screen NutriLens — logo apel + daun digambar secara beranimasi:
/// lingkaran apel menggambar dirinya sendiri (stroke sweep), daun tumbuh
/// dengan efek elastis, tulang daun ditarik, lalu wordmark "nutriLens" muncul
/// dengan kilau (shimmer). Latar punya partikel daun yang melayang lembut.
class SplashScreen extends StatefulWidget {
  /// Halaman tujuan setelah splash selesai.
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller utama menggerakkan seluruh sekuens lewat Interval.
  late final AnimationController _seq;
  // Controller ambient (loop) untuk partikel & glow.
  late final AnimationController _ambient;

  // ── fase animasi (interval pada _seq, durasi total 2800ms) ──────────────────
  late final Animation<double> _bgFade;       // 0.00–0.18  latar muncul
  late final Animation<double> _ringDraw;      // 0.08–0.42  lingkaran menggambar
  late final Animation<double> _leafGrow;      // 0.30–0.62  daun tumbuh (elastis)
  late final Animation<double> _veinDraw;      // 0.48–0.66  tulang daun
  late final Animation<double> _stemDraw;      // 0.40–0.56  tangkai
  late final Animation<double> _logoSettle;    // 0.55–0.72  logo turun sedikit
  late final Animation<double> _wordReveal;    // 0.62–0.86  wordmark slide+fade
  late final Animation<double> _shimmer;       // 0.78–1.00  kilau melintas
  late final Animation<double> _taglineFade;   // 0.84–1.00  tagline

  static const _leaf = Color(0xFF3DAA52);      // hijau daun (dari logo)
  static const _leafDeep = Color(0xFF2E9248);  // hijau gelap
  static const _ring = Color(0xFF45B45B);      // hijau outline apel
  static const _ink = Color(0xFF2B2D42);       // tinta wordmark (light)

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

    _bgFade = seg(0.00, 0.18, Curves.easeOut);
    _ringDraw = seg(0.08, 0.42, Curves.easeInOutCubic);
    _leafGrow = seg(0.30, 0.62, Curves.elasticOut);
    _stemDraw = seg(0.40, 0.56, Curves.easeOut);
    _veinDraw = seg(0.48, 0.66, Curves.easeOutCubic);
    _logoSettle = seg(0.55, 0.74, Curves.easeOutBack);
    _wordReveal = seg(0.62, 0.86, Curves.easeOutCubic);
    _shimmer = seg(0.78, 1.00, Curves.easeInOut);
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
                // ── partikel daun melayang ───────────────────────────────
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

                // ── konten tengah ────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // glow lembut di belakang logo
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
    // pulsa glow ambient (sinus) memperhalus tampilan
    final pulse = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // halo glow
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _leaf.withValues(
                      alpha: (0.18 + 0.12 * pulse) * _leafGrow.value.clamp(0, 1)),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(150, 150),
            painter: _LogoPainter(
              ringProgress: _ringDraw.value,
              leafProgress: _leafGrow.value.clamp(0.0, 1.0),
              veinProgress: _veinDraw.value,
              stemProgress: _stemDraw.value,
              ring: _ring,
              leaf: _leaf,
              leafDeep: _leafDeep,
            ),
          ),
        ],
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
            // kilau yang melintas dari kiri ke kanan
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
                  text: 'Lens',
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

/// Menggambar logo apel (lingkaran) + daun dengan progres animasi terpisah.
class _LogoPainter extends CustomPainter {
  final double ringProgress;
  final double leafProgress;
  final double veinProgress;
  final double stemProgress;
  final Color ring;
  final Color leaf;
  final Color leafDeep;

  _LogoPainter({
    required this.ringProgress,
    required this.leafProgress,
    required this.veinProgress,
    required this.stemProgress,
    required this.ring,
    required this.leaf,
    required this.leafDeep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;

    // ── 1. Lingkaran apel — menggambar dari atas, ada celah kecil di pucuk ──
    if (ringProgress > 0) {
      const gap = 0.5; // radian celah di atas (tempat tangkai)
      final start = -math.pi / 2 + gap / 2;
      final fullSweep = 2 * math.pi - gap;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.032
        ..strokeCap = StrokeCap.round
        ..color = ring;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        fullSweep * ringProgress,
        false,
        ringPaint,
      );
    }

    // ── 2. Tangkai kecil di pucuk apel ──────────────────────────────────────
    if (stemProgress > 0) {
      final stemPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.028
        ..strokeCap = StrokeCap.round
        ..color = leafDeep;
      final top = Offset(c.dx, c.dy - r);
      final stemPath = Path()
        ..moveTo(top.dx, top.dy + r * 0.05)
        ..quadraticBezierTo(
          top.dx + r * 0.10, top.dy - r * 0.18,
          top.dx + r * 0.02, top.dy - r * 0.32,
        );
      canvas.drawPath(_trimPath(stemPath, stemProgress), stemPaint);
    }

    // ── 3. Daun — tumbuh dari pangkal dengan skala elastis ──────────────────
    if (leafProgress > 0) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-math.pi / 5); // miringkan daun
      canvas.scale(leafProgress);

      final lh = r * 1.15;  // panjang daun
      final lw = r * 0.62;  // lebar daun

      // bentuk daun (almond): pangkal bawah → ujung atas, dua sisi melengkung
      final base = Offset(0, lh * 0.5);
      final tip = Offset(0, -lh * 0.5);
      final leafPath = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(lw, -lh * 0.12, tip.dx, tip.dy)
        ..quadraticBezierTo(-lw, -lh * 0.12, base.dx, base.dy)
        ..close();

      // gradien hijau memberi dimensi
      final leafPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [leaf, leafDeep],
        ).createShader(Rect.fromCenter(
            center: Offset.zero, width: lw * 2, height: lh));
      canvas.drawPath(leafPath, leafPaint);

      // ── 4. Tulang daun (vein) ────────────────────────────────────────────
      if (veinProgress > 0) {
        final veinPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.045
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.85);
        final vein = Path()
          ..moveTo(base.dx, base.dy * 0.86)
          ..quadraticBezierTo(
            lw * 0.10, 0, tip.dx, tip.dy * 0.80,
          );
        canvas.drawPath(_trimPath(vein, veinProgress), veinPaint);
      }

      canvas.restore();
    }
  }

  /// Mengembalikan potongan [path] sepanjang [t] (0–1) untuk efek menggambar.
  Path _trimPath(Path path, double t) {
    if (t >= 1) return path;
    final metrics = path.computeMetrics().toList();
    final out = Path();
    for (final m in metrics) {
      out.addPath(m.extractPath(0, m.length * t.clamp(0, 1)), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.ringProgress != ringProgress ||
      old.leafProgress != leafProgress ||
      old.veinProgress != veinProgress ||
      old.stemProgress != stemProgress;
}

/// Partikel daun/titik kecil yang melayang naik perlahan.
class _ParticlePainter extends CustomPainter {
  final double t; // 0–1 loop
  final Color color;
  final bool dark;
  _ParticlePainter({required this.t, required this.color, required this.dark});

  // posisi acak tetap (seed manual) agar tidak berubah tiap frame
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
      // melayang naik: posisi awal turun seiring fase
      final baseY = s[1] * size.height;
      final dy = baseY - phase * size.height * 0.25;
      final radius = (2.0 + s[2] * 2.2) *
          (0.6 + 0.4 * math.sin(phase * math.pi)); // berdenyut
      final fade = math.sin(phase * math.pi); // muncul-hilang
      paint.color = color.withValues(
          alpha: (dark ? 0.22 : 0.16) * fade.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
