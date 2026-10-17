import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paywall.dart';
import 'result_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _pageController = PageController();
  bool _generating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final auth = context.watch<AuthProvider>();
    final genOn = context.watch<DataProvider>().smartGeneratorEnabled;

    if (quiz.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('প্র্যাকটিস')),
        body: genOn
            ? EmptyState(
                icon: Icons.quiz_outlined,
                message:
                    'এই অধ্যায়ে এখনো কোনো প্রশ্ন নেই।\nজেনারেটর দিয়ে তাৎক্ষণিক প্রশ্ন তৈরি করুন!',
                actionLabel: 'প্রশ্ন জেনারেট করুন',
                onAction: () => _aiGenerate(context, quiz, auth),
              )
            : const EmptyState(
                icon: Icons.quiz_outlined,
                message: 'এই অধ্যায়ে এখনো কোনো প্রশ্ন যোগ করা হয়নি।',
              ),
      );
    }

    final item = quiz.current!;
    final q = item.question;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          quiz.currentChapter?.name ?? 'প্র্যাকটিস',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (quiz.isModelTest)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: Pill(
                  'মডেল টেস্ট • -${AppConfig.negativeMarking}',
                  color: AppColors.danger,
                  filled: true,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // progress + counters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'প্রশ্ন ${quiz.index + 1}/${quiz.total}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: quiz.total == 0
                          ? 0
                          : (quiz.index + 1) / quiz.total,
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Pill(
                  '✓ ${quiz.correctCount}',
                  color: AppColors.success,
                  filled: true,
                ),
                const SizedBox(width: 5),
                Pill(
                  '✗ ${quiz.wrongCount}',
                  color: AppColors.danger,
                  filled: true,
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // Swipe between consecutive QUESTIONS.
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  quiz.next();
                  if (quiz.sessionFinished && mounted) _openResult(context);
                } else if (details.primaryVelocity! > 200) {
                  quiz.prev();
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Pill(
                          q.difficultyLevel,
                          color: _diffColor(q.difficultyLevel),
                        ),
                        if (q.examTag.isNotEmpty) Pill(q.examTag),
                        if (genOn &&
                            (q.generatedBy == 'AI' ||
                                q.generatedBy == 'Generator'))
                          const Pill(
                            'জেনারেটর',
                            color: AppColors.primaryBlue,
                            icon: Icons.auto_awesome,
                          ),
                        if (q.isPremium && !auth.isPremium)
                          const Pill(
                            'প্রিমিয়াম',
                            color: AppColors.gold,
                            icon: Icons.workspace_premium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        q.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...q.options.map((o) => _optionTile(context, quiz, o)),
                    const SizedBox(height: 12),

                    if (item.answered) _explanationBox(item),

                    if (genOn) ...[
                      const SizedBox(height: 16),
                      _aiToolsRow(context, quiz, auth),
                    ],
                  ],
                ),
              ),
            ),
          ),

          _bottomBar(context, quiz),
        ],
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'Easy':
        return AppColors.green;
      case 'Hard':
        return AppColors.danger;
      default:
        return AppColors.gold;
    }
  }

  Widget _optionTile(
    BuildContext context,
    QuizProvider quiz,
    MapEntry<String, String> opt,
  ) {
    final item = quiz.current!;
    final answered = item.answered;
    final isCorrect = opt.key == item.question.correctAnswer;
    final isSelected = item.selected == opt.key;

    Color border = AppColors.divider;
    Color bg = Colors.white;
    Color textColor = AppColors.textPrimary;
    IconData? trailing;

    if (answered) {
      if (isCorrect) {
        border = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.08);
        trailing = Icons.check_circle;
      } else if (isSelected) {
        border = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: 0.08);
        trailing = Icons.cancel;
      }
    } else if (isSelected) {
      border = AppColors.primaryBlue;
      bg = AppColors.primaryBlue.withValues(alpha: 0.06);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: answered ? null : () => quiz.select(opt.key),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: border == AppColors.divider
                      ? AppColors.bg
                      : border.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: border == AppColors.divider
                        ? AppColors.textSecondary
                        : border,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opt.value,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  color: isCorrect ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explanationBox(QuizItem item) {
    final correct = item.isCorrect;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (correct ? AppColors.success : AppColors.danger).withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (correct ? AppColors.success : AppColors.danger).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? AppColors.success : AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'সঠিক উত্তর!' : 'ভুল উত্তর',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: correct ? AppColors.success : AppColors.danger,
                ),
              ),
              const Spacer(),
              Text(
                'সঠিক: ${item.question.correctAnswer}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ব্যাখ্যা',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            item.question.explanation.isEmpty
                ? 'ব্যাখ্যা শীঘ্রই যোগ করা হবে।'
                : item.question.explanation,
            style: const TextStyle(fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _aiToolsRow(
    BuildContext context,
    QuizProvider quiz,
    AuthProvider auth,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              if (!auth.isPremium && !auth.isGuest) {
                // free users get 1 similar during first-2-chapters
              }
              setState(() => _generating = true);
              await quiz.trySimilar();
              if (mounted) setState(() => _generating = false);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text(
              'একই ধরনের প্রশ্ন',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generating
                ? null
                : () => _aiGenerate(context, quiz, auth, single: false),
            icon: _generating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: const Text('প্রশ্নসেট তৈরি', style: TextStyle(fontSize: 12.5)),
          ),
        ),
      ],
    );
  }

  Future<void> _aiGenerate(
    BuildContext context,
    QuizProvider quiz,
    AuthProvider auth, {
    bool single = true,
  }) async {
    if (!auth.isPremium) {
      await Paywall.show(
        context,
        title: 'অন-ডিমান্ড প্রশ্নসেট',
        message:
            'সীমাহীন প্রশ্ন জেনারেশন ও অন-ডিমান্ড প্র্যাকটিস সেট প্রিমিয়াম সদস্যদের জন্য।',
      );
      return;
    }
    setState(() => _generating = true);
    await quiz.generatePractice(count: 5, premium: true);
    if (mounted) setState(() => _generating = false);
  }

  Widget _bottomBar(BuildContext context, QuizProvider quiz) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: quiz.hasPrev ? quiz.prev : null,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: const Text('আগের'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      quiz.next();
                      if (quiz.sessionFinished && mounted) _openResult(context);
                    },
                    icon: Icon(
                      quiz.hasNext ? Icons.arrow_forward : Icons.flag_outlined,
                    ),
                    label: Text(
                      quiz.hasNext ? 'পরবর্তী' : 'ফলাফল দেখুন',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Chapter navigation (next/prev) — with horizontal swipe support
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: quiz.hasPrevChapter
                        ? () {
                            quiz.prevChapter();
                            _pageController.jumpToPage(0);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text(
                      'আগের অধ্যায়',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                Container(width: 1, height: 18, color: AppColors.divider),
                Expanded(
                  child: TextButton.icon(
                    onPressed: quiz.hasNextChapter
                        ? () {
                            quiz.nextChapter();
                            _pageController.jumpToPage(0);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text(
                      'পরের অধ্যায়',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openResult(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ResultScreen()));
  }
}
