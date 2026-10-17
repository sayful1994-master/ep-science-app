import 'package:flutter/foundation.dart' hide Category;

import '../models/models.dart';
import '../services/local_db.dart';
import '../widgets/duration_selector.dart' show PlanDurations;

/// E&P Science — content, teacher, e-book and access state.
class DataProvider extends ChangeNotifier {
  final LocalDb _db = LocalDb.instance;

  DataProvider() {
    refresh();
  }

  void refresh() => notifyListeners();

  // ───────── syllabus ─────────
  List<Category> get categories => _db.categories;
  List<SubCategory> get subCategories => _db.subCategories;
  List<Subject> get subjects => _db.subjects;
  List<Chapter> get chapters => _db.chapters;
  List<SubCategory> subCategoriesOf(String id) => _db.subCategoriesOf(id);
  List<Subject> subjectsOf(String id) => _db.subjectsOf(id);
  List<Chapter> chaptersOf(String id) => _db.chaptersOf(id);
  List<Question> questionsOfChapter(String id) => _db.questionsOfChapter(id);
  List<Question> questionsOfSubject(String id) => _db.questionsOfSubject(id);

  Category? category(String id) => _db.categoryById(id);
  SubCategory? subCategory(String id) => _db.subCategoryById(id);
  Subject? subject(String id) => _db.subjectById(id);
  Chapter? chapter(String id) => _db.chapterById(id);
  Ebook? ebook(String id) => _db.ebookById(id);

  int chapterQuestionCount(String id) => _db.questionCountOfChapter(id);
  int subjectQuestionCount(String id) => _db.questionCountOfSubject(id);

  // ───────── questions (admin) ─────────
  List<Question> get allQuestions => _db.questions;
  int get totalQuestions => _db.questions.length;
  int get generatedQuestionCount =>
      _db.questions.where((q) => q.generatedBy == 'Generator').length;

  Future<void> saveQuestion(Question q) async {
    await _db.upsertQuestion(q);
    notifyListeners();
  }

  Future<void> deleteQuestion(String id) async {
    await _db.deleteQuestion(id);
    notifyListeners();
  }

  Future<int> bulkAddQuestions(List<Question> qs) async {
    await _db.addQuestions(qs);
    notifyListeners();
    return qs.length;
  }

  // ───────── teachers ─────────
  List<Teacher> get allTeachers => _db.teachers;
  List<Teacher> get approvedTeachers => _db.approvedTeachers;
  List<Teacher> get pendingTeachers => _db.pendingTeachers;
  Teacher? teacher(String id) => _db.teacherById(id);

