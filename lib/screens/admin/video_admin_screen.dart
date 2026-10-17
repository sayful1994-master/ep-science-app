import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../services/youtube_utils.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Admin — publish & manage ভিডিও ক্লাস.
///
/// Only lightweight metadata is stored (video_id, title, class_name,
/// subject_name, created_at) — the video itself stays on YouTube, so hosting
/// cost is ZERO.
class VideoAdminScreen extends StatefulWidget {
  const VideoAdminScreen({super.key});

  @override
  State<VideoAdminScreen> createState() => _VideoAdminScreenState();
}

class _VideoAdminScreenState extends State<VideoAdminScreen> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _desc = TextEditingController();
  String? _classId;
  String? _subjectId;
  bool _isPremium = true;

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
    final subs = data.subCategories;
    final subjectOptions = _classId == null
        ? <Subject>[]
        : data.subjectsOf(_classId!);

    return Scaffold(
      appBar: AppBar(title: const Text('ভিডিও ক্লাস ব্যবস্থাপনা')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.play_circle_outline,
                        color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'নতুন ভিডিও ক্লাস প্রকাশ করুন',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'শুধু YouTube লিংক দিন — ভিডিও ফাইল অ্যাপে সংরক্ষণ হয় না।',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'শিরোনাম',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'YouTube লিংক (watch / shorts / youtu.be)',
                    isDense: true,
                    prefixIcon: Icon(Icons.link, size: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_url.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _urlPreview(_url.text),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _classId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ক্লাস / ব্যাচ',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('নির্বাচন করুন'),
                          ),
                          ...subs.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _classId = v;
                          _subjectId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _subjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'বিষয়',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('নির্বাচন করুন'),
                          ),
                          ...subjectOptions.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _subjectId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'বর্ণনা (ঐচ্ছিক)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPremium,
                  activeThumbColor: AppColors.gold,
                  title: const Text('প্রিমিয়াম ক্লাস', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text(
                    'শুধু প্রিমিয়াম সাবস্ক্রাইবার দেখতে পারবে',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: (v) => setState(() => _isPremium = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _publish(context, data),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('প্রকাশ করুন'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle('প্রকাশিত ভিডিও (${data.allVideos.length})'),
          if (data.allVideos.isEmpty)
            const EmptyState(
              icon: Icons.video_library_outlined,
              message: 'এখনো কোনো ভিডিও ক্লাস প্রকাশ করা হয়নি',
            )
          else
            for (final v in data.allVideos) _videoRow(context, data, v),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _urlPreview(String raw) {
    final id = parseYoutubeId(raw);
    if (id == null) {
      return Row(
        children: const [
          Icon(Icons.error_outline, color: AppColors.danger, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'সঠিক YouTube লিংক নয়',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
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
          child: Text(
            'Video ID: $id',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _videoRow(BuildContext context, DataProvider data, VideoClass v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
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
                    Pill(
                      v.isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়',
                      color: v.isActive ? AppColors.green : AppColors.textSecondary,
                    ),
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
                onChanged: (val) =>
                    data.saveVideo(v.copyWith(isActive: val)),
              ),
              IconButton(
                tooltip: 'মুছে ফেলুন',
                onPressed: () => _confirmDelete(context, data, v),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DataProvider data, VideoClass v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ভিডিও মুছবেন?'),
        content: Text(v.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('মুছুন', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await data.deleteVideo(v.id);
  }

  Future<void> _publish(BuildContext context, DataProvider data) async {
    final id = parseYoutubeId(_url.text);
    if (_title.text.trim().isEmpty || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শিরোনাম ও সঠিক YouTube লিংক দিন'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final sub = _classId == null ? null : data.subCategory(_classId!);
    final subject = _subjectId == null ? null : data.subject(_subjectId!);
    await data.saveVideo(
      VideoClass(
        id: 'vid_${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        videoId: id,
        url: _url.text.trim(),
        categoryId: sub?.categoryId ?? '',
        classId: _classId ?? '',
        className: sub?.name ?? '',
        subjectId: _subjectId ?? '',
        subjectName: subject?.name ?? '',
        description: _desc.text.trim(),
        isPremium: _isPremium,
      ),
    );
    _title.clear();
    _url.clear();
    _desc.clear();
    setState(() {
      _classId = null;
      _subjectId = null;
      _isPremium = true;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ভিডিও ক্লাস প্রকাশিত হয়েছে ✓'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
