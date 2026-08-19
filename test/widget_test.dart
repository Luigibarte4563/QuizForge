import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizForgeApp());
    expect(find.text('QuizForge'), findsOneWidget);
  });
}
