import '../models/models.dart';
import 'curriculum_seed.dart';

/// E&P Science — seed data.
///
/// The full syllabus (Class 6–12 with SSC/HSC streams, Madrasah, Technical,
/// Admission) plus the four Job-Preparation categories comes from the
/// GENERATED [CurriculumSeed] (see scripts/gen_curriculum_dart.py). This file
/// adds teachers, e-books, sample study resources, announcements and a starter
/// question bank.
class SeedData {
  // ───────────────────────── SYLLABUS (generated) ───────────────
  static List<Category> get categories => CurriculumSeed.categories;
  static List<SubCategory> get subCategories => CurriculumSeed.subCategories;
  static List<Subject> get subjects => CurriculumSeed.subjects;
  static List<Chapter> get chapters => CurriculumSeed.chapters;

  static Subject? subjectById(String id) =>
      subjects.where((s) => s.id == id).firstOrNull;

  // ───────────────────────── TEACHERS ───────────────────────────
  static final List<Teacher> teachers = [
    Teacher(
      id: 't_1',
      name: 'ইঞ্জিনিয়ার শামীম স্যার',
      title: 'প্রভাষক (Physics & Higher Math Specialist)',
      qualification: 'B.Sc. Engg.',
      subjects: 'পদার্থ বিজ্ঞান + উচ্চতর গণিত',
      targetClasses: 'একাদশ-দ্বাদশ শ্রেণি (Academic + Admission)',
      phone: '01627-444526',
      email: 'ayatislam5555@gmail.com',
      location: 'জাকির হোসেন রোড, লালমাটিয়া, ঢাকা',
      isApproved: false,
    ),
    Teacher(
      id: 't_2',
      name: 'শাওন স্যার',
      title: 'প্রভাষক (জীব বিজ্ঞান)',
      qualification: 'B.Sc. (RU), M.Sc. (RU)',
      subjects: 'জীব বিজ্ঞান (Biology)',
      targetClasses: 'একাদশ-দ্বাদশ শ্রেণি (Academic + Admission)',
      phone: '01701-008759',
      location: 'জাকির হোসেন রোড, লালমাটিয়া, ঢাকা',
      isApproved: false,
    ),
    Teacher(
      id: 't_3',
      name: 'নাজমুল স্যার',
      title: 'প্রভাষক (রসায়ন)',
      subjects: 'রসায়ন (Chemistry)',
      targetClasses: 'একাদশ-দ্বাদশ শ্রেণি (Academic + Admission)',
      phone: '01722962036',
      location: 'জাকির হোসেন রোড, লালমাটিয়া, ঢাকা',
      isApproved: false,
    ),
    Teacher(
      id: 't_4',
      name: 'সিয়াম স্যার',
      title: 'প্রভাষক',
      subjects: 'হিসাব বিজ্ঞান ও ফিন্যান্স (Accounting & Finance)',
      targetClasses: 'একাদশ-দ্বাদশ শ্রেণি (Academic + Admission)',
      phone: '01721-798379',
      location: 'জাকির হোসেন রোড, লালমাটিয়া, ঢাকা',
      isApproved: false,
    ),
  ];