  Future<void> saveTeacher(Teacher t) async {
    await _db.upsertTeacher(t);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: t.isApproved ? 'APPROVE_TEACHER' : 'SAVE_TEACHER_DRAFT',
        targetUser: t.name,
        detail: '${t.title} • ${t.subjects}',
      ),
    );
    notifyListeners();
  }

  Future<void> setTeacherApproval(String id, bool approved) async {
    final t = _db.teacherById(id);
    if (t == null) return;
    await _db.upsertTeacher(t.copyWith(isApproved: approved));
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: approved ? 'APPROVE_TEACHER' : 'REVOKE_TEACHER',
        targetUser: t.name,
        detail: 'Public visibility = $approved',
      ),
    );
    notifyListeners();
  }

  Future<void> deleteTeacher(String id) async {
    await _db.deleteTeacher(id);
    notifyListeners();
  }

  // ───────── users (admin) ─────────
  List<AppUser> get users => _db.users;

  Future<void> togglePremium(String uid, bool value) async {
    final u = _db.userById(uid);
    if (u == null) return;
    await _db.upsertUser(
      u.copyWith(
        isPremium: value,
        subscriptionEndDate: value
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
            : null,
      ),
    );
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: value ? 'GRANT_PREMIUM' : 'REVOKE_PREMIUM',
        targetUser: u.email,
        detail: 'Premium status set to $value',
      ),
    );
    notifyListeners();
  }

  /// Mark a user as teacher (auto-moves profile to the teacher list).
  Future<void> markAsTeacher(String uid, {bool approved = true}) async {
    final u = _db.userById(uid);
    if (u == null) return;
    await _db.upsertUser(
      u.copyWith(role: 'teacher', isApproved: approved),
    );
    // Create/refresh a Teacher profile entry linked to this user.
    final existing = _db.teachers
        .where((t) => t.linkedUserId == uid)
        .firstOrNull;
    final t = Teacher(
      id: existing?.id ?? 't_user_$uid',
      name: u.name,
      title: u.title.isEmpty ? 'প্রভাষক' : u.title,
      subjects: u.subjects,
      phone: u.phone,
      email: u.email,
      location: u.location,
      photoUrl: u.photoUrl,
      isApproved: approved,
      linkedUserId: uid,
      createdAt: existing?.createdAt,
    );
    await _db.upsertTeacher(t);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'MARK_TEACHER',
        targetUser: u.email,
        detail: 'role=teacher, approved=$approved',
      ),
    );
    notifyListeners();
  }

  Future<void> unmarkTeacher(String uid) async {
    final u = _db.userById(uid);
    if (u == null) return;
    await _db.upsertUser(u.copyWith(role: 'student', isApproved: false));
    final linked =
        _db.teachers.where((t) => t.linkedUserId == uid).firstOrNull;
    if (linked != null) await _db.deleteTeacher(linked.id);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'UNMARK_TEACHER',
        targetUser: u.email,
        detail: 'role reverted to student',
      ),
    );
    notifyListeners();
  }

  Future<void> saveUser(AppUser u) async {
    await _db.upsertUser(u);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: u.canDownloadPdf
            ? 'GRANT_DOWNLOAD_ACCOUNT'
            : 'REVOKE_DOWNLOAD_ACCOUNT',
        targetUser: u.email,
        detail: 'Account-level PDF download permission = ${u.canDownloadPdf}',
      ),
    );
    notifyListeners();
  }

  Future<void> toggleUserDownload(String uid, bool value) async {
    final u = _db.userById(uid);
    if (u == null) return;
    await saveUser(u.copyWith(canDownloadPdf: value));
  }

  // ───────── e-books ─────────
  List<Ebook> get ebooks => _db.ebooks;
  List<Ebook> ebooksOfSubCategory(String subCategoryId) =>
      _db.ebooks.where((b) => b.subCategoryId == subCategoryId).toList();

  Future<void> saveEbook(Ebook b) async {
    await _db.upsertEbook(b);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'PUBLISH_EBOOK',
        targetUser: b.author.isEmpty ? 'E&P Science' : b.author,
        detail: '${b.title} • ${b.externalUrl}',
      ),
    );
    notifyListeners();
  }

  Future<void> deleteEbook(String id) async {
    await _db.deleteEbook(id);
    notifyListeners();
  }

  // ───────── purchases / access requests ─────────
  bool hasAccess(String userId, String ebookId) => _db.hasAccess(userId, ebookId);
  bool canDownloadPdf(String userId, String ebookId) =>
      _db.canDownloadPdf(userId, ebookId);
  Purchase? purchaseOf(String userId, String ebookId) =>
      _db.purchaseOf(userId, ebookId);
  List<Ebook> ownedEbooks(String userId) => _db.ownedEbooks(userId);
  List<Purchase> get allPurchases => _db.purchases;

  List<Purchase> get pendingRequests =>
      _db.purchases.where((p) => p.status == 'pending').toList();

  /// A normal user requests access / download from the book's owner-teacher
  /// (or the admin when there is no owner).
  Future<void> requestAccess({
    required String userId,
    required String ebookId,
    bool download = false,
  }) async {
    final owner = _db.ebookById(ebookId)?.ownerTeacherId ?? '';
    await _db.upsertPurchase(
      Purchase(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        ebookId: ebookId,
        status: 'pending',
        canDownloadPdf: download,
        ownerTeacherId: owner,
      ),
    );
    notifyListeners();
  }

  /// Owner-teacher or admin grants / denies an access request.
  Future<void> decideRequest({
    required String userId,
    required String ebookId,
    required bool grant,
    bool allowDownload = false,
  }) async {
    final p = _db.purchaseOf(userId, ebookId);
    await _db.upsertPurchase(
      Purchase(
        id: p?.id ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        ebookId: ebookId,
        status: grant ? 'granted' : 'denied',
        canDownloadPdf: grant && allowDownload,
        requestedAt: p?.requestedAt,
        decidedAt: DateTime.now().toIso8601String(),
        ownerTeacherId: p?.ownerTeacherId ?? '',
      ),
    );
    final u = _db.userById(userId);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: grant
            ? (allowDownload ? 'GRANT_ACCESS_DOWNLOAD' : 'GRANT_ACCESS_READ')
            : 'DENY_ACCESS',
        targetUser: u?.email ?? userId,
        detail: 'Book: $ebookId',
      ),
    );
    notifyListeners();
  }

  // ───────── messaging (Q→Teacher, private) ─────────
  List<QuestionThread> threadsForStudent(String studentId) =>
      _db.threadsForStudent(studentId);
  List<QuestionThread> threadsForTeacher(String teacherId) =>
      _db.threadsForTeacher(teacherId);
  List<ChatMessage> messagesOf(String threadId) => _db.messagesOf(threadId);

  QuestionThread ensureThread({
    required String studentId,
    required String studentName,
    required Teacher teacher,
  }) {
    final th = _db.ensureThread(
      studentId: studentId,
      studentName: studentName,
      teacher: teacher,
    );
    notifyListeners();
    return th;
  }

  Future<void> sendMessage({
    required QuestionThread thread,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _db.addMessage(
      ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        threadId: thread.id,
        senderId: senderId,
        senderName: senderName,
        text: text,
      ),
    );
    notifyListeners();
  }

  // ───────── announcements ─────────
  List<Announcement> get activeAnnouncements => _db.activeAnnouncements;
  List<Announcement> get allAnnouncements => _db.announcements;

  Future<void> addAnnouncement(Announcement a) async {
    await _db.addAnnouncement(a);
    notifyListeners();
  }

  Future<void> setAnnouncementActive(String id, bool active) async {
    await _db.setAnnouncementActive(id, active);
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.deleteAnnouncement(id);
    notifyListeners();
  }

  // ───────── video classes ─────────
  List<VideoClass> get allVideos => _db.videoClasses;
  List<VideoClass> get activeVideos => _db.activeVideos;

  List<VideoClass> videosFiltered({
    String? classId,
    String? subjectId,
    String? chapterId,
  }) {
    var list = _db.activeVideos;
    if (classId != null && classId.isNotEmpty) {
      list = list.where((v) => v.classId == classId).toList();
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      list = list.where((v) => v.subjectId == subjectId).toList();
    }
    if (chapterId != null && chapterId.isNotEmpty) {
      list = list.where((v) => v.chapterId == chapterId).toList();
    }
    return list;
  }

  List<VideoClass> videosOfChapter(String chapterId) =>
      _db.videosOfChapter(chapterId);

  Future<void> saveVideo(VideoClass v) async {
    await _db.upsertVideo(v);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'PUBLISH_VIDEO',
        targetUser: v.className.isEmpty ? 'All' : v.className,
        detail: '${v.title} • ${v.videoId}',
      ),
    );
    notifyListeners();
  }

  Future<void> deleteVideo(String id) async {
    await _db.deleteVideo(id);
    notifyListeners();
  }

  // ───────── study resources (notes / lectures / suggestions) ─────────
  List<StudyResource> get allStudyResources => _db.allStudyResources;

  List<StudyResource> studyResourcesOfSubject(String subjectId) =>
      _db.studyResourcesOfSubject(subjectId);

  List<StudyResource> studyResourcesOfChapter(String chapterId) =>
      _db.studyResourcesOfChapter(chapterId);

  List<StudyResource> studyResourcesOfSubCategory(String subCategoryId) =>
      _db.studyResourcesOfSubCategory(subCategoryId);

  StudyResource? studyResource(String id) => _db.studyResourceById(id);

  Future<void> saveStudyResource(StudyResource r) async {
    await _db.upsertStudyResource(r);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'PUBLISH_STUDY_RESOURCE',
        targetUser: r.subjectName.isEmpty ? r.subCategoryName : r.subjectName,
        detail: '${r.type.toUpperCase()} • ${r.title}',
      ),
    );
    notifyListeners();
  }

  Future<void> deleteStudyResource(String id) async {
    await _db.deleteStudyResource(id);
    notifyListeners();
  }

  // ───────── subscription plans ─────────
  List<SubscriptionPlan> get activePlans => _db.activePlans;
  List<SubscriptionPlan> get allPlans => _db.subscriptionPlans;

  Future<void> savePlan(SubscriptionPlan p) async {
    await _db.upsertPlan(p);
    notifyListeners();
  }

  Future<void> setFeature(String key, bool value) async {
    await _db.setFeature(key, value);
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: value ? 'FEATURE_ENABLE' : 'FEATURE_DISABLE',
        targetUser: 'app_settings',
        detail: key,
      ),
    );
    notifyListeners();
  }

  bool feature(String key) => _db.feature(key);
  String setting(String key) => _db.setting(key);
  bool get smartGeneratorEnabled => _db.feature('smart_generator_enabled');
  bool get videoClassesEnabled => _db.feature('video_classes_enabled');

  // ───────── users (create / remove) ─────────
  /// Admin creates a user account directly.
  /// When [isPremium] is true and [premiumMonths] > 0, premium access is
  /// granted for that duration starting today.
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String phone,
    String password = '1234',
    String role = 'student',
    bool isPremium = false,
    int premiumMonths = 0,
    String studyFor = 'class',
    String studyLevel = '',
    int intendedPlanMonths = 0,
  }) async {
    final now = DateTime.now();
    final planMonths = premiumMonths > 0 ? premiumMonths : intendedPlanMonths;
    final days = PlanDurations.daysFor(planMonths);
    final grantPremium = isPremium || planMonths > 0;
    final u = AppUser(
      uid: 'uid_${now.millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      isPremium: grantPremium,
      premiumActivatedAt: grantPremium ? now.toIso8601String() : '',
      subscriptionEndDate: grantPremium && days > 0
          ? now.add(Duration(days: days)).toIso8601String()
          : null,
      studyFor: studyFor,
      studyLevel: studyLevel,
      intendedPlanMonths: planMonths,
    );
    await _db.upsertUser(u);
    await _db.addAudit(
      AuditLog(
        id: 'log_${now.millisecondsSinceEpoch}',
        action: 'CREATE_USER',
        targetUser: email,
        detail: grantPremium
            ? 'role=$role • premium $planMonths month(s)'
            : 'role=$role',
      ),
    );
    notifyListeners();
    return u;
  }

  Future<void> deleteUser(String uid) async {
    final u = _db.userById(uid);
    _db.users.removeWhere((x) => x.uid == uid);
    await _db.saveUsers();
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'DELETE_USER',
        targetUser: u?.email ?? uid,
        detail: 'User removed by admin',
      ),
    );
    notifyListeners();
  }

  /// Admin activates/extends premium for a chosen duration in months.
  ///
  /// If the user already has an active subscription, the new duration is
  /// ADDED to the existing expiry (extend) instead of resetting it. If the
  /// subscription has lapsed, the new period starts from today.
  Future<void> activateSubscription(
    String uid, {
    required int months,
    required int days,
  }) async {
    final u = _db.userById(uid);
    if (u == null) return;
    final now = DateTime.now();
    final base = u.hasActivePremium ?
        (DateTime.tryParse(u.subscriptionEndDate ?? '') ?? now) : now;
    final newExpiry = base.add(Duration(days: days));
    await _db.upsertUser(
      u.copyWith(
        isPremium: true,
        premiumActivatedAt: now.toIso8601String(),
        subscriptionEndDate: newExpiry.toIso8601String(),
      ),
    );
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'ACTIVATE_SUBSCRIPTION',
        targetUser: u.email,
        detail: '$months month(s) → +$days days (expires '
            '${newExpiry.toIso8601String().split("T").first})',
      ),
    );
    notifyListeners();
  }

  /// Revoke premium entirely (clears the expiry too).
  Future<void> revokePremium(String uid) async {
    final u = _db.userById(uid);
    if (u == null) return;
    await _db.upsertUser(u.revokePremium());
    await _db.addAudit(
      AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        action: 'REVOKE_PREMIUM',
        targetUser: u.email,
        detail: 'Premium membership revoked by admin',
      ),
    );
    notifyListeners();
  }

  // ───────── audit ─────────
  List<AuditLog> get auditLogs => _db.auditLogs;

  // ───────── analytics (admin dashboard) ─────────
  int get premiumUserCount => _db.users.where((u) => u.isPremium).length;
  int get freeUserCount => _db.users.where((u) => !u.isPremium).length;
  int get studentCount =>
      _db.users.where((u) => u.role == 'student').length;
  int get teacherCount => _db.teachers.length;
  int get ebookCount => _db.ebooks.length;
  int get purchaseCount => _db.purchases.length;

  List<int> get questionsPerCategory {
    final out = <int>[];
    for (final c in _db.categories) {
      out.add(_db.questions.where((q) => q.categoryId == c.id).length);
    }
    return out;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
