import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';

/// Private conversation between a student and one teacher.
/// Visible ONLY to the two parties + admin.
class QuestionThreadScreen extends StatefulWidget {
  final String teacherId;
  const QuestionThreadScreen({super.key, required this.teacherId});

  @override
  State<QuestionThreadScreen> createState() => _QuestionThreadScreenState();
}

class _QuestionThreadScreenState extends State<QuestionThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  QuestionThread? _thread;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensure());
  }

  void _ensure() {
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final teacher = data.teacher(widget.teacherId);
    if (teacher == null || auth.user == null) return;
    _thread = data.ensureThread(
      studentId: auth.user!.uid,
      studentName: auth.user!.name,
      teacher: teacher,
    );
    setState(() {});
    _scrollDown();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _thread == null) return;
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    _input.clear();
    await data.sendMessage(
      thread: _thread!,
      senderId: auth.user!.uid,
      senderName: auth.user!.name,
      text: text,
    );
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final teacher = data.teacher(widget.teacherId);
    final messages = _thread == null ? <ChatMessage>[] : data.messagesOf(_thread!.id);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher?.name ?? 'শিক্ষক'),
            const Text(
              'ব্যক্তিগত প্রশ্নোত্তর',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.bg,
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'এই আলাপচারিতা শুধু আপনি, শিক্ষক ও অ্যাডমিন দেখতে পাবেন।',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'এখনো কোনো বার্তা নেই।\nনিচে আপনার প্রশ্ন লিখে পাঠান।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _bubble(messages[i], auth),
                  ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, AuthProvider auth) {
    final mine = m.senderId == auth.user?.uid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  m.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            Text(
              m.text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
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
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'আপনার প্রশ্ন লিখুন...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _send,
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
