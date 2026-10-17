import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// "About Founder / Instructor / Creator" — Bengali UI.
///
/// Section order (per product requirement):
///  1. শিক্ষক ও প্রতিষ্ঠান পরিচিতি — ইঞ্জিনিয়ার শামীম স্যার (Engr. Md. Rahman)
///  2. ক্রিয়েটর ও অ্যাপ ডেভেলপার — সাইফুল ইসলাম (Sayful Islam) — concise
///
/// Photos can be re-uploaded manually from the Admin Panel (stored as URLs in
/// app settings); when empty, the bundled asset images are used.
class AboutCreatorPage extends StatelessWidget {
  const AboutCreatorPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('খোলা যায়নি: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GradientHeader(
              title: 'প্রতিষ্ঠাতা ও ক্রিয়েটর',
              subtitle: 'Founder, Instructor & App Developer',
              showBack: true,
            ),
          ),

          // ───────────── 1. শিক্ষক ও প্রতিষ্ঠান পরিচিতি (FIRST) ─────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: SectionTitle('শিক্ষক ও প্রতিষ্ঠান পরিচিতি'),
            ),
          ),
          SliverToBoxAdapter(child: _founderCard(context, data)),

          // ───────────── 2. ক্রিয়েটর ও অ্যাপ ডেভেলপার (SECOND) ─────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: SectionTitle('ক্রিয়েটর ও অ্যাপ ডেভেলপার'),
            ),
          ),
          SliverToBoxAdapter(child: _creatorCard(context, data)),

          // ───────────── mission ─────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _missionCard(),
            ),
          ),

          // ───────────── why E&P ─────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _whyCard(),
            ),
          ),

          // ───────────── contact & links ─────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 4),
              child: SectionTitle('যোগাযোগ ও লিংক'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _contactTile(
                    Icons.email_outlined,
                    'ইমেইল',
                    AppConfig.instituteEmail,
                    onTap: () =>
                        _open(context, 'mailto:${AppConfig.instituteEmail}'),
                  ),
                  const SizedBox(height: 10),
                  _contactTile(
                    Icons.phone_outlined,
                    'ফোন',
                    AppConfig.institutePhone,
                    onTap: () => _open(
                      context,
                      'tel:${AppConfig.institutePhone.replaceAll('-', '')}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _contactTile(
                    Icons.location_on_outlined,
                    'ঠিকানা',
                    AppConfig.instituteAddress,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _open(context, AppConfig.facebookPage),
                      icon: const Icon(Icons.thumb_up_alt_outlined, size: 17),
                      label: const Text(
                        'Facebook Page',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _open(context, AppConfig.facebookGroup),
                      icon: const Icon(Icons.groups_outlined, size: 17),
                      label: const Text(
                        'Facebook Group',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} E&P Science • Designed by Sayful Islam',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar({
    required String asset,
    required String override,
    double size = 64,
  }) {
    final image = override.trim().isNotEmpty
        ? Image.network(
            override,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(asset, fit: BoxFit.cover),
          )
        : Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              size: 36,
              color: AppColors.navy,
            ),
          );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(child: image),
    );
  }

  /// Concise creator profile — name, role, designation/organisation and quick
  /// contact chips only (no long skill list, no duplicated contact tiles).
  Widget _creatorCard(BuildContext context, DataProvider data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(
                asset: AppConfig.creatorPhoto,
                override: data.setting('creator_photo'),
                size: 72,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সাইফুল ইসলাম',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Sayful Islam',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Pill(
                      'Creator & App Developer',
                      color: AppColors.primaryBlue,
                      filled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _kv('💼 পদবি', AppConfig.creatorTitle),
          const SizedBox(height: 6),
          _kv('🏢 প্রতিষ্ঠান', AppConfig.creatorOrg),
          const Divider(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.phone_outlined,
                'কল',
                () => _open(context, 'tel:${AppConfig.creatorPhone}'),
              ),
              _chip(
                Icons.email_outlined,
                'ইমেইল',
                () => _open(context, 'mailto:${AppConfig.creatorEmail}'),
              ),
              _chip(
                Icons.link,
                'LinkedIn',
                () => _open(context, AppConfig.creatorLinkedIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _founderCard(BuildContext context, DataProvider data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(
                asset: AppConfig.founderPhoto,
                override: data.setting('founder_photo'),
                size: 72,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ইঞ্জিনিয়ার শামীম স্যার',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Engr. Md. Rahman',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Pill(
                      'Founder & Director',
                      color: AppColors.teal,
                      filled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _kv('👑 প্রতিষ্ঠাতা', AppConfig.founderRole),
          const SizedBox(height: 8),
          _kv('💼 পদবি', AppConfig.founderDesignation),
          const SizedBox(height: 8),
          _kv('🎯 টার্গেট ক্লাস', 'একাদশ-দ্বাদশ শ্রেণি (HSC Academic + Admission)'),
          const SizedBox(height: 8),
          _kv('📚 বিষয়সমূহ', 'পদার্থবিজ্ঞান ও উচ্চতর গণিত'),
          const Divider(height: 24),
          _contactTile(
            Icons.location_on_outlined,
            'ঠিকানা',
            AppConfig.instituteAddress,
          ),
          const SizedBox(height: 10),
          _contactTile(
            Icons.phone_outlined,
            'মোবাইল',
            AppConfig.institutePhone,
            onTap: () => _open(
              context,
              'tel:${AppConfig.institutePhone.replaceAll('-', '')}',
            ),
          ),
          const SizedBox(height: 10),
          _contactTile(
            Icons.email_outlined,
            'ইমেইল',
            AppConfig.instituteEmail,
            onTap: () => _open(context, 'mailto:${AppConfig.instituteEmail}'),
          ),
          const SizedBox(height: 10),
          _contactTile(
            Icons.facebook,
            'ফেসবুক',
            'Facebook Profile',
            onTap: () => _open(context, AppConfig.founderFacebook),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 12.8,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _missionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'মিশন ও ভিশন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'মিশন',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'প্রতিটি শিক্ষার্থী ও চাকরিপ্রার্থীর হাতে সর্বোচ্চ মানের অনুশীলন '
            'পৌঁছে দেওয়া — যেখানে পড়াশোনা হবে স্মার্ট, নির্ভুল ও দ্বিভাষিক।',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          const Text(
            'ভিশন',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ষষ্ঠ শ্রেণি থেকে বিসিএস পর্যন্ত প্রতিটি প্রস্তুতির জন্য একটি নির্ভরযোগ্য '
            'ডিজিটাল প্ল্যাটফর্ম গড়ে তোলা।',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _whyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'কেন E&P Science?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _why(
            Icons.smart_toy_outlined,
            'স্মার্ট টিউটর',
            'ঘরে বসেই দ্বিভাষিক (বাংলা+ইংরেজি) পড়াশোনার সহায়তা',
          ),
          _why(
            Icons.video_library_outlined,
            'ভিডিও ক্লাস',
            'অ্যাপের ভেতরেই অধ্যায়ভিত্তিক রেকর্ডকৃত ও লাইভ ক্লাস',
          ),
          _why(
            Icons.groups_outlined,
            'শিক্ষককে প্রশ্ন',
            'ব্যক্তিগতভাবে যেকোনো শিক্ষককে প্রশ্ন করুন',
          ),
          _why(
            Icons.menu_book_outlined,
            'ই-বুক লাইব্রেরি',
            'অ্যাডমিন-নিয়ন্ত্রিত সুরক্ষিত ইন-অ্যাপ রিডার',
          ),
        ],
      ),
    );
  }

  Widget _why(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: onTap != null
                          ? AppColors.primaryBlue
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
