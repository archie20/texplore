import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/theme/app_theme.dart';
import '../../../graph/interaction/lattice_motion.dart';
import '../../../graph/interaction/viewport_controller.dart';
import '../../../graph/layout/layout_node.dart';

class Minimap extends StatelessWidget {
  const Minimap({
    required this.layout,
    required this.viewportSize,
    required this.onCentre,
    super.key,
  });

  final GraphLayout layout;
  final Size viewportSize;
  final void Function(Offset scene) onCentre;

  static const width = 180.0;
  static const height = 120.0;

  @override
  Widget build(BuildContext context) {
    final notebook = context.notebook;
    final viewport = ViewportScope.of(context);
    final motion = LatticeMotionScope.maybeOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: notebook.card,
          border: Border.all(color: notebook.hairline),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: motion == null
                ? viewport.transformation
                : Listenable.merge([viewport.transformation, motion]),
            builder: (context, _) {
              final map = _Map.fromLayout(
                layout,
                const Size(width, height),
                motion,
              );
              final sceneTopLeft = ViewportController.scenePoint(
                viewport.transformation.toScene(Offset.zero),
              );
              final sceneBottomRight = ViewportController.scenePoint(
                viewport.transformation.toScene(
                  Offset(viewportSize.width, viewportSize.height),
                ),
              );
              return GestureDetector(
                onTapDown: (details) {
                  final scene = map.toScene(details.localPosition);
                  if (scene != null) onCentre(scene);
                },
                child: CustomPaint(
                  painter: _MinimapPainter(
                    layout: layout,
                    motion: motion,
                    map: map,
                    sceneTopLeft: sceneTopLeft,
                    sceneBottomRight: sceneBottomRight,
                    nodeColor: notebook.inkSoft,
                    frameColor: notebook.ink,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Map {
  const _Map({
    required this.left,
    required this.top,
    required this.scale,
    required this.origin,
  });

  final double left;
  final double top;
  final double scale;
  final Offset origin;

  static _Map fromLayout(GraphLayout layout, Size size, LatticeMotion? motion) {
    if (layout.nodes.isEmpty || layout.width <= 0 || layout.height <= 0) {
      return const _Map(left: 0, top: 0, scale: 1, origin: Offset.zero);
    }
    Offset originOf(LayoutNode node) =>
        motion?.topLeft(node) ?? Offset(node.x, node.y);
    final first = originOf(layout.nodes.first);
    var left = first.dx;
    var top = first.dy;
    var right = left + layout.nodes.first.width;
    var bottom = top + LatticeMetrics.heightFor(layout.nodes.first.stage);
    for (final node in layout.nodes.skip(1)) {
      final origin = originOf(node);
      left = math.min(left, origin.dx);
      top = math.min(top, origin.dy);
      right = math.max(right, origin.dx + node.width);
      bottom = math.max(
        bottom,
        origin.dy + LatticeMetrics.heightFor(node.stage),
      );
    }
    const pad = 24.0;
    left -= pad;
    top -= pad;
    right += pad;
    bottom += pad;
    final spanW = math.max(1.0, right - left);
    final spanH = math.max(1.0, bottom - top);
    final scale = math.min(size.width / spanW, size.height / spanH);
    final origin = Offset(
      (size.width - spanW * scale) / 2,
      (size.height - spanH * scale) / 2,
    );
    return _Map(left: left, top: top, scale: scale, origin: origin);
  }

  Offset plot(double x, double y) =>
      Offset(origin.dx + (x - left) * scale, origin.dy + (y - top) * scale);

  Offset? toScene(Offset local) {
    if (scale == 0) return null;
    return Offset(
      left + (local.dx - origin.dx) / scale,
      top + (local.dy - origin.dy) / scale,
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.layout,
    required this.motion,
    required this.map,
    required this.sceneTopLeft,
    required this.sceneBottomRight,
    required this.nodeColor,
    required this.frameColor,
  });

  final GraphLayout layout;
  final LatticeMotion? motion;
  final _Map map;
  final Offset sceneTopLeft;
  final Offset sceneBottomRight;
  final Color nodeColor;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.nodes.isEmpty) return;
    final links = Paint()
      ..color = nodeColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final edges = motion?.follow(layout.edges) ?? layout.edges;
    for (final edge in edges) {
      if (edge.crossLink || edge.navigation) continue;
      canvas.drawLine(
        map.plot(edge.start.x, edge.start.y),
        map.plot(edge.end.x, edge.end.y),
        links,
      );
    }
    final nodes = Paint()..color = nodeColor;
    for (final node in layout.nodes) {
      final diameter = LatticeMetrics.diameterFor(node.stage);
      final topLeft = motion?.topLeft(node) ?? Offset(node.x, node.y);
      final center = map.plot(
        topLeft.dx + node.width / 2,
        topLeft.dy + diameter / 2,
      );
      canvas.drawCircle(center, math.max(1.6, diameter * map.scale / 2), nodes);
    }
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = frameColor;
    final raw = Rect.fromPoints(
      map.plot(sceneTopLeft.dx, sceneTopLeft.dy),
      map.plot(sceneBottomRight.dx, sceneBottomRight.dy),
    );
    final visible = raw.intersect(
      Rect.fromLTWH(
        2,
        2,
        math.max(0, size.width - 4),
        math.max(0, size.height - 4),
      ),
    );
    if (!visible.isEmpty) canvas.drawRect(visible, frame);
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) => true;
}
