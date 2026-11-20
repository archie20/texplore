import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pan and zoom stay off the bloc. They change every frame.
class ViewportController extends ChangeNotifier {
  ViewportController() {
    // Logical (0, 0) sits at the child's pad, so the opening frame shows the
    // same place it did before that shift.
    transformation.value = Matrix4.identity()
      ..translateByDouble(-canvasPad, -canvasPad, 0, 1);
  }

  final TransformationController transformation = TransformationController();
  final ValueNotifier<double> flight = ValueNotifier<double>(1);
  Matrix4? _target;

  static const minScale = 0.02;
  static const maxScale = 3.2;

  /// Room on every side of the scene. The viewer child is hit-tested only
  /// inside its own box, and that box starts at (0, 0), so a circle that
  /// rests above or left of the layout would be drawn and never receive a
  /// click. Scene points are stored as they are and drawn shifted by this pad.
  static const canvasPad = 16000.0;

  static Offset childPoint(Offset scene) =>
      scene + const Offset(canvasPad, canvasPad);

  static Offset scenePoint(Offset child) =>
      child - const Offset(canvasPad, canvasPad);

  Matrix4? takeTarget() {
    final target = _target;
    _target = null;
    return target;
  }

  void request(Matrix4 matrix) {
    _target = matrix;
    notifyListeners();
  }

  void reportFlight(double value) {
    if ((flight.value - value).abs() < 0.001) return;
    flight.value = value;
  }

  /// Rebuilds the view from the scale and the scene point under the centre.
  static Matrix4 interpolateView({
    required Matrix4 from,
    required Matrix4 to,
    required double t,
    required Size viewport,
  }) {
    final scale =
        from.getMaxScaleOnAxis() +
        (to.getMaxScaleOnAxis() - from.getMaxScaleOnAxis()) * t;
    final center = Offset.lerp(
      sceneAtCenter(from, viewport),
      sceneAtCenter(to, viewport),
      t,
    )!;
    return centredOn(center, scale, viewport);
  }

  static Offset sceneAtCenter(Matrix4 matrix, Size viewport) {
    final inverse = Matrix4.tryInvert(matrix.clone());
    if (inverse == null) return Offset.zero;
    return scenePoint(
      MatrixUtils.transformPoint(
        inverse,
        Offset(viewport.width / 2, viewport.height / 2),
      ),
    );
  }

  static Matrix4 centredOn(Offset scene, double scale, Size viewport) {
    final child = childPoint(scene);
    final tx = viewport.width / 2 - child.dx * scale;
    final ty = viewport.height / 2 - child.dy * scale;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void fit(Rect world, Size viewport, {double bottomChrome = 0}) {
    request(matrixFor(world, viewport, bottomChrome: bottomChrome));
  }

  void zoomBy(double factor, Size viewport) {
    final current = transformation.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(minScale, maxScale);
    final scene = scenePoint(
      transformation.toScene(Offset(viewport.width / 2, viewport.height / 2)),
    );
    request(centredOn(scene, next, viewport));
  }

  void centreOn(Rect world, Size viewport) {
    final scale = transformation.value.getMaxScaleOnAxis().clamp(
      minScale,
      maxScale,
    );
    request(centredOn(world.center, scale, viewport));
  }

  void focusAt(Rect world, Size viewport, {required double scale}) {
    request(
      centredOn(
        world.center,
        scale.clamp(minScale, maxScale).toDouble(),
        viewport,
      ),
    );
  }

  static Matrix4 matrixFor(
    Rect world,
    Size viewport, {
    double bottomChrome = 0,
  }) {
    const pad = 56.0;
    final availableWidth = math.max(viewport.width - pad * 2, 1);
    final availableHeight = math.max(
      viewport.height - pad * 2 - bottomChrome,
      1,
    );
    final worldWidth = math.max(world.width, 1);
    final worldHeight = math.max(world.height, 1);
    final scale = math
        .min(availableWidth / worldWidth, availableHeight / worldHeight)
        .clamp(minScale, maxScale);
    final childLeft = world.left + canvasPad;
    final childTop = world.top + canvasPad;
    final tx = (viewport.width - worldWidth * scale) / 2 - childLeft * scale;
    final ty =
        (viewport.height - bottomChrome - worldHeight * scale) / 2 -
        childTop * scale;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  void dispose() {
    flight.dispose();
    transformation.dispose();
    super.dispose();
  }
}

class ViewportScope extends InheritedNotifier<ViewportController> {
  const ViewportScope({
    required ViewportController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ViewportController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ViewportScope>();
    assert(scope != null, 'ViewportScope is missing');
    return scope!.notifier!;
  }
}
