import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../ebook/reader/external_doc_view.dart';

/// In-app reader for a [StudyResource] (note / lecture sheet / suggestion /
/// guide). The document is hosted OUTSIDE the app and streamed in — nothing
/// bulky is stored. Screenshots are allowed; copy/long-press is suppressed,
/// matching the e-book reader's security model.
class StudyResourceViewerScreen extends StatelessWidget {
  final StudyResource resource;
  const StudyResourceViewerScreen({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    final r = resource;
    final url = r.fileUrl.isNotEmpty ? r.fileUrl : r.externalUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1524),
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Pill(
                _typeLabel(r.type),
                color: AppColors.teal,
                icon: _typeIcon(r.type),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _banner(r),
          Expanded(
            child: url.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'এই কনটেন্টের লিংক এখনো যুক্ত হয়নি।\nশীঘ্রই প্রকাশ করা হবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : _guardedDoc(context, url, r),
          ),
          _bottomBar(context, r, url),
        ],
      ),
    );
  }

  Widget _banner(StudyResource r) {
    final crumbs = [r.subjectName, r.chapterName]
        .where((s) => s.isNotEmpty)
        .join(' • ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryBlue.withValues(alpha: 0.25),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              crumbs.isEmpty
                  ? 'স্ক্রিনশট নেওয়া যাবে, তবে কপি নিষ্ক্রিয়।'
                  : '$crumbs\nস্ক্রিনশট নেওয়া যাবে, তবে কপি নিষ্ক্রিয়।',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardedDoc(BuildContext context, String url, StudyResource r) {
    return Stack(
      children: [
        ExternalDocView(url: url, fileType: r.fileType, title: r.title),
        Positioned.fill(
          child: GestureDetector(
            onLongPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('কপি/টেক্সট নির্বাচন নিষ্ক্রিয় করা হয়েছে।'),
                ),
              );
            },
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, StudyResource r, String url) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF0A1524),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                r.description.isEmpty ? 'E&P Science স্টাডি কনটেন্ট' : r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.5,
                ),
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'ব্রাউজারে খুলুন',
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri == null) return;
                  final ok = await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('লিংক খোলা যায়নি।')),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, color: AppColors.teal),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _typeLabel(String t) {
    switch (t) {
      case 'lecture':
        return 'লেকচার';
      case 'suggestion':
        return 'সাজেশন';
      case 'guide':
        return 'গাইড';
      default:
        return 'নোট';
    }
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
}
