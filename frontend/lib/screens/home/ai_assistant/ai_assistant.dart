import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fintech/services/ai_assistant_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatLine {
  _ChatLine({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatLine>[
    _ChatLine(
      isUser: false,
      text:
          "Hi! I'm Miro. Ask me anything about budgeting, saving, credit, or using Monéo.",
    ),
  ];
  bool _sending = false;

  static const _suggestions = [
    'What is compound interest?',
    'How can I save money faster?',
    'What is a good monthly budget?',
    'How do savings goals work?',
    'Which calculator should I use?',
    'How can I improve my credit score?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use the assistant.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _messages.add(_ChatLine(isUser: true, text: text));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiAssistantService.instance.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatLine(isUser: false, text: reply));
        _sending = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final msg = switch (e.code) {
        'failed-precondition' =>
          'Assistant is not set up yet. Ask your developer to deploy `miroChat` and set the OPENAI_API_KEY secret.',
        'unauthenticated' => 'Please sign in again.',
        'invalid-argument' => e.message ?? 'Invalid message.',
        _ => e.message ?? 'Something went wrong. Try again.',
      };
      setState(() {
        _messages.add(_ChatLine(isUser: false, text: msg));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(
          _ChatLine(
            isUser: false,
            text: e is StateError ? e.message : 'Could not get a reply. Try again.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF1B2340) : const Color(0xFFEAF2FF);
    final bgBottom = isDark ? const Color(0xFF0F1020) : const Color(0xFFF5F7FB);
    final ink = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);
    const primary = Color(0xFF007AFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: ink,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.18),
                              primary.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/owl_Background_Removed.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Ask Miro!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Type your question below and let’s figure it out together.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _suggestions
                          .map(
                            (s) => _SuggestionChip(
                              label: s,
                              ink: ink,
                              isDark: isDark,
                              onTap: () => setState(() => _controller.text = s),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    ..._messages.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChatBubble(
                          isUser: m.isUser,
                          text: m.text,
                          ink: ink,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    if (_sending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Miro is thinking…',
                              style: TextStyle(
                                fontSize: 13,
                                color: muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B1D33)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          style: TextStyle(color: ink),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Ask anything…',
                            hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _sending
                              ? primary.withValues(alpha: 0.5)
                              : primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.isUser,
    required this.text,
    required this.ink,
    required this.isDark,
  });

  final bool isUser;
  final String text;
  final Color ink;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isUser
        ? const Color(0xFF007AFF)
        : (isDark ? const Color(0xFF1B1D33) : Colors.white);
    final fg = isUser ? Colors.white : ink;
    final border = isUser
        ? Colors.transparent
        : (isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE8ECF4));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: SelectableText(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                height: 1.35,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.ink,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final Color ink;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007AFF);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D33) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primary.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}