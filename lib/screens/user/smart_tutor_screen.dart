import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/paywall.dart';
import 'practice_screen.dart';

/// স্মার্ট টিউটর — on-demand question generator + study chat.
/// (Presented to learners as the "স্মার্ট টিউটর"; no "AI" wording anywhere.)
class SmartTutorScreen extends StatefulWidget {
  const SmartTutorScreen({super.key});

  @override
  State<SmartTutorScreen> createState() => _SmartTutorScreenState();
}

class _ChatMsg {
  final String role; // user | tutor
  final String text;
  final List<Question>? practice;
  _ChatMsg(this.role, this.text, {this.practice});
}

class _SmartTutorScreenState extends State<SmartTutorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      'tutor',
      'আসসালামু আলাইকুম! আমি E&P Science স্মার্ট টিউটর। 🎓\n\n'
          'যেকোনো বিষয় লিখুন অথবা বলুন — “ভেক্টর নিয়ে ৫টি hard MCQ” — '
          'আমি সঙ্গে সঙ্গে প্রশ্ন তৈরি করে দেব।',
    ),
  ];
  bool _typing = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final auth = context.read<AuthProvider>();
    final text = preset ?? _input.text.trim();
    if (text.isEmpty) return;

    final wantsMcq = RegExp(
      r'(mcq|question|প্রশ্ন|\d+\s*(hard|easy|medium))',
      caseSensitive: false,
    ).hasMatch(text);

    if (wantsMcq && auth.isGuest) {
      Paywall.show(
        context,
        title: 'স্মার্ট জেনারেটর',
        message:
            'গেস্ট মোডে স্মার্ট জেনারেটর সীমিত। সম্পূর্ণ অ্যাক্সেসে লগইন/প্রিমিয়াম প্রয়োজন।',
      );
    }

    setState(() {
      _messages.add(_ChatMsg('user', text));
      _typing = true;
      _input.clear();
    });
    _scrollDown();

    final reply = await GeminiService.instance.tutorReply(text);
    final practice = GeminiService.instance.extractPracticeSet(reply, text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg('tutor', reply, practice: practice));
      _typing = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startPractice(List<Question> qs) {
    final quiz = context.read<QuizProvider>();
    quiz.setAdHocSession(qs);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PracticeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('স্মার্ট টিউটর'),
            Text(
              'অন-ডিমান্ড প্রশ্ন জেনারেটর',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: GeminiService.instance.isLive
                  ? AppColors.success
                  : AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              GeminiService.instance.isLive ? 'লাইভ' : 'অফলাইন',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (_typing && i == _messages.length) return _typingBubble();
                return _bubble(_messages[i]);
              },
            ),
          ),
          _quickActions(),
          _composer(data),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                m.text.replaceAll(RegExp(r'```json[\s\S]*```'), '').trim(),
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            if (m.practice != null && m.practice!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${m.practice!.length}টি প্রশ্ন তৈরি হয়েছে',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startPractice(m.practice!),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text(
                          'এখনই প্র্যাকটিস শুরু করুন',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('টিউটর ভাবছে...', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _quickActions() {
    const chips = [
      'ভেক্টর নিয়ে ৫টি hard MCQ',
      'বাংলা ব্যাকরণ ৫টি প্রশ্ন',
      'রসায়ন বন্ধন ৫টি MCQ',
      'গাণিতিক যুক্তি প্র্যাকটিস',
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(chips[i], style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.divider),
          onPressed: () => _send(chips[i]),
        ),
      ),
    );
  }

  Widget _composer(DataProvider data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'যেকোনো বিষয় বা প্রশ্ন লিখুন...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _send(),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
