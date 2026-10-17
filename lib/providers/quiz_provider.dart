import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/local_db.dart';
import '../services/gemini_service.dart';
import '../config/app_config.dart';

/// Question shown during a practice/exam session, plus live user state.
class QuizItem {
  final Question question;
  String? selected; // 'A'..'E' or null
  bool get answered => selected != null;
  bool get isCorrect => selected == question.correctAnswer;
  QuizItem(this.question);
}

class WeaknessStat {
  final String chapterId;
  final String chapterName;
  final int attempts;
  final int wrong;
  WeaknessStat(this.chapterId, this.chapterName, this.attempts, this.wrong);
  double get accuracy => attempts == 0 ? 0 : (attempts - wrong) / attempts;
}

/// Practice engine: session building, chapter navigation (next/prev + swipe),
/// BCS negative marking, AI weakness identifier and similar-question support.
class QuizProvider extends ChangeNotifier {
  final LocalDb _db = LocalDb.instance;
  final GeminiService _ai = GeminiService.instance;

  List<QuizItem> items = [];
  int index = 0;
  bool isModelTest = false;
  bool sessionFinished = false;

  Subject? subject;
  List<Chapter> chapters = [];
  int chapterPos = 0;

  // Weakness tracking: chapterId -> [attempts, wrong]
  final Map<String, List<int>> _weakness = {};

  QuizItem? get current => items.isEmpty ? null : items[index];
  Chapter? get currentChapter => chapters.isEmpty ? null : chapters[chapterPos];
  int get total => items.length;
  int get answeredCount => items.where((e) => e.answered).length;
  bool get hasNext => index < items.length - 1;
  bool get hasPrev => index > 0;
  bool get hasNextChapter => chapterPos < chapters.length - 1;
  bool get hasPrevChapter => chapterPos > 0;

  int get correctCount => items.where((e) => e.answered && e.isCorrect).length;
  int get wrongCount => items.where((e) => e.answered && !e.isCorrect).length;

  double get rawScore => correctCount.toDouble();
  double get negativeDeduction =>
      isModelTest ? wrongCount * AppConfig.negativeMarking : 0;
  double get finalScore =>
      (rawScore - negativeDeduction).clamp(0, double.infinity);

  List<WeaknessStat> get weaknessReport {
    final out = <WeaknessStat>[];
    _weakness.forEach((chapterId, v) {
      final ch = _db.chapterById(chapterId);
      out.add(WeaknessStat(chapterId, ch?.name ?? chapterId, v[0], v[1]));
    });
    out.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return out;
  }

  // ───────── session builders ─────────
  void startChapter({
    required Subject subj,
    required List<Chapter> allChapters,
    required int startPos,
    bool modelTest = false,
  }) {
    subject = subj;
    chapters = allChapters;
    chapterPos = startPos;
    isModelTest = modelTest;
    _buildItems();
  }

  void _buildItems() {
    final ch = currentChapter;
    if (ch == null) {
      items = [];
    } else {
      final qs = _db.questionsOfChapter(ch.id);
      items = qs.map(QuizItem.new).toList();
    }
    index = 0;
    sessionFinished = false;
    notifyListeners();
  }

  void gotoChapter(int pos) {
    if (pos < 0 || pos >= chapters.length) return;
    chapterPos = pos;
    _buildItems();
  }

  void nextChapter() => gotoChapter(chapterPos + 1);
  void prevChapter() => gotoChapter(chapterPos - 1);

  /// Model test: pull questions across the whole subject.
  void startSubjectModelTest(
    Subject subj,
    List<Chapter> allChapters, {
    int limit = 30,
  }) {
    subject = subj;
    chapters = allChapters;
    chapterPos = 0;
    isModelTest = true;
    final qs = _db.questionsOfSubject(subj.id).take(limit).toList();
    items = qs.map(QuizItem.new).toList();
    index = 0;
    sessionFinished = false;
    notifyListeners();
  }

  // ───────── answering ─────────
  void select(String option) {
    final c = current;
    if (c == null || c.answered) return;
    c.selected = option;
    final chId = c.question.chapterId;
    final rec = _weakness.putIfAbsent(chId, () => [0, 0]);
    rec[0] += 1;
    if (!c.isCorrect) rec[1] += 1;
    notifyListeners();
  }

  void next() {
    if (hasNext) {
      index++;
      notifyListeners();
    } else {
      finish();
    }
  }

  void prev() {
    if (hasPrev) {
      index--;
      notifyListeners();
    }
  }

  void jump(int i) {
    if (i >= 0 && i < items.length) {
      index = i;
      notifyListeners();
    }
  }

  void finish() {
    sessionFinished = true;
    notifyListeners();
  }

  /// Inject an externally-generated set of questions (AI tutor practice).
  void setAdHocSession(List<Question> qs) {
    subject = null;
    chapters = [];
    chapterPos = 0;
    isModelTest = false;
    items = qs.map(QuizItem.new).toList();
    index = 0;
    sessionFinished = false;
    notifyListeners();
  }

  void reset() {
    items = [];
    index = 0;
    sessionFinished = false;
    subject = null;
    chapters = [];
    chapterPos = 0;
    notifyListeners();
  }

  // ───────── AI helpers ─────────
  Future<List<Question>> generatePractice({
    required int count,
    String difficulty = 'Medium',
    bool premium = true,
  }) async {
    final ch = currentChapter;
    if (ch == null || subject == null) return [];
    final generated = await _ai.generateQuestions(
      categoryId: 'ai',
      categoryName: 'AI Generator',
      subCategoryId: 'ai',
      subCategoryName: 'On-demand',
      subjectId: subject!.id,
      subjectName: subject!.name,
      chapterId: ch.id,
      chapterName: ch.name,
      difficulty: difficulty,
      count: count,
      premium: premium,
    );
    // Merge generated into the local bank so it persists for the session.
    await _db.addQuestions(generated);
    // Rebuild the current session with the freshly generated set.
    items = generated.map(QuizItem.new).toList();
    index = 0;
    sessionFinished = false;
    notifyListeners();
    return generated;
  }

  Future<Question?> trySimilar() async {
    final c = current;
    if (c == null) return null;
    final sim = await _ai.trySimilar(
      c.question,
      chapterName: currentChapter?.name ?? c.question.examTag,
    );
    final idx = items.indexWhere((e) => e.question.id == c.question.id);
    final newItem = QuizItem(sim);
    if (idx >= 0) {
      items[idx] = newItem;
    } else {
      items.add(newItem);
      index = items.length - 1;
    }
    await _db.addQuestions([sim]);
    await _db.deleteQuestion(c.question.id).catchError((_) {});
    notifyListeners();
    return sim;
  }
}
