import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paywall.dart';
import 'practice_screen.dart';

class SubjectChaptersScreen extends StatelessWidget {
  final Subject subject;
  final String categoryName;
  final String subCategoryId;
  const SubjectChaptersScreen({
    super.key,
    required this.subject,
    required this.categoryName,
    required this.subCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final chapters = data.chaptersOf(subject.id);
    final sub = data.subCategory(subCategoryId);
    final subName = sub?.name ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: subject.name,
              subtitle: '$categoryName • $subName',
              showBack: true,
              child: Row(
                children: [
                  _chip('${chapters.length} অধ্যায়', Icons.list_alt),
                  const SizedBox(width: 8),
                  _chip(
                    '${data.subjectQuestionCount(subject.id)} প্রশ্ন',
                    Icons.quiz_outlined,
                  ),
                  const SizedBox(width: 8),
                  if (!auth.isPremium)
                    _chip('ফ্রি: ১ম ২ অধ্যায়', Icons.lock_open),
                ],
              ),
            ),
          ),

          // Model test CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: _modelTestCard(context, auth, data),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: SectionTitle('অধ্যায়ভিত্তিক প্র্যাকটিস'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _chapterTile(context, auth, data, chapters, i),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _chip(String t, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
      ],
    ),
  );

  Widget _modelTestCard(
    BuildContext context,
    AuthProvider auth,
    DataProvider data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'মডেল টেস্ট (নেগেটিভ মার্কিং)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                SizedBox(height: 2),
                Text(
                  'প্রতিটি ভুল উত্তরে -${AppConfig.negativeMarking} নম্বর কাটা হবে',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!auth.isPremium) {
                Paywall.show(
                  context,
                  title: 'মডেল টেস্ট প্রিমিয়াম',
                  message:
                      '২০০ মার্কের বিসিএস মডেল টেস্ট ও নেগেটিভ মার্কিংসহ সম্পূর্ণ মডেল টেস্ট ফিচার প্রিমিয়াম সদস্যদের জন্য।',
                );
                return;
              }
              final quiz = context.read<QuizProvider>();
              quiz.startSubjectModelTest(subject, data.chaptersOf(subject.id));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('শুরু', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chapterTile(
    BuildContext context,
    AuthProvider auth,
    DataProvider data,
    List<Chapter> chapters,
    int i,
  ) {
    final ch = chapters[i];
    final qCount = data.chapterQuestionCount(ch.id);
    final locked =
        !auth.canAccessChapter(i, questionPremium: true) && !auth.isPremium;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (locked) {
          Paywall.show(
            context,
            title: 'অধ্যায় ${i + 1} লকড',
            message:
                'অধ্যায় “${ch.name}” প্রিমিয়াম সদস্যদের জন্য সংরক্ষিত। ফ্রি সদস্যরা প্রতিটি বিষয়ের প্রথম ২টি অধ্যায় পেয়ে থাকেন।',
          );
          return;
        }
        context.read<QuizProvider>().startChapter(
          subj: subject,
          allChapters: chapters,
          startPos: i,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PracticeScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.bg
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: locked
                  ? const Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 19,
                    )
                  : Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '$qCount টি প্রশ্ন',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      if (i < AppConfig.freeChapterLimit && !locked) ...[
                        const SizedBox(width: 8),
                        const Pill('ফ্রি', color: AppColors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (locked)
              const Pill(
                'প্রিমিয়াম',
                color: AppColors.gold,
                icon: Icons.workspace_premium,
              )
            else
              const Icon(
                Icons.play_circle_outline,
                color: AppColors.teal,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}