  // ───────────────────────── E-BOOKS (external-link) ───────────
  static final List<Ebook> ebooks = [
    Ebook(
      id: 'book_physics_1',
      title: 'পদার্থবিজ্ঞান ১ম পত্র — একাদশ-দ্বাদশ',
      author: 'ইঞ্জিনিয়ার শামীম স্যার',
      ownerTeacherId: 't_1',
      description:
          'জাতীয় শিক্ষাক্রম অনুসারে একাদশ-দ্বাদশ শ্রেণির পদার্থবিজ্ঞান ১ম পত্রের পূর্ণাঙ্গ গাইড।',
      coverColor: '#12324F',
      pages: 320,
      price: 0,
      isPremium: false,
      requiresPayment: false,
      externalUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      categoryId: 'cat_academic',
      subCategoryId: 'cls_11__science',
      subjectId: 'subj_cls_11_science_physics_1st_paper',
    ),
    Ebook(
      id: 'book_chem_1',
      title: 'রসায়ন ১ম পত্র — একাদশ-দ্বাদশ',
      author: 'নাজমুল স্যার',
      ownerTeacherId: 't_3',
      description: 'রসায়নের মূল ধারণা, বিক্রিয়া ও অঙ্কের সমন্বিত গাইড।',
      coverColor: '#0E7C86',
      pages: 280,
      price: 200,
      isPremium: true,
      requiresPayment: true,
      externalUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      categoryId: 'cat_academic',
      subCategoryId: 'cls_11__science',
      subjectId: 'subj_cls_11_science_chemistry_1st_paper',
    ),
    Ebook(
      id: 'book_bio_1',
      title: 'জীববিজ্ঞান — MCQ প্র্যাকটিস',
      author: 'শাওন স্যার',
      ownerTeacherId: 't_2',
      description: 'একাদশ-দ্বাদশ ও এডমিশন জীববিজ্ঞানের MCQ ভিত্তিক প্র্যাকটিস বুক।',
      coverColor: '#2FB86B',
      pages: 200,
      price: 150,
      isPremium: true,
      requiresPayment: true,
      externalUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      categoryId: 'cat_academic',
      subCategoryId: 'cls_11__science',
      subjectId: 'subj_cls_11_science_biology_1st_paper',
    ),
    Ebook(
      id: 'book_bcs_gk',
      title: 'বিসিএস বাংলাদেশ বিষয়াবলী ডাইজেস্ট',
      author: 'E&P Science',
      ownerTeacherId: '',
      description: 'বিসিএস ও সরকারি চাকরির জন্য হাই-ইল্ড সাধারণ জ্ঞান।',
      coverColor: '#1D5FD0',
      pages: 240,
      price: 0,
      isPremium: true,
      requiresPayment: false,
      externalUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      categoryId: 'cat_job',
      subCategoryId: 'job_bcs',
      subjectId: 'subj_job_bcs_bangladesh_affairs',
    ),
  ];

  // ───────────────────────── STUDY RESOURCES (demo) ────────────
  static final List<StudyResource> studyResources = [
    StudyResource(
      id: 'sr_1',
      title: 'পদার্থবিজ্ঞান ১ম পত্র — অধ্যায়ভিত্তিক লেকচার শিট',
      type: 'lecture',
      description: 'সব অধ্যায়ের সূত্র, সংজ্ঞা ও গুরুত্বপূর্ণ গাণিতিক উদাহরণ।',
      fileUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      isPremium: false,
      categoryId: 'cat_academic',
      subCategoryId: 'cls_11__science',
      subCategoryName: 'একাদশ শ্রেণি — বিজ্ঞান',
      streamKey: 'science',
      subjectId: 'subj_cls_11_science_physics_1st_paper',
      subjectName: 'পদার্থবিজ্ঞান ১ম পত্র',
      chapterId: 'subj_cls_11_science_physics_1st_paper_ch1',
      chapterName: 'ভৌত রাশি ও পরিমাপ',
    ),
    StudyResource(
      id: 'sr_2',
      title: 'রসায়ন ১ম পত্র — নোট',
      type: 'note',
      description: 'রাসায়নিক সমীকরণ, বন্ধন ও দ্রবণ অধ্যায়ের সহজ নোট।',
      fileUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      isPremium: true,
      categoryId: 'cat_academic',
      subCategoryId: 'cls_11__science',
      subCategoryName: 'একাদশ শ্রেণি — বিজ্ঞান',
      streamKey: 'science',
      subjectId: 'subj_cls_11_science_chemistry_1st_paper',
      subjectName: 'রসায়ন ১ম পত্র',
      chapterId: 'subj_cls_11_science_chemistry_1st_paper_ch1',
      chapterName: 'পদার্থের অবস্থা',
    ),
    StudyResource(
      id: 'sr_3',
      title: 'বিসিএস বাংলাদেশ বিষয়াবলী — সাজেশন',
      type: 'suggestion',
      description: 'হাই-ইল্ড টপিক, বিগত বছরের প্রশ্ন বিশ্লেষণ ও সম্ভাব্য প্রশ্ন।',
      fileUrl: 'https://www.orimi.com/pdf-test.pdf',
      fileType: 'pdf',
      isPremium: true,
      categoryId: 'cat_job',
      subCategoryId: 'job_bcs',
      subCategoryName: 'বিসিএস প্রস্তুতি',
      streamKey: 'job',
      subjectId: 'subj_job_bcs_bangladesh_affairs',
      subjectName: 'বাংলাদেশ বিষয়াবলী',
      chapterId: 'subj_job_bcs_bangladesh_affairs_ch1',
      chapterName: 'ইতিহাস',
    ),
  ];

  // ───────────────────────── ANNOUNCEMENTS ──────────────────────
  static final List<Announcement> announcements = [
    Announcement(
      id: 'a1',
      title: 'E&P Science-এ স্বাগতম!',
      body: 'ষষ্ঠ-দ্বাদশ শ্রেণি (বিজ্ঞান, মানবিক, ব্যবসায় শিক্ষা), এডমিশন ও '
          'চাকুরি প্রস্তুতির সব কনটেন্ট এখন এক অ্যাপে। প্রো অ্যাক্সেস নিতে '
          'বিকাশে সেন্ড মানি করুন — ৫-১০ মিনিটেই অ্যাক্সেস।',
    ),
  ];

