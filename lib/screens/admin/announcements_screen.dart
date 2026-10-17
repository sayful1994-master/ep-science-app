import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Announcements — home-page popup notices pushed by the admin.
///
/// Every active announcement pops up on the user's home screen once per
/// session. Admin can publish new notices here.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final all = data.allAnnouncements;

    return Scaffold(
      appBar: AppBar(title: const Text('ঘোষণা / পপআপ নোটিশ')),
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
                    Icon(Icons.campaign_outlined, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'নতুন ঘোষণা প্রকাশ করুন',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
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
                  controller: _body,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'বার্তা',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
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
          SectionTitle('প্রকাশিত ঘোষণা (${all.length})'),
          if (all.isEmpty)
            const EmptyState(
              icon: Icons.campaign_outlined,
              message: 'এখনো কোনো ঘোষণা প্রকাশ করা হয়নি',
            )
          else
            for (final a in all) _announcementCard(a),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _announcementCard(Announcement a) {
    final data = context.read<DataProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.teal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a.body,
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.createdAt.substring(0, 16).replaceAll('T', ' '),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'মুছে ফেলুন',
                onPressed: () => data.deleteAnnouncement(a.id),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(
                a.isActive ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: a.isActive ? AppColors.green : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.isActive ? 'পপআপ সক্রিয়' : 'পপআপ নিষ্ক্রিয়',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              Switch(
                value: a.isActive,
                activeThumbColor: AppColors.green,
                onChanged: (v) => data.setAnnouncementActive(a.id, v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context, DataProvider data) async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শিরোনাম ও বার্তা লিখুন'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    await data.addAnnouncement(
      Announcement(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        body: _body.text.trim(),
      ),
    );
    _title.clear();
    _body.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ঘোষণা প্রকাশিত হয়েছে ✓ — ইউজার হোমে পপআপ দেখাবে'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
