import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';

// Local question with built-in answer — used when API is unavailable
class _LocalQ {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;

  const _LocalQ({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });

  QuizQuestion toQuestion() =>
      QuizQuestion(id: id, text: text, options: options, category: category);

  QuizAnswer checkAnswer(int selected) => QuizAnswer(
        isCorrect: selected == correctIndex,
        correctIndex: correctIndex,
        correctAnswer: options[correctIndex],
        explanation: explanation,
        pointsEarned: selected == correctIndex ? 10 : 0,
      );
}

const _kFallbackQuestions = <_LocalQ>[
  _LocalQ(
    id: 'local_1',
    text: 'Berapa batas konsumsi gula harian yang direkomendasikan WHO untuk orang dewasa?',
    options: ['10 gram', '25 gram', '50 gram', '100 gram'],
    correctIndex: 1,
    explanation: 'WHO merekomendasikan konsumsi gula bebas tidak lebih dari 25 gram (sekitar 6 sendok teh) per hari untuk orang dewasa.',
    category: 'gizi',
  ),
  _LocalQ(
    id: 'local_2',
    text: 'Apa yang dimaksud dengan Nutri-Score A pada kemasan makanan?',
    options: [
      'Produk mengandung pemanis buatan',
      'Kualitas gizi terbaik dalam kategorinya',
      'Produk bebas gluten',
      'Sertifikasi organik dari pemerintah',
    ],
    correctIndex: 1,
    explanation: 'Nutri-Score A (warna hijau gelap) menunjukkan produk memiliki profil gizi terbaik — rendah gula, lemak jenuh, dan natrium, serta tinggi serat dan protein.',
    category: 'label',
  ),
  _LocalQ(
    id: 'local_3',
    text: 'Berapa batas konsumsi natrium (sodium) per hari yang aman menurut WHO?',
    options: ['500 mg', '1000 mg', '2000 mg', '3500 mg'],
    correctIndex: 2,
    explanation: 'WHO merekomendasikan konsumsi natrium kurang dari 2000 mg per hari (setara ±5 gram garam). Kelebihan natrium berisiko hipertensi dan penyakit jantung.',
    category: 'gizi',
  ),
  _LocalQ(
    id: 'local_4',
    text: 'Kandungan apa yang biasanya paling tinggi dalam mie instan?',
    options: ['Protein', 'Serat', 'Natrium', 'Kalsium'],
    correctIndex: 2,
    explanation: 'Mie instan umumnya sangat tinggi natrium — satu bungkus bisa mengandung 800–1400 mg natrium, atau lebih dari separuh batas harian yang direkomendasikan.',
    category: 'produk',
  ),
  _LocalQ(
    id: 'local_5',
    text: 'Apa fungsi utama serat makanan (dietary fiber) bagi tubuh?',
    options: [
      'Meningkatkan kadar gula darah',
      'Melancarkan sistem pencernaan',
      'Menambah massa otot',
      'Melarutkan vitamin A',
    ],
    correctIndex: 1,
    explanation: 'Serat membantu melancarkan pencernaan, mencegah konstipasi, menjaga kadar gula darah, dan memberi rasa kenyang lebih lama. Kebutuhan harian dewasa sekitar 25–38 gram.',
    category: 'gizi',
  ),
  _LocalQ(
    id: 'local_6',
    text: 'Vitamin apa yang paling dominan dalam buah jeruk dan citrus?',
    options: ['Vitamin A', 'Vitamin B12', 'Vitamin C', 'Vitamin D'],
    correctIndex: 2,
    explanation: 'Jeruk kaya Vitamin C (asam askorbat) yang berperan sebagai antioksidan, membantu penyerapan zat besi, dan mendukung imunitas tubuh.',
    category: 'vitamin',
  ),
  _LocalQ(
    id: 'local_7',
    text: 'Apa itu lemak trans (trans fat) dan mengapa berbahaya?',
    options: [
      'Lemak dari tumbuhan, aman dikonsumsi',
      'Lemak jenuh alami dari susu',
      'Lemak hasil proses hidrogenasi yang meningkatkan risiko penyakit jantung',
      'Lemak tak jenuh ganda yang bermanfaat',
    ],
    correctIndex: 2,
    explanation: 'Lemak trans terbentuk dari proses hidrogenasi parsial minyak nabati (margarin). Lemak ini meningkatkan LDL (kolesterol jahat) dan menurunkan HDL, sehingga sangat berisiko bagi jantung.',
    category: 'lemak',
  ),
  _LocalQ(
    id: 'local_8',
    text: 'Manakah yang termasuk sumber karbohidrat kompleks?',
    options: ['Gula pasir', 'Minuman bersoda', 'Nasi merah & oat', 'Permen karet'],
    correctIndex: 2,
    explanation: 'Karbohidrat kompleks (nasi merah, oat, gandum utuh) dicerna lebih lambat sehingga tidak menyebabkan lonjakan gula darah mendadak, berbeda dengan karbohidrat sederhana seperti gula.',
    category: 'karbohidrat',
  ),
  _LocalQ(
    id: 'local_9',
    text: 'Apa yang dimaksud Indeks Glikemik (GI) pada makanan?',
    options: [
      'Jumlah kalori per 100 gram produk',
      'Ukuran seberapa cepat makanan menaikkan kadar gula darah',
      'Persentase protein dalam makanan',
      'Label keamanan pangan dari BPOM',
    ],
    correctIndex: 1,
    explanation: 'Indeks Glikemik mengukur seberapa cepat karbohidrat dalam makanan diubah menjadi glukosa darah. GI tinggi (>70) menyebabkan lonjakan gula cepat; GI rendah (<55) lebih stabil.',
    category: 'gizi',
  ),
  _LocalQ(
    id: 'local_10',
    text: 'Sumber protein hewani mana yang paling rendah lemak?',
    options: [
      'Daging sapi berlemak',
      'Kulit ayam goreng',
      'Dada ayam tanpa kulit',
      'Jeroan sapi',
    ],
    correctIndex: 2,
    explanation: 'Dada ayam tanpa kulit adalah sumber protein hewani yang sangat lean — tinggi protein (±31g/100g) namun rendah lemak jenuh, sehingga cocok untuk diet sehat.',
    category: 'protein',
  ),
  _LocalQ(
    id: 'local_11',
    text: 'Mineral apa yang paling penting untuk kesehatan tulang dan gigi?',
    options: ['Zat Besi', 'Kalsium', 'Kalium', 'Magnesium'],
    correctIndex: 1,
    explanation: 'Kalsium adalah mineral utama pembentuk tulang dan gigi. Kekurangan kalsium jangka panjang dapat menyebabkan osteoporosis. Sumber terbaik: susu, keju, tahu, dan ikan sarden.',
    category: 'mineral',
  ),
  _LocalQ(
    id: 'local_12',
    text: 'Berapa kebutuhan kalori harian rata-rata orang dewasa (pria aktif)?',
    options: ['1200 kkal', '1800 kkal', '2500 kkal', '3500 kkal'],
    correctIndex: 2,
    explanation: 'Pria dewasa aktif membutuhkan sekitar 2200–2800 kkal per hari. Angka ini bervariasi berdasarkan usia, berat badan, dan tingkat aktivitas fisik.',
    category: 'gizi',
  ),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<QuizQuestion>? _questions;
  List<_LocalQ>? _localQuestions; // non-null when using fallback mode
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  QuizAnswer? _answerResult;
  bool _submitting = false;
  bool _quizDone = false;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _loadQuiz();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() { _loading = true; _error = null; });
    try {
      final qs = await ApiService().getQuiz(count: 10);
      if (qs.isNotEmpty) {
        setState(() { _questions = qs; _localQuestions = null; _loading = false; });
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    // Shuffle + pick 8 questions from the fallback pool
    final pool = List.of(_kFallbackQuestions)..shuffle();
    final picked = pool.take(8).toList();
    setState(() {
      _localQuestions = picked;
      _questions = picked.map((q) => q.toQuestion()).toList();
      _loading = false;
    });
  }

  void _resetQuiz() {
    _animCtrl.reset();
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answerResult = null;
      _quizDone = false;
      _loading = false;
    });
    if (_localQuestions != null) {
      _useFallback();
    } else {
      setState(() => _loading = true);
      _loadQuiz();
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _submitting) return;
    final q = _questions![_currentIndex];
    setState(() => _submitting = true);

    QuizAnswer result;
    if (_localQuestions != null) {
      // Local mode — check answer offline
      result = _localQuestions![_currentIndex].checkAnswer(_selectedAnswer!);
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      try {
        result = await ApiService().answerQuiz(q.id, _selectedAnswer!);
      } catch (_) {
        // API answer failed — fall back to best guess (unknown)
        result = QuizAnswer(
          isCorrect: false,
          correctIndex: 0,
          correctAnswer: '',
          explanation: 'Tidak dapat memverifikasi jawaban saat ini.',
          pointsEarned: 0,
        );
      }
    }

    if (result.isCorrect) {
      _animCtrl.forward(from: 0);
    }
    setState(() {
      _answerResult = result;
      if (result.isCorrect) _score++;
      _submitting = false;
    });
  }

  void _nextQuestion() {
    final total = _questions!.length;
    if (_currentIndex < total - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answerResult = null;
      });
    } else {
      setState(() => _quizDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text(
          'Kuis Nutrisi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            const SizedBox(height: 16),
            Text('Memuat soal...',
                style: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) return _buildError();
    if (_questions == null || _questions!.isEmpty) return _buildEmpty();
    if (_quizDone) return _buildDoneScreen();
    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final questions = _questions!;
    final q = questions[_currentIndex];
    final total = questions.length;
    final isLocal = _localQuestions != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge + mode indicator
          Row(
            children: [
              if (q.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAD7BFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFAD7BFF).withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    q.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: const Color(0xFFAD7BFF), letterSpacing: 1,
                    ),
                  ),
                ),
              const Spacer(),
              if (isLocal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Mode Offline',
                      style: GoogleFonts.inter(
                          fontSize: 9, color: AppColors.textQuaternary(context))),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          Row(
            children: [
              Text(
                'Soal ${_currentIndex + 1} / $total',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context)),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFAD00)),
                  const SizedBox(width: 4),
                  Text('$_score poin',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFAD00),
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: AppColors.cardBorder(context),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 24),

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4ECDC4).withValues(alpha: 0.06),
                  AppColors.cardBg(context),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline_rounded,
                    size: 20, color: const Color(0xFF4ECDC4).withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                Text(
                  q.text,
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context), height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...q.options.asMap().entries.map(
              (e) => _buildOption(e.key, e.value, q.options.length)),
          const SizedBox(height: 8),

          // Feedback section
          if (_answerResult != null) ...[
            ScaleTransition(
              scale: _scaleAnim,
              child: _buildExplanation(_answerResult!),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: Icon(
                  _currentIndex < questions.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.emoji_events_rounded,
                  size: 18,
                ),
                label: Text(
                  _currentIndex < questions.length - 1
                      ? 'Soal Berikutnya'
                      : 'Lihat Hasil',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else if (_selectedAnswer != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : Text('Konfirmasi Jawaban',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                'Pilih salah satu jawaban di atas',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text, int totalOptions) {
    final isSelected = _selectedAnswer == index;
    final answered = _answerResult != null;
    final isCorrect = answered && index == _answerResult!.correctIndex;
    final isWrong = answered && isSelected && !_answerResult!.isCorrect;

    Color borderColor = AppColors.cardBorder(context);
    Color bgColor = AppColors.cardBg(context);
    Color textColor = Colors.white70;
    Color circleBg = AppColors.cardBorder(context);

    if (isCorrect) {
      borderColor = const Color(0xFF4ECDC4).withValues(alpha: 0.5);
      bgColor = const Color(0xFF4ECDC4).withValues(alpha: 0.1);
      textColor = const Color(0xFF4ECDC4);
      circleBg = const Color(0xFF4ECDC4).withValues(alpha: 0.2);
    } else if (isWrong) {
      borderColor = const Color(0xFFFF6B6B).withValues(alpha: 0.5);
      bgColor = const Color(0xFFFF6B6B).withValues(alpha: 0.1);
      textColor = const Color(0xFFFF6B6B);
      circleBg = const Color(0xFFFF6B6B).withValues(alpha: 0.2);
    } else if (isSelected && !answered) {
      borderColor = const Color(0xFF4ECDC4).withValues(alpha: 0.5);
      bgColor = const Color(0xFF4ECDC4).withValues(alpha: 0.08);
      textColor = Colors.white;
      circleBg = const Color(0xFF4ECDC4).withValues(alpha: 0.2);
    }

    final label = String.fromCharCode(65 + index);

    return GestureDetector(
      onTap: answered ? null : () => setState(() => _selectedAnswer = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: isCorrect
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF4ECDC4))
                  : isWrong
                      ? const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFFFF6B6B))
                      : Text(label,
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: textColor,
                          )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14, color: textColor,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(QuizAnswer result) {
    final isCorrect = result.isCorrect;
    final color =
        isCorrect ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color, size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect
                    ? 'Benar! +${result.pointsEarned} poin'
                    : 'Kurang tepat',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color,
                ),
              ),
            ],
          ),
          if (!isCorrect && result.correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Jawaban benar: ${result.correctAnswer}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600),
            ),
          ],
          if (result.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: color.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.explanation,
                    style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary(context), height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoneScreen() {
    final total = _questions!.length;
    final percent = ((_score / total) * 100).round();
    final color = percent >= 80
        ? const Color(0xFF4ECDC4)
        : percent >= 50
            ? const Color(0xFFFFAD00)
            : const Color(0xFFFF6B6B);
    final emoji = percent >= 80 ? '🏆' : percent >= 50 ? '👍' : '📚';
    final message = percent >= 80
        ? 'Luar biasa! Kamu ahli gizi sejati!'
        : percent >= 50
            ? 'Bagus! Terus belajar tentang nutrisi.'
            : 'Jangan menyerah! Coba lagi untuk hasil lebih baik.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),

            // Score ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      backgroundColor: AppColors.cardBorder(context),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(v * 100).round()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 28, fontWeight: FontWeight.bold, color: color,
                        ),
                      ),
                      Text(
                        '$_score/$total',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Kuis Selesai!',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
                )),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary(context), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _resetQuiz,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text('Main Lagi',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali',
                  style: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined,
              size: 48, color: AppColors.textQuaternary(context)),
          const SizedBox(height: 12),
          Text('Belum ada soal',
              style: GoogleFonts.poppins(color: AppColors.textTertiary(context), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _useFallback,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.black,
            ),
            child: const Text('Gunakan Soal Offline'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text('Tidak dapat memuat soal dari server',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context))),
            const SizedBox(height: 8),
            Text('Kamu tetap bisa bermain dengan soal offline.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary(context))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _useFallback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Main dengan Soal Offline',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadQuiz,
              child: Text('Coba Koneksi Lagi',
                  style: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
