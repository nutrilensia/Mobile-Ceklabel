import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../models/family_profile.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';

class ChatScreen extends StatefulWidget {
  final FamilyProfile? initialProfile;
  const ChatScreen({super.key, this.initialProfile});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  FamilyProfile? _selectedProfile;

  // Colors now from AppColors
  
  static const _teal = Color(0xFF4ECDC4);
  // Surface/bg colors now from AppColors
  

  static const _greeting = 'Halo! Saya Asisten Gizi NutriLens. Saya bisa bantu kamu memahami label makanan, menganalisis pola makan, atau menjawab pertanyaan seputar nutrisi. Ada yang ingin kamu tanyakan?';

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.initialProfile;
    final cached = ApiService().chatHistory;
    if (cached.isNotEmpty) {
      _messages.addAll(cached);
    } else {
      _messages.add(ChatMessage(role: 'assistant', content: _greeting));
      ApiService().chatHistory = List.from(_messages);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _saveHistory();
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await ApiService().sendChatMessage(
        _messages,
        profileId: _selectedProfile?.id,
      );
      if (mounted) {
        setState(() => _messages.add(reply));
        _saveHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Maaf, terjadi kesalahan. Silakan coba lagi.',
        )));
        _saveHistory();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _saveHistory() => ApiService().chatHistory = List.from(_messages);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _insertSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheet(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _teal.withValues(alpha: 0.4)),
              ),
              child: const AppLogo(size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asisten Gizi', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
                )),
                Text(
                  _selectedProfile != null ? 'Profil: ${_selectedProfile!.name}' : 'Profil utama',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary(context), size: 20),
              tooltip: 'Mulai percakapan baru',
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _messages.add(ChatMessage(
                    role: 'assistant',
                    content: 'Percakapan baru dimulai. Ada yang ingin kamu tanyakan?',
                  ));
                });
                _saveHistory();
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _buildTypingIndicator();
                final msg = _messages[i];
                final isUser = msg.role == 'user';
                return _buildBubble(msg.content, isUser, i == 0);
              },
            ),
          ),
          if (_messages.length == 1) _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(String content, bool isUser, bool isFirst) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 8,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const AppLogo(size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubble(context) : AppColors.surface(context),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 4),
                  topRight: Radius.circular(isUser ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                border: Border.all(
                  color: isUser
                      ? _teal.withValues(alpha: 0.3)
                      : AppColors.cardBorder(context),
                ),
              ),
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 48),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const AppLogo(size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _dot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context2, v, child2) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.4 + 0.6 * v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'Berapa batas gula harian yang aman?',
      'Apa arti NutriScore D pada produk?',
      'Rekomendasikan sarapan sehat rendah gula',
      'Kenapa natrium berbahaya jika berlebih?',
    ];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _insertSuggestion(suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withValues(alpha: 0.3)),
            ),
            child: Text(
              suggestions[i],
              style: GoogleFonts.inter(fontSize: 12, color: _teal),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.cardBorder(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.inputBorder(context)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Tanya seputar nutrisi...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textQuaternary(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [_teal, Color(0xFF44A08D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading ? AppColors.disabledBg(context) : null,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded, color: AppColors.textPrimary(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
