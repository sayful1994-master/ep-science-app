import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'question_thread_screen.dart';
import 'teacher_reply_screen.dart';

/// Lists private Q→Teacher threads. Students see their own threads;
/// teachers see the questions addressed to them.
class MyThreadsScreen extends StatelessWidget {
  const MyThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();

    final isTeacherView = auth.isTeacher;
    final threads = isTeacherView
        ? _teacherThreads(data, auth)
        : (auth.user == null ? <QuestionThread>[] : data.threadsForStudent(auth.user!.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacherView ? 'শিক্ষার্থীদের প্রশ্ন' : 'আমার প্রশ্নসমূহ'),
      ),
      body: threads.isEmpty
          ? EmptyState(
              icon: Icons.forum_outlined,
              message: isTeacherView
                  ? 'এখনো কোনো শিক্ষার্থী প্রশ্ন করেনি।'
                  : 'আপনি এখনো কোনো শিক্ষককে প্রশ্ন করেননি।\nশিক্ষক ট্যাব থেকে প্রশ্ন করুন।',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _tile(context, data, auth, threads[i], isTeacherView),
            ),
    );
  }

  List<QuestionThread> _teacherThreads(DataProvider data, AuthProvider auth) {
    // Find teacher profile(s) linked to this user, then gather their threads.
    final linked = data.allTeachers
        .where((t) => t.linkedUserId == auth.user?.uid)
        .toList();
    if (linked.isEmpty) {
      // Fall back to matching by name (seeded teachers).
      final byName = data.allTeachers
          .where((t) => t.name == auth.user?.name)
          .toList();
      linked.addAll(byName);
    }
    final ids = linked.map((t) => t.id).toSet();
    return ids.expand((id) => data.threadsForTeacher(id)).toList();
  }

  Widget _tile(
    BuildContext context,
    DataProvider data,
    AuthProvider auth,
    QuestionThread t,
    bool teacherView,
  ) {
    final other = teacherView ? t.studentName : t.teacherName;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (teacherView) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherReplyScreen(thread: t),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuestionThreadScreen(teacherId: t.teacherId),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.forum, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.lastMessage.isEmpty ? 'নতুন আলাপচারিতা' : t.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
