import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_selector.dart';

/// Mandatory onboarding — the user must pick what they are studying for
/// (Class or Job) right after their first login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _studyFor; // 'class' | 'job'
  String? _level;
  int? _planMonths; // optional subscription duration

  static const _classLevels = [
    'ষষ্ঠ শ্রেণি',
    'সপ্তম শ্রেণি',
    'অষ্টম শ্রেণি',
    'নবম শ্রেণি',
    'দশম শ্রেণি',
    'একাদশ শ্রেণি',
    'দ্বাদশ শ্রেণি',
    'এডমিশন / ভর্তি প্রস্তুতি',
  ];
  static const _jobLevels = [
    'বিসিএস',
    'ব্যাংক',
    'প্রাইমারি শিক্ষক',
    'সরকারি চাকরি',
    'অন্যান্য',
  ];

  Future<void> _finish() async {
    if (_studyFor == null || _level == null) return;
    await context.read<AuthProvider>().completeOnboarding(
          studyFor: _studyFor!,
          studyLevel: _level!,
          intendedPlanMonths: _planMonths ?? 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final levels = _studyFor == 'job' ? _jobLevels : _classLevels;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'আপনি কীসের জন্য প্রস্তুতি নিচ্ছেন?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'আপনার জন্য উপযুক্ত কনটেন্ট সাজাতে এটি একবার নির্বাচন করুন।',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _choiceCard(
                        title: 'একাডেমিক স্টাডি',
                        subtitle: 'ক্লাস ৯–১২ / এইচএসসি',
                        icon: Icons.school_outlined,
                        selected: _studyFor == 'class',
                        onTap: () => setState(() {
                          _studyFor = 'class';
                          _level = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _choiceCard(
                        title: 'চাকুরি প্রস্তুতি',
                        subtitle: 'বিসিএস / ব্যাংক / প্রাইমারি',
                        icon: Icons.workspace_premium_outlined,
                        selected: _studyFor == 'job',
                        onTap: () => setState(() {
                          _studyFor = 'job';
                          _level = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_studyFor != null) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'আরও নির্দিষ্ট করুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: levels.map((l) {
                      final sel = _level == l;
                      return GestureDetector(
                        onTap: () => setState(() => _level = l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.teal
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: sel
                                  ? AppColors.teal
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            l,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 26),
                DurationSelector(
                  selectedMonths: _planMonths,
                  onSelect: (m) => setState(
                    () => _planMonths = _planMonths == m ? null : m,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: (_studyFor != null && _level != null)
                      ? _finish
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('শুরু করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.teal, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
