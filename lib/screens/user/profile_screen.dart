import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paywall.dart';
import 'about_creator_page.dart';
import 'result_screen.dart';
import 'my_threads_screen.dart';
import 'premium_screen.dart';
import 'privacy_policy_screen.dart';
import 'edit_profile_screen.dart';
import '../splash_screen.dart' show AuthScreen;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final quiz = context.watch<QuizProvider>();
    final user = auth.user;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: user?.name ?? 'প্রোফাইল',
            subtitle: user?.email ?? '',
            trailing: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: (user?.photoUrl.isNotEmpty ?? false)
                    ? NetworkImage(user!.photoUrl)
                    : null,
                child: (user?.photoUrl.isEmpty ?? true)
                    ? Text(
                        (user?.name ?? 'G').trim().isNotEmpty
                            ? user!.name.trim().characters.first.toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    auth.isPremium
                        ? Icons.workspace_premium
                        : Icons.person_outline,
                    color: auth.isPremium ? AppColors.gold : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    auth.isGuest
                        ? 'গেস্ট মোড'
                        : auth.isPremium
                        ? 'প্রিমিয়াম সদস্য'
                        : 'ফ্রি সদস্য',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const Spacer(),
                  if (!auth.isPremium && !auth.isGuest)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      ),
                      child: const Pill(
                        'আপগ্রেড',
                        color: AppColors.gold,
                        filled: true,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _stat('প্রশ্ন চেষ্টা', '${quiz.answeredCount}'),
                const SizedBox(width: 10),
                _stat('সঠিক', '${quiz.correctCount}'),
                _stat('ই-বুক', '${data.ownedEbooks(user?.uid ?? '').length}'),
              ],
            ),
          ),

          if (quiz.weaknessReport.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _progressCard(context, quiz),
            ),

          _menuTile(
            context,
            Icons.edit_outlined,
            'প্রোফাইল সম্পাদনা',
            'নাম, ছবি ও ক্লাস পরিবর্তন',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _menuTile(
            context,
            Icons.forum_outlined,
            'আমার প্রশ্নসমূহ',
            'শিক্ষকদের সাথে ব্যক্তিগত আলাপচারিতা',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyThreadsScreen()),
            ),
          ),
          _menuTile(
            context,
            Icons.person_outline,
            'প্রতিষ্ঠাতা ও ক্রিয়েটর',
            'Founder, Instructor & App Developer',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutCreatorPage()),
            ),
          ),
          _menuTile(
            context,
            Icons.workspace_premium_outlined,
            'প্রিমিয়াম আপগ্রেড',
            'সব ফিচার আনলক করুন',
            onTap: () {
              if (auth.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('আপনি ইতিমধ্যেই প্রিমিয়াম সদস্য।')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
          ),
          _menuTile(
            context,
            Icons.help_outline,
            'সহায়তা ও যোগাযোগ',
            AppConfig.institutePhone,
            onTap: () => Paywall.show(context),
          ),
          _menuTile(
            context,
            Icons.privacy_tip_outlined,
            'প্রাইভেসি পলিসি',
            'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (r) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('লগআউট'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'E&P Science • v1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _progressCard(BuildContext context, QuizProvider quiz) {
    final overall = quiz.items.isEmpty
        ? 0.0
        : quiz.correctCount / quiz.items.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আমার অগ্রগতি',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: overall,
                      strokeWidth: 7,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                    ),
                    Text(
                      '${(overall * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quiz.weaknessReport.length}টি অধ্যায় বিশ্লেষিত',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'সামগ্রিক অগ্রগতি ট্র্যাক হচ্ছে — দুর্বল অধ্যায়ে ফোকাস করুন।',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResultScreen()),
            ),
            icon: const Icon(Icons.insights, size: 16),
            label: const Text(
              'বিস্তারিত বিশ্লেষণ দেখুন',
              style: TextStyle(fontSize: 12.5),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListTile(
        onTap: onTap ?? () {},
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: AppColors.primaryBlue, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
