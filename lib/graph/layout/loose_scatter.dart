import 'dart:math' as math;
import 'dart:ui';

import '../../domain/enums/research_stage.dart';
import 'layout_node.dart';

/// One circle to drop near a parent.
class ScatterChild {
  const ScatterChild({
    required this.id,
    required this.width,
    required this.diameter,
    required this.height,
    required this.reach,
  });

  factory ScatterChild.of(String id, ResearchStage stage) {
    return ScatterChild(
      id: id,
      width: LatticeMetrics.widthFor(stage),
      diameter: LatticeMetrics.diameterFor(stage),
      height: LatticeMetrics.heightFor(stage),
      reach: LooseScatter.reach(stage),
    );
  }

  final String id;
  final double width;
  final double diameter;
  final double height;

  /// How far the box reaches from the circle centre, plus a small gap.
  final double reach;
}

/// A stage circle and the records that belong to it.
class ScatterGroup {
  const ScatterGroup({required this.child, required this.members});

  final ScatterChild child;
  final List<ScatterChild> members;
}

/// Irregular places around a parent.
///
/// Each child takes a distance and a direction from its own id. Nothing is
/// set on a ring, a fan, or an even step. The same ids always land in the
/// same places. The extra distance past a clear gap stays short, so the line
/// back to the parent can be followed without a large zoom. A circle already
/// placed eases aside when the new one needs that spot.
class LooseScatter {
  const LooseScatter._();

  static const clearance = 16.0;
  static const linePad = 12.0;

  /// How much farther than a clear gap a child may sit. Long enough to vary,
  /// short enough to trace on one screen.
  static const maxSlack = 150.0;

  static double reach(ResearchStage stage) {
    final halfW = LatticeMetrics.widthFor(stage) / 2;
    final halfD = LatticeMetrics.diameterFor(stage) / 2;
    final below = halfD + LatticeMetrics.captionFor(stage);
    return math.sqrt(halfW * halfW + below * below) + 18;
  }

