import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'browse_screen.dart';
import 'smart_tutor_screen.dart';
import 'category_screen.dart';
import 'premium_screen.dart';
import 'my_threads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _announcementShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAnnouncement());
  }

  void _maybeShowAnnouncement() {
    if (_announcementShown || !mounted) return;
    final data = context.read<DataProvider>();
    final active = data.activeAnnouncements;
    if (active.isEmpty) return;
    _announcementShown = true;
    _showAnnouncement(active.first);
  }

  void _showAnnouncement(Announcement a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppColors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                a.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(a.body, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'আসসালামু আলাইকুম 👋',
              subtitle: auth.isGuest
                  ? 'গেস্ট মোড • সীমিত কনটেন্ট'
                  : '${auth.user?.name ?? "শিক্ষার্থী"} • ${auth.isPremium ? "প্রিমিয়াম" : "ফ্রি সদস্য"}',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      auth.isPremium ? Icons.verified : Icons.star_border,
                      color: auth.isPremium ? AppColors.gold : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      auth.isPremium ? 'PRO' : 'FREE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BrowseScreen(),
                          ),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'বিষয়, অধ্যায় বা প্রশ্ন খুঁজুন...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _statCard(
                    'প্রশ্ন',
                    '${data.totalQuestions}',
                    Icons.quiz_outlined,
                    AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'বিষয়',
                    '${data.subjects.length}',
                    Icons.category_outlined,
                    AppColors.teal,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'শিক্ষক',
                    '${data.approvedTeachers.length}',
                    Icons.groups_outlined,
                    AppColors.green,
                  ),
                ],
              ),
            ),
          ),

          // Smart generator hero CTA (hidden when the admin disables it)
          if (data.smartGeneratorEnabled)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _generatorHero(context),
              ),
            ),

          // Free-tier messaging / premium banner
          if (!auth.isPremium)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _premiumBanner(context, auth),
              ),
            ),

          // Ask a teacher quick entry
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _askTeacherCard(context, auth),
            ),
          ),

          // Weakness identifier
          if (quiz.weaknessReport.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _weaknessCard(context, quiz),
              ),
            ),

          // Categories
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: SectionTitle('ক্যাটাগরি অনুযায়ী শিখুন'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final c = data.categories[i];
                return _categoryCard(context, c);
              }, childCount: data.categories.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
  }

  Widget _generatorHero(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartTutorScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'স্মার্ট প্রশ্ন জেনারেটর',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'যেকোনো বিষয়/অধ্যায়ের জন্য তাৎক্ষণিক নতুন\nপ্রশ্নসেট তৈরি করুন — এখানেই!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _premiumBanner(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.gold, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সম্পূর্ণ আনলক করুন',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                SizedBox(height: 2),
                Text(
                  'সব অধ্যায় + বিগত বছরের প্রশ্ন + মডেল টেস্ট',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'নিন',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _askTeacherCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.question_answer_outlined,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'শিক্ষককে প্রশ্ন করুন',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                SizedBox(height: 2),
                Text(
                  'ব্যক্তিগতভাবে প্রশ্ন করুন — শুধু আপনি ও শিক্ষক দেখবেন',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyThreadsScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_ios, size: 15),
          ),
        ],
      ),
    );
  }

  Widget _weaknessCard(BuildContext context, QuizProvider quiz) {
    final worst = quiz.weaknessReport.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'দুর্বলতা শনাক্তকারী',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ),
              Pill(
                '${(worst.accuracy * 100).toStringAsFixed(0)}% নির্ভুলতা',
                color: AppColors.danger,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“${worst.chapterName}” অধ্যায়ে আপনার নির্ভুলতা সবচেয়ে কম। '
            'এখনই টার্গেটেড প্র্যাকটিস সেট তৈরি করুন।',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                quiz.reset();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrowseScreen()),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text(
                'টার্গেটেড প্র্যাকটিস',
                style: TextStyle(fontSize: 12.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(BuildContext context, Category c) {
    final data = context.read<DataProvider>();
    final count = data.subCategoriesOf(c.id).length;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryScreen(category: c)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconFromName(c.icon), color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(
              c.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count টি গ্রুপ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
