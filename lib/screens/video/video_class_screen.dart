import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paywall.dart';
import 'video_player_screen.dart';

/// ভিডিও ক্লাস — class/subject filters + in-app playback.
class VideoClassScreen extends StatefulWidget {
  const VideoClassScreen({super.key});

  @override
  State<VideoClassScreen> createState() => _VideoClassScreenState();
}

class _VideoClassScreenState extends State<VideoClassScreen> {
  String? _classId;
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final videos = data.videosFiltered(classId: _classId, subjectId: _subjectId);

    // Build filter option sets from active videos.
    final classSet = <String, String>{};
    final subjectSet = <String, String>{};
    for (final v in data.activeVideos) {
      if (v.classId.isNotEmpty) classSet[v.classId] = v.className;
      if (v.subjectId.isNotEmpty) subjectSet[v.subjectId] = v.subjectName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ভিডিও ক্লাস')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        child: Text('সব ক্লাস'),
                      ),
                      ...classSet.entries.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _classId = v),
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
                        child: Text('সব বিষয়'),
                      ),
                      ...subjectSet.entries.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _subjectId = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: videos.isEmpty
                ? const EmptyState(
                    icon: Icons.video_library_outlined,
                    message: 'এই ফিল্টারে কোনো ভিডিও ক্লাস নেই',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _videoCard(context, videos[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(BuildContext context, VideoClass v) {
    final auth = context.watch<AuthProvider>();
    final locked = v.isPremium && !auth.isPremium;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (locked) {
          Paywall.show(context);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    v.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.navy,
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white70,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 34),
                      ),
                    ),
                  )
                else
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (v.className.isNotEmpty)
                        Pill(v.className, color: AppColors.primaryBlue),
                      if (v.subjectName.isNotEmpty)
                        Pill(v.subjectName, color: AppColors.teal),
                      if (v.isPremium)
                        const Pill('প্রিমিয়াম', color: AppColors.gold, filled: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
