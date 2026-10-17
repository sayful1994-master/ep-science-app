import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Book / e-library management.
///
/// Flow: pick the CLASS (category → sub-category) first, then publish a book
/// by pasting a public cloud link (Google Drive / any external URL). Each book
/// is owned by a teacher — that teacher gets access + becomes the approver of
/// user access requests for the book.
class BooksAdminScreen extends StatefulWidget {
  const BooksAdminScreen({super.key});

  @override
  State<BooksAdminScreen> createState() => _BooksAdminScreenState();
}

class _BooksAdminScreenState extends State<BooksAdminScreen> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final books = _categoryFilter == null
        ? data.ebooks
        : data.ebooks.where((b) => b.categoryId == _categoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('বই ও লাইব্রেরি'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_link, size: 16),
              label: const Text('বই প্রকাশ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _categoryFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'ক্যাটাগরি অনুযায়ী ফিল্টার',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('সব ক্যাটাগরি'),
                      ),
                      ...data.categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: books.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_outlined,
                    message: 'কোনো বই প্রকাশ করা হয়নি',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _bookCard(context, data, books[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bookCard(BuildContext context, DataProvider data, Ebook b) {
    final subCat = data.subCategory(b.subCategoryId);
    final subj = data.subject(b.subjectId);
    final owner = data.teacher(b.ownerTeacherId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  color: _hex(b.coverColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      '${subCat?.name ?? "-"} • ${subj?.name ?? "-"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    if (owner != null)
                      Text(
                        'মালিক: ${owner.name}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (b.requiresPayment)
                Pill('৳${b.price.toStringAsFixed(0)}', color: AppColors.gold, filled: true)
              else
                const Pill('ফ্রি', color: AppColors.green, filled: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.link, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b.externalUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              Pill(b.fileType.toUpperCase(), color: AppColors.navy),
              if (b.isPremium)
                const Pill('প্রিমিয়াম', color: AppColors.teal),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openEditor(context, existing: b),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('সম্পাদনা', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    '“${b.title}” মুছে ফেলতে চান?',
                  );
                  if (!context.mounted) return;
                  if (ok) await data.deleteEbook(b.id);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'মুছুন',
                  style: TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _hex(String h) {
    final s = h.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  void _openEditor(BuildContext context, {Ebook? existing}) {
    showDialog(
      context: context,
      builder: (_) => _BookEditor(existing: existing),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    final result = await showDialog<bool>(
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
    return result;
  }
}

// ─────────────────────────────────────────────────────────────
class _BookEditor extends StatefulWidget {
  final Ebook? existing;
  const _BookEditor({this.existing});

  @override
  State<_BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<_BookEditor> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _pages = TextEditingController(text: '100');
  final _price = TextEditingController(text: '0');

  String? categoryId;
  String? subCategoryId;
  String? subjectId;
  String? ownerTeacherId;
  String _fileType = 'pdf';
  bool _premium = true;
  bool _requiresPayment = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _title.text = b?.title ?? '';
    _description.text = b?.description ?? '';
    _url.text = b?.externalUrl ?? '';
    _pages.text = (b?.pages ?? 100).toString();
    _price.text = b?.price.toStringAsFixed(0) ?? '0';
    categoryId = b?.categoryId;
    subCategoryId = b?.subCategoryId;
    subjectId = b?.subjectId;
    ownerTeacherId = b?.ownerTeacherId;
    _fileType = b?.fileType ?? 'pdf';
    _premium = b?.isPremium ?? true;
    _requiresPayment = b?.requiresPayment ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    _pages.dispose();
    _price.dispose();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'নতুন বই প্রকাশ করুন' : 'বই সম্পাদনা',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'প্রথমে ক্লাস (ক্যাটাগরি → সাব-ক্যাটাগরি) নির্বাচন করুন, তারপর পাবলিক লিংক দিন।',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                              'ক্যাটাগরি *',
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
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'ক্লাস / সাব-ক্যাটাগরি *',
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
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dd(
                        'বিষয় (ঐচ্ছিক)',
                        subjectId,
                        subjects
                            .map<DropdownMenuItem<String>>(
                              (s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        (v) => setState(() => subjectId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'বইয়ের নাম *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'সংক্ষিপ্ত বিবরণ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _url,
                        decoration: const InputDecoration(
                          labelText: 'পাবলিক ডকুমেন্ট লিংক (Drive / URL) *',
                          hintText: 'https://drive.google.com/...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dd(
                        'মালিক শিক্ষক (যিনি আপলোড করেছেন)',
                        ownerTeacherId,
                        [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('E&P Science (Admin)'),
                          ),
                          ...data.approvedTeachers.map(
                            (t) => DropdownMenuItem<String>(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          ),
                        ],
                        (v) => setState(() => ownerTeacherId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              'ফাইল টাইপ',
                              _fileType,
                              const [
                                DropdownMenuItem(
                                  value: 'pdf',
                                  child: Text('PDF'),
                                ),
                                DropdownMenuItem(
                                  value: 'doc',
                                  child: Text('Document'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Other'),
                                ),
                              ],
                              (v) => setState(() => _fileType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pages,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'পৃষ্ঠা সংখ্যা',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _price,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'মূল্য (৳)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _requiresPayment,
                              onChanged: (v) => setState(() => _requiresPayment = v),
                              title: const Text(
                                'পেমেন্ট প্রয়োজন',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _premium,
                        onChanged: (v) => setState(() => _premium = v),
                        title: const Text(
                          'প্রিমিয়াম কনটেন্ট',
                          style: TextStyle(fontSize: 13.5),
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
                  ElevatedButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.publish, size: 16),
                    label: const Text('প্রকাশ করুন'),
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

  Future<void> _save(BuildContext context) async {
    if (categoryId == null ||
        subCategoryId == null ||
        _title.text.trim().isEmpty ||
        _url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ক্যাটাগরি, ক্লাস, নাম ও লিংক অবশ্যই দিতে হবে'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final data = context.read<DataProvider>();
    final owner = ownerTeacherId ?? '';
    final ownerName =
        owner.isEmpty ? 'E&P Science' : (data.teacher(owner)?.name ?? 'E&P Science');
    final b = Ebook(
      id: widget.existing?.id ?? 'book_${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      author: ownerName,
      ownerTeacherId: owner,
      description: _description.text.trim(),
      coverColor: widget.existing?.coverColor ?? '#12324F',
      pages: int.tryParse(_pages.text.trim()) ?? 100,
      price: double.tryParse(_price.text.trim()) ?? 0,
      isPremium: _premium,
      requiresPayment: _requiresPayment,
      externalUrl: _url.text.trim(),
      fileType: _fileType,
      categoryId: categoryId!,
      subCategoryId: subCategoryId!,
      subjectId: subjectId ?? '',
      createdAt: widget.existing?.createdAt,
    );
    await data.saveEbook(b);
    if (!mounted) return;
    Navigator.pop(context);
  }
}
