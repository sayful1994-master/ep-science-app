/// E&P Science — data models (Firestore-mirrored).
library;

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\u0980-\u09FF]+'), '-')
    .replaceAll(RegExp(r'(^-|-$)'), '');

// ───────────────────────────── categories ─────────────────────────────
class Category {
  final String id;
  final String name; // Bengali
  final String nameEn;
  final String slug;
  final String icon;
  final String description;
  Category({
    required this.id,
    required this.name,
    this.nameEn = '',
    String? slug,
    this.icon = 'menu_book',
    this.description = '',
  }) : slug = slug ?? _slug(name);

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        nameEn: m['name_en'] ?? '',
        slug: m['slug'],
        icon: m['icon'] ?? 'menu_book',
        description: m['description'] ?? '',
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'name_en': nameEn,
        'slug': slug,
        'icon': icon,
        'description': description,
      };
}

// ───────────────────────────── sub_categories (classes) ───────────────
class SubCategory {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  SubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    String? slug,
  }) : slug = slug ?? _slug(name);

  factory SubCategory.fromMap(Map<String, dynamic> m) => SubCategory(
        id: m['id'] ?? '',
        categoryId: m['category_id'] ?? '',
        name: m['name'] ?? '',
        slug: m['slug'],
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'slug': slug,
      };
}

// ───────────────────────────── subjects ───────────────────────────────
class Subject {
  final String id;
  final String subCategoryId;
  final String name;
  final String slug;
  final String icon;
  final String stream;
  Subject({
    required this.id,
    required this.subCategoryId,
    required this.name,
    String? slug,
    this.icon = 'book',
    this.stream = '',
  }) : slug = slug ?? _slug(name);

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
        id: m['id'] ?? '',
        subCategoryId: m['sub_category_id'] ?? '',
        name: m['name'] ?? '',
        slug: m['slug'],
        icon: m['icon'] ?? 'book',
        stream: m['stream'] ?? '',
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'sub_category_id': subCategoryId,
        'name': name,
        'slug': slug,
        'icon': icon,
        'stream': stream,
      };
}
// ───────────────────────────── chapters ───────────────────────────────
class Chapter {
  final String id;
  final String subjectId;
  final String name;
  final String slug;
  final int order;
  Chapter({
    required this.id,
    required this.subjectId,
    required this.name,
    String? slug,
    this.order = 0,
  }) : slug = slug ?? _slug(name);

  factory Chapter.fromMap(Map<String, dynamic> m) => Chapter(
        id: m['id'] ?? '',
        subjectId: m['subject_id'] ?? '',
        name: m['name'] ?? '',
        slug: m['slug'],
        order: m['order'] ?? 0,
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'name': name,
        'slug': slug,
        'order': order,
      };
}

// ───────────────────────────── questions ──────────────────────────────
class Question {
  final String id;
  final String categoryId;
  final String subCategoryId;
  final String subjectId;
  final String chapterId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String optionE;
  final String correctAnswer;
  final String explanation;
  final String examTag;
  final String difficultyLevel;
  final bool isPremium;
  final String generatedBy;

