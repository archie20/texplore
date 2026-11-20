import 'dart:math' as math;
import 'dart:ui';

import '../layout/layout_node.dart';

/// Keeps every link a single straight run between circle rims.
///
/// A circle that would sit on a line, or whose line would cross another line,
/// is given a short slide. The line itself is never bent.
class StraightLinks {
  const StraightLinks();

  static const pad = 12.0;

  bool affects({
    required LayoutNode node,
    required Offset at,
    required List<LayoutNode> nodes,
    required List<RoutedEdge> edges,
    required Map<String, Offset> placed,
  }) {
    final byId = {for (final item in nodes) item.id: item};
    for (final edge in edges) {
      final segment = _segment(edge, node, at, byId, placed);
      if (segment == null) continue;
      final incident = edge.sourceId == node.id || edge.targetId == node.id;
      if (!incident) {
        if (_hitsBox(segment.$1, segment.$2, at, _box(node))) return true;
        continue;
      }
      for (final other in nodes) {
        if (other.id == edge.sourceId || other.id == edge.targetId) continue;
        final there = placed[other.id];
        if (there == null) continue;
        if (_hitsBox(segment.$1, segment.$2, there, _box(other))) return true;
      }
      for (final other in edges) {
        if (other.id == edge.id || _shares(edge, other)) continue;
        final rival = _segment(other, node, at, byId, placed);
        if (rival == null) continue;
        if (_conflicts(segment.$1, segment.$2, rival.$1, rival.$2)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Smallest slide that takes [node] off every straight link. Box overlap is
  /// left to the caller.
  Offset? escape({
    required LayoutNode node,
    required Offset at,
    required List<LayoutNode> nodes,
    required List<RoutedEdge> edges,
    required Map<String, Offset> placed,
  }) {
    if (!affects(
      node: node,
      at: at,
      nodes: nodes,
      edges: edges,
      placed: placed,
    )) {
      return null;
    }
    final byId = {for (final item in nodes) item.id: item};
    final moves = <Offset>[];
    for (final edge in edges) {
      final segment = _segment(edge, node, at, byId, placed);
      if (segment == null) continue;
      final incident = edge.sourceId == node.id || edge.targetId == node.id;
      if (!incident) {
        if (_hitsBox(segment.$1, segment.$2, at, _box(node))) {
          final slide = _offSegment(at, _box(node), segment.$1, segment.$2);
          if (slide != null) moves.add(slide);
        }
        continue;
      }
      for (final other in edges) {
        if (other.id == edge.id || _shares(edge, other)) continue;
        final rival = _segment(other, node, at, byId, placed);
        if (rival == null) continue;
        if (!_conflicts(segment.$1, segment.$2, rival.$1, rival.$2)) continue;
        final mine = edge.sourceId == node.id ? segment.$1 : segment.$2;
        final otherEnd = edge.sourceId == node.id ? segment.$2 : segment.$1;
        final slide = _uncross(rival.$1, rival.$2, otherEnd, mine);
        if (slide != null) moves.add(slide);
      }
    }
    Offset? best;
    for (final move in moves) {
      if (best != null && move.distance >= best.distance) continue;
      final clear = !affects(
        node: node,
        at: at + move,
        nodes: nodes,
        edges: edges,
        placed: placed,
      );
      if (clear) best = move;
    }
    return best;
  }

  (Offset, Offset)? _segment(
    RoutedEdge edge,
    LayoutNode moving,
    Offset at,
    Map<String, LayoutNode> byId,
    Map<String, Offset> placed,
  ) {
    final source = byId[edge.sourceId];
    final target = byId[edge.targetId];
    if (source == null || target == null) return null;
    final sourceAt = edge.sourceId == moving.id ? at : placed[edge.sourceId];
    final targetAt = edge.targetId == moving.id ? at : placed[edge.targetId];
    if (sourceAt == null || targetAt == null) return null;
    final sourceCenter = _center(source, sourceAt);
    final targetCenter = _center(target, targetAt);
    return (
      _rim(source, sourceAt, targetCenter),
      _rim(target, targetAt, sourceCenter),
    );
  }

  bool _shares(RoutedEdge a, RoutedEdge b) {
    return a.sourceId == b.sourceId ||
        a.sourceId == b.targetId ||
        a.targetId == b.sourceId ||
        a.targetId == b.targetId;
  }

  Offset _center(LayoutNode node, Offset topLeft) {
    return Offset(
      topLeft.dx + node.width / 2,
      topLeft.dy + LatticeMetrics.diameterFor(node.stage) / 2,
    );
  }

  Offset _rim(LayoutNode node, Offset topLeft, Offset toward) {
    final center = _center(node, topLeft);
    final delta = toward - center;
    final len = delta.distance;
    final radius = LatticeMetrics.diameterFor(node.stage) / 2 + 3;
    if (len <= 0.001) return center;
    return center + delta / len * radius;
  }

  Size _box(LayoutNode node) {
    return Size(
      node.width,
      math.max(node.height, LatticeMetrics.heightFor(node.stage)),
    );
  }

  bool _hitsBox(Offset a, Offset b, Offset topLeft, Size size) {
    final rect = Rect.fromLTWH(
      topLeft.dx - pad,
      topLeft.dy - pad,
      size.width + pad * 2,
      size.height + pad * 2,
    );
    if (rect.contains(a) || rect.contains(b)) return true;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    for (var i = 0; i < 4; i++) {
      if (_crosses(a, b, corners[i], corners[(i + 1) % 4])) return true;
    }
    return false;
  }

  Offset? _offSegment(Offset topLeft, Size size, Offset a, Offset b) {
    if (!_hitsBox(a, b, topLeft, size)) return null;
    final dirs = <Offset>[
      const Offset(1, 0),
      const Offset(-1, 0),
      const Offset(0, 1),
      const Offset(0, -1),
    ];
    final span = b - a;
    if (span.distance > 1) {
      final n = Offset(-span.dy, span.dx) / span.distance;
      dirs
        ..add(n)
        ..add(-n);
    }
    final limit = math.max(size.width, size.height) + pad * 2 + 4;
    Offset? best;
    for (final dir in dirs) {
      if (_hitsBox(a, b, topLeft + dir * limit, size)) continue;
      var low = 0.0;
      var high = limit;
      for (var i = 0; i < 14; i++) {
        final mid = (low + high) / 2;
        if (_hitsBox(a, b, topLeft + dir * mid, size)) {
          low = mid;
        } else {
          high = mid;
        }
      }
      final move = dir * (high + 1);
      if (best == null || move.distance < best.distance) best = move;
    }
    return best;
  }

  Offset? _uncross(Offset a, Offset b, Offset stay, Offset moving) {
    final span = b - a;
    final len = span.distance;
    if (len < 1) return null;
    final normal = Offset(-span.dy / len, span.dx / len);
    double side(Offset point) =>
        (point - a).dx * normal.dx + (point - a).dy * normal.dy;
    final staySide = side(stay);
    final movingSide = side(moving);
    if (staySide * movingSide > 0 && movingSide.abs() >= pad) return null;
    final sign = staySide.abs() < 0.01
        ? (movingSide >= 0 ? 1.0 : -1.0)
        : (staySide > 0 ? 1.0 : -1.0);
    return normal * (sign * pad - movingSide);
  }

  bool _conflicts(Offset a, Offset b, Offset c, Offset d) {
    if (_crosses(a, b, c, d)) return true;
    return _distance(a, b, c, d) < pad;
  }

  bool _crosses(Offset a, Offset b, Offset c, Offset d) {
    final d1 = _cross(b - a, c - a);
    final d2 = _cross(b - a, d - a);
    final d3 = _cross(d - c, a - c);
    final d4 = _cross(d - c, b - c);
    const eps = 0.05;
    return ((d1 > eps && d2 < -eps) || (d1 < -eps && d2 > eps)) &&
        ((d3 > eps && d4 < -eps) || (d3 < -eps && d4 > eps));
  }

  double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

  double _distance(Offset a, Offset b, Offset c, Offset d) {
    final length = (b - a).distance;
    final steps = math.max(1, (length / 6).ceil());
    var best = double.infinity;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      best = math.min(best, _pointSegment(point, c, d));
    }
    return best;
  }

  double _pointSegment(Offset p, Offset a, Offset b) {
    final span = b - a;
    final len2 = span.dx * span.dx + span.dy * span.dy;
    if (len2 < 0.01) return (p - a).distance;
    final t = ((p.dx - a.dx) * span.dx + (p.dy - a.dy) * span.dy) / len2;
    final clamped = t.clamp(0.0, 1.0);
    return (p - (a + span * clamped)).distance;
  }
}
