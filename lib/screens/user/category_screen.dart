import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../study/subject_study_hub.dart';
import 'smart_tutor_screen.dart';

class CategoryScreen extends StatelessWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final subs = data.subCategoriesOf(category.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: category.name,
              subtitle: category.nameEn,
              showBack: true,
              child: Text(
                '${subs.length} টি গ্রুপ • ${data.subjects.where((s) => subs.any((x) => x.id == s.subCategoryId)).length} বিষয়',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: SectionTitle('গ্রুপ / ক্লাস'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final sub = subs[i];
                final subjects = data.subjectsOf(sub.id);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.layers_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sub.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${subjects.length} টি বিষয়',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      children: [
                        for (final s in subjects)
                          _subjectTile(context, data, s),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _subjectTile(BuildContext context, DataProvider data, Subject s) {
    final chapters = data.chaptersOf(s.id);
    final qCount = data.subjectQuestionCount(s.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectStudyHub(
              subject: s,
              categoryName: category.name,
              subCategoryId: s.subCategoryId,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(iconFromName(s.icon), color: AppColors.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${chapters.length} অধ্যায় • $qCount প্রশ্ন',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.smartGeneratorEnabled)
                IconButton(
                  tooltip: 'স্মার্ট জেনারেটর',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmartTutorScreen()),
                  ),
                  icon: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
