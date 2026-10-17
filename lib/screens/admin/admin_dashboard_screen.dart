import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final catCounts = data.questionsPerCategory;

    return Scaffold(
      appBar: AppBar(title: const Text('ড্যাশবোর্ড')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi(
                'মোট প্রশ্ন',
                '${data.totalQuestions}',
                Icons.quiz_outlined,
                AppColors.primaryBlue,
              ),
              _kpi(
                'জেনারেট করা',
                '${data.generatedQuestionCount}',
                Icons.auto_awesome,
                AppColors.teal,
              ),
              _kpi(
                'মোট ইউজার',
                '${data.users.length}',
                Icons.people_outline,
                AppColors.green,
              ),
              _kpi(
                'প্রিমিয়াম',
                '${data.premiumUserCount}',
                Icons.workspace_premium_outlined,
                AppColors.gold,
              ),
              _kpi(
                'শিক্ষক',
                '${data.teacherCount}',
                Icons.groups_outlined,
                AppColors.accentCyan,
              ),
              _kpi(
                'ই-বুক',
                '${data.ebookCount}',
                Icons.menu_book_outlined,
                AppColors.navy,
              ),
              _kpi(
                'অ্যাক্সেস রিকোয়েস্ট',
                '${data.pendingRequests.length}',
                Icons.verified_user_outlined,
                AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _card(
            title: 'ক্যাটাগরি অনুযায়ী প্রশ্ন বিতরণ',
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (catCounts.isEmpty
                          ? 10
                          : catCounts
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble()) +
                      4,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.categories.length) {
                            return const SizedBox();
                          }
                          final name = data.categories[i].name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              name.length > 8
                                  ? '${name.substring(0, 8)}…'
                                  : name,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < catCounts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: catCounts[i].toDouble(),
                            color: AppColors.teal,
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'সাবস্ক্রিপশন বিভাজন',
            child: Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      sections: [
                        PieChartSectionData(
                          value: data.premiumUserCount.toDouble().clamp(
                            0.1,
                            999,
                          ),
                          color: AppColors.gold,
                          title: '${data.premiumUserCount}',
                          radius: 30,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        PieChartSectionData(
                          value: data.freeUserCount.toDouble().clamp(0.1, 999),
                          color: AppColors.primaryBlue,
                          title: '${data.freeUserCount}',
                          radius: 30,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(color: AppColors.gold, label: 'প্রিমিয়াম ইউজার'),
                    SizedBox(height: 8),
                    _Legend(color: AppColors.primaryBlue, label: 'ফ্রি ইউজার'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'সাম্প্রতিক অ্যাক্টিভিটি (অডিট লগ)',
            child: data.auditLogs.isEmpty
                ? const Text(
                    'এখনো কোনো অ্যাক্টিভিটি নেই।',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: [
                      for (final l in data.auditLogs.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 15,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          title: Text(
                            '${l.action} — ${l.targetUser}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          subtitle: Text(
                            l.detail,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}
