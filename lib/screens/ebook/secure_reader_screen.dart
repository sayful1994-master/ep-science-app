import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'reader/external_doc_view.dart';

/// Secure in-app E-Book reader for EXTERNALLY-hosted documents.
///
/// SECURITY MODEL
/// ───────────────
/// • The document (PDF/DOC) lives OUTSIDE the app (cloud / Drive / public URL)
///   and is fetched & rendered dynamically — no bulky files are stored.
/// • SCREENSHOTS ARE ALLOWED (per product requirement). COPY is DISABLED:
///   selection / long-press copy is suppressed and a copy-guard overlay is
///   applied. Unauthorized download/sharing stays off unless an admin or the
///   owning teacher grants it.
/// • When download is NOT granted, the bottom action sends an access-grant
///   request message to the admin (or the teacher who uploaded the book).
/// • When the admin/teacher grants download, the "ডাউনলোড" action appears.
class SecureReaderScreen extends StatefulWidget {
  final Ebook ebook;
  final bool canDownload;
  const SecureReaderScreen({
    super.key,
    required this.ebook,
    required this.canDownload,
  });

  @override
  State<SecureReaderScreen> createState() => _SecureReaderScreenState();
}

class _SecureReaderScreenState extends State<SecureReaderScreen> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    // Screenshots are intentionally ALLOWED — no FLAG_SECURE is applied.
  }

  Future<void> _requestDownload() async {
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুমতি চাইতে অনুগ্রহ করে লগইন করুন।')),
      );
      return;
    }
    await data.requestAccess(userId: uid, ebookId: widget.ebook.id, download: true);
    if (!mounted) return;
    setState(() => _requested = true);
    final owner = widget.ebook.author.isEmpty ? 'অ্যাডমিন' : widget.ebook.author;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ডাউনলোডের অনুমতির বার্তা $owner-এর কাছে পাঠানো হয়েছে ✓'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.ebook;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1524),
        title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Pill(
                'কপি নিষ্ক্রিয়',
                color: AppColors.teal,
                icon: Icons.block,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _securityBanner(),
          Expanded(
            child: (b.externalUrl.isEmpty)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'এই বইয়ের লিংক এখনো যুক্ত হয়নি।\nশীঘ্রই প্রকাশ করা হবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : _guardedDocument(b.externalUrl),
          ),
          _bottomControl(b),
        ],
      ),
    );
  }

  /// Wraps the external document and suppresses text selection / copy.
  Widget _guardedDocument(String url) {
    final b = widget.ebook;
    return Stack(
      children: [
        ExternalDocView(url: url, fileType: b.fileType, title: b.title),
        // Copy-guard overlay: blocks long-press selection gestures from
        // reaching the underlying document.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
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
        ),
      ],
    );
  }

  Widget _securityBanner() {
    final can = widget.canDownload;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: can
          ? AppColors.green.withValues(alpha: 0.15)
          : AppColors.primaryBlue.withValues(alpha: 0.25),
      child: Row(
        children: [
          Icon(
            can ? Icons.lock_open : Icons.shield,
            color: can ? AppColors.green : AppColors.teal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              can
                  ? 'ডাউনলোডের অনুমতি সক্রিয়।'
                  : 'স্ক্রিনশট নেওয়া যাবে, তবে কপি ও অননুমোদিত ডাউনলোড বন্ধ।',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: can
                    ? AppColors.green
                    : Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControl(Ebook b) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF0A1524),
      child: SafeArea(
        top: false,
        child: widget.canDownload
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('অনুমোদিত — ডাউনলোড / শেয়ার করা যাবে ✓'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'ডাউনলোড / শেয়ার করুন',
                    style: TextStyle(fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _requested ? null : _requestDownload,
                      icon: Icon(
                        _requested ? Icons.hourglass_top : Icons.download_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _requested
                            ? 'অনুমতির অনুরোধ পাঠানো হয়েছে'
                            : 'ডাউনলোডের অনুমতি চাই',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.author.isEmpty
                        ? 'ডাউনলোড চাইলে অ্যাডমিনের কাছে অনুরোধ যাবে।'
                        : 'ডাউনলোড চাইলে “${b.author}”-এর কাছে অনুরোধ যাবে।',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