  Question({
    required this.id,
    required this.categoryId,
    required this.subCategoryId,
    required this.subjectId,
    required this.chapterId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.optionE = '',
    required this.correctAnswer,
    this.explanation = '',
    this.examTag = '',
    this.difficultyLevel = 'Medium',
    this.isPremium = true,
    this.generatedBy = 'Manual',
  });

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'] ?? '',
        categoryId: m['category_id'] ?? '',
        subCategoryId: m['sub_category_id'] ?? '',
        subjectId: m['subject_id'] ?? '',
        chapterId: m['chapter_id'] ?? '',
        questionText: m['question_text'] ?? '',
        optionA: m['option_a'] ?? '',
        optionB: m['option_b'] ?? '',
        optionC: m['option_c'] ?? '',
        optionD: m['option_d'] ?? '',
        optionE: m['option_e'] ?? '',
        correctAnswer: m['correct_answer'] ?? 'A',
        explanation: m['explanation'] ?? '',
        examTag: m['exam_tag'] ?? '',
        difficultyLevel: m['difficulty_level'] ?? 'Medium',
        isPremium: m['is_premium'] ?? true,
        generatedBy: m['generated_by'] ?? 'Manual',
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'subject_id': subjectId,
        'chapter_id': chapterId,
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'option_e': optionE,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'exam_tag': examTag,
        'difficulty_level': difficultyLevel,
        'is_premium': isPremium,
        'generated_by': generatedBy,
      };
  List<MapEntry<String, String>> get options => [
        MapEntry('A', optionA),
        MapEntry('B', optionB),
        MapEntry('C', optionC),
        MapEntry('D', optionD),
        if (optionE.isNotEmpty) MapEntry('E', optionE),
      ];
}

// ───────────────────────────── users ──────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role;
  final bool isPremium;
  final String? subscriptionEndDate;
  final String premiumActivatedAt;
  final String createdAt;
  final bool isApproved;
  final bool canDownloadPdf;
  final String studyFor;
  final String studyLevel;
  final String title;
  final String subjects;
  final String location;
  final int intendedPlanMonths;
  final bool createdByAdmin;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.role = 'student',
    this.isPremium = false,
    this.subscriptionEndDate,
    this.premiumActivatedAt = '',
    String? createdAt,
    this.isApproved = false,
    this.canDownloadPdf = false,
    this.studyFor = '',
    this.studyLevel = '',
    this.title = '',
    this.subjects = '',
    this.location = '',
    this.intendedPlanMonths = 0,
    this.createdByAdmin = false,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';

  bool get hasActivePremium {
    if (!isPremium) return false;
    if (subscriptionEndDate == null || subscriptionEndDate!.isEmpty) return true;
    final exp = DateTime.tryParse(subscriptionEndDate!);
    if (exp == null) return true;
    return DateTime.now().isBefore(exp);
  }

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        photoUrl: m['photo_url'] ?? '',
        role: m['role'] ?? 'student',
        isPremium: m['is_premium'] ?? false,
        subscriptionEndDate: m['subscription_end_date'],
        premiumActivatedAt: m['premium_activated_at'] ?? '',
        createdAt: m['created_at'],
        isApproved: m['is_approved'] ?? false,
        canDownloadPdf: m['can_download_pdf'] ?? false,
        studyFor: m['study_for'] ?? '',
        studyLevel: m['study_level'] ?? '',
        title: m['title'] ?? '',
        subjects: m['subjects'] ?? '',
        location: m['location'] ?? '',
        intendedPlanMonths: m['intended_plan_months'] ?? 0,
        createdByAdmin: m['created_by_admin'] ?? false,
      );

  factory AppUser.guest() =>
      AppUser(uid: 'guest', name: 'Guest', email: 'guest@epscience.app');

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'photo_url': photoUrl,
        'role': role,
        'is_premium': isPremium,
        'subscription_end_date': subscriptionEndDate,
        'premium_activated_at': premiumActivatedAt,
        'created_at': createdAt,
        'is_approved': isApproved,
        'can_download_pdf': canDownloadPdf,
        'study_for': studyFor,
        'study_level': studyLevel,
        'title': title,
        'subjects': subjects,
        'location': location,
        'intended_plan_months': intendedPlanMonths,
        'created_by_admin': createdByAdmin,
      };
  AppUser revokePremium() => AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
        role: role,
        isPremium: false,
        subscriptionEndDate: null,
        premiumActivatedAt: premiumActivatedAt,
        createdAt: createdAt,
        isApproved: isApproved,
        canDownloadPdf: canDownloadPdf,
        studyFor: studyFor,
        studyLevel: studyLevel,
        title: title,
        subjects: subjects,
        location: location,
        intendedPlanMonths: intendedPlanMonths,
        createdByAdmin: createdByAdmin,
      );

  int get premiumDaysLeft {
    final s = subscriptionEndDate;
    if (s == null || s.isEmpty) return 0;
    final exp = DateTime.tryParse(s);
    if (exp == null) return 0;
    final d = exp.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? role,
    bool? isPremium,
    String? subscriptionEndDate,
    String? premiumActivatedAt,
    bool? isApproved,
    bool? canDownloadPdf,
    String? studyFor,
    String? studyLevel,
    String? title,
    String? subjects,
    String? location,
    int? intendedPlanMonths,
    bool? createdByAdmin,
  }) =>
      AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        isPremium: isPremium ?? this.isPremium,
        subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
        premiumActivatedAt: premiumActivatedAt ?? this.premiumActivatedAt,
        createdAt: createdAt,
        isApproved: isApproved ?? this.isApproved,
        canDownloadPdf: canDownloadPdf ?? this.canDownloadPdf,
        studyFor: studyFor ?? this.studyFor,
        studyLevel: studyLevel ?? this.studyLevel,
        title: title ?? this.title,
        subjects: subjects ?? this.subjects,
        location: location ?? this.location,
        intendedPlanMonths: intendedPlanMonths ?? this.intendedPlanMonths,
        createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      );
}

