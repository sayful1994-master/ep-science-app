import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class QuestionsAdminScreen extends StatefulWidget {
  const QuestionsAdminScreen({super.key});

  @override
  State<QuestionsAdminScreen> createState() => _QuestionsAdminScreenState();
}

class _QuestionsAdminScreenState extends State<QuestionsAdminScreen> {
  String _filter = '';
  String? _subjectFilter;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    var qs = data.allQuestions.toList().reversed.toList();
    if (_filter.isNotEmpty) {
      qs = qs
          .where(
            (q) => q.questionText.toLowerCase().contains(_filter.toLowerCase()),
          )
          .toList();
    }
    if (_subjectFilter != null) {
      qs = qs.where((q) => q.subjectId == _subjectFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রশ্নব্যাংক ম্যানেজমেন্ট'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () => _openBulkUpload(context),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('বাল্ক CSV আপলোড'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('নতুন প্রশ্ন'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: const InputDecoration(
                      hintText: 'প্রশ্ন খুঁজুন...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _subjectFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'বিষয় ফিল্টার',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('সব বিষয়'),
                      ),
                      ...data.subjects.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _subjectFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: qs.isEmpty
                ? const EmptyState(
                    icon: Icons.quiz_outlined,
                    message: 'কোনো প্রশ্ন পাওয়া যায়নি',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: qs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _questionCard(context, data, qs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(BuildContext context, DataProvider data, Question q) {
    final subj = data.subject(q.subjectId);
    final ch = data.chapter(q.chapterId);
    return Container(
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
              Pill(
                q.generatedBy == 'Generator' ? 'জেনারেটেড' : 'ম্যানুয়াল',
                color: q.generatedBy == 'Generator'
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                icon: q.generatedBy == 'Generator'
                    ? Icons.auto_awesome
                    : Icons.edit,
              ),
              const SizedBox(width: 6),
              Pill(q.difficultyLevel, color: AppColors.gold),
              const SizedBox(width: 6),
              if (q.isPremium)
                const Pill('প্রিমিয়াম', color: AppColors.teal, filled: true),
              const Spacer(),
              Text(
                'উত্তর: ${q.correctAnswer}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.questionText,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            '${subj?.name ?? "-"} • ${ch?.name ?? "-"}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Pill('A. ${_cut(q.optionA)}'),
              const SizedBox(width: 6),
              Pill('B. ${_cut(q.optionB)}'),
              const SizedBox(width: 6),
              Pill('C. ${_cut(q.optionC)}'),
              const SizedBox(width: 6),
              Pill('D. ${_cut(q.optionD)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _openEditor(context, existing: q),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final provider = context.read<DataProvider>();
                  final ok = await _confirm(
                    context,
                    'প্রশ্নটি ডিলিট করতে চান?',
                  );
                  if (ok) await provider.deleteQuestion(q.id);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cut(String s) => s.length > 14 ? '${s.substring(0, 14)}…' : s;

  Future<bool> _confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('নিশ্চিত করুন'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('না'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('হ্যাঁ'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _openEditor(BuildContext context, {Question? existing}) {
    showDialog(
      context: context,
      builder: (_) => _QuestionEditor(existing: existing),
    );
  }

  void _openBulkUpload(BuildContext context) {
    showDialog(context: context, builder: (_) => const _BulkUploadDialog());
  }
}

// ─────────────────────────────────────────────────────────────
class _QuestionEditor extends StatefulWidget {
  final Question? existing;
  const _QuestionEditor({this.existing});

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late DataProvider data;
  late String? categoryId;
  late String? subCategoryId;
  late String? subjectId;
  late String? chapterId;

  final _qt = TextEditingController();
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _c = TextEditingController();
  final _d = TextEditingController();
  final _e = TextEditingController();
  final _expl = TextEditingController();
  final _tag = TextEditingController();
  String _answer = 'A';
  String _difficulty = 'Medium';
  bool _premium = true;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _qt.text = q?.questionText ?? '';
    _a.text = q?.optionA ?? '';
    _b.text = q?.optionB ?? '';
    _c.text = q?.optionC ?? '';
    _d.text = q?.optionD ?? '';
    _e.text = q?.optionE ?? '';
    _expl.text = q?.explanation ?? '';
    _tag.text = q?.examTag ?? '';
    _answer = q?.correctAnswer ?? 'A';
    _difficulty = q?.difficultyLevel ?? 'Medium';
    _premium = q?.isPremium ?? true;
    categoryId = q?.categoryId;
    subCategoryId = q?.subCategoryId;
    subjectId = q?.subjectId;
    chapterId = q?.chapterId;
  }

  @override
  void dispose() {
    _qt.dispose();
    _a.dispose();
    _b.dispose();
    _c.dispose();
    _d.dispose();
    _e.dispose();
    _expl.dispose();
    _tag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    data = context.watch<DataProvider>();
    final subs = categoryId == null
        ? <SubCategory>[]
        : data.subCategoriesOf(categoryId!);
    final subjects = subCategoryId == null
        ? <Subject>[]
        : data.subjectsOf(subCategoryId!);
    final chapters = subjectId == null
        ? <Chapter>[]
        : data.chaptersOf(subjectId!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'নতুন প্রশ্ন যোগ করুন'
                    : 'প্রশ্ন সম্পাদনা',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              'ক্যাটাগরি',
                              categoryId,
                              data.categories
                                  .map<DropdownMenuItem<String>>(
                                    (c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              (v) {
                                setState(() {
                                  categoryId = v;
                                  subCategoryId = null;
                                  subjectId = null;
                                  chapterId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'সাব-ক্যাটাগরি',
                              subCategoryId,
                              subs
                                  .map<DropdownMenuItem<String>>(
                                    (s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ),
                                  )
                                  .toList(),
                              (v) {
                                setState(() {
                                  subCategoryId = v;
                                  subjectId = null;
                                  chapterId = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              'বিষয়',
                              subjectId,
                              subjects
                                  .map<DropdownMenuItem<String>>(
                                    (s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ),
                                  )
                                  .toList(),
                              (v) {
                                setState(() {
                                  subjectId = v;
                                  chapterId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'অধ্যায়',
                              chapterId,
                              chapters
                                  .map<DropdownMenuItem<String>>(
                                    (c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              (v) => setState(() => chapterId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qt,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'প্রশ্ন'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _opt(_a, 'অপশন A')),
                          const SizedBox(width: 10),
                          Expanded(child: _opt(_b, 'অপশন B')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _opt(_c, 'অপশন C')),
                          const SizedBox(width: 10),
                          Expanded(child: _opt(_d, 'অপশন D')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _opt(_e, 'অপশন E (ঐচ্ছিক)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _ddAnswer()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _difficulty,
                              decoration: const InputDecoration(
                                labelText: 'কাঠিন্য',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Easy',
                                  child: Text('Easy'),
                                ),
                                DropdownMenuItem(
                                  value: 'Medium',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem(
                                  value: 'Hard',
                                  child: Text('Hard'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _difficulty = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tag,
                        decoration: const InputDecoration(
                          labelText: 'পরীক্ষার ট্যাগ (যেমন: 45th BCS)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _expl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ব্যাখ্যা (Step-by-step)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _premium,
                        onChanged: (v) => setState(() => _premium = v),
                        title: const Text(
                          'প্রিমিয়াম কনটেন্ট',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'ফ্রি ইউজাররা এটি লকড দেখবে',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বাতিল'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('সংরক্ষণ করুন'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opt(TextEditingController c, String label) => TextField(
    controller: c,
    decoration: InputDecoration(labelText: label, isDense: true),
  );

  Widget _dd(
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

  Widget _ddAnswer() => DropdownButtonFormField<String>(
    initialValue: _answer,
    decoration: const InputDecoration(labelText: 'সঠিক উত্তর', isDense: true),
    items: const [
      DropdownMenuItem(value: 'A', child: Text('A')),
      DropdownMenuItem(value: 'B', child: Text('B')),
      DropdownMenuItem(value: 'C', child: Text('C')),
      DropdownMenuItem(value: 'D', child: Text('D')),
      DropdownMenuItem(value: 'E', child: Text('E')),
    ],
    onChanged: (v) => setState(() => _answer = v!),
  );

  Future<void> _save() async {
    if (categoryId == null ||
        subCategoryId == null ||
        subjectId == null ||
        chapterId == null ||
        _qt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'সব প্রয়োজনীয় ফিল্ড পূরণ করুন (শ্রেণিবিন্যাস + প্রশ্ন)',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final q = Question(
      id: widget.existing?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: categoryId!,
      subCategoryId: subCategoryId!,
      subjectId: subjectId!,
      chapterId: chapterId!,
      questionText: _qt.text.trim(),
      optionA: _a.text.trim(),
      optionB: _b.text.trim(),
      optionC: _c.text.trim(),
      optionD: _d.text.trim(),
      optionE: _e.text.trim(),
      correctAnswer: _answer,
      explanation: _expl.text.trim(),
      examTag: _tag.text.trim(),
      difficultyLevel: _difficulty,
      isPremium: _premium,
      generatedBy: widget.existing?.generatedBy ?? 'Manual',
    );
    await context.read<DataProvider>().saveQuestion(q);
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────
class _BulkUploadDialog extends StatefulWidget {
  const _BulkUploadDialog();

  @override
  State<_BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<_BulkUploadDialog> {
  final _csv = TextEditingController();
  String? categoryId;
  String? subCategoryId;
  String? subjectId;
  String? chapterId;
  String _result = '';
  bool _premium = true;

  static const _sample =
      'question_text,option_a,option_b,option_c,option_d,'
      'correct_answer,explanation,exam_tag,difficulty_level\n'
      '"পদার্থের গতিশক্তি কার উপর নির্ভর করে?","ভর ও বেগ","শুধু ভর",'
      '"শুধু বেগ","তাপমাত্রা","A","KE = ½mv², তাই ভর ও বেগের উপর নির্ভর করে।",'
      '"একাদশ-দ্বাদশ","Easy"\n';

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'বাল্ক CSV / Excel আপলোড',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Excel থেকে CSV হিসেবে সেভ করে নিচে পেস্ট করুন। টার্গেট অধ্যায় নির্বাচন করুন।',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _dd(
                      'ক্যাটাগরি',
                      categoryId,
                      data.categories
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() {
                        categoryId = v;
                        subCategoryId = null;
                        subjectId = null;
                        chapterId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dd(
                      'সাব-ক্যাটাগরি',
                      subCategoryId,
                      subs
                          .map<DropdownMenuItem<String>>(
                            (s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() {
                        subCategoryId = v;
                        subjectId = null;
                        chapterId = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dd(
                      'বিষয়',
                      subjectId,
                      subjects
                          .map<DropdownMenuItem<String>>(
                            (s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() {
                        subjectId = v;
                        chapterId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dd(
                      'অধ্যায়',
                      chapterId,
                      chapters
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      (v) => setState(() => chapterId = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _premium,
                onChanged: (v) => setState(() => _premium = v),
                title: const Text(
                  'প্রিমিয়াম হিসেবে চিহ্নিত করুন',
                  style: TextStyle(fontSize: 13.5),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _csv.text = _sample),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text(
                      'স্যাম্পল লোড করুন',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CSV ফরম্যাট: question_text, option_a...',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _csv,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'CSV ডেটা এখানে পেস্ট করুন...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              if (_result.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _result,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বাতিল'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _parse,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('পার্স করুন ও আমদানি'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dd(
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

  Future<void> _parse() async {
    if (chapterId == null || subjectId == null) {
      setState(() => _result = '⚠️ আগে বিষয় ও অধ্যায় নির্বাচন করুন।');
      return;
    }
    final rows = _parseCsv(_csv.text);
    if (rows.isEmpty) {
      setState(() => _result = '⚠️ কোনো বৈধ সারি পাওয়া যায়নি।');
      return;
    }
    final data = context.read<DataProvider>();
    final subj = data.subject(subjectId!)!;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final qs = <Question>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if ((r['question_text'] ?? '').isEmpty) continue;
      qs.add(
        Question(
          id: 'q_csv_${stamp}_$i',
          categoryId: categoryId!,
          subCategoryId: subCategoryId!,
          subjectId: subjectId!,
          chapterId: chapterId!,
          questionText: r['question_text'] ?? '',
          optionA: r['option_a'] ?? '',
          optionB: r['option_b'] ?? '',
          optionC: r['option_c'] ?? '',
          optionD: r['option_d'] ?? '',
          optionE: r['option_e'] ?? '',
          correctAnswer: (r['correct_answer'] ?? 'A').toUpperCase(),
          explanation: r['explanation'] ?? '',
          examTag: r['exam_tag'] ?? 'Bulk Import',
          difficultyLevel: r['difficulty_level'] ?? 'Medium',
          isPremium: _premium,
          generatedBy: 'Manual',
        ),
      );
    }
    await data.bulkAddQuestions(qs);
    if (mounted) {
      setState(
        () => _result =
            '✅ ${qs.length}টি প্রশ্ন সফলভাবে আমদানি হয়েছে (${subj.name})।',
      );
    }
  }

  List<Map<String, String>> _parseCsv(String text) {
    final lines = text
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return [];
    List<String> split(String line) {
      final out = <String>[];
      final buf = StringBuffer();
      var inQuotes = false;
      for (var i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
        } else if (ch == ',' && !inQuotes) {
          out.add(buf.toString().trim());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
      out.add(buf.toString().trim());
      return out;
    }

    final headers = split(lines.first).map((h) => h.toLowerCase()).toList();
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = split(lines[i]);
      final map = <String, String>{};
      for (var c = 0; c < headers.length && c < cols.length; c++) {
        map[headers[c]] = cols[c];
      }
      rows.add(map);
    }
    return rows;
  }
}
