import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Admin question generator — builds chapter-wise MCQ sets using the
/// smart generator service (Gemini when a key is configured, offline
/// academic templates otherwise).
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  String? categoryId;
  String? subCategoryId;
  String? subjectId;
  String? chapterId;
  String _difficulty = 'Medium';
  int _count = 5;
  bool _premium = true;
  bool _generating = false;
  List<Question> _preview = [];
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final subs = categoryId == null
        ? <SubCategory>[]
        : data.subCategoriesOf(categoryId!);
    final subjects = subCategoryId == null
        ? <Subject>[]
        : data.subjectsOf(subCategoryId!);
    final chapters = subjectId == null
        ? <Chapter>[]
        : data.chaptersOf(subjectId!);
    final live = GeminiService.instance.isLive;

    return Scaffold(
      appBar: AppBar(title: const Text('প্রশ্ন জেনারেটর (Admin)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'শ্রেণি ও অধ্যায় নির্বাচন করে স্বয়ংক্রিয়ভাবে প্রশ্ন তৈরি করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        live
                            ? 'লাইভ জেনারেশন সক্রিয়'
                            : 'অফলাইন মোড (কী যুক্ত করলে লাইভ হবে)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Pill(
                  live ? 'LIVE' : 'OFFLINE',
                  color: live ? AppColors.green : AppColors.gold,
                  filled: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _dropdown(
            'ক্যাটাগরি',
            categoryId,
            data.categories
                .map<DropdownMenuItem<String>>(
                  (c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)),
                )
                .toList(),
            (v) => setState(() {
              categoryId = v;
              subCategoryId = null;
              subjectId = null;
              chapterId = null;
            }),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'সাব-ক্যাটাগরি / ক্লাস',
            subCategoryId,
            subs
                .map<DropdownMenuItem<String>>(
                  (s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name)),
                )
                .toList(),
            (v) => setState(() {
              subCategoryId = v;
              subjectId = null;
              chapterId = null;
            }),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'বিষয়',
            subjectId,
            subjects
                .map<DropdownMenuItem<String>>(
                  (s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name)),
                )
                .toList(),
            (v) => setState(() {
              subjectId = v;
              chapterId = null;
            }),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'অধ্যায়',
            chapterId,
            chapters
                .map<DropdownMenuItem<String>>(
                  (c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)),
                )
                .toList(),
            (v) => setState(() => chapterId = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dropdown('কাঠিন্য', _difficulty, const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                ], (v) => setState(() => _difficulty = v!)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _count,
                  decoration: const InputDecoration(
                    labelText: 'প্রশ্ন সংখ্যা',
                    isDense: true,
                  ),
                  items: [1, 3, 5, 10, 15, 20]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => setState(() => _count = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _premium,
            onChanged: (v) => setState(() => _premium = v),
            title: const Text(
              'প্রিমিয়াম হিসেবে সংরক্ষণ করুন',
              style: TextStyle(fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : () => _generate(context, data),
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _generating ? 'তৈরি হচ্ছে...' : '$_count প্রশ্ন তৈরি করুন',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionTitle('প্রিভিউ'),
            for (var i = 0; i < _preview.length; i++)
              _previewCard(_preview[i], i),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _preview = [];
                      _status = '';
                    }),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('নতুন করে তৈরি করুন'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _save(context, data),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: Text('সংরক্ষণ (${_preview.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _previewCard(Question q, int i) {
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
              Pill('${i + 1}', color: AppColors.primaryBlue, filled: true),
              const SizedBox(width: 8),
              Pill(q.difficultyLevel, color: AppColors.gold),
              const Spacer(),
              Text(
                'উত্তর: ${q.correctAnswer}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.questionText,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: q.options
                .map(
                  (o) => Pill(
                    '${o.key}. ${o.value}',
                    color: o.key == q.correctAnswer
                        ? AppColors.green
                        : AppColors.textSecondary,
                  ),
                )
                .toList(),
          ),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ব্যাখ্যা: ${q.explanation}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context, DataProvider data) async {
    if (chapterId == null || subjectId == null) {
      setState(() => _status = '⚠️ আগে বিষয় ও অধ্যায় নির্বাচন করুন।');
      return;
    }
    setState(() {
      _generating = true;
      _status = '';
    });
    final subj = data.subject(subjectId!)!;
    final ch = data.chapter(chapterId!)!;
    final cat = data.category(categoryId!);
    final subCat = data.subCategory(subCategoryId!);

    final qs = await GeminiService.instance.generateQuestions(
      categoryId: categoryId!,
      categoryName: cat?.name ?? '',
      subCategoryId: subCategoryId!,
      subCategoryName: subCat?.name ?? '',
      subjectId: subjectId!,
      subjectName: subj.name,
      chapterId: chapterId!,
      chapterName: ch.name,
      difficulty: _difficulty,
      count: _count,
      premium: _premium,
    );
    if (!mounted) return;
    setState(() {
      _preview = qs;
      _generating = false;
      _status = '✅ $_count টি প্রশ্ন তৈরি হয়েছে — সংরক্ষণ করুন।';
    });
  }

  Future<void> _save(BuildContext context, DataProvider data) async {
    final messenger = ScaffoldMessenger.of(context);
    await data.bulkAddQuestions(_preview);
    if (!mounted) return;
    setState(() {
      _status = '✅ ${_preview.length}টি প্রশ্ন সফলভাবে সংরক্ষিত।';
      _preview = [];
    });
    messenger.showSnackBar(
      const SnackBar(
        content: Text('প্রশ্ন সংরক্ষণ সম্পন্ন ✓'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
