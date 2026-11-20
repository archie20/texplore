import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:thesis_topics/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('load the catalogue, open a node, and switch to the outline', (
    tester,
  ) async {
    await tester.pumpWidget(const ThesisApp());
    await tester.pump();
    for (
      var i = 0;
      i < 40 && find.textContaining('Kente').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.textContaining('Kente'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.byKey(const ValueKey('node-kente-problem')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('More'), findsOneWidget);

    // The widget test resizes the surface. A browser drive cannot, so this
    // check only runs where the test view accepts a new size.
    try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
    } on UnsupportedError {
      return;
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('outline-toggle')), findsOneWidget);
  });
}
