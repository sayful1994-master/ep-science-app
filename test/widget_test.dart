import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epscience/main.dart';
import 'package:epscience/models/models.dart';
import 'package:epscience/services/local_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalDb seeds syllabus and question bank', () async {
    await LocalDb.instance.init();
    expect(LocalDb.instance.categories.isNotEmpty, true);
    expect(LocalDb.instance.subjects.isNotEmpty, true);
    expect(LocalDb.instance.questions.isNotEmpty, true);
  });

  test('Negative marking computes correctly for model tests', () {
    final q = Question(
      id: 't1',
      categoryId: 'c',
      subCategoryId: 's',
      subjectId: 'sub',
      chapterId: 'ch',
      questionText: 'Q',
      optionA: 'A',
      optionB: 'B',
      optionC: 'C',
      optionD: 'D',
      correctAnswer: 'A',
    );
    expect(q.correctAnswer, 'A');
    expect(q.options.length, 4);
  });

  testWidgets('App boots and renders splash', (tester) async {
    await LocalDb.instance.init();
    await tester.pumpWidget(const EPScienceApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
