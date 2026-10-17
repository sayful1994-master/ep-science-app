import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../user/user_shell.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final pct = quiz.total == 0
        ? 0
        : ((quiz.finalScore / quiz.total) * 100).clamp(0, 100).toDouble();
    final pass = pct >= 50;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'ফলাফল',
            subtitle: quiz.isModelTest
                ? 'মডেল টেস্ট • নেগেটিভ মার্কিং সক্রিয়'
                : 'অধ্যায় প্র্যাকটিস',
            showBack: true,
            colors: pass
                ? const [AppColors.green, AppColors.teal]
                : const [AppColors.danger, Color(0xFFB03A3D)],
            child: Row(
              children: [
                Expanded(
                  child: _bigStat(
                    'নম্বর',
                    '${quiz.finalScore.toStringAsFixed(quiz.isModelTest ? 1 : 0)}/${quiz.total}',
                  ),
                ),
                Expanded(
                  child: _bigStat('নির্ভুলতা', '${pct.toStringAsFixed(0)}%'),
                ),
                Expanded(
                  child: _bigStat('র‍্যাংক', pass ? 'পাস ✓' : 'উন্নতি দরকার'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _mini(
                        'সঠিক',
                        '${quiz.correctCount}',
                        Icons.check_circle,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _mini(
                        'ভুল',
                        '${quiz.wrongCount}',
                        Icons.cancel,
                        AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _mini(
                        'অনুত্তরিত',
                        '${quiz.total - quiz.answeredCount}',
                        Icons.help_outline,
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (quiz.isModelTest) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'নেগেটিভ মার্কিং: ${quiz.wrongCount} × ${AppConfig.negativeMarking} = -${quiz.negativeDeduction.toStringAsFixed(2)} নম্বর কাটা হয়েছে।',
                            style: const TextStyle(fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SectionTitle('দুর্বলতাগুলো বিশ্লেষণ'),
                ...quiz.weaknessReport.take(5).map((w) => _weakRow(w)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const UserShell()),
                    );
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('হোমে ফিরে যান'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
        ),
      ),
    ],
  );

  Widget _mini(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weakRow(WeaknessStat w) {
    final acc = (w.accuracy * 100).clamp(0, 100).toDouble();
    final color = acc >= 70
        ? AppColors.success
        : acc >= 40
        ? AppColors.gold
        : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  w.chapterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Pill('${acc.toStringAsFixed(0)}%', color: color, filled: true),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: acc / 100,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${w.attempts}টি চেষ্টা • ${w.wrong}টি ভুল',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
