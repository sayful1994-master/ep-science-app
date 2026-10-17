import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../study/subject_study_hub.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final all = data.categories
        .expand((c) => data.subCategoriesOf(c.id))
        .expand((s) => data.subjectsOf(s.id))
        .toList();
    final filtered = _query.isEmpty
        ? all
        : all
              .where(
                (s) => s.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('অনুসন্ধান করুন')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _q,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'বিষয় বা অধ্যায় লিখুন...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: 'কিছু পাওয়া যায়নি। ভিন্ন কীওয়ার্ড চেষ্টা করুন।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      final sub = data.subCategory(s.subCategoryId);
                      final cat = sub == null
                          ? null
                          : data.category(sub.categoryId);
                      final chapters = data.chaptersOf(s.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectStudyHub(
                              subject: s,
                              categoryName: cat?.name ?? '',
                              subCategoryId: s.subCategoryId,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  iconFromName(s.icon),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${cat?.name ?? ""} • ${sub?.name ?? ""} • ${chapters.length} অধ্যায়',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
