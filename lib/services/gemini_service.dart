import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/models.dart';

/// E&P Science — Smart Generator & Smart Tutor engine (powered by Gemini).
///
/// NOTE: User-facing copy never says "AI". The engine is presented to learners
/// as the "স্মার্ট জেনারেটর" (Smart Generator) and "স্মার্ট টিউটর".
///
///  1. Admin bulk question generation
///  2. Student on-demand practice sets
///  3. Live Smart Tutor chat
///  4. "একই ধরনের প্রশ্ন" (similar question) variants
///
/// When no API key is configured a deterministic offline engine produces
/// fully structured results so the platform is demo-able with ZERO credentials.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  bool get isLive => AppConfig.hasGeminiKey;

  // ─────────────────────────────────────────────────────────
  //  Prompt templates
  // ─────────────────────────────────────────────────────────
  static String questionGenPrompt({
    required String category,
    required String subCategory,
    required String subject,
    required String chapter,
    required String difficulty,
    required int count,
  }) =>
      '''
You are an expert exam-setter for Bangladeshi academic (Class 9-12 / HSC /
Admission) and competitive (BCS, Bank, Primary, Govt) exams.
Generate exactly $count multiple-choice questions.

CONTEXT:
- Category: $category
- Class/Exam Group: $subCategory
- Subject: $subject
- Chapter/Topic: $chapter
- Difficulty: $difficulty

OUTPUT: Return ONLY a valid JSON array (no markdown, no commentary).
Each element MUST have EXACTLY these keys:
{
  "question_text": "string",
  "option_a": "string",
  "option_b": "string",
  "option_c": "string",
  "option_d": "string",
  "option_e": "",
  "correct_answer": "A|B|C|D|E",
  "explanation": "step-by-step reasoning",
  "exam_tag": "string  e.g. 46th BCS / HSC Board 2024",
  "difficulty_level": "Easy|Medium|Hard"
}
RULES:
- Distractors must be plausible; only ONE correct option.
- "explanation" must justify the answer and briefly reject wrong options.
- Match the requested difficulty. For BCS/Hard also allow negative-marking style.
- Never use commercial, import-export, letter-of-credit or L/C style content.
''';

  static const String tutorSystemPrompt = '''
You are the "E&P Science স্মার্ট টিউটর" — a friendly bilingual (Bangla + English)
study coach for Class 9-12 (HSC), Admission and competitive jobs (BCS, Bank,
Primary, Govt). Explain simply, give examples, and when the student asks for
MCQs, also return a JSON practice block the app can turn into a quiz.
Never use commercial, import-export or L/C related material.
''';

  // ─────────────────────────────────────────────────────────
  //  1) Structured MCQ generation (Admin + Student)
  // ─────────────────────────────────────────────────────────
  Future<List<Question>> generateQuestions({
    required String categoryId,
    required String categoryName,
    required String subCategoryId,
    required String subCategoryName,
    required String subjectId,
    required String subjectName,
    required String chapterId,
    required String chapterName,
    String difficulty = 'Medium',
    int count = 5,
    bool premium = true,
    String generatedBy = 'Generator',
  }) async {
    List<Map<String, dynamic>> raw;

    if (isLive) {
      try {
        raw = await _callGeminiForQuestions(
          prompt: questionGenPrompt(
            category: categoryName,
            subCategory: subCategoryName,
            subject: subjectName,
            chapter: chapterName,
            difficulty: difficulty,
            count: count,
          ),
          count: count,
        );
      } catch (e) {
        debugPrint('Smart generator live call failed, offline engine used: $e');
        raw = _offlineGenerate(
          subjectName: subjectName,
          chapterName: chapterName,
          difficulty: difficulty,
          count: count,
        );
      }
    } else {
      raw = _offlineGenerate(
        subjectName: subjectName,
        chapterName: chapterName,
        difficulty: difficulty,
        count: count,
      );
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    return <Question>[
      for (var i = 0; i < raw.length; i++)
        Question(
          id: 'q_gen_${stamp}_$i',
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          subjectId: subjectId,
          chapterId: chapterId,
          questionText: raw[i]['question_text'] ?? '',
          optionA: raw[i]['option_a'] ?? '',
          optionB: raw[i]['option_b'] ?? '',
          optionC: raw[i]['option_c'] ?? '',
          optionD: raw[i]['option_d'] ?? '',
          optionE: raw[i]['option_e'] ?? '',
          correctAnswer: (raw[i]['correct_answer'] ?? 'A')
              .toString()
              .toUpperCase(),
          explanation: raw[i]['explanation'] ?? '',
          examTag: raw[i]['exam_tag'] ?? 'স্মার্ট জেনারেটর',
          difficultyLevel: raw[i]['difficulty_level'] ?? difficulty,
          isPremium: premium,
          generatedBy: generatedBy,
        ),
    ];
  }

  /// Variant of an existing question ("একই ধরনের প্রশ্ন").
  Future<Question> trySimilar(Question q, {String? chapterName}) async {
    final list = await generateQuestions(
      categoryId: q.categoryId,
      categoryName: q.categoryId,
      subCategoryId: q.subCategoryId,
      subCategoryName: q.subCategoryId,
      subjectId: q.subjectId,
      subjectName: q.subjectId,
      chapterId: q.chapterId,
      chapterName: chapterName ?? q.examTag,
      difficulty: q.difficultyLevel,
      count: 1,
      premium: q.isPremium,
    );
    return list.first;
  }

  // ─────────────────────────────────────────────────────────
  //  3) Live Smart Tutor chat
  // ─────────────────────────────────────────────────────────
  Future<String> tutorReply(
    String userMessage, {
    List<Map<String, String>> history = const [],
  }) async {
    if (isLive) {
      try {
        return await _callGeminiChat(userMessage, history);
      } catch (e) {
        debugPrint('Smart tutor live call failed, offline tutor used: $e');
      }
    }
    return _offlineTutor(userMessage);
  }

  /// Extracts an embedded JSON practice block (if any) from a tutor reply.
  List<Question> extractPracticeSet(String reply, String topic) {
    final match = RegExp(r'\[[\s\S]*\]').firstMatch(reply);
    if (match != null) {
      try {
        final decoded = jsonDecode(match.group(0)!) as List;
        final stamp = DateTime.now().millisecondsSinceEpoch;
        return [
          for (var i = 0; i < decoded.length; i++)
            Question(
              id: 'q_tutor_${stamp}_$i',
              categoryId: 'cat_academic',
              subCategoryId: 'sub_custom',
              subjectId: 'subj_custom',
              chapterId: 'ch_custom',
              questionText: (decoded[i] as Map)['question_text'] ?? '',
              optionA: (decoded[i] as Map)['option_a'] ?? '',
              optionB: (decoded[i] as Map)['option_b'] ?? '',
              optionC: (decoded[i] as Map)['option_c'] ?? '',
              optionD: (decoded[i] as Map)['option_d'] ?? '',
              correctAnswer: ((decoded[i] as Map)['correct_answer'] ?? 'A')
                  .toString(),
              explanation: (decoded[i] as Map)['explanation'] ?? '',
              examTag: topic,
              generatedBy: 'Generator',
            ),
        ];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────
  //  HTTP plumbing
  // ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _callGeminiForQuestions({
    required String prompt,
    required int count,
  }) async {
    final url = Uri.parse(
      '${AppConfig.geminiBaseUrl}/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.8,
        'responseMimeType': 'application/json',
      },
    });
    final res = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('Gemini ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = _stripFences(text);
    final decoded = jsonDecode(cleaned) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<String> _callGeminiChat(
    String message,
    List<Map<String, String>> history,
  ) async {
    final url = Uri.parse(
      '${AppConfig.geminiBaseUrl}/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': tutorSystemPrompt},
        ],
      },
      ...history.map(
        (h) => {
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': h['text'] ?? ''},
          ],
        },
      ),
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];
    final res = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'contents': contents}),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('Gemini ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }

  // ─────────────────────────────────────────────────────────
  //  Offline deterministic engine (no credentials needed)
  // ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _offlineGenerate({
    required String subjectName,
    required String chapterName,
    required String difficulty,
    required int count,
  }) {
    final templates = _templatesFor(chapterName, subjectName);
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final t = templates[i % templates.length];
      out.add({
        'question_text': '${i + 1}. ${t.q}',
        'option_a': t.opts[0],
        'option_b': t.opts[1],
        'option_c': t.opts[2],
        'option_d': t.opts[3],
        'option_e': '',
        'correct_answer': t.answer,
        'explanation': t.expl,
        'exam_tag': '$subjectName • $chapterName',
        'difficulty_level': difficulty,
      });
    }
    return out;
  }

  List<_Tpl> _templatesFor(String chapter, String subject) {
    // Domain-aware academic / job templates (no commercial content).
    final key = '$chapter $subject'.toLowerCase();
    if (key.contains('পদার্থ') || key.contains('physics') || key.contains('vector')) {
      return [
        _Tpl(
          'নিচের কোনটি ভেক্টর রাশি?',
          ['দ্রুতি', 'সরণ', 'ভর', 'কাজ'],
          'B',
          'সরণের মান ও দিক উভয়ই আছে, তাই এটি ভেক্টর রাশি। দ্রুতি, ভর ও কাজ স্কেলার।',
        ),
        _Tpl(
          'নিউটনের দ্বিতীয় সূত্র অনুসারে বল = ?',
          ['ভর × বেগ', 'ভর × ত্বরণ', 'ভর ÷ ত্বরণ', 'বেগ ÷ সময়'],
          'B',
          'F = ma; বল = ভর × ত্বরণ — এটিই নিউটনের দ্বিতীয় সূত্র।',
        ),
        _Tpl(
          'মহাকর্ষীয় ধ্রুবক G-এর মান কত?',
          ['6.67×10⁻¹¹ N·m²/kg²', '9.8 m/s²', '3×10⁸ m/s', '1.6×10⁻¹⁹ C'],
          'A',
          'G = 6.674×10⁻¹¹ N·m²/kg² — সার্বজনীন মহাকর্ষীয় ধ্রুবক।',
        ),
        _Tpl(
          'একটি বস্তুর ভর দ্বিগুণ করলে তার গতিশক্তি—',
          ['অপরিবর্তিত', 'দ্বিগুণ', 'চারগুণ', 'অর্ধেক'],
          'B',
          'KE = ½mv², ভর দ্বিগুণ হলে বেগ অপরিবর্তিত থাকলে গতিশক্তি দ্বিগুণ হয়।',
        ),
      ];
    }
    if (key.contains('রসায়ন') || key.contains('chem')) {
      return [
        _Tpl(
          'পরমাণুর কেন্দ্রে কী থাকে?',
          ['ইলেকট্রন', 'প্রোটন ও নিউট্রন', 'শুধু প্রোটন', 'শুধু নিউট্রন'],
          'B',
          'নিউক্লিয়াসে প্রোটন ও নিউট্রন থাকে; ইলেকট্রন বাইরে ঘোরে।',
        ),
        _Tpl(
          'STP-তে 1 মোল গ্যাসের আয়তন কত?',
          ['22.4 L', '24 L', '11.2 L', '1 L'],
          'A',
          'STP-তে যেকোনো আদর্শ গ্যাসের 1 মোল = 22.4 লিটার।',
        ),
        _Tpl(
          'নিচের কোনটি ক্ষারীয় ধাতু?',
          ['Na', 'Fe', 'Cl', 'O'],
          'A',
          'সোডিয়াম (Na) পর্যায় সারণির গ্রুপ-১ এর ক্ষারীয় ধাতু।',
        ),
      ];
    }
    if (key.contains('গণিত') || key.contains('math')) {
      return [
        _Tpl(
          'একটি 2×2 ম্যাট্রিক্সের ডিটারমিন্যান্ট |A| = 0 হলে ম্যাট্রিক্সটি—',
          ['অব্যস্ত', 'ব্যস্ত', 'অভেদক', 'শূন্য ম্যাট্রিক্স'],
          'A',
          'ডিটারমিন্যান্ট শূন্য হলে ম্যাট্রিক্স singular বা অব্যস্ত।',
        ),
        _Tpl(
          'log₁₀ 1000 = ?',
          ['2', '3', '10', '100'],
          'B',
          '10³ = 1000, তাই log₁₀ 1000 = 3।',
        ),
        _Tpl(
          'sin²θ + cos²θ = ?',
          ['0', '1', '2', 'sin2θ'],
          'B',
          'ত্রিকোণমিতিক অভেদ অনুসারে sin²θ + cos²θ = 1।',
        ),
      ];
    }
    if (key.contains('জীব') || key.contains('bio')) {
      return [
        _Tpl(
          'কোষের শক্তিঘর বলা হয় কোনটিকে?',
          ['নিউক্লিয়াস', 'মাইটোকন্ড্রিয়া', 'রাইবোজোম', 'গলগি বডি'],
          'B',
          'মাইটোকন্ড্রিয়া ATP উৎপাদন করে, তাই একে কোষের শক্তিঘর বলা হয়।',
        ),
        _Tpl(
          'মানবদেহে রক্তের pH কত?',
          ['৬.৪', '৭.০', '৭.৪', '৮.০'],
          'C',
          'স্বাভাবিক মানব রক্তের pH প্রায় ৭.৪ (সামান্য ক্ষারীয়)।',
        ),
      ];
    }
    if (key.contains('হিসাব') || key.contains('account') || key.contains('finance')) {
      return [
        _Tpl(
          'হিসাববিজ্ঞানের মূল সমীকরণ কোনটি?',
          [
            'সম্পদ = দায় + মালিকের ইকুইটি',
            'সম্পদ = দায় − ইকুইটি',
            'দায় = সম্পদ + ইকুইটি',
            'ইকুইটি = সম্পদ + দায়',
          ],
          'A',
          "Assets = Liabilities + Owner's Equity — হিসাববিজ্ঞানের ভিত্তি সমীকরণ।",
        ),
        _Tpl(
          'রেওয়ামিল প্রস্তুত করার মূল উদ্দেশ্য কী?',
          ['মুনাফা নির্ণয়', 'হিসাবের গাণিতিক শুদ্ধতা যাচাই', 'নগদ প্রবাহ জানা', 'কর হিসাব'],
          'B',
          'রেওয়ামিল ডেবিট-ক্রেডিট মিলিয়ে হিসাবের গাণিতিক নির্ভুলতা যাচাই করে।',
        ),
      ];
    }
    // Generic fallback (still academic & plausible).
    return [
      _Tpl(
        '"$chapter" অধ্যায়ের মূল বিষয় কী?',
        ['কেবল মুখস্থ', 'মৌলিক ধারণা ও প্রয়োগ', 'শুধু সূত্র', 'ইতিহাস'],
        'B',
        '"$chapter" অধ্যায়ে মৌলিক ধারণা ও তার প্রয়োগই মূল আলোচ্য বিষয়।',
      ),
      _Tpl(
        '$subject-এ "$chapter" পড়ার সময় শিক্ষার্থীরা যে ভুলটি বেশি করে—',
        ['দ্রুত পড়া', 'একক/চিহ্ন উপেক্ষা', 'ভুল প্রশ্ন পড়া', 'ক্যালকুলেটর না থাকা'],
        'B',
        'একক ও চিহ্নের নিয়ম উপেক্ষা করাই "$chapter" প্রশ্নে সবচেয়ে সাধারণ ভুল।',
      ),
      _Tpl(
        '২০০ নম্বরের মডেল টেস্টে একটি ভুল উত্তরে কত নম্বর কাটা হয়?',
        ['০', '−০.২৫', '−০.৫০', '−১.০০'],
        'C',
        'E&P Science মডেল টেস্টে প্রতিটি ভুল উত্তরে −০.৫০ নেগেটিভ মার্কিং প্রযোজ্য।',
      ),
    ];
  }

  String _offlineTutor(String msg) {
    final m = msg.toLowerCase();
    final wantsMcq = m.contains('mcq') ||
        m.contains('question') ||
        m.contains('প্রশ্ন') ||
        RegExp(r'\d+\s*(hard|easy|medium)?\s*(questions|mcq)').hasMatch(m);

    final topic = _guessTopic(msg);

    if (wantsMcq) {
      final count = _guessCount(msg);
      final json = _templatesFor(topic, topic)
          .take(count)
          .map(
            (t) => {
              'question_text': t.q,
              'option_a': t.opts[0],
              'option_b': t.opts[1],
              'option_c': t.opts[2],
              'option_d': t.opts[3],
              'correct_answer': t.answer,
              'explanation': t.expl,
            },
          )
          .toList();
      return '''এখানে "$topic" বিষয়ে $countটি প্রশ্ন তৈরি করলাম 👇

${List.generate(json.length, (i) => '${i + 1}. ${json[i]['question_text']}').join('\n')}

নিচের প্রশ্নগুলো প্র্যাকটিস সেট হিসেবে অ্যাপে খুলতে "Start Practice" চাপুন অথবা যেকোনো প্রশ্নে আরও ব্যাখ্যা চাইতে পারেন।

```json
${jsonEncode(json)}
```''';
    }

    return '''চমৎকার প্রশ্ন! "$topic" নিয়ে সংক্ষেপে:

• মূল ধারণা: বিষয়টির মৌলিক সংজ্ঞা ও প্রয়োগ বুঝুন।
• টিপস: বিগত সালের প্রশ্ন বিশ্লেষণ করলে প্যাটার্ন ধরা পড়ে।
• চাইলে বলুন — "$topic নিয়ে ৫টি hard MCQ" — আমি সঙ্গে সঙ্গে একটি প্র্যাকটিস সেট বানিয়ে দেব।''';
  }

  String _guessTopic(String msg) {
    final cleaned = msg
        .replaceAll(
          RegExp(
            r'give me|generate|create|please|নিয়ে|তৈরি|করো|mcq|questions?|hard|easy|medium|টি|\d+',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'সাধারণ জ্ঞান';
    return cleaned;
  }

  int _guessCount(String msg) {
    final m = RegExp(r'(\d+)').firstMatch(msg);
    if (m != null) {
      final n = int.tryParse(m.group(1)!) ?? 5;
      return n.clamp(1, 20);
    }
    return 5;
  }
}

class _Tpl {
  final String q;
  final List<String> opts;
  final String answer;
  final String expl;
  _Tpl(this.q, this.opts, this.answer, this.expl);
}
