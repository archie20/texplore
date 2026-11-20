import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/graph/interaction/camera_motion.dart';
import 'package:thesis_topics/graph/interaction/viewport_controller.dart';

import '../support/catalogue_factory.dart';

void main() {
  final catalogue = chainCatalogue();

  test('a child zooms in and a parent zooms out', () {
    final closer = cameraScale(
      catalogue: catalogue,
      fromId: 'n-problem',
      toId: 'n-question',
      current: 1,
    );
    final wider = cameraScale(
      catalogue: catalogue,
      fromId: 'n-question',
      toId: 'n-problem',
      current: closer,
    );
    expect(closer, greaterThan(1));
    expect(wider, lessThan(closer));
  });

  test('the first selection comes in from an overview', () {
    final scale = cameraScale(
      catalogue: catalogue,
      fromId: null,
      toId: 'n-area',
      current: 0.2,
    );
    expect(scale, greaterThan(0.2));
  });

  test('the flight keeps the focal point on the way to the next one', () {
    const viewport = Size(800, 600);
    final from = ViewportController.centredOn(
      const Offset(100, 80),
      1,
      viewport,
    );
    final to = ViewportController.centredOn(
      const Offset(300, 200),
      2,
      viewport,
    );
    final mid = ViewportController.interpolateView(
      from: from,
      to: to,
      t: 0.5,
      viewport: viewport,
    );
    expect(mid.getMaxScaleOnAxis(), closeTo(1.5, 0.001));
    final center = ViewportController.sceneAtCenter(mid, viewport);
    expect(center.dx, closeTo(200, 0.5));
    expect(center.dy, closeTo(140, 0.5));
  });

  test('a circle above the layout still maps inside the viewer child', () {
    const scene = Offset(-420, -180);
    final child = ViewportController.childPoint(scene);
    expect(child.dx, greaterThan(scene.dx.abs()));
    expect(child.dy, greaterThan(scene.dy.abs()));
    const viewport = Size(800, 600);
    final matrix = ViewportController.centredOn(scene, 1.4, viewport);
    final back = ViewportController.sceneAtCenter(matrix, viewport);
    expect(back.dx, closeTo(scene.dx, 0.01));
    expect(back.dy, closeTo(scene.dy, 0.01));
    final fitted = ViewportController.matrixFor(
      const Rect.fromLTWH(-420, -180, 300, 220),
      viewport,
    );
    final fittedCenter = ViewportController.sceneAtCenter(fitted, viewport);
    expect(fittedCenter.dx, closeTo(-270, 0.5));
    expect(fittedCenter.dy, closeTo(-70, 0.5));
  });
}
