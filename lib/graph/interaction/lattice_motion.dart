import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../domain/enums/research_stage.dart';
import '../../domain/services/stage_group.dart';
import '../layout/layout_node.dart';
import '../routing/straight_links.dart';
import 'viewport_controller.dart';

const _clusterCenter = Offset(280, 240);
const _clearance = 16.0;

/// How far a resting circle is pushed while another circle is dragged.
Offset giveWayOffset({
  required Offset homeCenter,
  required Offset draggedCenter,
  double influence = 280,
  double gain = 0.92,
  double maxPush = 120,
}) {
  var delta = homeCenter - draggedCenter;
  var distance = delta.distance;
  if (distance < 0.5) {
    delta = const Offset(12, 0);
    distance = 12;
  }
  if (distance >= influence) return Offset.zero;
  final push = ((influence - distance) * gain).clamp(0.0, maxPush);
  return delta / distance * push;
}

/// Free positions for the circles. The layout only suggests where a circle
/// appears the first time. A new child starts on its parent and eases out
/// around it; a child that leaves eases back into the parent, then drops off
/// the canvas. A drag eases a circle toward the pointer and leans its
/// neighbours aside. The hard clearance — no circle on a circle, no straight
/// line across a circle — runs when the circle is released and when a new
/// circle takes its place. Children travel with a parent, so the straight
/// lines between them travel too.
class LatticeMotion extends ChangeNotifier {
  LatticeMotion({math.Random? random}) : _random = random ?? math.Random();

  final GlobalKey viewerKey = GlobalKey();
  final math.Random _random;
  final StraightLinks _links = const StraightLinks();

  GraphLayout? _layout;
  TransformationController? _transform;
  Ticker? _ticker;
  Duration? _lastTick;
  var _disposed = false;
  final Map<String, Offset> _home = {};
  final Map<String, Offset> _position = {};
  final Map<String, LayoutNode> _known = {};
  final Map<String, Offset> _memory = {};
  final Map<String, Offset> _origin = {};
  final Map<String, double> _hold = {};
  final Map<String, double> _presence = {};
  final Map<String, double> _span = {};
  final Map<String, String?> _departParent = {};
  final Map<String, RoutedEdge> _ghosts = {};
  final Set<String> _arriving = {};
  final Set<String> _leaving = {};
  final Set<String> _fadeOnly = {};
  final Set<String> _fadeIn = {};

  String? _dragId;
  Offset _grab = Offset.zero;
  Offset _pointer = Offset.zero;
  var reducedMotion = false;

  bool pointerClaimed = false;
  bool _dismissArmed = false;
  Offset? _dismissDown;
  var _dismissMoved = false;

  void attach(TransformationController transform) {
    _transform = transform;
  }

  void bind(TickerProvider vsync) {
    _ticker ??= vsync.createTicker(_onTick);
  }

  void unbind() {
    _ticker?.dispose();
    _ticker = null;
    _lastTick = null;
  }

  void sync(GraphLayout layout) {
    if (identical(layout, _layout)) return;
    final previous = _layout;
    final hadLayout = previous != null;
    _layout = layout;
    for (final node in layout.nodes) {
      _known[node.id] = node;
      if (!_leaving.contains(node.id)) continue;
      final fading = _fadeOnly.remove(node.id);
      _departParent.remove(node.id);
      _leaving.remove(node.id);
      _ghosts.removeWhere(
        (_, edge) => edge.sourceId == node.id || edge.targetId == node.id,
      );
      if (fading) {
        _fadeIn.add(node.id);
        continue;
      }
      _span.remove(node.id);
      _hold.remove(node.id);
      _home.remove(node.id);
      _position.remove(node.id);
      _presence.remove(node.id);
    }
    _placeMissing(layout, animate: hadLayout);
    final seen = {for (final node in layout.nodes) node.id};
    final removed = [
      for (final id in _home.keys.toList())
        if (!seen.contains(id) && !_leaving.contains(id)) id,
    ];
    final retiring = removed.toSet();
    var pending = List<String>.of(removed);
    var guard = 0;
    while (pending.isNotEmpty && guard < pending.length + 2) {
      final waiting = <String>[];
      for (final id in pending) {
        final parentId = _parentIn(previous, id);
        if (parentId != null &&
            retiring.contains(parentId) &&
            !_leaving.contains(parentId)) {
          waiting.add(id);
          continue;
        }
        _beginLeaving(id, previous, animate: hadLayout && !reducedMotion);
      }
      if (waiting.length == pending.length) {
        for (final id in waiting) {
          _beginLeaving(id, previous, animate: hadLayout && !reducedMotion);
        }
        break;
      }
      pending = waiting;
      guard++;
    }
    if (_dragId != null && !seen.contains(_dragId)) _dragId = null;
    if (_dragId != null || _busy) _ensureTicking();
    if (hadLayout) {
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    }
  }

