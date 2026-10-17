import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/ebook_card.dart';
import 'secure_reader_screen.dart';

/// E-Book store — books are published by the admin via public links.
/// A shared link opens the doc/PDF directly in the secure in-app reader.
class EbookStoreScreen extends StatelessWidget {
  const EbookStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? 'guest';

    final myBooks = data.ownedEbooks(uid);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GradientHeader(
            title: 'ই-বুক লাইব্রেরি',
            subtitle: 'অ্যাডমিন-প্রকাশিত বই • সিকিউর ইন-অ্যাপ রিডার',
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.teal, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'বই সরাসরি অ্যাপের ভেতরে খুলবে — স্ক্রিনশট নেওয়া যাবে, '
                    'কিন্তু কপি/টেক্সট নেওয়া বন্ধ। ডাউনলোড চাইলে শিক্ষক/অ্যাডমিনের '
                    'অনুমতি লাগবে।',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (myBooks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: SectionTitle('আমার লাইব্রেরি'),
            ),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myBooks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ownedCard(context, data, myBooks[i], uid),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: SectionTitle('স্টোরে সব বই'),
          ),

          for (final b in data.ebooks)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: EbookStoreCard(ebook: b),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _ownedCard(
    BuildContext context,
    DataProvider data,
    Ebook b,
    String uid,
  ) {
    final canDownload = data.canDownloadPdf(uid, b.id);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openReader(context, b),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _hex(b.coverColor),
                    _hex(b.coverColor).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.menu_book, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              b.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.2,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  canDownload ? Icons.download_for_offline : Icons.lock,
                  size: 13,
                  color: canDownload
                      ? AppColors.green
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  canDownload ? 'ডাউনলোডযোগ্য' : 'শুধু ইন-অ্যাপ',
                  style: TextStyle(
                    fontSize: 10,
                    color: canDownload
                        ? AppColors.green
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openReader(BuildContext context, Ebook b) {
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid ?? 'guest';
    final canDownload = data.canDownloadPdf(uid, b.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureReaderScreen(ebook: b, canDownload: canDownload),
      ),
    );
  }

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
