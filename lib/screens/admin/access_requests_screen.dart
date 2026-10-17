import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Access-request control.
///
/// Users (or the owning teacher) request read / download access to a book.
/// Admin has full permission by default and can grant or deny each request,
/// with or without download permission.
class AccessRequestsScreen extends StatefulWidget {
  const AccessRequestsScreen({super.key});

  @override
  State<AccessRequestsScreen> createState() => _AccessRequestsScreenState();
}

class _AccessRequestsScreenState extends State<AccessRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final pending = data.pendingRequests;
    final decided = data.allPurchases
        .where((p) => p.status != 'pending')
        .toList()
      ..sort((a, b) => b.decidedAt.compareTo(a.decidedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাক্সেস রিকোয়েস্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.teal, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ডিফল্টভাবে ই-বুক শুধু পড়া যায় (রিড-অনলি)। ইউজার ডাউনলোড চাইলে এখানে '
                    'রিকোয়েস্ট আসে। অনুমোদন দিলে সে পড়তে পারবে; “ডাউনলোডসহ” দিলে শেয়ার/ডাউনলোডও পারবে।',
                    style: TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle('অপেক্ষমাণ রিকোয়েস্ট (${pending.length})'),
          if (pending.isEmpty)
            const EmptyState(
              icon: Icons.mark_email_read_outlined,
              message: 'কোনো অপেক্ষমাণ অ্যাক্সেস রিকোয়েস্ট নেই',
            )
          else
            for (final p in pending) _requestCard(context, data, p, pending: true),
          const SizedBox(height: 22),
          SectionTitle('সিদ্ধান্তকৃত (${decided.length})'),
          if (decided.isEmpty)
            const Text(
              'এখনো কোনো সিদ্ধান্ত নেওয়া হয়নি।',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final p in decided.take(30))
              _requestCard(context, data, p, pending: false),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    DataProvider data,
    Purchase p, {
    required bool pending,
  }) {
    final user = data.users.where((u) => u.uid == p.userId).firstOrNull;
    final book = data.ebook(p.ebookId);
    final owner = book != null ? data.teacher(book.ownerTeacherId) : null;

    final granted = p.status == 'granted';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: pending
                ? AppColors.gold
                : (granted ? AppColors.green : AppColors.danger),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user?.name ?? p.userId,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Pill(
                pending ? 'অপেক্ষমাণ' : (granted ? 'অনুমোদিত' : 'বাতিল'),
                color: pending
                    ? AppColors.gold
                    : (granted ? AppColors.green : AppColors.danger),
                filled: true,
              ),
            ],
          ),
          if (user != null)
            Text(
              user.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book?.title ?? p.ebookId,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (owner != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'মালিক শিক্ষক: ${owner.name}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            p.canDownloadPdf
                ? 'চাহিদা: পড়া + ডাউনলোড'
                : 'চাহিদা: শুধু পড়া (রিড-অনলি)',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          if (pending) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => data.decideRequest(
                      userId: p.userId,
                      ebookId: p.ebookId,
                      grant: false,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('বাতিল', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => data.decideRequest(
                      userId: p.userId,
                      ebookId: p.ebookId,
                      grant: true,
                    ),
                    icon: const Icon(Icons.menu_book, size: 16),
                    label: const Text('শুধু পড়া', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => data.decideRequest(
                      userId: p.userId,
                      ebookId: p.ebookId,
                      grant: true,
                      allowDownload: true,
                    ),
                    icon: const Icon(Icons.download_done, size: 16),
                    label: const Text('ডাউনলোডসহ', style: TextStyle(fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