  /// New circles sit beside wherever their parent currently rests. Circles
  /// that are already on the canvas keep the place they were dropped, and
  /// slide aside when a new circle would cover them.
  void _placeMissing(GraphLayout layout, {required bool animate}) {
    var pending = [
      for (final node in layout.nodes)
        if (!_home.containsKey(node.id)) node,
    ];
    var guard = 0;
    while (pending.isNotEmpty && guard < pending.length + 2) {
      final waiting = <LayoutNode>[];
      for (final node in pending) {
        final home = _homeBesideParent(node, layout);
        if (home == null) {
          waiting.add(node);
          continue;
        }
        _takePlace(node, home, animate: animate);
      }
      if (waiting.length == pending.length) {
        for (final node in waiting) {
          _takePlace(node, Offset(node.x, node.y), animate: animate);
        }
        break;
      }
      pending = waiting;
      guard++;
    }
  }

  void _takePlace(LayoutNode node, Offset home, {required bool animate}) {
    _known[node.id] = node;
    final born = !_position.containsKey(node.id);
    _home[node.id] = home;
    final reveal = born && animate && !reducedMotion;
    if (reveal) {
      final origin = _bloomOrigin(node);
      if (origin != null && (origin - home).distance > 1) {
        _position[node.id] = origin;
        _origin[node.id] = origin;
        _arriving.add(node.id);
        _presence[node.id] = 0;
        final stagger = _siblingOrdinal(node) * 0.045;
        if (stagger > 0) _hold[node.id] = stagger;
      } else if (node.stage == ResearchStage.thesisProblem &&
          _memory.containsKey(node.id)) {
        _position[node.id] = home;
        _presence[node.id] = 0;
        _fadeIn.add(node.id);
        _memory.remove(node.id);
      } else {
        _position[node.id] = home;
        _presence.remove(node.id);
      }
    } else {
      _position.putIfAbsent(node.id, () => home);
      _arriving.remove(node.id);
      _origin.remove(node.id);
    }
    _yieldTo(node.id, animate: animate && !reducedMotion);
    if (_arriving.contains(node.id) || _fadeIn.contains(node.id)) {
      _ensureTicking();
    }
  }

  Offset? _homeBesideParent(LayoutNode node, GraphLayout layout) {
    final parentId = _parentIn(layout, node.id);
    if (parentId != null) {
      final parent = layout.nodeById(parentId);
      final parentHome = _home[parentId];
      if (parent == null || parentHome == null) return null;
      return parentHome + Offset(node.x - parent.x, node.y - parent.y);
    }
    if (node.stage == ResearchStage.thesisProblem) {
      return _memory[node.id] ?? _clusteredProblem(node);
    }
    return Offset(node.x, node.y);
  }

  Offset? _bloomOrigin(LayoutNode node) {
    final parentId = _parentIn(_layout, node.id);
    if (parentId == null) return null;
    return _position[parentId] ?? _home[parentId];
  }

  int _siblingOrdinal(LayoutNode node) {
    final layout = _layout;
    final parentId = _parentIn(layout, node.id);
    if (layout == null || parentId == null) return 0;
    final siblings =
        [
          for (final other in layout.nodes)
            if (_parentIn(layout, other.id) == parentId) other,
        ]..sort((a, b) {
          final dy = a.y.compareTo(b.y);
          if (dy != 0) return dy;
          return a.x.compareTo(b.x);
        });
    final index = siblings.indexWhere((other) => other.id == node.id);
    return index < 0 ? 0 : index;
  }