// ───────────────────────────── teachers ───────────────────────────────
class Teacher {
  final String id;
  final String name;
  final String title;
  final String qualification;
  final String subjects;
  final String targetClasses;
  final String phone;
  final String email;
  final String location;
  final String photoUrl;
  final bool isApproved;
  final String linkedUserId;
  final String createdAt;

  Teacher({
    required this.id,
    required this.name,
    this.title = '',
    this.qualification = '',
    this.subjects = '',
    this.targetClasses = '',
    this.phone = '',
    this.email = '',
    this.location = '',
    this.photoUrl = '',
    this.isApproved = false,
    this.linkedUserId = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Teacher.fromMap(Map<String, dynamic> m) => Teacher(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        title: m['title'] ?? '',
        qualification: m['qualification'] ?? '',
        subjects: m['subjects'] ?? '',
        targetClasses: m['target_classes'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        location: m['location'] ?? '',
        photoUrl: m['photo_url'] ?? '',
        isApproved: m['is_approved'] ?? false,
        linkedUserId: m['linked_user_id'] ?? '',
        createdAt: m['created_at'],
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'title': title,
        'qualification': qualification,
        'subjects': subjects,
        'target_classes': targetClasses,
        'phone': phone,
        'email': email,
        'location': location,
        'photo_url': photoUrl,
        'is_approved': isApproved,
        'linked_user_id': linkedUserId,
        'created_at': createdAt,
      };

  Teacher copyWith({
    String? name,
    String? title,
    String? qualification,
    String? subjects,
    String? targetClasses,
    String? phone,
    String? email,
    String? location,
    String? photoUrl,
    bool? isApproved,
  }) =>
      Teacher(
        id: id,
        name: name ?? this.name,
        title: title ?? this.title,
        qualification: qualification ?? this.qualification,
        subjects: subjects ?? this.subjects,
        targetClasses: targetClasses ?? this.targetClasses,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        location: location ?? this.location,
        photoUrl: photoUrl ?? this.photoUrl,
        isApproved: isApproved ?? this.isApproved,
        linkedUserId: linkedUserId,
        createdAt: createdAt,
      );
}

// ───────────────────────────── ebooks (external-link) ─────────────────
class Ebook {
  final String id;
  final String title;
  final String author;
  final String ownerTeacherId;
  final String description;
  final String coverColor;
  final int pages;
  final double price;
  final bool isPremium;
  final bool requiresPayment;
  final String externalUrl;
  final String fileType;
  final String categoryId;
  final String subCategoryId;
  final String subjectId;
  final String createdAt;

  Ebook({
    required this.id,
    required this.title,
    this.author = '',
    this.ownerTeacherId = '',
    this.description = '',
    this.coverColor = '#12324F',
    this.pages = 100,
    this.price = 0,
    this.isPremium = true,
    this.requiresPayment = false,
    this.externalUrl = '',
    this.fileType = 'pdf',
    this.categoryId = '',
    this.subCategoryId = '',
    this.subjectId = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Ebook.fromMap(Map<String, dynamic> m) => Ebook(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        author: m['author'] ?? '',
        ownerTeacherId: m['owner_teacher_id'] ?? '',
        description: m['description'] ?? '',
        coverColor: m['cover_color'] ?? '#12324F',
        pages: m['pages'] ?? 100,
        price: (m['price'] ?? 0).toDouble(),
        isPremium: m['is_premium'] ?? true,
        requiresPayment: m['requires_payment'] ?? false,
        externalUrl: m['external_url'] ?? '',
        fileType: m['file_type'] ?? 'pdf',
        categoryId: m['category_id'] ?? '',
        subCategoryId: m['sub_category_id'] ?? '',
        subjectId: m['subject_id'] ?? '',
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'owner_teacher_id': ownerTeacherId,
        'description': description,
        'cover_color': coverColor,
        'pages': pages,
        'price': price,
        'is_premium': isPremium,
        'requires_payment': requiresPayment,
        'external_url': externalUrl,
        'file_type': fileType,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'subject_id': subjectId,
        'created_at': createdAt,
      };

  Ebook copyWith({
    String? title,
    String? author,
    String? ownerTeacherId,
    String? description,
    double? price,
    bool? isPremium,
    bool? requiresPayment,
    String? externalUrl,
    String? fileType,
    String? coverColor,
  }) =>
      Ebook(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        ownerTeacherId: ownerTeacherId ?? this.ownerTeacherId,
        description: description ?? this.description,
        coverColor: coverColor ?? this.coverColor,
        pages: pages,
        price: price ?? this.price,
        isPremium: isPremium ?? this.isPremium,
        requiresPayment: requiresPayment ?? this.requiresPayment,
        externalUrl: externalUrl ?? this.externalUrl,
        fileType: fileType ?? this.fileType,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        subjectId: subjectId,
        createdAt: createdAt,
      );
}
// ───────────────────────────── purchases / access requests ────────────
class Purchase {
  final String id;
  final String userId;
  final String ebookId;
  final String status;
  final bool canDownloadPdf;
  final String requestedAt;
  final String decidedAt;
  final String ownerTeacherId;

  Purchase({
    required this.id,
    required this.userId,
    required this.ebookId,
    this.status = 'pending',
    this.canDownloadPdf = false,
    String? requestedAt,
    this.decidedAt = '',
    this.ownerTeacherId = '',
  }) : requestedAt = requestedAt ?? DateTime.now().toIso8601String();

  factory Purchase.fromMap(Map<String, dynamic> m) => Purchase(
        id: m['id'] ?? '',
        userId: m['user_id'] ?? '',
        ebookId: m['ebook_id'] ?? '',
        status: m['status'] ?? 'pending',
        canDownloadPdf: m['can_download_pdf'] ?? false,
        requestedAt: m['requested_at'],
        decidedAt: m['decided_at'] ?? '',
        ownerTeacherId: m['owner_teacher_id'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'ebook_id': ebookId,
        'status': status,
        'can_download_pdf': canDownloadPdf,
        'requested_at': requestedAt,
        'decided_at': decidedAt,
        'owner_teacher_id': ownerTeacherId,
      };
}

// ───────────────────────────── messages (Q→Teacher, private) ──────────
class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    String? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toIso8601String();

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] ?? '',
        threadId: m['thread_id'] ?? '',
        senderId: m['sender_id'] ?? '',
        senderName: m['sender_name'] ?? '',
        text: m['text'] ?? '',
        timestamp: m['timestamp'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'thread_id': threadId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'timestamp': timestamp,
      };
}

class QuestionThread {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String lastMessage;
  final String updatedAt;

  QuestionThread({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    this.lastMessage = '',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory QuestionThread.fromMap(Map<String, dynamic> m) => QuestionThread(
        id: m['id'] ?? '',
        studentId: m['student_id'] ?? '',
        studentName: m['student_name'] ?? '',
        teacherId: m['teacher_id'] ?? '',
        teacherName: m['teacher_name'] ?? '',
        lastMessage: m['last_message'] ?? '',
        updatedAt: m['updated_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'student_name': studentName,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'last_message': lastMessage,
        'updated_at': updatedAt,
      };
}

// ───────────────────────────── announcements ──────────────────────────
class Announcement {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    String? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        createdAt: m['created_at'],
        isActive: m['is_active'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt,
        'is_active': isActive,
      };
}
// ───────────────────────────── video_classes ──────────────────────────
class VideoClass {
  final String id;
  final String title;
  final String videoId;
  final String url;
  final String categoryId;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String chapterId;
  final String chapterName;
  final String description;
  final bool isPremium;
  final bool isActive;
  final String createdAt;

  VideoClass({
    required this.id,
    required this.title,
    required this.videoId,
    this.url = '',
    this.categoryId = '',
    this.classId = '',
    this.className = '',
    this.subjectId = '',
    this.subjectName = '',
    this.chapterId = '',
    this.chapterName = '',
    this.description = '',
    this.isPremium = true,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  String get thumbnail => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  factory VideoClass.fromMap(Map<String, dynamic> m) => VideoClass(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        videoId: m['video_id'] ?? '',
        url: m['url'] ?? '',
        categoryId: m['category_id'] ?? '',
        classId: m['class_id'] ?? '',
        className: m['class_name'] ?? '',
        subjectId: m['subject_id'] ?? '',
        subjectName: m['subject_name'] ?? '',
        chapterId: m['chapter_id'] ?? '',
        chapterName: m['chapter_name'] ?? '',
        description: m['description'] ?? '',
        isPremium: m['is_premium'] ?? true,
        isActive: m['is_active'] ?? true,
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'video_id': videoId,
        'url': url,
        'category_id': categoryId,
        'class_id': classId,
        'class_name': className,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'chapter_id': chapterId,
        'chapter_name': chapterName,
        'description': description,
        'is_premium': isPremium,
        'is_active': isActive,
        'created_at': createdAt,
      };

  VideoClass copyWith({
    String? title,
    String? videoId,
    String? url,
    String? categoryId,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? chapterName,
    String? description,
    bool? isPremium,
    bool? isActive,
  }) =>
      VideoClass(
        id: id,
        title: title ?? this.title,
        videoId: videoId ?? this.videoId,
        url: url ?? this.url,
        categoryId: categoryId ?? this.categoryId,
        classId: classId ?? this.classId,
        className: className ?? this.className,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        chapterId: chapterId ?? this.chapterId,
        chapterName: chapterName ?? this.chapterName,
        description: description ?? this.description,
        isPremium: isPremium ?? this.isPremium,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

// ───────────────────────────── subscription_plans ─────────────────────
class SubscriptionPlan {
  final String id;
  final int months;
  final double price;
  final String labelBn;
  final String labelEn;
  final int days;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.months,
    required this.price,
    this.labelBn = '',
    this.labelEn = '',
    this.days = 30,
    this.isActive = true,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> m) => SubscriptionPlan(
        id: m['id'] ?? '',
        months: (m['months'] ?? 1) as int,
        price: (m['price'] ?? 0).toDouble(),
        labelBn: m['label_bn'] ?? '',
        labelEn: m['label_en'] ?? '',
        days: (m['days'] ?? 30) as int,
        isActive: m['is_active'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'months': months,
        'price': price,
        'label_bn': labelBn,
        'label_en': labelEn,
        'days': days,
        'is_active': isActive,
      };
}
// ───────────────────────────── audit_logs ─────────────────────────────
class AuditLog {
  final String id;
  final String action;
  final String targetUser;
  final String detail;
  final String timestamp;
  final String actor;

  AuditLog({
    required this.id,
    required this.action,
    required this.targetUser,
    this.detail = '',
    String? timestamp,
    this.actor = 'admin',
  }) : timestamp = timestamp ?? DateTime.now().toIso8601String();

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'] ?? '',
        action: m['action'] ?? '',
        targetUser: m['target_user'] ?? '',
        detail: m['detail'] ?? '',
        timestamp: m['timestamp'],
        actor: m['actor'] ?? 'admin',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'action': action,
        'target_user': targetUser,
        'detail': detail,
        'timestamp': timestamp,
        'actor': actor,
      };
}

// ───────────────────────── study_resources ────────────────────────────
class StudyResource {
  final String id;
  final String title;
  final String type;
  final String description;
  final String fileUrl;
  final String fileType;
  final String externalUrl;
  final bool isPremium;
  final String categoryId;
  final String subCategoryId;
  final String subCategoryName;
  final String streamKey;
  final String subjectId;
  final String subjectName;
  final String chapterId;
  final String chapterName;
  final String createdAt;

  StudyResource({
    required this.id,
    required this.title,
    this.type = 'note',
    this.description = '',
    this.fileUrl = '',
    this.fileType = 'pdf',
    this.externalUrl = '',
    this.isPremium = true,
    this.categoryId = '',
    this.subCategoryId = '',
    this.subCategoryName = '',
    this.streamKey = '',
    this.subjectId = '',
    this.subjectName = '',
    this.chapterId = '',
    this.chapterName = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory StudyResource.fromMap(Map<String, dynamic> m) => StudyResource(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        type: m['type'] ?? 'note',
        description: m['description'] ?? '',
        fileUrl: m['file_url'] ?? '',
        fileType: m['file_type'] ?? 'pdf',
        externalUrl: m['external_url'] ?? '',
        isPremium: m['is_premium'] ?? true,
        categoryId: m['category_id'] ?? '',
        subCategoryId: m['sub_category_id'] ?? '',
        subCategoryName: m['sub_category_name'] ?? '',
        streamKey: m['stream_key'] ?? '',
        subjectId: m['subject_id'] ?? '',
        subjectName: m['subject_name'] ?? '',
        chapterId: m['chapter_id'] ?? '',
        chapterName: m['chapter_name'] ?? '',
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'description': description,
        'file_url': fileUrl,
        'file_type': fileType,
        'external_url': externalUrl,
        'is_premium': isPremium,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'sub_category_name': subCategoryName,
        'stream_key': streamKey,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'chapter_id': chapterId,
        'chapter_name': chapterName,
        'created_at': createdAt,
      };

  StudyResource copyWith({
    String? title,
    String? type,
    String? description,
    String? fileUrl,
    String? fileType,
    String? externalUrl,
    bool? isPremium,
    String? chapterId,
    String? chapterName,
  }) =>
      StudyResource(
        id: id,
        title: title ?? this.title,
        type: type ?? this.type,
        description: description ?? this.description,
        fileUrl: fileUrl ?? this.fileUrl,
        fileType: fileType ?? this.fileType,
        externalUrl: externalUrl ?? this.externalUrl,
        isPremium: isPremium ?? this.isPremium,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        subCategoryName: subCategoryName,
        streamKey: streamKey,
        subjectId: subjectId,
        subjectName: subjectName,
        chapterId: chapterId ?? this.chapterId,
        chapterName: chapterName ?? this.chapterName,
        createdAt: createdAt,
      );
}
