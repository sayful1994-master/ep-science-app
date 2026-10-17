import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import '../screens/ebook/secure_reader_screen.dart';
import '../screens/ebook/book_payment_sheet.dart';

/// Reusable e-book store card — used by both the E-Book Library screen and the
/// Subject Study Hub so book behaviour (preview, access request, payment,
/// secure reader) is IDENTICAL everywhere.
class EbookStoreCard extends StatelessWidget {
  final Ebook ebook;
  const EbookStoreCard({super.key, required this.ebook});

  /// Cover colour helper shared with the horizontal "my library" card.
  static Color coverColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  /// Opens the secure in-app reader for a book.
  static void openReader(BuildContext context, Ebook b) {
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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? 'guest';
    final b = ebook;

    final hasAccess = data.hasAccess(uid, b.id);
    final purchase = data.purchaseOf(uid, b.id);
    final pending = purchase?.status == 'pending';
    final denied = purchase?.status == 'denied';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coverColor(b.coverColor),
                      coverColor(b.coverColor).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book, color: Colors.white, size: 34),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${b.author.isEmpty ? "E&P Science" : b.author} • ${b.pages} পৃষ্ঠা',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Pill(
                            b.price == 0
                                ? 'ফ্রি'
                                : '৳${b.price.toStringAsFixed(0)}',
                            color: b.price == 0
                                ? AppColors.green
                                : AppColors.primaryBlue,
                            filled: true,
                          ),
                          const Pill(
                            'সিকিউর রিডার',
                            color: AppColors.teal,
                            icon: Icons.shield,
                          ),
                          if (pending)
                            const Pill('অনুমতি অপেক্ষমাণ',
                                color: AppColors.gold),
                          if (hasAccess)
                            const Pill('সংগৃহীত',
                                color: AppColors.success, filled: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openReader(context, b),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('প্রিভিউ',
                        style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _primaryAction(
                      context,
                      data,
                      auth,
                      b,
                      uid,
                      hasAccess: hasAccess,
                      pending: pending,
                      denied: denied,
                    ),
                    icon: Icon(
                      hasAccess
                          ? Icons.menu_book
                          : pending
                              ? Icons.hourglass_top
                              : Icons.lock_open,
                      size: 16,
                    ),
                    label: Text(
                      hasAccess
                          ? 'পড়া শুরু'
                          : pending
                              ? 'অপেক্ষমাণ'
                              : denied
                                  ? 'আবার অনুরোধ'
                                  : 'অ্যাক্সেস নিন',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAccess
                          ? AppColors.teal
                          : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _primaryAction(
    BuildContext context,
    DataProvider data,
    AuthProvider auth,
    Ebook b,
    String uid, {
    required bool hasAccess,
    required bool pending,
    required bool denied,
  }) async {
    if (hasAccess) {
      openReader(context, b);
      return;
    }
    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অ্যাক্সেস নিতে অনুগ্রহ করে লগইন করুন।')),
      );
      return;
    }
    if (pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('আপনার অনুরোধ শিক্ষক/অ্যাডমিনের কাছে অপেক্ষমাণ।')),
      );
      return;
    }
    // Books requiring payment → show the payment popup first.
    if (b.requiresPayment && b.price > 0) {
      final paid = await BookPaymentSheet.show(context, b);
      if (paid != true) return;
    }
    await data.requestAccess(userId: uid, ebookId: b.id);
    if (context.mounted) {
      final owner = b.author.isEmpty ? 'অ্যাডমিন' : b.author;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অ্যাক্সেসের অনুরোধ $owner-এর কাছে পাঠানো হয়েছে ✓'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