  static int seedOf(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// Centres for [parentShape] and every stage and record.
  ///
  /// Stages scatter around [parent]. Records use that same scatter around
  /// their stage. Records are placed even when the stage is closed, so
  /// opening one does not move the others.
  static Map<String, Offset> place({
    required Offset parent,
    required ScatterChild parentShape,
    required List<ScatterGroup> groups,
  }) {
    final dots = <_Dot>[
      _Dot(
        id: parentShape.id,
        center: parent,
        width: parentShape.width,
        diameter: parentShape.diameter,
        height: parentShape.height,
        reach: parentShape.reach,
        parentIndex: -1,
      ),
    ];
    final indexOf = <String, int>{parentShape.id: 0};
    for (final group in groups) {
      indexOf[group.child.id] = dots.length;
      dots.add(_settle(group.child, parentIndex: 0, dots: dots));
    }
    for (final group in groups) {
      final stageIndex = indexOf[group.child.id]!;
      for (final member in group.members) {
        dots.add(_settle(member, parentIndex: stageIndex, dots: dots));
      }
    }
    _easeEveryone(dots);
    return {
      for (final dot in dots)
        if (dot.id != parentShape.id) dot.id: dot.center,
    };
  }

  /// Slide a crowded circle to the nearest free spot inside its short reach.
  static void _easeEveryone(List<_Dot> dots) {
    if (dots.length > 60) return;
    for (var pass = 0; pass < 12; pass++) {
      var moved = false;
      for (var i = 1; i < dots.length; i++) {
        if (_freeOf(i, dots[i].center, dots)) continue;
        final spot = _nearestFree(i, dots);
        if (spot == null) continue;
        final delta = spot - dots[i].center;
        if (delta.distance < 0.5) continue;
        dots[i].center = spot;
        for (var child = 0; child < dots.length; child++) {
          if (dots[child].parentIndex != i) continue;
          dots[child].center = _clamp(
            dots[child],
            dots[child].center + delta,
            dots,
            120,
          );
          if (_freeOf(child, dots[child].center, dots)) continue;
          final again = _nearestFree(child, dots);
          if (again != null) dots[child].center = again;
        }
        moved = true;
      }
      if (!moved) break;
    }
    for (var pass = 0; pass < 8; pass++) {
      var moved = false;
      for (var i = 1; i < dots.length; i++) {
        for (var j = 0; j < i; j++) {
          if (!_boxesOverlap(dots[i].box, dots[j].box)) continue;
          final push = _boxPush(dots[i].box, dots[j].box);
          final candidates = [
            push,
            Offset(push.dx, 0),
            Offset(0, push.dy),
            Offset(-push.dy, push.dx),
            Offset(push.dy, -push.dx),
          ];
          for (final delta in candidates) {
            final next = _clamp(dots[i], dots[i].center + delta, dots, 120);
            if (!_freeOf(i, next, dots)) continue;
            dots[i].center = next;
            moved = true;
            break;
          }
        }
      }
      if (!moved) break;
    }
  }

  static Offset? _nearestFree(int index, List<_Dot> dots) {
    final dot = dots[index];
    final parent = dots[dot.parentIndex].center;
    final minRadius = dots[dot.parentIndex].reach + dot.reach;
    final maxRadius = minRadius + maxSlack + 120;
    final away = dot.center - parent;
    final outward = _awayAngle(dot.parentIndex, dots);
    final base = outward ?? math.atan2(away.dy, away.dx);
    final start = away.distance.clamp(minRadius, maxRadius);
    Offset? best;
    var bestDistance = double.infinity;
    for (var ring = 0; ring <= 6; ring++) {
      final radius = (start + ring * 36).clamp(minRadius, maxRadius);
      final samples = 10 + ring * 2;
      for (var sample = 0; sample < samples; sample++) {
        final turn = (sample + 1) ~/ 2;
        final sign = sample.isOdd ? 1.0 : -1.0;
        final swing = sign * turn * 0.32;
        if (outward != null && swing.abs() > 1.6) continue;
        final angle = base + swing;
        final center =
            parent + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (!_freeOf(index, center, dots)) continue;
        final distance = (center - dot.center).distance;
        if (distance >= bestDistance) continue;
        best = center;
        bestDistance = distance;
      }
      if (best != null) return best;
    }
    return best;
  }

  static bool _freeOf(int index, Offset center, List<_Dot> dots) {
    final dot = dots[index];
    final box = _Rect(
      center.dx - dot.width / 2,
      center.dy - dot.diameter / 2,
      dot.width,
      dot.height,
    );
    for (var i = 0; i < dots.length; i++) {
      if (i == index) continue;
      if (_boxesOverlap(box, dots[i].box)) return false;
    }
    final parentIndex = dot.parentIndex;
    if (parentIndex >= 0) {
      final origin = dots[parentIndex].center;
      for (var i = 0; i < dots.length; i++) {
        if (i == index || i == parentIndex) continue;
        if (_segmentHits(origin, center, dots[i].box, linePad)) return false;
      }
    }
    for (final spoke in dots) {
      if (spoke.parentIndex < 0) continue;
      if (identical(spoke, dot) || spoke.parentIndex == index) continue;
      final a = dots[spoke.parentIndex].center;
      final b = spoke.center;
      if (_segmentHits(a, b, box, linePad)) return false;
      if (parentIndex < 0) continue;
      final origin = dots[parentIndex].center;
      if (_shares(origin, center, a, b)) continue;
      if (_segmentsConflict(origin, center, a, b)) return false;
    }
    return true;
  }

  static _Dot _settle(
    ScatterChild child, {
    required int parentIndex,
    required List<_Dot> dots,
  }) {
    final random = math.Random(seedOf(child.id));
    final parent = dots[parentIndex];
    final minRadius = parent.reach + child.reach;
    // Records stay on the outer side of their stage, so a short line does not
    // have to cross the thesis problem or the circles already around it.
    final away = _awayAngle(parentIndex, dots);
    const outerSweep = 3.6;
    final base = away == null
        ? random.nextDouble() * math.pi * 2
        : away + (random.nextDouble() - 0.5) * outerSweep;
    double angleAt(int turn, int count, double salt) {
      if (away == null) return base + turn * (math.pi * 2 / count) + salt;
      return away + (turn / (count - 1) - 0.5) * outerSweep + salt * 0.15;
    }

    final preferred = _within(
      parent.center,
      base,
      minRadius,
      _slack(child.id, 0),
    );
    if (_take(preferred, child, parentIndex, dots)) {
      return _dot(child, preferred, parentIndex);
    }
    for (final fraction in const [0.35, 0.6, 0.82, 1.0]) {
      for (var turn = 0; turn < 12; turn++) {
        final angle = angleAt(turn, 12, fraction);
        final center = _within(
          parent.center,
          angle,
          minRadius,
          maxSlack * fraction,
        );
        if (_take(center, child, parentIndex, dots)) {
          return _dot(child, center, parentIndex);
        }
      }
    }
    // Nothing in reach was fully clear. Pick the nearest-band spot that does
    // not cover a circle, and let the lines ease aside with the neighbours.
    Offset? open;
    var openFaults = 1 << 20;
    for (final fraction in const [1.0, 0.7, 0.45]) {
      for (var turn = 0; turn < 16; turn++) {
        final center = _within(
          parent.center,
          angleAt(turn, 16, fraction),
          minRadius,
          maxSlack * fraction,
        );
        final faults = _faults(center, child, parentIndex, dots);
        if (faults >= 100 || faults >= openFaults) continue;
        open = center;
        openFaults = faults;
        if (faults == 0) break;
      }
    }
    return _dot(child, open ?? preferred, parentIndex);
  }

  /// Overlaps count by the hundred, so a covered circle always loses to a
  /// clear one. Line crossings are the remainder.
  static int _faults(
    Offset center,
    ScatterChild child,
    int parentIndex,
    List<_Dot> dots,
  ) {
    final box = _boxOf(center, child);
    var overlaps = 0;
    for (final other in dots) {
      if (_boxesOverlap(box, other.box)) overlaps++;
    }
    if (overlaps > 0) return overlaps * 100;
    final origin = dots[parentIndex].center;
    var lines = 0;
    for (var i = 0; i < dots.length; i++) {
      if (i == parentIndex) continue;
      if (_segmentHits(origin, center, dots[i].box, linePad)) lines++;
    }
    for (final other in dots) {
      if (other.parentIndex < 0) continue;
      final a = dots[other.parentIndex].center;
      final b = other.center;
      if (_segmentHits(a, b, box, linePad)) lines++;
      if (_shares(origin, center, a, b)) continue;
      if (_segmentsConflict(origin, center, a, b)) lines++;
    }
    return lines;
  }

  static bool _take(
    Offset center,
    ScatterChild child,
    int parentIndex,
    List<_Dot> dots,
  ) {
    if (_clear(center, child, parentIndex, dots)) return true;
    var siblings = 0;
    for (final dot in dots) {
      if (dot.parentIndex == parentIndex) siblings++;
    }
    if (siblings > 16) return false;
    final saved = [for (final dot in dots) dot.center];
    _vacate(center, child, parentIndex, dots);
    final ok = _clear(center, child, parentIndex, dots) && _restingClear(dots);
    if (ok) return true;
    for (var i = 0; i < dots.length; i++) {
      dots[i].center = saved[i];
    }
    return false;
  }

  static bool _restingClear(List<_Dot> dots) {
    for (var i = 0; i < dots.length; i++) {
      for (var j = i + 1; j < dots.length; j++) {
        if (_boxesOverlap(dots[i].box, dots[j].box)) return false;
      }
    }
    for (final spoke in dots) {
      if (spoke.parentIndex < 0) continue;
      final a = dots[spoke.parentIndex].center;
      final b = spoke.center;
      for (final other in dots) {
        if (identical(other, spoke) ||
            identical(other, dots[spoke.parentIndex])) {
          continue;
        }
        if (_segmentHits(a, b, other.box, linePad)) return false;
      }
    }
    final spokes = [
      for (final dot in dots)
        if (dot.parentIndex >= 0) dot,
    ];
    for (var i = 0; i < spokes.length; i++) {
      for (var j = i + 1; j < spokes.length; j++) {
        final a = dots[spokes[i].parentIndex].center;
        final b = spokes[i].center;
        final c = dots[spokes[j].parentIndex].center;
        final d = spokes[j].center;
        if (_shares(a, b, c, d)) continue;
        if (_segmentsConflict(a, b, c, d)) return false;
      }
    }
    return true;
  }

  static double? _awayAngle(int parentIndex, List<_Dot> dots) {
    final parent = dots[parentIndex];
    if (parent.parentIndex < 0) return null;
    final root = dots[parent.parentIndex].center;
    final away = parent.center - root;
    if (away.distance < 1) return -math.pi / 2;
    return math.atan2(away.dy, away.dx);
  }

  static double _slack(String id, int attempt) {
    final mixed = (seedOf(id) + attempt * 53) & 0x7fffffff;
    return (mixed % 1000) / 1000 * maxSlack;
  }

  static Offset _within(
    Offset parent,
    double angle,
    double minRadius,
    double slack,
  ) {
    return parent +
        Offset(math.cos(angle), math.sin(angle)) * (minRadius + slack);
  }

  /// Move circles that block [incoming] to another spot within their own
  /// short reach, so the new circle does not have to travel out.
  static void _vacate(
    Offset incoming,
    ScatterChild child,
    int parentIndex,
    List<_Dot> dots,
  ) {
    final box = _boxOf(incoming, child);
    for (var i = 0; i < dots.length; i++) {
      if (i == parentIndex || dots[i].parentIndex < 0) continue;
      if (!_blocks(incoming, box, dots[i], parentIndex, dots)) continue;
      _relocate(i, box, dots);
    }
  }

  static bool _relocate(int index, _Rect incoming, List<_Dot> dots) {
    final dot = dots[index];
    final parent = dots[dot.parentIndex];
    final minRadius = parent.reach + dot.reach;
    final away = dot.center - parent.center;
    final angle = math.atan2(away.dy, away.dx);
    final slack = (away.distance - minRadius).clamp(0.0, maxSlack);
    final saved = dot.center;
    final carried = <_Dot, Offset>{
      for (final child in dots)
        if (child.parentIndex == index) child: child.center,
    };
    final outward = _awayAngle(dot.parentIndex, dots);
    for (var turn = 1; turn <= 10; turn++) {
      final sign = turn.isOdd ? 1.0 : -1.0;
      final nextAngle = outward == null
          ? angle + sign * turn * 0.42
          : outward + sign * math.min(turn * 0.28, 1.5);
      dot.center = _within(parent.center, nextAngle, minRadius, slack);
      final delta = dot.center - saved;
      for (final entry in carried.entries) {
        entry.key.center = _clamp(entry.key, entry.value + delta, dots);
      }
      if (_boxesOverlap(dot.box, incoming)) continue;
      var busy = false;
      for (final other in dots) {
        if (identical(other, dot)) continue;
        if (_boxesOverlap(dot.box, other.box)) {
          busy = true;
          break;
        }
      }
      if (!busy) return true;
    }
    dot.center = saved;
    for (final entry in carried.entries) {
      entry.key.center = entry.value;
    }
    return false;
  }

  static bool _blocks(
    Offset incoming,
    _Rect incomingBox,
    _Dot other,
    int parentIndex,
    List<_Dot> dots,
  ) {
    if (_boxesOverlap(incomingBox, other.box)) return true;
    final origin = dots[parentIndex].center;
    if (_segmentHits(origin, incoming, other.box, linePad)) return true;
    if (other.parentIndex < 0) return false;
    final a = dots[other.parentIndex].center;
    final b = other.center;
    return _segmentHits(a, b, incomingBox, linePad);
  }

  static Offset _clamp(
    _Dot dot,
    Offset next,
    List<_Dot> dots, [
    double budget = 0,
  ]) {
    final parentIndex = dot.parentIndex;
    if (parentIndex < 0) return dot.center;
    final parent = dots[parentIndex];
    final away = next - parent.center;
    final distance = away.distance;
    final minRadius = parent.reach + dot.reach;
    final maxRadius = minRadius + maxSlack + budget;
    if (distance < 1) {
      return parent.center + Offset(minRadius, 0);
    }
    final clamped = distance.clamp(minRadius, maxRadius);
    return parent.center + away / distance * clamped;
  }

  static Offset _boxPush(_Rect mover, _Rect fixed) {
    final left = mover.left + mover.width + clearance - fixed.left;
    final right = fixed.left + fixed.width + clearance - mover.left;
    final up = mover.top + mover.height + clearance - fixed.top;
    final down = fixed.top + fixed.height + clearance - mover.top;
    var best = Offset(-left, 0);
    if (right < best.distance) best = Offset(right, 0);
    if (up < best.distance) best = Offset(0, -up);
    if (down < best.distance) best = Offset(0, down);
    return best;
  }

  static _Rect _boxOf(Offset center, ScatterChild child) {
    return _Rect(
      center.dx - child.width / 2,
      center.dy - child.diameter / 2,
      child.width,
      child.height,
    );
  }

  static _Dot _dot(ScatterChild child, Offset center, int parentIndex) {
    return _Dot(
      id: child.id,
      center: center,
      width: child.width,
      diameter: child.diameter,
      height: child.height,
      reach: child.reach,
      parentIndex: parentIndex,
    );
  }

  static bool _clear(
    Offset center,
    ScatterChild child,
    int parentIndex,
    List<_Dot> dots,
  ) {
    final box = _Rect(
      center.dx - child.width / 2,
      center.dy - child.diameter / 2,
      child.width,
      child.height,
    );
    for (final other in dots) {
      if (_boxesOverlap(box, other.box)) return false;
    }
    final origin = dots[parentIndex].center;
    for (var i = 0; i < dots.length; i++) {
      if (i == parentIndex) continue;
      if (_segmentHits(origin, center, dots[i].box, linePad)) return false;
    }
    for (final other in dots) {
      if (other.parentIndex < 0) continue;
      final a = dots[other.parentIndex].center;
      final b = other.center;
      if (_segmentHits(a, b, box, linePad)) return false;
      if (_shares(origin, center, a, b)) continue;
      if (_segmentsConflict(origin, center, a, b)) return false;
    }
    return true;
  }

  static bool _boxesOverlap(_Rect a, _Rect b) {
    return a.left < b.left + b.width + clearance &&
        b.left < a.left + a.width + clearance &&
        a.top < b.top + b.height + clearance &&
        b.top < a.top + a.height + clearance;
  }

  static bool _segmentHits(Offset a, Offset b, _Rect box, double pad) {
    final rect = _Rect(
      box.left - pad,
      box.top - pad,
      box.width + pad * 2,
      box.height + pad * 2,
    );
    if (rect.contains(a) || rect.contains(b)) return true;
    final corners = rect.corners;
    for (var i = 0; i < 4; i++) {
      if (_crosses(a, b, corners[i], corners[(i + 1) % 4])) return true;
    }
    return false;
  }

  static bool _shares(Offset a, Offset b, Offset c, Offset d) {
    return _near(a, c) || _near(a, d) || _near(b, c) || _near(b, d);
  }

  static bool _near(Offset a, Offset b) => (a - b).distance < 0.5;

  static bool _segmentsConflict(Offset a, Offset b, Offset c, Offset d) {
    if (_crosses(a, b, c, d)) return true;
    return _segmentDistance(a, b, c, d) < linePad;
  }

  static bool _crosses(Offset a, Offset b, Offset c, Offset d) {
    final d1 = _cross(b - a, c - a);
    final d2 = _cross(b - a, d - a);
    final d3 = _cross(d - c, a - c);
    final d4 = _cross(d - c, b - c);
    const eps = 0.05;
    return ((d1 > eps && d2 < -eps) || (d1 < -eps && d2 > eps)) &&
        ((d3 > eps && d4 < -eps) || (d3 < -eps && d4 > eps));
  }

  static double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

  static double _segmentDistance(Offset a, Offset b, Offset c, Offset d) {
    return math.min(
      math.min(_pointSegment(a, c, d), _pointSegment(b, c, d)),
      math.min(_pointSegment(c, a, b), _pointSegment(d, a, b)),
    );
  }

  static double _pointSegment(Offset p, Offset a, Offset b) {
    final span = b - a;
    final len2 = span.dx * span.dx + span.dy * span.dy;
    if (len2 < 0.01) return (p - a).distance;
    final t = ((p.dx - a.dx) * span.dx + (p.dy - a.dy) * span.dy) / len2;
    final clamped = t.clamp(0.0, 1.0);
    return (p - (a + span * clamped)).distance;
  }
}

class _Dot {
  _Dot({
    required this.id,
    required this.center,
    required this.width,
    required this.diameter,
    required this.height,
    required this.reach,
    required this.parentIndex,
  });

  final String id;
  Offset center;
  final double width;
  final double diameter;
  final double height;
  final double reach;
  final int parentIndex;

  _Rect get box =>
      _Rect(center.dx - width / 2, center.dy - diameter / 2, width, height);
}

class _Rect {
  const _Rect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  bool contains(Offset point) {
    return point.dx >= left &&
        point.dx <= left + width &&
        point.dy >= top &&
        point.dy <= top + height;
  }

  List<Offset> get corners => [
    Offset(left, top),
    Offset(left + width, top),
    Offset(left + width, top + height),
    Offset(left, top + height),
  ];
}
