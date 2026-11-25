import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../layout/layout_node.dart';
import 'node_drift.dart';

class EdgePainter extends CustomPainter {
  EdgePainter({
    required this.edges,
    required this.edgeColor,
    required this.mutedColor,
    required this.accentColor,
    required this.highlighted,
    this.route = const {},
    required this.flow,
    this.offset = Offset.zero,
    this.driftSeconds,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final List<RoutedEdge> edges;
  final Color edgeColor;
  final Color mutedColor;
  final Color accentColor;
  final Set<String> highlighted;

  /// Ends of the path from the thesis problem to the selected circle.
  /// The comet travels this chain, not the highlighted sibling links.
  final Set<String> route;

  final Animation<double> flow;

  /// Added to every endpoint so a line meets a circle that was shifted into
  /// the hit-testable child.
  final Offset offset;

  /// Elapsed life time, in seconds. Null holds every line still.
  final double Function()? driftSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = driftSeconds?.call();
    final routeSpans = <_RouteSpan>[];
    for (final edge in edges) {
      final onPath =
          edge.structural &&
          highlighted.contains(edge.sourceId) &&
          highlighted.contains(edge.targetId);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = onPath ? 1.8 : (edge.navigation ? 1.0 : 1.15)
        ..color = onPath
            ? accentColor
            : (edge.crossLink || edge.navigation ? mutedColor : edgeColor)
        ..strokeCap = StrokeCap.round;
      final start =
          Offset(edge.start.x, edge.start.y) +
          offset +
          _drift(edge.sourceId, seconds);
      final end =
          Offset(edge.end.x, edge.end.y) +
          offset +
          _drift(edge.targetId, seconds);
      if (edge.dashed) {
        _dashLine(
          canvas,
          start,
          end,
          paint,
          dash: edge.navigation ? 4 : 7,
          gap: edge.navigation ? 6 : 5,
        );
      } else {
        canvas.drawLine(start, end, paint);
      }
      final onRoute =
          edge.structural &&
          route.contains(edge.sourceId) &&
          route.contains(edge.targetId);
      if (onRoute) {
        routeSpans.add(
          _RouteSpan(
            sourceId: edge.sourceId,
            targetId: edge.targetId,
            start: start,
            end: end,
          ),
        );
      }
    }
    _flowAlong(canvas, routeSpans, flow.value);
  }

  /// One bright segment travels the whole path, then wraps back to the start.
  void _flowAlong(Canvas canvas, List<_RouteSpan> spans, double phase) {
    final ordered = _orderRoute(spans);
    if (ordered.isEmpty) return;
    final lengths = [for (final span in ordered) span.length];
    final total = lengths.fold(0.0, (sum, length) => sum + length);
    if (total < 8) return;
    const comet = 32.0;
    final head = (phase % 1) * total;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = accentColor;
    final tail = head - comet;
    if (tail < 0) {
      _drawPathRange(canvas, ordered, lengths, total + tail, total, paint);
      _drawPathRange(canvas, ordered, lengths, 0, head, paint);
    } else {
      _drawPathRange(canvas, ordered, lengths, tail, head, paint);
    }
  }

  void _drawPathRange(
    Canvas canvas,
    List<_RouteSpan> spans,
    List<double> lengths,
    double from,
    double to,
    Paint paint,
  ) {
    if (to <= from) return;
    var cursor = 0.0;
    for (var i = 0; i < spans.length; i++) {
      final span = spans[i];
      final length = lengths[i];
      final spanEnd = cursor + length;
      final localFrom = from > cursor ? from : cursor;
      final localTo = to < spanEnd ? to : spanEnd;
      if (localTo > localFrom && length > 0.001) {
        final dir = (span.end - span.start) / length;
        canvas.drawLine(
          span.start + dir * (localFrom - cursor),
          span.start + dir * (localTo - cursor),
          paint,
        );
      }
      cursor = spanEnd;
    }
  }

  List<_RouteSpan> _orderRoute(List<_RouteSpan> spans) {
    if (spans.length <= 1) return spans;
    final bySource = {for (final span in spans) span.sourceId: span};
    final targets = {for (final span in spans) span.targetId};
    _RouteSpan? cursor;
    for (final span in spans) {
      if (!targets.contains(span.sourceId)) {
        cursor = span;
        break;
      }
    }
    cursor ??= spans.first;
    final ordered = <_RouteSpan>[];
    final seen = <String>{};
    while (cursor != null && seen.add(cursor.sourceId)) {
      ordered.add(cursor);
      cursor = bySource[cursor.targetId];
    }
    return ordered;
  }

  void _dashLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final delta = end - start;
    final len = delta.distance;
    if (len < 1) return;
    final dir = delta / len;
    var distance = 0.0;
    while (distance < len) {
      final next = mathMin(distance + dash, len);
      canvas.drawLine(start + dir * distance, start + dir * next, paint);
      distance = next + gap;
    }
  }

  double mathMin(double a, double b) => a < b ? a : b;

  Offset _drift(String id, double? seconds) {
    if (seconds == null) return Offset.zero;
    return NodeDrift.at(id, seconds);
  }

  @override
  bool shouldRepaint(EdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.route != route ||
        oldDelegate.edgeColor != edgeColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.offset != offset ||
        (oldDelegate.driftSeconds == null) != (driftSeconds == null);
  }
}

class _RouteSpan {
  const _RouteSpan({
    required this.sourceId,
    required this.targetId,
    required this.start,
    required this.end,
  });

  final String sourceId;
  final String targetId;
  final Offset start;
  final Offset end;

  double get length => (end - start).distance;
}

class DotGridPainter extends CustomPainter {
  const DotGridPainter({required this.color, this.spacing = 34});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing; y < size.height; y += spacing) {
      for (var x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) => oldDelegate.color != color;
}
