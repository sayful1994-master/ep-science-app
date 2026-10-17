import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paywall.dart';
import '../../widgets/ebook_card.dart';
import '../video/video_player_screen.dart';
import '../user/practice_screen.dart';
import 'study_resource_viewer_screen.dart';

/// Subject Study Hub — the single place where a student STUDIES a subject.
///
/// Tabs:
///   • অধ্যায়      — chapter-wise practice + full model test
///   • ভিডিও       — subject/chapter video classes (in-app playback)
///   • নোট/ডকুমেন্ট — notes, lecture sheets, suggestions, guides
///   • বই          — reference books for the subject
///
/// Premium content is gated with the dynamic paywall.
class SubjectStudyHub extends StatelessWidget {
  final Subject subject;
  final String categoryName;
  final String subCategoryId;
  const SubjectStudyHub({
    super.key,
    required this.subject,
    required this.categoryName,
    required this.subCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final chapters = data.chaptersOf(subject.id);
    final videos = data.videosFiltered(subjectId: subject.id);
    final resources = data.studyResourcesOfSubject(subject.id);
    final books =
        data.ebooks.where((b) => b.subjectId == subject.id).toList();

    final sub = data.subCategory(subCategoryId);
    final subName = sub?.name ?? '';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: subject.name,
                subtitle: '$categoryName • $subName',
                showBack: true,
                child: Row(
                  children: [
                    _chip('${chapters.length} অধ্যায়', Icons.list_alt),
                    const SizedBox(width: 8),
                    _chip('${data.subjectQuestionCount(subject.id)} প্রশ্ন',
                        Icons.quiz_outlined),
                    const SizedBox(width: 8),
                    if (!auth.isPremium)
                      _chip('ফ্রি: ১ম ২ অধ্যায়', Icons.lock_open),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeader(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.teal,
                  tabs: const [
                    Tab(text: 'অধ্যায়', icon: Icon(Icons.menu_book_outlined)),
                    Tab(text: 'ভিডিও', icon: Icon(Icons.play_circle_outline)),
                    Tab(text: 'নোট / ডকুমেন্ট', icon: Icon(Icons.description_outlined)),
                    Tab(text: 'বই', icon: Icon(Icons.library_books_outlined)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ChaptersTab(
                subject: subject,
                chapters: chapters,
              ),
              _VideosTab(videos: videos),
              _ResourcesTab(resources: resources),
              _BooksTab(books: books, subjectName: subject.name),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarHeader(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 8;
  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.only(top: 8),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader old) => old.tabBar != tabBar;
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — chapters + model test
// ─────────────────────────────────────────────────────────────
class _ChaptersTab extends StatelessWidget {
  final Subject subject;
  final List<Chapter> chapters;
  const _ChaptersTab({required this.subject, required this.chapters});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _modelTestCard(context, auth, data),
        const SizedBox(height: 18),
        const SectionTitle('অধ্যায়ভিত্তিক প্র্যাকটিস'),
        if (chapters.isEmpty)
          const EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'এই বিষয়ের অধ্যায় এখনো যুক্ত হয়নি',
          )
        else
          for (var i = 0; i < chapters.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _chapterTile(context, auth, data, i),
            ),
      ],
    );
  }

  Widget _modelTestCard(
      BuildContext context, AuthProvider auth, DataProvider data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer_outlined,
                color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('মডেল টেস্ট (নেগেটিভ মার্কিং)',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                SizedBox(height: 2),
                Text(
                  'প্রতিটি ভুল উত্তরে -${AppConfig.negativeMarking} নম্বর কাটা হবে',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!auth.isPremium) {
                Paywall.show(
                  context,
                  title: 'মডেল টেস্ট প্রিমিয়াম',
                  message:
                      'নেগেটিভ মার্কিংসহ সম্পূর্ণ মডেল টেস্ট ফিচার প্রিমিয়াম সদস্যদের জন্য।',
                );
                return;
              }
              context
                  .read<QuizProvider>()
                  .startSubjectModelTest(subject, data.chaptersOf(subject.id));
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('শুরু', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chapterTile(
      BuildContext context, AuthProvider auth, DataProvider data, int i) {
    final ch = chapters[i];
    final qCount = data.chapterQuestionCount(ch.id);
    final vCount = data.videosOfChapter(ch.id).length;
    final rCount = data.studyResourcesOfChapter(ch.id).length;
    final locked =
        !auth.canAccessChapter(i, questionPremium: true) && !auth.isPremium;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (locked) {
          Paywall.show(
            context,
            title: 'অধ্যায় ${i + 1} লকড',
            message:
                'অধ্যায় “${ch.name}” প্রিমিয়াম সদস্যদের জন্য সংরক্ষিত। ফ্রি সদস্যরা প্রতিটি বিষয়ের প্রথম ২টি অধ্যায় পান।',
          );
          return;
        }
        context.read<QuizProvider>().startChapter(
              subj: subject,
              allChapters: chapters,
              startPos: i,
            );
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PracticeScreen()));
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
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.bg
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: locked
                  ? const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 19)
                  : Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('$qCount প্রশ্ন',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5)),
                      if (vCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.play_circle_outline,
                            size: 12, color: AppColors.teal),
                        Text(' $vCount',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11.5)),
                      ],
                      if (rCount > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.description_outlined,
                            size: 12, color: AppColors.primaryBlue),
                        Text(' $rCount',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11.5)),
                      ],
                      if (i < AppConfig.freeChapterLimit && !locked) ...[
                        const SizedBox(width: 8),
                        const Pill('ফ্রি', color: AppColors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (locked)
              const Pill('প্রিমিয়াম',
                  color: AppColors.gold, icon: Icons.workspace_premium)
            else
              const Icon(Icons.play_circle_outline,
                  color: AppColors.teal, size: 26),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — videos
// ─────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<VideoClass> videos;
  const _VideosTab({required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const EmptyState(
        icon: Icons.video_library_outlined,
        message: 'এই বিষয়ের কোনো ভিডিও ক্লাস এখনো যুক্ত হয়নি',
      );
    }
    // Group by chapter where possible (chapter videos first).
    final withChapter = videos.where((v) => v.chapterName.isNotEmpty).toList();
    final general = videos.where((v) => v.chapterName.isEmpty).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (withChapter.isNotEmpty) ...[
          const SectionTitle('অধ্যায়ভিত্তিক ভিডিও'),
          for (final v in withChapter)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _videoCard(context, v),
            ),
        ],
        if (general.isNotEmpty) ...[
          if (withChapter.isNotEmpty) const SizedBox(height: 8),
          const SectionTitle('সাধারণ ভিডিও ক্লাস'),
          for (final v in general)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _videoCard(context, v),
            ),
        ],
      ],
    );
  }

  Widget _videoCard(BuildContext context, VideoClass v) {
    final auth = context.watch<AuthProvider>();
    final locked = v.isPremium && !auth.isPremium;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (locked) {
          Paywall.show(context,
              title: 'প্রিমিয়াম ভিডিও',
              message: '“${v.title}” ভিডিওটি প্রিমিয়াম সদস্যদের জন্য।');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    v.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.navy,
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white70, size: 44),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      locked ? Icons.lock : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                        color: Colors.black.withValues(alpha: 0.4)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (v.chapterName.isNotEmpty)
                        Pill(v.chapterName, color: AppColors.teal),
                      if (v.isPremium)
                        const Pill('প্রিমিয়াম',
                            color: AppColors.gold, filled: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — notes / documents
// ─────────────────────────────────────────────────────────────
class _ResourcesTab extends StatelessWidget {
  final List<StudyResource> resources;
  const _ResourcesTab({required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        message: 'এই বিষয়ের কোনো নোট / ডকুমেন্ট এখনো যুক্ত হয়নি',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        for (final r in resources)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _resourceTile(context, r),
          ),
      ],
    );
  }

  Widget _resourceTile(BuildContext context, StudyResource r) {
    final auth = context.watch<AuthProvider>();
    final locked = r.isPremium && !auth.isPremium;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (locked) {
          Paywall.show(context,
              title: 'প্রিমিয়াম কনটেন্ট',
              message: '“${r.title}” প্রিমিয়াম সদস্যদের জন্য সংরক্ষিত।');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudyResourceViewerScreen(resource: r),
          ),
        );
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(r.type), color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(r.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(_typeLabel(r.type), color: AppColors.navy),
                      Pill(r.fileType.toUpperCase(),
                          color: AppColors.primaryBlue),
                      if (r.chapterName.isNotEmpty)
                        Pill(r.chapterName, color: AppColors.teal),
                    ],
                  ),
                ],
              ),
            ),
            if (locked)
              const Pill('প্রিমিয়াম', color: AppColors.gold)
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(String t) {
    switch (t) {
      case 'lecture':
        return Icons.co_present_outlined;
      case 'suggestion':
        return Icons.tips_and_updates_outlined;
      case 'guide':
        return Icons.auto_stories_outlined;
      default:
        return Icons.sticky_note_2_outlined;
    }
  }

  static String _typeLabel(String t) {
    switch (t) {
      case 'lecture':
        return 'লেকচার';
      case 'suggestion':
        return 'সাজেশন';
      case 'guide':
        return 'গাইড';
      default:
        return 'নোট';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 4 — books
// ─────────────────────────────────────────────────────────────
class _BooksTab extends StatelessWidget {
  final List<Ebook> books;
  final String subjectName;
  const _BooksTab({required this.books, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const EmptyState(
        icon: Icons.library_books_outlined,
        message: 'এই বিষয়ের বই / লাইব্রেরি এখনো যুক্ত হয়নি',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        for (final b in books)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EbookStoreCard(ebook: b),
          ),
      ],
    );
  }
}
