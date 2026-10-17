import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final logs = data.auditLogs;

    return Scaffold(
      appBar: AppBar(title: const Text('অডিট লগ — অ্যাক্টিভিটি ট্র্যাকিং')),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              message:
                  'এখনো কোনো অ্যাক্টিভিটি নেই।\nশিক্ষক অনুমোদন, বই প্রকাশ বা অ্যাক্সেস '
                  'সিদ্ধান্ত নিলে এখানে রেকর্ড হবে।',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final l = logs[i];
                final grant = l.action.contains('GRANT');
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: grant ? AppColors.green : AppColors.danger,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        grant ? Icons.download_done : Icons.lock,
                        color: grant ? AppColors.green : AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.action.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.targetUser,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            if (l.detail.isNotEmpty)
                              Text(
                                l.detail,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              l.timestamp.substring(0, 19).replaceAll('T', ' '),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill('by ${l.actor}', color: AppColors.navy),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
