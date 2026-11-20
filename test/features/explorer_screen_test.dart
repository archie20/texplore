import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('roots, the inspector, and the narrow outline all work', (
    tester,
  ) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ThesisApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Kente'), findsWidgets);
    expect(
      find.text(
        'Plausible textile images are not necessarily weavable structures',
      ),
      findsOneWidget,
    );
    expect(find.text('Thesis topics'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));

    final dragged = find.byKey(const ValueKey('node-kente-problem'));
    final other = find.byKey(const ValueKey('node-se-problem'));
    final beforeDragged = tester.getTopLeft(dragged);
    final beforeOther = tester.getTopLeft(other);
    final gesture = await tester.startGesture(tester.getCenter(dragged));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(80, 0));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      ((tester.getTopLeft(dragged) - beforeDragged) -
              (tester.getTopLeft(other) - beforeOther))
          .distance,
      greaterThan(20),
    );
    await gesture.up();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      ((tester.getTopLeft(dragged) - tester.getTopLeft(other)) -
              (beforeDragged - beforeOther))
          .distance,
      greaterThan(20),
    );

    await tester.tap(find.byKey(const ValueKey('node-kente-problem')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('More'), findsOneWidget);
    expect(
      find.textContaining('A generated textile image can look convincing'),
      findsOneWidget,
    );
    expect(find.text('Thesis problem · Hypothesis'), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pump();
    expect(find.text('Less'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Visual similarity is not evidence of weaveability'),
      48,
      scrollable: find.descendant(
        of: find.byKey(const Key('circle-speech')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.textContaining('Visual similarity is not evidence of weaveability'),
      findsOneWidget,
    );
    await tester.tap(find.text('Thesis topics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('node-popup')), findsNothing);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('outline-toggle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('outline-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Canvas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