  // ───────────────────────── SAMPLE QUESTIONS ───────────────────
  static List<Question> get questions {
    final list = <Question>[];
    void add({
      required String subjectId,
      required String subCategoryId,
      required String chapterId,
      required String q,
      required List<String> options,
      required String answer,
      required String explanation,
      String examTag = 'E&P Model Test',
      String difficulty = 'Medium',
      bool premium = true,
    }) {
      final sub = subCategories.firstWhere((s) => s.id == subCategoryId);
      list.add(Question(
        id: 'q_${list.length + 1}',
        categoryId: sub.categoryId,
        subCategoryId: subCategoryId,
        subjectId: subjectId,
        chapterId: chapterId,
        questionText: q,
        optionA: options[0],
        optionB: options[1],
        optionC: options[2],
        optionD: options[3],
        optionE: options.length > 4 ? options[4] : '',
        correctAnswer: answer,
        explanation: explanation,
        examTag: examTag,
        difficultyLevel: difficulty,
        isPremium: premium,
        generatedBy: 'Manual',
      ));
    }

    // Physics (Class 11 Science) — free ch1-2
    add(
      subjectId: 'subj_cls_11_science_physics_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_physics_1st_paper_ch1',
      q: 'নিচের কোনটি ভেক্টর রাশি?',
      options: ['দ্রুতি', 'সরণ', 'ভর', 'কাজ'],
      answer: 'B',
      explanation: 'সরণের মান ও দিক উভয়ই আছে, তাই এটি ভেক্টর রাশি। দ্রুতি, ভর ও কাজ স্কেলার।',
      difficulty: 'Easy',
      premium: false,
    );
    add(
      subjectId: 'subj_cls_11_science_physics_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_physics_1st_paper_ch2',
      q: 'নিউটনের দ্বিতীয় সূত্র অনুসারে বল = ?',
      options: ['ভর × বেগ', 'ভর × ত্বরণ', 'ভর ÷ ত্বরণ', 'বেগ ÷ সময়'],
      answer: 'B',
      explanation: 'F = ma; বল = ভর × ত্বরণ — এটিই নিউটনের দ্বিতীয় সূত্র।',
      premium: false,
    );
    add(
      subjectId: 'subj_cls_11_science_physics_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_physics_1st_paper_ch4',
      q: 'মহাকর্ষীয় ধ্রুবক G-এর মান কত?',
      options: ['6.67×10⁻¹¹ N·m²/kg²', '9.8 m/s²', '3×10⁸ m/s', '1.6×10⁻¹⁹ C'],
      answer: 'A',
      explanation: 'G = 6.674×10⁻¹¹ N·m²/kg² — সার্বজনীন মহাকর্ষীয় ধ্রুবক।',
      difficulty: 'Hard',
      premium: true,
    );
    // Chemistry
    add(
      subjectId: 'subj_cls_11_science_chemistry_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_chemistry_1st_paper_ch2',
      q: 'পরমাণুর কেন্দ্রে কী থাকে?',
      options: ['ইলেকট্রন', 'প্রোটন ও নিউট্রন', 'শুধু প্রোটন', 'শুধু নিউট্রন'],
      answer: 'B',
      explanation: 'নিউক্লিয়াসে প্রোটন ও নিউট্রন থাকে; ইলেকট্রন বাইরে ঘোরে।',
      difficulty: 'Easy',
      premium: false,
    );
    // Higher Math
    add(
      subjectId: 'subj_cls_11_science_higher_mathematics_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_higher_mathematics_1st_paper_ch1',
      q: 'একটি 2×2 ম্যাট্রিক্সের ডিটারমিন্যান্ট |A| = 0 হলে ম্যাট্রিক্সটি—',
      options: ['অব্যস্ত', 'ব্যস্ত', 'অভেদক', 'শূন্য ম্যাট্রিক্স'],
      answer: 'A',
      explanation: 'ডিটারমিন্যান্ট শূন্য হলে ম্যাট্রিক্স singular বা অব্যস্ত।',
      premium: true,
    );
    // Biology
    add(
      subjectId: 'subj_cls_11_science_biology_1st_paper',
      subCategoryId: 'cls_11__science',
      chapterId: 'subj_cls_11_science_biology_1st_paper_ch1',
      q: 'কোষের শক্তিঘর বলা হয় কোনটিকে?',
      options: ['নিউক্লিয়াস', 'মাইটোকন্ড্রিয়া', 'রাইবোজোম', 'গলগি বডি'],
      answer: 'B',
      explanation: 'মাইটোকন্ড্রিয়া ATP উৎপাদন করে, তাই একে কোষের শক্তিঘর বলা হয়।',
      difficulty: 'Easy',
      premium: false,
    );
    // Accounting (Business)
    add(
      subjectId: 'subj_cls_11_business_accounting_1st_paper',
      subCategoryId: 'cls_11__business',
      chapterId: 'subj_cls_11_business_accounting_1st_paper_ch1',
      q: 'হিসাববিজ্ঞানের মূল সমীকরণ কোনটি?',
      options: [
        'সম্পদ = দায় + মালিকের ইকুইটি',
        'সম্পদ = দায় − ইকুইটি',
        'দায় = সম্পদ + ইকুইটি',
        'ইকুইটি = সম্পদ + দায়',
      ],
      answer: 'A',
      explanation: 'Assets = Liabilities + Owner\'s Equity — হিসাববিজ্ঞানের ভিত্তি সমীকরণ।',
      difficulty: 'Easy',
      premium: false,
    );
    // Admission
    add(
      subjectId: 'subj_admission_physics_admission',
      subCategoryId: 'sub_admission',
      chapterId: 'subj_admission_physics_admission_ch1',
      q: 'A body moves with uniform acceleration. Its velocity-time graph is:',
      options: ['Horizontal line', 'Straight inclined line', 'Parabola', 'Circle'],
      answer: 'B',
      explanation: 'Uniform acceleration ⇒ constant slope ⇒ straight inclined line on a v-t graph.',
      examTag: 'Admission',
      premium: true,
    );
    // BCS / Job
    add(
      subjectId: 'subj_job_bcs_bangladesh_affairs',
      subCategoryId: 'job_bcs',
      chapterId: 'subj_job_bcs_bangladesh_affairs_ch1',
      q: 'বাংলাদেশের সংবিধান কার্যকর হয় কোন তারিখে?',
      options: ['১৬ ডিসেম্বর ১৯৭২', '২৬ মার্চ ১৯৭২', '৪ নভেম্বর ১৯৭২', '১৭ এপ্রিল ১৯৭১'],
      answer: 'A',
      explanation: 'সংবিধান ৪ নভেম্বর ১৯৭২ গৃহীত, ১৬ ডিসেম্বর ১৯৭২ থেকে কার্যকর।',
      difficulty: 'Easy',
      premium: false,
    );
    add(
      subjectId: 'subj_job_bcs_bangla_language_literature',
      subCategoryId: 'job_bcs',
      chapterId: 'subj_job_bcs_bangla_language_literature_ch1',
      q: '\'অগ্নিবীণা\' কাব্যগ্রন্থের রচয়িতা কে?',
      options: ['রবীন্দ্রনাথ ঠাকুর', 'কাজী নজরুল ইসলাম', 'জীবনানন্দ দাশ', 'সুকুমার রায়'],
      answer: 'B',
      explanation: 'কাজী নজরুল ইসলামের প্রথম কাব্যগ্রন্থ অগ্নিবীণা (১৯২২)।',
      difficulty: 'Easy',
      premium: false,
    );
    add(
      subjectId: 'subj_job_bank_mathematics_quantitative_aptitude',
      subCategoryId: 'job_bank',
      chapterId: 'subj_job_bank_mathematics_quantitative_aptitude_ch1',
      q: 'A trader marks up goods 40% then gives 25% discount. Net profit %?',
      options: ['5%', '10%', '15%', '12.5%'],
      answer: 'A',
      explanation: 'Cost 100 → MP 140 → SP 105 → profit 5%.',
      difficulty: 'Hard',
      premium: true,
    );
    add(
      subjectId: 'subj_job_primary_general_knowledge_current_affairs',
      subCategoryId: 'job_primary',
      chapterId: 'subj_job_primary_general_knowledge_current_affairs_ch2',
      q: 'শিশুর প্রাথমিক সামাজিকীকরণের প্রধান কেন্দ্র কোনটি?',
      options: ['বিদ্যালয়', 'পরিবার', 'খেলার মাঠ', 'ধর্মীয় প্রতিষ্ঠান'],
      answer: 'B',
      explanation: 'পরিবার হলো শিশুর প্রথম ও প্রধান সামাজিকীকরণের কেন্দ্র।',
      difficulty: 'Easy',
      premium: false,
    );

    return list;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
