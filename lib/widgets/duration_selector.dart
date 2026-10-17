import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The canonical subscription durations (months → days).
/// 1 → 30, 2 → 60, 3 → 90, 6 → 180, 9 → 270, 12 → 365.
class PlanDurations {
  static const List<int> months = [1, 2, 3, 6, 9, 12];

  static const Map<int, String> labelBn = {
    1: '১ মাস',
    2: '২ মাস',
    3: '৩ মাস',
    6: '৬ মাস',
    9: '৯ মাস',
    12: '১ বছর',
  };

  /// Days added to `premium_expires_at` for a chosen duration.
  static int daysFor(int months) {
    switch (months) {
      case 1:
        return 30;
      case 2:
        return 60;
      case 3:
        return 90;
      case 6:
        return 180;
      case 9:
        return 270;
      case 12:
        return 365;
      default:
        return months * 30;
    }
  }

  static String label(int months) => labelBn[months] ?? '$months মাস';
}

/// Horizontal, wrap-friendly duration chooser used during signup and the
/// post-login onboarding step. Optional — the user can skip it.
class DurationSelector extends StatelessWidget {
  final int? selectedMonths;
  final ValueChanged<int> onSelect;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color chipBg;
  final Color chipBorder;

  const DurationSelector({
    super.key,
    required this.selectedMonths,
    required this.onSelect,
    this.title = 'সাবস্ক্রিপশন মেয়াদ (ঐচ্ছিক)',
    this.subtitle =
        'পছন্দের প্রিমিয়াম মেয়াদ বেছে নিন — পরে অ্যাডমিন/নিজে থেকে অ্যাক্টিভ করে নিতে পারবেন।',
    this.textColor = Colors.white,
    this.chipBg = Colors.white,
    this.chipBorder = AppColors.divider,
  });

  @override
  Widget build(BuildContext context) {
    final dark = textColor == Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: dark
                ? Colors.white.withValues(alpha: 0.75)
                : AppColors.textSecondary,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in PlanDurations.months)
              GestureDetector(
                onTap: () => onSelect(m),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedMonths == m
                        ? AppColors.teal
                        : (dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : chipBg),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selectedMonths == m
                          ? AppColors.teal
                          : (dark
                              ? Colors.white.withValues(alpha: 0.25)
                              : chipBorder),
                    ),
                  ),
                  child: Text(
                    PlanDurations.label(m),
                    style: TextStyle(
                      color: selectedMonths == m ? Colors.white : textColor,
                      fontSize: 12.5,
                      fontWeight: selectedMonths == m
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
