import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../data/seed_data.dart';

/// E&P Science — zero-cost local backend (SharedPreferences; web + mobile).
/// Mirrors the Firestore collections 1:1. Swap method bodies for Firestore
/// queries once rules + Admin SDK are configured.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const _kCats = 'db_categories';
  static const _kSubs = 'db_sub_categories';
  static const _kSubjects = 'db_subjects';
  static const _kChapters = 'db_chapters';
  static const _kQuestions = 'db_questions';
  static const _kUsers = 'db_users';
  static const _kTeachers = 'db_teachers';
  static const _kEbooks = 'db_ebooks';
  static const _kPurchases = 'db_purchases';
  static const _kThreads = 'db_threads';
  static const _kMessages = 'db_messages';
  static const _kAnnouncements = 'db_announcements';
  static const _kAudit = 'db_audit_logs';
  static const _kVideos = 'db_video_classes';
  static const _kPlans = 'db_subscription_plans';
  static const _kSettings = 'db_app_settings';
  static const _kStudy = 'db_study_resources';

  /// Seed schema version. Bump when the syllabus / seed content changes so
  /// existing installs refresh their taxonomy without losing user data.
  ///   v2 → Class 9-12 + Admission + 4 job categories
  ///   v3 → full NCTB Class 6-12 (all streams) + Madrasah + Technical +
  ///        Admission + Job Preparation (BCS/Bank/Primary/Govt)
  static const _kSeedVersion = 'db_seed_version';
  static const _seedVersion = 3;

  late SharedPreferences _prefs;

  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  List<Subject> subjects = [];
  List<Chapter> chapters = [];
  List<Question> questions = [];
  List<AppUser> users = [];
  List<Teacher> teachers = [];
  List<Ebook> ebooks = [];
  List<Purchase> purchases = [];
  List<QuestionThread> threads = [];
  List<ChatMessage> messages = [];
  List<Announcement> announcements = [];
  List<AuditLog> auditLogs = [];
  List<VideoClass> videoClasses = [];
  List<StudyResource> studyResources = [];
  List<SubscriptionPlan> subscriptionPlans = [];

  /// Feature toggles (admin-controlled). Keyed by feature name.
  Map<String, dynamic> appSettings = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final ver = _prefs.getInt(_kSeedVersion) ?? 0;
    if (ver == 0) {
      // First install — seed everything.
      categories = List.of(SeedData.categories);
      subCategories = List.of(SeedData.subCategories);
      subjects = List.of(SeedData.subjects);
      chapters = List.of(SeedData.chapters);
      questions = List.of(SeedData.questions);
      teachers = List.of(SeedData.teachers);
      ebooks = List.of(SeedData.ebooks);
      studyResources = List.of(SeedData.studyResources);
      announcements = List.of(SeedData.announcements);
      users = _seedUsers();
      purchases = [];
      threads = [];
      messages = [];
      auditLogs = [];
      videoClasses = [];
      subscriptionPlans = _seedPlans();
      appSettings = _defaultSettings();
      await _persistAll();
      await _prefs.setInt(_kSeedVersion, _seedVersion);
      return;
    }

    _loadAll();

    // Migrate older installs: refresh the syllabus from the generated
    // CurriculumSeed and add study resources, WITHOUT wiping users, teacher
    // profiles, purchases, threads or admin-authored questions/videos.
    if (ver < _seedVersion) {
      await _refreshSyllabus();
      await _prefs.setInt(_kSeedVersion, _seedVersion);
    }
  }

  /// Replace the syllabus taxonomy with the current seed (used on schema bump)
  /// while leaving all user-generated content untouched.
  Future<void> _refreshSyllabus() async {
    categories = List.of(SeedData.categories);
    subCategories = List.of(SeedData.subCategories);
    subjects = List.of(SeedData.subjects);
    chapters = List.of(SeedData.chapters);
    if (studyResources.isEmpty) {
      studyResources = List.of(SeedData.studyResources);
    }
    await _put(_kCats, categories.map((e) => e.toMap()).toList());
    await _put(_kSubs, subCategories.map((e) => e.toMap()).toList());
    await _put(_kSubjects, subjects.map((e) => e.toMap()).toList());
    await _put(_kChapters, chapters.map((e) => e.toMap()).toList());
    await _put(_kStudy, studyResources.map((e) => e.toMap()).toList());
  }

  List<AppUser> _seedUsers() => [
        AppUser(
          uid: 'admin_uid',
          name: 'E&P Science Admin',
          email: 'e&pscience@learning.com',
          phone: '01627-444526',
          role: 'admin',
          isPremium: true,
          isApproved: true,
          canDownloadPdf: true,
        ),
        AppUser(
          uid: 'demo_free',
          name: 'রাকিব হাসান',
          email: 'rakib.demo@gmail.com',
          phone: '+8801711000001',
          role: 'student',
          isPremium: false,
          studyFor: 'class',
          studyLevel: 'একাদশ শ্রেণি',
        ),
        AppUser(
          uid: 'demo_premium',
          name: 'নুসরাত জাহান',
          email: 'nusrat.pro@gmail.com',
          phone: '+8801711000002',
          role: 'student',
          isPremium: true,
          subscriptionEndDate: '2026-12-31',
          studyFor: 'job',
          studyLevel: 'বিসিএস',
        ),
      ];

  void _loadAll() {
    categories = _list(_kCats).map(Category.fromMap).toList();
    subCategories = _list(_kSubs).map(SubCategory.fromMap).toList();
    subjects = _list(_kSubjects).map(Subject.fromMap).toList();
    chapters = _list(_kChapters).map(Chapter.fromMap).toList();
    questions = _list(_kQuestions).map(Question.fromMap).toList();
    users = _list(_kUsers).map(AppUser.fromMap).toList();
    teachers = _list(_kTeachers).map(Teacher.fromMap).toList();
    ebooks = _list(_kEbooks).map(Ebook.fromMap).toList();
    purchases = _list(_kPurchases).map(Purchase.fromMap).toList();
    threads = _list(_kThreads).map(QuestionThread.fromMap).toList();
    messages = _list(_kMessages).map(ChatMessage.fromMap).toList();
    announcements = _list(_kAnnouncements).map(Announcement.fromMap).toList();
    auditLogs = _list(_kAudit).map(AuditLog.fromMap).toList();
    videoClasses = _list(_kVideos).map(VideoClass.fromMap).toList();
    studyResources = _list(_kStudy).map(StudyResource.fromMap).toList();
    subscriptionPlans = _list(_kPlans).map(SubscriptionPlan.fromMap).toList();
    if (subscriptionPlans.isEmpty) {
      subscriptionPlans = _seedPlans();
    } else {
      // Migration: ensure any newly-introduced default plans (6/9/12-month)
      // appear on existing installs without wiping admin price edits.
      final have = subscriptionPlans.map((p) => p.id).toSet();
      for (final p in _seedPlans()) {
        if (!have.contains(p.id)) subscriptionPlans.add(p);
      }
    }
    appSettings = _map(_kSettings);
    if (appSettings.isEmpty) appSettings = _defaultSettings();
  }

  List<Map<String, dynamic>> _list(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic> _map(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _put(String key, List<Map<String, dynamic>> data) =>
      _prefs.setString(key, jsonEncode(data));

  Future<void> _persistAll() async {
    await _put(_kCats, categories.map((e) => e.toMap()).toList());
    await _put(_kSubs, subCategories.map((e) => e.toMap()).toList());
    await _put(_kSubjects, subjects.map((e) => e.toMap()).toList());
    await _put(_kChapters, chapters.map((e) => e.toMap()).toList());
    await _put(_kQuestions, questions.map((e) => e.toMap()).toList());
    await _put(_kUsers, users.map((e) => e.toMap()).toList());
    await _put(_kTeachers, teachers.map((e) => e.toMap()).toList());
    await _put(_kEbooks, ebooks.map((e) => e.toMap()).toList());
    await _put(_kPurchases, purchases.map((e) => e.toMap()).toList());
    await _put(_kThreads, threads.map((e) => e.toMap()).toList());
    await _put(_kMessages, messages.map((e) => e.toMap()).toList());
    await _put(_kAnnouncements, announcements.map((e) => e.toMap()).toList());
    await _put(_kAudit, auditLogs.map((e) => e.toMap()).toList());
    await _put(_kVideos, videoClasses.map((e) => e.toMap()).toList());
    await _put(_kStudy, studyResources.map((e) => e.toMap()).toList());
    await _put(_kPlans, subscriptionPlans.map((e) => e.toMap()).toList());
    await _prefs.setString(_kSettings, jsonEncode(appSettings));
  }

  List<SubscriptionPlan> _seedPlans() => [
        SubscriptionPlan(id: 'plan_1m', months: 1, price: 500, labelBn: '১ মাস', labelEn: '1 Month', days: 30),
        SubscriptionPlan(id: 'plan_2m', months: 2, price: 900, labelBn: '২ মাস', labelEn: '2 Months', days: 60),
        SubscriptionPlan(id: 'plan_3m', months: 3, price: 1200, labelBn: '৩ মাস', labelEn: '3 Months', days: 90),
        SubscriptionPlan(id: 'plan_6m', months: 6, price: 2200, labelBn: '৬ মাস', labelEn: '6 Months', days: 180),
        SubscriptionPlan(id: 'plan_9m', months: 9, price: 3000, labelBn: '৯ মাস', labelEn: '9 Months', days: 270),
        SubscriptionPlan(id: 'plan_12m', months: 12, price: 3800, labelBn: '১ বছর', labelEn: '1 Year', days: 365),
      ];

  Map<String, dynamic> _defaultSettings() => {
        'smart_generator_enabled': true,
        'video_classes_enabled': true,
        'ebooks_enabled': true,
        'announcements_enabled': true,
        'bkash_number': '01627444526',
        'whatsapp1': '8801627444526',
        'whatsapp2': '8801676714139',
      };

  // ─────────── syllabus queries ───────────
  List<SubCategory> subCategoriesOf(String categoryId) =>
      subCategories.where((s) => s.categoryId == categoryId).toList();
  List<Subject> subjectsOf(String subCategoryId) =>
      subjects.where((s) => s.subCategoryId == subCategoryId).toList();
  List<Chapter> chaptersOf(String subjectId) =>
      (chapters.where((c) => c.subjectId == subjectId).toList()
        ..sort((a, b) => a.order.compareTo(b.order)));
  List<Question> questionsOfChapter(String chapterId) =>
      questions.where((q) => q.chapterId == chapterId).toList();
  List<Question> questionsOfSubject(String subjectId) =>
      questions.where((q) => q.subjectId == subjectId).toList();
  int questionCountOfChapter(String id) =>
      questions.where((q) => q.chapterId == id).length;
  int questionCountOfSubject(String id) =>
      questions.where((q) => q.subjectId == id).length;

  Category? categoryById(String id) =>
      categories.where((c) => c.id == id).firstOrNull;
  SubCategory? subCategoryById(String id) =>
      subCategories.where((c) => c.id == id).firstOrNull;
  Subject? subjectById(String id) => subjects.where((c) => c.id == id).firstOrNull;
  Chapter? chapterById(String id) => chapters.where((c) => c.id == id).firstOrNull;
  Ebook? ebookById(String id) => ebooks.where((c) => c.id == id).firstOrNull;
  AppUser? userById(String id) => users.where((c) => c.uid == id).firstOrNull;
  Teacher? teacherById(String id) => teachers.where((c) => c.id == id).firstOrNull;

  // ─────────── teachers ───────────
  List<Teacher> get approvedTeachers =>
      teachers.where((t) => t.isApproved).toList();
  List<Teacher> get pendingTeachers =>
      teachers.where((t) => !t.isApproved).toList();

  Future<void> upsertTeacher(Teacher t) async {
    final idx = teachers.indexWhere((e) => e.id == t.id);
    if (idx >= 0) {
      teachers[idx] = t;
    } else {
      teachers.add(t);
    }
    await _put(_kTeachers, teachers.map((e) => e.toMap()).toList());
  }

  Future<void> deleteTeacher(String id) async {
    teachers.removeWhere((e) => e.id == id);
    await _put(_kTeachers, teachers.map((e) => e.toMap()).toList());
  }

  // ─────────── questions ───────────
  Future<void> upsertQuestion(Question q) async {
    final idx = questions.indexWhere((e) => e.id == q.id);
    if (idx >= 0) {
      questions[idx] = q;
    } else {
      questions.add(q);
    }
    await _put(_kQuestions, questions.map((e) => e.toMap()).toList());
  }

  Future<void> addQuestions(List<Question> qs) async {
    questions.addAll(qs);
    await _put(_kQuestions, questions.map((e) => e.toMap()).toList());
  }

  Future<void> deleteQuestion(String id) async {
    questions.removeWhere((e) => e.id == id);
    await _put(_kQuestions, questions.map((e) => e.toMap()).toList());
  }

  // ─────────── users ───────────
  Future<void> upsertUser(AppUser u) async {
    final idx = users.indexWhere((e) => e.uid == u.uid);
    if (idx >= 0) {
      users[idx] = u;
    } else {
      users.add(u);
    }
    await _put(_kUsers, users.map((e) => e.toMap()).toList());
  }

  Future<void> saveUsers() async {
    await _put(_kUsers, users.map((e) => e.toMap()).toList());
  }

  // ─────────── e-books & access ───────────
  Future<void> upsertEbook(Ebook b) async {
    final idx = ebooks.indexWhere((e) => e.id == b.id);
    if (idx >= 0) {
      ebooks[idx] = b;
    } else {
      ebooks.add(b);
    }
    await _put(_kEbooks, ebooks.map((e) => e.toMap()).toList());
  }

  Future<void> deleteEbook(String id) async {
    ebooks.removeWhere((e) => e.id == id);
    await _put(_kEbooks, ebooks.map((e) => e.toMap()).toList());
  }

  Purchase? purchaseOf(String userId, String ebookId) => purchases
      .where((p) => p.userId == userId && p.ebookId == ebookId)
      .firstOrNull;

  bool hasAccess(String userId, String ebookId) {
    final p = purchaseOf(userId, ebookId);
    return p != null && p.status == 'granted';
  }

  bool canDownloadPdf(String userId, String ebookId) {
    final p = purchaseOf(userId, ebookId);
    if (p != null && p.canDownloadPdf) return true;
    return userById(userId)?.canDownloadPdf ?? false;
  }

  Future<void> upsertPurchase(Purchase p) async {
    final idx = purchases.indexWhere(
        (e) => e.userId == p.userId && e.ebookId == p.ebookId);
    if (idx >= 0) {
      purchases[idx] = p;
    } else {
      purchases.add(p);
    }
    await _put(_kPurchases, purchases.map((e) => e.toMap()).toList());
  }

  List<Ebook> ownedEbooks(String userId) => ebooks
      .where((b) => hasAccess(userId, b.id))
      .toList();

  // ─────────── messaging (Q→Teacher) ───────────
  QuestionThread ensureThread({
    required String studentId,
    required String studentName,
    required Teacher teacher,
  }) {
    final existing = threads
        .where((t) =>
            t.studentId == studentId && t.teacherId == teacher.id)
        .firstOrNull;
    if (existing != null) return existing;
    final th = QuestionThread(
      id: 'th_${studentId}_${teacher.id}',
      studentId: studentId,
      studentName: studentName,
      teacherId: teacher.id,
      teacherName: teacher.name,
    );
    threads.add(th);
    _put(_kThreads, threads.map((e) => e.toMap()).toList());
    return th;
  }

  List<ChatMessage> messagesOf(String threadId) =>
      (messages.where((m) => m.threadId == threadId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));

  Future<void> addMessage(ChatMessage m) async {
    messages.add(m);
    await _put(_kMessages, messages.map((e) => e.toMap()).toList());
    final idx = threads.indexWhere((t) => t.id == m.threadId);
    if (idx >= 0) {
      final t = threads[idx];
      threads[idx] = QuestionThread(
        id: t.id,
        studentId: t.studentId,
        studentName: t.studentName,
        teacherId: t.teacherId,
        teacherName: t.teacherName,
        lastMessage: m.text,
        updatedAt: m.timestamp,
      );
      await _put(_kThreads, threads.map((e) => e.toMap()).toList());
    }
  }

  List<QuestionThread> threadsForStudent(String studentId) =>
      threads.where((t) => t.studentId == studentId).toList();
  List<QuestionThread> threadsForTeacher(String teacherId) =>
      threads.where((t) => t.teacherId == teacherId).toList();

  // ─────────── announcements ───────────
  List<Announcement> get activeAnnouncements =>
      announcements.where((a) => a.isActive).toList();

  Future<void> addAnnouncement(Announcement a) async {
    announcements.insert(0, a);
    await _put(_kAnnouncements, announcements.map((e) => e.toMap()).toList());
  }

  Future<void> setAnnouncementActive(String id, bool active) async {
    final idx = announcements.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final a = announcements[idx];
    announcements[idx] = Announcement(
      id: a.id,
      title: a.title,
      body: a.body,
      createdAt: a.createdAt,
      isActive: active,
    );
    await _put(_kAnnouncements, announcements.map((e) => e.toMap()).toList());
  }

  Future<void> deleteAnnouncement(String id) async {
    announcements.removeWhere((a) => a.id == id);
    await _put(_kAnnouncements, announcements.map((e) => e.toMap()).toList());
  }

  // ─────────── video classes ───────────
  List<VideoClass> get activeVideos =>
      videoClasses.where((v) => v.isActive).toList();

  Future<void> upsertVideo(VideoClass v) async {
    final idx = videoClasses.indexWhere((e) => e.id == v.id);
    if (idx >= 0) {
      videoClasses[idx] = v;
    } else {
      videoClasses.insert(0, v);
    }
    await _put(_kVideos, videoClasses.map((e) => e.toMap()).toList());
  }

  Future<void> deleteVideo(String id) async {
    videoClasses.removeWhere((e) => e.id == id);
    await _put(_kVideos, videoClasses.map((e) => e.toMap()).toList());
  }

  /// Videos attached directly to a specific chapter (optional link).
  List<VideoClass> videosOfChapter(String chapterId) => videoClasses
      .where((v) => v.isActive && v.chapterId == chapterId)
      .toList();

  // ─────────── study resources (notes / lectures / suggestions) ─────────
  List<StudyResource> get allStudyResources => studyResources;

  List<StudyResource> studyResourcesOfSubject(String subjectId) =>
      studyResources.where((r) => r.subjectId == subjectId).toList();

  List<StudyResource> studyResourcesOfChapter(String chapterId) =>
      studyResources.where((r) => r.chapterId == chapterId).toList();

  List<StudyResource> studyResourcesOfSubCategory(String subCategoryId) =>
      studyResources.where((r) => r.subCategoryId == subCategoryId).toList();

  StudyResource? studyResourceById(String id) =>
      studyResources.where((r) => r.id == id).firstOrNull;

  Future<void> upsertStudyResource(StudyResource r) async {
    final idx = studyResources.indexWhere((e) => e.id == r.id);
    if (idx >= 0) {
      studyResources[idx] = r;
    } else {
      studyResources.insert(0, r);
    }
    await _put(_kStudy, studyResources.map((e) => e.toMap()).toList());
  }

  Future<void> deleteStudyResource(String id) async {
    studyResources.removeWhere((e) => e.id == id);
    await _put(_kStudy, studyResources.map((e) => e.toMap()).toList());
  }

  // ─────────── subscription plans ───────────
  List<SubscriptionPlan> get activePlans {
    final p = subscriptionPlans.where((x) => x.isActive).toList()
      ..sort((a, b) => a.months.compareTo(b.months));
    return p;
  }

  Future<void> upsertPlan(SubscriptionPlan p) async {
    final idx = subscriptionPlans.indexWhere((e) => e.id == p.id);
    if (idx >= 0) {
      subscriptionPlans[idx] = p;
    } else {
      subscriptionPlans.add(p);
    }
    await _put(_kPlans, subscriptionPlans.map((e) => e.toMap()).toList());
  }

  // ─────────── feature toggles ───────────
  bool feature(String key) => appSettings[key] == true;
  String setting(String key) => (appSettings[key] ?? '').toString();

  Future<void> setFeature(String key, bool value) async {
    appSettings[key] = value;
    await _prefs.setString(_kSettings, jsonEncode(appSettings));
  }

  Future<void> setSetting(String key, String value) async {
    appSettings[key] = value;
    await _prefs.setString(_kSettings, jsonEncode(appSettings));
  }

  // ─────────── audit ───────────
  Future<void> addAudit(AuditLog log) async {
    auditLogs.insert(0, log);
    await _put(_kAudit, auditLogs.map((e) => e.toMap()).toList());
  }

  Future<void> resetToSeed() async {
    await _prefs.setInt(_kSeedVersion, 0);
    await init();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
