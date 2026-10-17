import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'question_thread_screen.dart';

/// A single teacher's public profile + "প্রশ্ন করুন" entry point.
class TeacherInfoPage extends StatelessWidget {
  final String teacherId;
  const TeacherInfoPage({super.key, required this.teacherId});

  Future<void> _call(BuildContext context, String phone) async {
    final u = Uri.parse('tel:${phone.replaceAll('-', '')}');
    if (await canLaunchUrl(u)) {
      await launchUrl(u);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final t = data.teacher(teacherId);

    if (t == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('শিক্ষক')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          message: 'শিক্ষকের তথ্য পাওয়া যায়নি।',
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: t.name,
              subtitle: t.title,
              showBack: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoCard(t),
                  const SizedBox(height: 16),
                  const SectionTitle('প্রশ্ন করুন'),
                  _askCard(context, auth, t),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context, t.phone),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('কল করুন'),
                        ),
                      ),
                      if (t.email.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse('mailto:${t.email}'),
                            ),
                            icon: const Icon(Icons.email_outlined, size: 18),
                            label: const Text('ইমেইল'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _infoCard(Teacher t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.badge_outlined, 'পদবি', t.title),
          if (t.qualification.isNotEmpty)
            _row(Icons.school_outlined, 'শিক্ষাগত যোগ্যতা', t.qualification),
          _row(Icons.menu_book_outlined, 'বিষয়', t.subjects),
          if (t.targetClasses.isNotEmpty)
            _row(Icons.groups_outlined, 'ক্লাস', t.targetClasses),
          _row(Icons.call_outlined, 'ফোন', t.phone),
          if (t.email.isNotEmpty)
            _row(Icons.email_outlined, 'ইমেইল', t.email),
          _row(Icons.location_on_outlined, 'ঠিকানা', t.location),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _askCard(BuildContext context, AuthProvider auth, Teacher t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আপনার প্রশ্ন সরাসরি এই শিক্ষকের কাছে যাবে।',
            style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'আলাপচারিতা শুধু আপনি, শিক্ষক ও অ্যাডমিন দেখতে পাবেন।',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (auth.isGuest) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('প্রশ্ন করতে অনুগ্রহ করে লগইন করুন।'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionThreadScreen(teacherId: t.id),
                  ),
                );
              },
              icon: const Icon(Icons.question_answer_outlined, size: 18),
              label: const Text('প্রশ্ন লিখুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
