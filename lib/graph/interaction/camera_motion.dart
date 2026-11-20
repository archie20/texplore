import 'dart:math' as math;

import '../../domain/models/catalogue.dart';
import '../../domain/services/graph_queries.dart';
import 'viewport_controller.dart';

/// Scale to fly to when the selection moves.
///
/// A descendant zooms in. An ancestor zooms out. Anything else keeps the
/// current scale, unless the lattice is still too far away to read.
double cameraScale({
  required Catalogue catalogue,
  required String? fromId,
  required String toId,
  required double current,
}) {
  double clampScale(double value) => value
      .clamp(ViewportController.minScale, ViewportController.maxScale)
      .toDouble();
  if (fromId == null || fromId == toId) {
    return clampScale(math.max(current, 1.05));
  }
  final deeper = GraphQueries.descendantIds(catalogue, fromId).contains(toId);
  final shallower = GraphQueries.ancestorIds(catalogue, fromId).contains(toId);
  if (deeper) {
    final steps = _stageSteps(catalogue, fromId, toId);
    final factor = math.pow(1.58, steps.clamp(1, 3)).toDouble();
    return clampScale(math.max(current * factor, 1.08));
  }
  if (shallower) {
    final steps = _stageSteps(catalogue, toId, fromId);
    final factor = math.pow(1.58, steps.clamp(1, 3)).toDouble();
    return clampScale(current / factor);
  }
  if (current < 0.85) return clampScale(1);
  return clampScale(current);
}

int _stageSteps(Catalogue catalogue, String ancestorId, String descendantId) {
  final ancestor = catalogue.nodes[ancestorId];
  final descendant = catalogue.nodes[descendantId];
  if (ancestor == null || descendant == null) return 1;
  final delta = descendant.stage.order - ancestor.stage.order;
  return delta <= 0 ? 1 : delta;
}