  /// Thesis problems open near one another. Any circle already there slides
  /// clear; the new problem stays at this spot.
  Offset _clusteredProblem(LayoutNode node) {
    final anchor = Offset(
      node.width / 2,
      LatticeMetrics.diameterFor(node.stage) / 2,
    );
    final angle = _random.nextDouble() * math.pi * 2;
    final radius = 28 + _random.nextDouble() * 90;
    return _clusterCenter +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius) -
        anchor;
  }

  /// [pinnedId] keeps its home. Every other circle that would cover it, or
  /// that is pushed into a neighbour, takes the nearest clear spot.
  void _yieldTo(String pinnedId, {required bool animate}) {
    final layout = _layout;
    if (layout == null || _home[pinnedId] == null) return;
    final placed = <String, Offset>{
      for (final node in layout.nodes)
        if (_home[node.id] != null) node.id: _home[node.id]!,
    };
    _separate(placed, pinnedId);
    var changed = false;
    for (final entry in placed.entries) {
      final previous = _home[entry.key];
      if (previous == null || (previous - entry.value).distance > 0.5) {
        changed = true;
      }
      _home[entry.key] = entry.value;
    }
    if (!animate) {
      for (final entry in placed.entries) {
        _position[entry.key] = entry.value;
      }
      return;
    }
    if (changed) _ensureTicking();
  }

  void _separate(Map<String, Offset> placed, String pinnedId) {
    final layout = _layout;
    if (layout == null) return;
    for (var pass = 0; pass < 12; pass++) {
      var moved = false;
      var skipped = false;
      for (final node in layout.nodes) {
        if (node.id == pinnedId) continue;
        final here = placed[node.id];
        if (here == null) continue;
        final overlaps = _mapOverlaps(node, here, placed);
        final line = _onLine(node, here, placed);
        if (!overlaps && !line) continue;
        if (!overlaps && line && pass < 8 && _adjacent(node.id, pinnedId)) {
          skipped = true;
          continue;
        }
        final free = _nearestClear(node, here, placed);
        final delta = free - here;
        if (delta.distance > 0.5) {
          placed[node.id] = free;
          for (final id in _descendants(node.id)) {
            final childAt = placed[id];
            if (childAt != null) placed[id] = childAt + delta;
          }
          moved = true;
        }
      }
      if (!moved && !skipped) return;
    }
  }

  bool _adjacent(String id, String pinnedId) {
    final edges = _layout?.edges;
    if (edges == null) return false;
    for (final edge in edges) {
      final touches =
          edge.sourceId == id && edge.targetId == pinnedId ||
          edge.targetId == id && edge.sourceId == pinnedId;
      if (touches) return true;
    }
    return false;
  }

  bool _onLine(LayoutNode node, Offset at, Map<String, Offset> placed) {
    final layout = _layout;
    if (layout == null) return false;
    return _links.affects(
      node: node,
      at: at,
      nodes: layout.nodes,
      edges: layout.edges,
      placed: placed,
    );
  }

  bool _mapOverlaps(
    LayoutNode node,
    Offset topLeft,
    Map<String, Offset> placed,
  ) {
    final layout = _layout;
    if (layout == null) return false;
    final box = _box(node);
    for (final other in layout.nodes) {
      if (other.id == node.id) continue;
      final there = placed[other.id];
      if (there == null) continue;
      if (_rectsOverlap(topLeft, box, there, _box(other))) return true;
    }
    return false;
  }

  Offset _nearestClear(
    LayoutNode node,
    Offset from,
    Map<String, Offset> placed,
  ) {
    var resolved = from;
    final layout = _layout;
    if (layout == null) return from;
    for (var pass = 0; pass < 4; pass++) {
      var pushed = false;
      for (final other in layout.nodes) {
        if (other.id == node.id) continue;
        final there = placed[other.id];
        if (there == null) continue;
        if (!_rectsOverlap(resolved, _box(node), there, _box(other))) continue;
        resolved += _minimumPush(resolved, _box(node), there, _box(other));
        pushed = true;
      }
      if (!pushed) break;
    }
    if (!_crowded(node, resolved, placed)) return resolved;
    final slide = _links.escape(
      node: node,
      at: resolved,
      nodes: layout.nodes,
      edges: layout.edges,
      placed: placed,
    );
    if (slide != null && !_crowded(node, resolved + slide, placed)) {
      return resolved + slide;
    }
    const step = 32.0;
    for (var ring = 1; ring <= 24; ring++) {
      final samples = 8 + ring * 2;
      for (var sample = 0; sample < samples; sample++) {
        final angle = sample / samples * math.pi * 2;
        final candidate =
            from +
            Offset(
              math.cos(angle) * step * ring,
              math.sin(angle) * step * ring,
            );
        if (!_crowded(node, candidate, placed)) return candidate;
      }
    }
    return resolved;
  }

  bool _crowded(LayoutNode node, Offset at, Map<String, Offset> placed) {
    return _mapOverlaps(node, at, placed) || _onLine(node, at, placed);
  }

  Size _box(LayoutNode node) {
    return Size(
      node.width,
      math.max(node.height, LatticeMetrics.heightFor(node.stage)),
    );
  }

  bool _rectsOverlap(Offset a, Size aSize, Offset b, Size bSize) {
    return a.dx < b.dx + bSize.width + _clearance &&
        b.dx < a.dx + aSize.width + _clearance &&
        a.dy < b.dy + bSize.height + _clearance &&
        b.dy < a.dy + aSize.height + _clearance;
  }

  /// Smallest move that takes [mover] off [fixed], including the clearance.
  Offset _minimumPush(
    Offset mover,
    Size moverSize,
    Offset fixed,
    Size fixedSize,
  ) {
    final left = mover.dx + moverSize.width + _clearance - fixed.dx;
    final right = fixed.dx + fixedSize.width + _clearance - mover.dx;
    final up = mover.dy + moverSize.height + _clearance - fixed.dy;
    final down = fixed.dy + fixedSize.height + _clearance - mover.dy;
    var best = Offset(-left, 0);
    if (right < best.distance) best = Offset(right, 0);
    if (up < best.distance) best = Offset(0, -up);
    if (down < best.distance) best = Offset(0, down);
    return best;
  }

  Offset topLeft(LayoutNode node) =>
      _position[node.id] ?? Offset(node.x, node.y);

  /// Where the circle settles. The camera frames this while a child is still
  /// travelling out of its parent.
  Offset restingTopLeft(LayoutNode node) =>
      _home[node.id] ?? _position[node.id] ?? Offset(node.x, node.y);

  /// 0 while a circle is still on its parent, 1 once it has arrived.
  /// A circle that is leaving fades back toward 0.
  double presence(String id) => (_presence[id] ?? 1).clamp(0.0, 1.0);

  List<LayoutNode> get departingNodes => [
    for (final id in _leaving)
      if (_known[id] != null) _known[id]!,
  ];

  void beginDrag(String id, Offset global) {
    final scene = sceneOf(global);
    if (scene == null) return;
    beginDragScene(id, scene);
  }

  void beginDragScene(String id, Offset scene) {
    final node = _layout?.nodeById(id);
    if (node == null) return;
    final current = _position[id] ?? Offset(node.x, node.y);
    _dragId = id;
    _grab = scene - current;
    _pointer = scene;
    _ensureTicking();
  }

  void updateDrag(Offset global) {
    final scene = sceneOf(global);
    if (scene == null) return;
    updateDragScene(scene);
  }

  void updateDragScene(Offset scene) {
    if (_dragId == null) return;
    _pointer = scene;
    _ensureTicking();
  }

  void endDrag() {
    final id = _dragId;
    if (id == null) return;
    final previous = _home[id] ?? (_position[id] ?? Offset.zero);
    final next = _pointer - _grab;
    final delta = next - previous;
    _home[id] = next;
    for (final childId in _descendants(id)) {
      final home = _home[childId];
      if (home != null) _home[childId] = home + delta;
    }
    _dragId = null;
    _yieldTo(id, animate: true);
  }

  /// One simulation step. Tests pass a fixed slice of time.
  void advance([double seconds = 1 / 60]) {
    _step(seconds.clamp(0.001, 0.05));
  }

  Offset? sceneOf(Offset global) {
    final box = viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final transform = _transform;
    if (box == null || !box.attached || !box.hasSize || transform == null) {
      return null;
    }
    return ViewportController.scenePoint(
      transform.toScene(box.globalToLocal(global)),
    );
  }

  List<RoutedEdge> follow(List<RoutedEdge> edges) {
    final layout = _layout;
    if (layout == null || (edges.isEmpty && _ghosts.isEmpty)) return edges;
    final seen = {for (final edge in edges) edge.id};
    final all = [
      ...edges,
      for (final edge in _ghosts.values)
        if (!seen.contains(edge.id)) edge,
    ];
    return [for (final edge in all) _straight(edge)];
  }

  RoutedEdge _straight(RoutedEdge edge) {
    final source = _resolve(edge.sourceId);
    final target = _resolve(edge.targetId);
    if (source == null || target == null) return edge;
    final sourceAt = source;
    final targetAt = target;
    final start = LatticeMetrics.rim(
      sourceAt,
      LatticeMetrics.centerOf(targetAt),
    );
    final end = LatticeMetrics.rim(targetAt, LatticeMetrics.centerOf(sourceAt));
    return RoutedEdge(
      id: edge.id,
      sourceId: edge.sourceId,
      targetId: edge.targetId,
      start: start,
      control1: start,
      control2: end,
      end: end,
      dashed: edge.dashed,
      crossLink: edge.crossLink,
    );
  }

  void claimPointer() => pointerClaimed = true;

  void armDismiss(Offset position) {
    if (pointerClaimed) {
      _dismissArmed = false;
      return;
    }
    _dismissArmed = true;
    _dismissDown = position;
    _dismissMoved = false;
  }

  void trackDismiss(Offset position) {
    final down = _dismissDown;
    if (!_dismissArmed || down == null) return;
    if ((position - down).distance > 8) _dismissMoved = true;
  }

  bool takeDismiss(Offset position) {
    trackDismiss(position);
    final dismiss = _dismissArmed && !_dismissMoved && !pointerClaimed;
    _dismissArmed = false;
    _dismissDown = null;
    pointerClaimed = false;
    return dismiss;
  }

  void cancelDismiss() {
    _dismissArmed = false;
    _dismissDown = null;
    pointerClaimed = false;
  }

  LayoutNode? _resolve(String id) {
    final live = _layout?.nodeById(id) ?? _known[id];
    if (live == null) return null;
    return _moved(live);
  }

  LayoutNode _moved(LayoutNode node) {
    final position = _position[node.id];
    if (position == null || (position.dx == node.x && position.dy == node.y)) {
      return node;
    }
    return LayoutNode(
      id: node.id,
      candidateId: node.candidateId,
      stage: node.stage,
      title: node.title,
      summary: node.summary,
      x: position.dx,
      y: position.dy,
      width: node.width,
      height: node.height,
      childCount: node.childCount,
      expanded: node.expanded,
    );
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final seconds = (elapsed - last).inMicroseconds / 1000000;
    _step(seconds.clamp(0.001, 0.05));
    if (_ticker?.isActive != true) _lastTick = null;
  }

  void _step(double seconds) {
    final layout = _layout;
    if (layout == null) return;
    final follow = reducedMotion ? 1.0 : 1 - math.exp(-seconds * 36);
    final settle = reducedMotion ? 1.0 : 1 - math.exp(-seconds * 12);
    final dragId = _dragId;
    Offset? draggedCenter;
    final targets = <String, Offset>{};
    final carried = dragId == null ? const <String>{} : _descendants(dragId);
    var parentDelta = Offset.zero;
    if (dragId != null) {
      final node = layout.nodeById(dragId);
      if (node != null) {
        final home = _home[dragId] ?? Offset(node.x, node.y);
        final current = _position[dragId] ?? home;
        final next = Offset.lerp(current, _pointer - _grab, follow)!;
        _position[dragId] = next;
        draggedCenter = _center(node, next);
        targets[dragId] = next;
        parentDelta = next - home;
      }
    }
    for (final node in layout.nodes) {
      if (node.id == dragId) continue;
      final held = _hold[node.id];
      if (held != null && held > 0 && !carried.contains(node.id)) {
        _hold[node.id] = held - seconds;
        _presence[node.id] = 0;
        continue;
      }
      _hold.remove(node.id);
      final home = _home[node.id] ?? Offset(node.x, node.y);
      if (carried.contains(node.id)) {
        targets[node.id] = home + parentDelta;
        continue;
      }
      final push = draggedCenter == null
          ? Offset.zero
          : giveWayOffset(
              homeCenter: _center(node, home),
              draggedCenter: draggedCenter,
            );
      targets[node.id] = home + push;
    }
    for (final node in layout.nodes) {
      if (node.id == dragId || _hold.containsKey(node.id)) continue;
      final home = _home[node.id] ?? Offset(node.x, node.y);
      final current = _position[node.id] ?? home;
      final target = targets[node.id] ?? home;
      final next = Offset.lerp(current, target, settle)!;
      _position[node.id] = (next - target).distance < 0.35 ? target : next;
      if (!_arriving.contains(node.id)) continue;
      final origin = _origin[node.id];
      final at = _position[node.id]!;
      final goal = _home[node.id] ?? target;
      if (origin == null) {
        _presence[node.id] = 1;
        _arriving.remove(node.id);
        continue;
      }
      final span = (origin - goal).distance;
      _presence[node.id] = span < 1
          ? 1
          : (1 - (at - goal).distance / span).clamp(0.0, 1.0);
      if ((at - goal).distance < 0.6) {
        _arriving.remove(node.id);
        _origin.remove(node.id);
        _presence[node.id] = 1;
      }
    }
    _stepDepartures(seconds, settle);
    _stepFadeIn(seconds);
    notifyListeners();
    if (dragId != null) return;
    if (_busy) return;
    if (_atRest) _ticker?.stop();
  }

  bool get _busy =>
      _leaving.isNotEmpty ||
      _fadeIn.isNotEmpty ||
      _arriving.isNotEmpty ||
      _hold.values.any((hold) => hold > 0);

  void _stepFadeIn(double seconds) {
    for (final id in _fadeIn.toList()) {
      final next = (_presence[id] ?? 0) + seconds / 0.32;
      if (next >= 1) {
        _presence[id] = 1;
        _fadeIn.remove(id);
      } else {
        _presence[id] = next;
      }
    }
  }

  void _stepDepartures(double seconds, double settle) {
    for (final id in _leaving.toList()) {
      if (_fadeOnly.contains(id)) {
        if (_childStillLeaving(id)) continue;
        final next = (_presence[id] ?? 1) - seconds / 0.32;
        if (next <= 0.02) {
          _drop(id);
        } else {
          _presence[id] = next;
        }
        continue;
      }
      final home = _home[id];
      if (home == null) {
        _drop(id);
        continue;
      }
      final current = _position[id] ?? home;
      final next = Offset.lerp(current, home, settle)!;
      _position[id] = (next - home).distance < 0.35 ? home : next;
      final span = _span[id] ?? (current - home).distance;
      final left = (_position[id]! - home).distance;
      _presence[id] = span < 1 ? 0 : (left / span).clamp(0.0, 1.0);
      if (left < 1.2) _drop(id);
    }
  }

  bool _childStillLeaving(String id) {
    for (final other in _leaving) {
      if (other != id && _foldsInto(other, id)) return true;
    }
    return false;
  }

  bool _foldsInto(String id, String ancestor) {
    var current = _departParent[id];
    var guard = 0;
    while (current != null && guard < 16) {
      if (current == ancestor) return true;
      current = _departParent[current];
      guard++;
    }
    return false;
  }

  bool get _atRest {
    final layout = _layout;
    if (layout == null) return true;
    for (final node in layout.nodes) {
      final position = _position[node.id];
      final home = _home[node.id];
      if (position == null || home == null) continue;
      if ((position - home).distance > 0.4) return false;
    }
    return true;
  }

  Set<String> _descendants(String id) {
    final layout = _layout;
    if (layout == null) return const {};
    final children = <String, List<String>>{};
    for (final node in layout.nodes) {
      final parentId = _parentIn(layout, node.id);
      if (parentId == null) continue;
      children.putIfAbsent(parentId, () => []).add(node.id);
    }
    final out = <String>{};
    final stack = <String>[...?children[id]];
    while (stack.isNotEmpty) {
      final next = stack.removeLast();
      if (!out.add(next)) continue;
      final below = children[next];
      if (below != null) stack.addAll(below);
    }
    return out;
  }

  Offset _center(LayoutNode node, Offset topLeft) {
    return Offset(
      topLeft.dx + node.width / 2,
      topLeft.dy + LatticeMetrics.diameterFor(node.stage) / 2,
    );
  }

  /// Stages belong to the thesis problem, and records belong to their stage,
  /// even where the drawn line is only the short link that keeps the row or
  /// the stack from crossing itself.
  String? _parentIn(GraphLayout? layout, String id) {
    if (layout == null) return null;
    final node = layout.nodeById(id);
    if (node != null) {
      if (StageGroup.parse(node.id) != null) {
        for (final other in layout.nodes) {
          if (other.candidateId == node.candidateId &&
              other.stage == ResearchStage.thesisProblem) {
            return other.id;
          }
        }
      } else if (node.stage != ResearchStage.thesisProblem) {
        final groupId = StageGroup.idFor(node.candidateId, node.stage);
        if (layout.nodeById(groupId) != null) return groupId;
      } else {
        return null;
      }
    }
    for (final edge in layout.edges) {
      if (!edge.crossLink && edge.targetId == id) return edge.sourceId;
    }
    return null;
  }

  void _beginLeaving(
    String id,
    GraphLayout? previous, {
    required bool animate,
  }) {
    if (!animate) {
      _drop(id);
      return;
    }
    final from = _position[id] ?? _home[id] ?? Offset.zero;
    final parentId = _parentIn(previous, id);
    final parentLeaving = parentId != null && _leaving.contains(parentId);
    final dest = parentId == null
        ? from
        : parentLeaving
        ? (_home[parentId] ?? _position[parentId] ?? from)
        : (_position[parentId] ?? _home[parentId] ?? from);
    _home[id] = dest;
    _leaving.add(id);
    _arriving.remove(id);
    _origin.remove(id);
    _fadeIn.remove(id);
    _departParent[id] = parentId;
    final span = (from - dest).distance;
    if (parentId == null || span < 1) {
      _fadeOnly.add(id);
      _presence[id] = _presence[id] ?? 1;
    } else {
      _fadeOnly.remove(id);
      _span[id] = span;
      _presence[id] = 1;
    }
    if (previous != null) {
      for (final edge in previous.edges) {
        if (edge.sourceId == id || edge.targetId == id) {
          _ghosts[edge.id] = edge;
        }
      }
    }
    _ensureTicking();
  }

  void _drop(String id) {
    final node = _known[id];
    final home = _home[id] ?? _position[id];
    final parent = _departParent[id];
    for (final entry in _departParent.entries.toList()) {
      if (entry.key != id && entry.value == id) {
        _departParent[entry.key] = parent;
      }
    }
    if (node?.stage == ResearchStage.thesisProblem &&
        home != null &&
        _departParent[id] == null) {
      _memory[id] = home;
    }
    _home.remove(id);
    _position.remove(id);
    _presence.remove(id);
    _origin.remove(id);
    _span.remove(id);
    _hold.remove(id);
    _arriving.remove(id);
    _leaving.remove(id);
    _fadeOnly.remove(id);
    _fadeIn.remove(id);
    _departParent.remove(id);
    _known.remove(id);
    _ghosts.removeWhere(
      (_, edge) => edge.sourceId == id || edge.targetId == id,
    );
    if (_dragId == id) _dragId = null;
  }

  void _ensureTicking() {
    final ticker = _ticker;
    if (ticker == null || ticker.isActive) return;
    _lastTick = null;
    ticker.start();
  }

  @override
  void dispose() {
    _disposed = true;
    unbind();
    super.dispose();
  }
}

class LatticeMotionScope extends InheritedWidget {
  const LatticeMotionScope({
    required this.motion,
    required super.child,
    super.key,
  });

  final LatticeMotion motion;

  static LatticeMotion? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<LatticeMotionScope>()?.motion;
  }

  @override
  bool updateShouldNotify(LatticeMotionScope oldWidget) {
    return motion != oldWidget.motion;
  }
}
