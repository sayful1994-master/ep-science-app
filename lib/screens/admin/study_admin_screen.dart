import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../services/youtube_utils.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Admin — স্টাডি কনটেন্ট ব্যবস্থাপনা.
///
/// Two tabs:
///  1. স্টাডি কনটেন্ট — publish NOTES / LECTURE sheets / SUGGESTIONS / GUIDES
///     under the full NCTB + Job-Prep hierarchy
///     (ক্যাটাগরি → ক্লাস/স্ট্রিম → বিষয় → অধ্যায়) with a public document link.
///  2. অধ্যায়ভিত্তিক ভিডিও — attach a YouTube class video to a specific
///     chapter (in addition to the standalone ভিডিও ক্লাস screen).
///
/// Everything is organised by section/category so students can STUDY the
/// whole syllabus inside the app.
class StudyAdminScreen extends StatelessWidget {
  const StudyAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('স্টাডি কনটেন্ট'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ডকুমেন্ট / নোট', icon: Icon(Icons.description_outlined)),
              Tab(text: 'অধ্যায়ভিত্তিক ভিডিও', icon: Icon(Icons.video_library_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ResourcesTab(), _ChapterVideosTab()],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — study resources (notes / lectures / suggestions / guides)
// ─────────────────────────────────────────────────────────────
class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final list = data.allStudyResources;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _ResourceEditor(),
        ),
        icon: const Icon(Icons.upload_file),
        label: const Text('নতুন কনটেন্ট'),
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.description_outlined,
              message: 'কোনো স্টাডি কনটেন্ট আপলোড করা হয়নি\n'
                  'ক্যাটাগরি → ক্লাস → বিষয় অনুযায়ী ডকুমেন্ট / নোট যুক্ত করুন',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _resourceCard(context, data, list[i]),
            ),
    );
  }

  Widget _resourceCard(BuildContext context, DataProvider data, StudyResource r) {
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(r.type), color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      _crumbs(data, r),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (r.isPremium)
                const Pill('প্রিমিয়াম', color: AppColors.gold),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.description,
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(_typeLabel(r.type), color: AppColors.navy),
              Pill(r.fileType.toUpperCase(), color: AppColors.primaryBlue),
              if (r.chapterName.isNotEmpty)
                Pill(r.chapterName, color: AppColors.teal),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _ResourceEditor(existing: r),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('সম্পাদনা', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () => data.deleteStudyResource(r.id),
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.danger),
                label: const Text('মুছুন',
                    style: TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _crumbs(DataProvider data, StudyResource r) {
    final sub = data.subCategory(r.subCategoryId);
    final subj = data.subject(r.subjectId);
    return [
      sub?.name ?? r.subCategoryName,
      subj?.name ?? r.subjectName,
    ].where((s) => s.isNotEmpty).join(' • ');
  }

  static IconData _typeIcon(String t) {
    switch (t) {
      case 'lecture':
        return Icons.co_present_outlined;
      case 'suggestion':
        return Icons.tips_and_updates_outlined;
      case 'guide':
        return Icons.auto_stories_outlined;
      default:
        return Icons.sticky_note_2_outlined;
    }
  }

  static String _typeLabel(String t) {
    switch (t) {
      case 'lecture':
        return 'লেকচার শিট';
      case 'suggestion':
        return 'সাজেশন';
      case 'guide':
        return 'গাইড';
      default:
        return 'নোট';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Resource editor dialog
// ─────────────────────────────────────────────────────────────
class _ResourceEditor extends StatefulWidget {
  final StudyResource? existing;
  const _ResourceEditor({this.existing});

  @override
  State<_ResourceEditor> createState() => _ResourceEditorState();
}

class _ResourceEditorState extends State<_ResourceEditor> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();

  String? categoryId;
  String? subCategoryId;
  String? subjectId;
  String? chapterId;
  String _type = 'note';
  String _fileType = 'pdf';
  bool _premium = true;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _title.text = r?.title ?? '';
    _desc.text = r?.description ?? '';
    _url.text = r?.fileUrl ?? (r?.externalUrl ?? '');
    categoryId = r?.categoryId;
    subCategoryId = r?.subCategoryId;
    subjectId = r?.subjectId;
    chapterId = (r?.chapterId.isEmpty ?? true) ? null : r?.chapterId;
    _type = r?.type ?? 'note';
    _fileType = r?.fileType ?? 'pdf';
    _premium = r?.isPremium ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final subs = categoryId == null
        ? <SubCategory>[]
        : data.subCategoriesOf(categoryId!);
    final subjects =
        subCategoryId == null ? <Subject>[] : data.subjectsOf(subCategoryId!);
    final chapters =
        subjectId == null ? <Chapter>[] : data.chaptersOf(subjectId!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'নতুন স্টাডি কনটেন্ট আপলোড'
                    : 'স্টাডি কনটেন্ট সম্পাদনা',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'সেকশন অনুযায়ী ক্যাটাগরি → ক্লাস/স্ট্রিম → বিষয় (→ অধ্যায়) '
                'নির্বাচন করে ডকুমেন্টের পাবলিক লিংক দিন।',
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
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ))
                                  .toList(),
                              (v) => setState(() {
                                categoryId = v;
                                subCategoryId = null;
                                subjectId = null;
                                chapterId = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'ক্লাস / স্ট্রিম *',
                              subCategoryId,
                              subs
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
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
                      const SizedBox(height: 12),
                      _dd(
                        'বিষয় *',
                        subjectId,
                        subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        (v) => setState(() {
                          subjectId = v;
                          chapterId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _dd(
                        'অধ্যায় (ঐচ্ছিক)',
                        chapterId,
                        chapters
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        (v) => setState(() => chapterId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              'কনটেন্ট ধরন',
                              _type,
                              const [
                                DropdownMenuItem(
                                    value: 'note', child: Text('নোট')),
                                DropdownMenuItem(
                                    value: 'lecture', child: Text('লেকচার শিট')),
                                DropdownMenuItem(
                                    value: 'suggestion', child: Text('সাজেশন')),
                                DropdownMenuItem(
                                    value: 'guide', child: Text('গাইড')),
                              ],
                              (v) => setState(() => _type = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'ফাইল টাইপ',
                              _fileType,
                              const [
                                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                                DropdownMenuItem(
                                    value: 'doc', child: Text('Document')),
                                DropdownMenuItem(
                                    value: 'image', child: Text('Image')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Other')),
                              ],
                              (v) => setState(() => _fileType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'শিরোনাম *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _desc,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'সংক্ষিপ্ত বিবরণ'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _url,
                        decoration: const InputDecoration(
                          labelText: 'ডকুমেন্ট লিংক (Drive / URL) *',
                          hintText: 'https://drive.google.com/...',
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _premium,
                        activeThumbColor: AppColors.gold,
                        title: const Text('প্রিমিয়াম কনটেন্ট',
                            style: TextStyle(fontSize: 13.5)),
                        subtitle: const Text(
                          'ফ্রি সদস্যরা লকড দেখবে, প্রিমিয়াম সদস্যরা পড়তে পারবে',
                          style: TextStyle(fontSize: 11),
                        ),
                        onChanged: (v) => setState(() => _premium = v),
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
        subjectId == null ||
        _title.text.trim().isEmpty ||
        _url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ক্যাটাগরি, ক্লাস, বিষয়, শিরোনাম ও লিংক অবশ্যই দিতে হবে'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final data = context.read<DataProvider>();
    final sub = data.subCategory(subCategoryId!);
    final subj = data.subject(subjectId!);
    final ch = chapterId == null ? null : data.chapter(chapterId!);
    final r = StudyResource(
      id: widget.existing?.id ??
          'sr_${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      type: _type,
      description: _desc.text.trim(),
      fileUrl: _url.text.trim(),
      fileType: _fileType,
      isPremium: _premium,
      categoryId: categoryId!,
      subCategoryId: subCategoryId!,
      subCategoryName: sub?.name ?? '',
      streamKey: subj?.stream ?? '',
      subjectId: subjectId!,
      subjectName: subj?.name ?? '',
      chapterId: ch?.id ?? '',
      chapterName: ch?.name ?? '',
      createdAt: widget.existing?.createdAt,
    );
    await data.saveStudyResource(r);
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — chapter videos (YouTube link attached to a chapter)
// ─────────────────────────────────────────────────────────────
class _ChapterVideosTab extends StatelessWidget {
  const _ChapterVideosTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final list = data.allVideos;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _VideoEditor(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('ভিডিও যুক্ত করুন'),
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.video_library_outlined,
              message: 'কোনো অধ্যায়ভিত্তিক ভিডিও নেই\n'
                  'ক্লাস → বিষয় → অধ্যায় নির্বাচন করে YouTube লিংক দিন',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _videoCard(context, data, list[i]),
            ),
    );
  }

  Widget _videoCard(BuildContext context, DataProvider data, VideoClass v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              v.thumbnail,
              width: 84,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 48,
                color: AppColors.navy,
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (v.className.isNotEmpty)
                      Pill(v.className, color: AppColors.primaryBlue),
                    if (v.subjectName.isNotEmpty)
                      Pill(v.subjectName, color: AppColors.teal),
                    if (v.chapterName.isNotEmpty)
                      Pill(v.chapterName, color: AppColors.gold),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: v.isActive,
                activeThumbColor: AppColors.green,
                onChanged: (val) => data.saveVideo(v.copyWith(isActive: val)),
              ),
              IconButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _VideoEditor(existing: v),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'মুছে ফেলুন',
                onPressed: () => data.deleteVideo(v.id),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoEditor extends StatefulWidget {
  final VideoClass? existing;
  const _VideoEditor({this.existing});

  @override
  State<_VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<_VideoEditor> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _desc = TextEditingController();

  String? categoryId;
  String? subCategoryId;
  String? subjectId;
  String? chapterId;
  bool _premium = true;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _title.text = v?.title ?? '';
    _url.text = v?.url ?? '';
    _desc.text = v?.description ?? '';
    categoryId = (v?.categoryId.isEmpty ?? true) ? null : v?.categoryId;
    subCategoryId = (v?.classId.isEmpty ?? true) ? null : v?.classId;
    subjectId = (v?.subjectId.isEmpty ?? true) ? null : v?.subjectId;
    chapterId = (v?.chapterId.isEmpty ?? true) ? null : v?.chapterId;
    _premium = v?.isPremium ?? true;
    _active = v?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final subs = categoryId == null
        ? <SubCategory>[]
        : data.subCategoriesOf(categoryId!);
    final subjects =
        subCategoryId == null ? <Subject>[] : data.subjectsOf(subCategoryId!);
    final chapters =
        subjectId == null ? <Chapter>[] : data.chaptersOf(subjectId!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'অধ্যায়ভিত্তিক ভিডিও যুক্ত করুন'
                    : 'ভিডিও সম্পাদনা',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'শুধু YouTube লিংক দিন — ভিডিও ফাইল অ্যাপে সংরক্ষণ হয় না।',
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
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ))
                                  .toList(),
                              (v) => setState(() {
                                categoryId = v;
                                subCategoryId = null;
                                subjectId = null;
                                chapterId = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'ক্লাস / স্ট্রিম *',
                              subCategoryId,
                              subs
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dd(
                              'বিষয় *',
                              subjectId,
                              subjects
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              (v) => setState(() {
                                subjectId = v;
                                chapterId = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dd(
                              'অধ্যায় (ঐচ্ছিক)',
                              chapterId,
                              chapters
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              (v) => setState(() => chapterId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'শিরোনাম *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _url,
                        decoration: const InputDecoration(
                          labelText: 'YouTube লিংক *',
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_url.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _preview(_url.text),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _desc,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'বর্ণনা (ঐচ্ছিক)'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _premium,
                        activeThumbColor: AppColors.gold,
                        title: const Text('প্রিমিয়াম ভিডিও',
                            style: TextStyle(fontSize: 13.5)),
                        onChanged: (v) => setState(() => _premium = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _active,
                        activeThumbColor: AppColors.green,
                        title: const Text('সক্রিয় (ছাত্ররা দেখতে পারবে)',
                            style: TextStyle(fontSize: 13.5)),
                        onChanged: (v) => setState(() => _active = v),
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

  Widget _preview(String raw) {
    final id = parseYoutubeId(raw);
    if (id == null) {
      return const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text('সঠিক YouTube লিংক নয়',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        ],
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            youtubeThumb(id),
            width: 96,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 96,
              height: 54,
              color: AppColors.navy,
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Video ID: $id',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
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
    final vid = parseYoutubeId(_url.text);
    if (subCategoryId == null ||
        subjectId == null ||
        _title.text.trim().isEmpty ||
        vid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ক্লাস, বিষয়, শিরোনাম ও সঠিক YouTube লিংক দিন'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final data = context.read<DataProvider>();
    final sub = data.subCategory(subCategoryId!);
    final subj = data.subject(subjectId!);
    final ch = chapterId == null ? null : data.chapter(chapterId!);
    await data.saveVideo(
      VideoClass(
        id: widget.existing?.id ??
            'vid_${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        videoId: vid,
        url: _url.text.trim(),
        categoryId: sub?.categoryId ?? categoryId ?? '',
        classId: subCategoryId!,
        className: sub?.name ?? '',
        subjectId: subjectId!,
        subjectName: subj?.name ?? '',
        chapterId: ch?.id ?? '',
        chapterName: ch?.name ?? '',
        description: _desc.text.trim(),
        isPremium: _premium,
        isActive: _active,
        createdAt: widget.existing?.createdAt,
      ),
    );
    if (context.mounted) Navigator.pop(context);
  }
}
