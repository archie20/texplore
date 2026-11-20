import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/services/stage_group.dart';
import 'package:thesis_topics/graph/interaction/lattice_motion.dart';
import 'package:thesis_topics/graph/layout/layout_node.dart';

void main() {
  test('a nearby circle gives way and the dropped circle stays', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final dragged = _node('dragged', 0, 0);
    final neighbour = _node('neighbour', 180, 0);
    motion.sync(
      GraphLayout(
        nodes: [dragged, neighbour],
        edges: [
          RoutedEdge(
            id: 'edge',
            sourceId: dragged.id,
            targetId: neighbour.id,
            start: const GraphPoint(70, 29),
            control1: const GraphPoint(100, 29),
            control2: const GraphPoint(130, 29),
            end: const GraphPoint(160, 29),
            dashed: false,
            crossLink: false,
          ),
        ],
        bands: const [],
        width: 400,
        height: 200,
      ),
    );

    motion.beginDragScene(dragged.id, const Offset(0, 0));
    motion.updateDragScene(const Offset(100, 0));
    for (var i = 0; i < 30; i++) {
      motion.advance();
    }

    expect(motion.topLeft(dragged).dx, greaterThan(70));
    expect(motion.topLeft(neighbour).dx, greaterThan(neighbour.x + 20));
    final edges = motion.follow([
      RoutedEdge(
        id: 'edge',
        sourceId: dragged.id,
        targetId: neighbour.id,
        start: const GraphPoint(70, 29),
        control1: const GraphPoint(100, 29),
        control2: const GraphPoint(130, 29),
        end: const GraphPoint(160, 29),
        dashed: false,
        crossLink: false,
      ),
    ]);
    expect(edges.single.end.x, greaterThan(160));

    motion.endDrag();
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }
    expect(motion.topLeft(dragged).dx, closeTo(100, 0.5));
    expect(
      _restsOn(
        motion.topLeft(dragged),
        _boxOf(dragged),
        motion.topLeft(neighbour),
        _boxOf(neighbour),
      ),
      isFalse,
    );
    expect(
      motion.topLeft(neighbour).dx,
      greaterThan(dragged.x + dragged.width),
    );

    final dropped = motion.topLeft(dragged);
    motion.sync(
      GraphLayout(
        nodes: [
          _node('dragged', 500, 400),
          _node('neighbour', 90, 0),
          _node('child', 720, 400),
        ],
        edges: [
          RoutedEdge(
            id: 'child-edge',
            sourceId: 'dragged',
            targetId: 'child',
            start: const GraphPoint(0, 0),
            control1: const GraphPoint(0, 0),
            control2: const GraphPoint(0, 0),
            end: const GraphPoint(0, 0),
            dashed: false,
            crossLink: false,
          ),
        ],
        bands: const [],
        width: 900,
        height: 600,
      ),
    );
    expect(motion.topLeft(dragged).dx, closeTo(dropped.dx, 0.5));
    expect(motion.topLeft(dragged).dy, closeTo(dropped.dy, 0.5));
    final child = _node('child', 720, 400);
    expect(motion.topLeft(child), motion.topLeft(dragged));
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }
    expect(motion.topLeft(child).dx, closeTo(dropped.dx + 220, 0.5));
    expect(motion.topLeft(child).dy, closeTo(dropped.dy, 0.5));
    expect(motion.presence(child.id), closeTo(1, 0.01));
  });

  test('give-way fades out at the edge of the influence radius', () {
    expect(
      giveWayOffset(
        homeCenter: const Offset(400, 0),
        draggedCenter: Offset.zero,
      ),
      Offset.zero,
    );
    final push = giveWayOffset(
      homeCenter: const Offset(80, 0),
      draggedCenter: Offset.zero,
    );
    expect(push.dx, greaterThan(0));
    expect(push.dy, closeTo(0, 0.001));
  });

  test(
    'thesis problems open in a close cluster and children stay beside them',
    () {
      final motion = LatticeMotion(random: math.Random(4));
      addTearDown(motion.dispose);
      final problems = [
        for (var i = 0; i < 6; i++) _problem('problem-$i', 64, 78 + i * 280),
      ];
      motion.sync(
        GraphLayout(
          nodes: problems,
          edges: const [],
          bands: const [],
          width: 800,
          height: 1800,
        ),
      );
      final homes = [for (final node in problems) motion.topLeft(node)];
      final xs = [for (final home in homes) home.dx];
      final minX = xs.reduce(math.min);
      final maxX = xs.reduce(math.max);
      expect(maxX - minX, greaterThan(40));
      for (var i = 0; i < problems.length; i++) {
        for (var j = i + 1; j < problems.length; j++) {
          expect((homes[i] - homes[j]).distance, lessThan(1100));
          expect(
            _restsOn(
              homes[i],
              _boxOf(problems[i]),
              homes[j],
              _boxOf(problems[j]),
            ),
            isFalse,
            reason: '${problems[i].id} rests on ${problems[j].id}',
          );
        }
      }
      expect(homes.first.dx, isNot(closeTo(problems.first.x, 1)));

      final parent = problems.first;
      final parentHome = motion.topLeft(parent);
      final child = _node('child', parent.x + 220, parent.y);
      motion.sync(
        GraphLayout(
          nodes: [...problems, child],
          edges: [
            RoutedEdge(
              id: 'edge',
              sourceId: parent.id,
              targetId: child.id,
              start: const GraphPoint(0, 0),
              control1: const GraphPoint(0, 0),
              control2: const GraphPoint(0, 0),
              end: const GraphPoint(0, 0),
              dashed: false,
              crossLink: false,
            ),
          ],
          bands: const [],
          width: 800,
          height: 1800,
        ),
      );
      expect(motion.topLeft(child), parentHome);
      expect(motion.presence(child.id), 0);
      expect(motion.topLeft(parent), parentHome);
      for (var i = 0; i < 80; i++) {
        motion.advance();
      }
      final placed = [...problems, child];
      for (var i = 0; i < placed.length; i++) {
        for (var j = i + 1; j < placed.length; j++) {
          expect(
            _restsOn(
              motion.topLeft(placed[i]),
              _boxOf(placed[i]),
              motion.topLeft(placed[j]),
              _boxOf(placed[j]),
            ),
            isFalse,
            reason: '${placed[i].id} rests on ${placed[j].id}',
          );
        }
      }
      expect(motion.topLeft(child), Offset(parentHome.dx + 220, parentHome.dy));
      expect(motion.topLeft(parent), parentHome);
    },
  );

  test('an old circle slides aside when a new one lands on it', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final old = _node('old', 0, 0);
    motion.sync(
      GraphLayout(
        nodes: [old],
        edges: const [],
        bands: const [],
        width: 400,
        height: 300,
      ),
    );
    final fresh = _node('fresh', 12, 4);
    motion.sync(
      GraphLayout(
        nodes: [old, fresh],
        edges: const [],
        bands: const [],
        width: 400,
        height: 300,
      ),
    );
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }
    expect(motion.topLeft(fresh).dx, closeTo(12, 0.5));
    expect(motion.topLeft(fresh).dy, closeTo(4, 0.5));
    expect((motion.topLeft(old) - Offset.zero).distance, greaterThan(20));
    expect(
      _restsOn(
        motion.topLeft(old),
        _boxOf(old),
        motion.topLeft(fresh),
        _boxOf(fresh),
      ),
      isFalse,
    );
  });

  test(
    'a circle on a straight link slides aside and the line stays straight',
    () {
      final motion = LatticeMotion();
      addTearDown(motion.dispose);
      final blocker = _node('blocker', 200, 40);
      motion.sync(_layout([blocker], const []));
      final source = _node('source', 0, 40);
      final target = _node('target', 520, 40);
      motion.sync(
        _layout([source, blocker, target], [_edge('source', 'target')]),
      );
      for (var i = 0; i < 80; i++) {
        motion.advance();
      }
      expect(motion.topLeft(source), const Offset(0, 40));
      expect(motion.topLeft(target), const Offset(520, 40));
      expect(
        (motion.topLeft(blocker) - const Offset(200, 40)).distance,
        greaterThan(20),
      );
      final line = motion.follow([_edge('source', 'target')]).single;
      expect(line.control1, line.start);
      expect(line.control2, line.end);
      expect(
        _lineHits(
          Offset(line.start.x, line.start.y),
          Offset(line.end.x, line.end.y),
          motion.topLeft(blocker),
          _boxOf(blocker),
        ),
        isFalse,
      );
    },
  );

  test('two straight links slide apart instead of crossing', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final a = _node('a', 0, 0);
    final b = _node('b', 420, 260);
    motion.sync(_layout([a, b], [_edge('a', 'b')]));
    final c = _node('c', 420, 0);
    final d = _node('d', 0, 260);
    motion.sync(_layout([a, b, c, d], [_edge('a', 'b'), _edge('c', 'd')]));
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }
    expect(motion.topLeft(d), const Offset(0, 260));
    final lines = motion.follow([_edge('a', 'b'), _edge('c', 'd')]);
    for (final line in lines) {
      expect(line.control1, line.start);
      expect(line.control2, line.end);
    }
    expect(
      _linesCross(
        Offset(lines[0].start.x, lines[0].start.y),
        Offset(lines[0].end.x, lines[0].end.y),
        Offset(lines[1].start.x, lines[1].start.y),
        Offset(lines[1].end.x, lines[1].end.y),
      ),
      isFalse,
    );
  });

  test('a parent drag carries its children and the straight link', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final parent = _node('parent', 0, 0);
    final child = _node('child', 220, 40);
    final grandchild = _node('grandchild', 440, 80);
    final bystander = _node('bystander', 0, 420);
    motion.sync(
      _layout(
        [parent, child, grandchild, bystander],
        [_edge('parent', 'child'), _edge('child', 'grandchild')],
      ),
    );

    final parentBefore = motion.topLeft(parent);
    final childBefore = motion.topLeft(child);
    final grandchildBefore = motion.topLeft(grandchild);
    final bystanderBefore = motion.topLeft(bystander);
    const drag = Offset(70, 24);
    motion.beginDragScene(parent.id, parentBefore);
    motion.updateDragScene(parentBefore + drag);
    for (var i = 0; i < 40; i++) {
      motion.advance();
    }
    motion.endDrag();
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }

    expect(motion.topLeft(parent), parentBefore + drag);
    expect(motion.topLeft(child), childBefore + drag);
    expect(motion.topLeft(grandchild), grandchildBefore + drag);
    expect(motion.topLeft(bystander), bystanderBefore);
    final line = motion.follow([_edge('parent', 'child')]).single;
    expect(line.control1, line.start);
    expect(line.control2, line.end);
    expect(
      (Offset(line.end.x, line.end.y) - Offset(line.start.x, line.start.y))
          .distance,
      greaterThan(8),
    );
  });

  test('a child slides with its parent when the parent gives way', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final parent = _node('parent', 0, 0);
    final child = _node('child', 240, 0);
    motion.sync(_layout([parent, child], [_edge('parent', 'child')]));
    final parentBefore = motion.topLeft(parent);
    final childBefore = motion.topLeft(child);
    final fresh = _node('fresh', parentBefore.dx + 8, parentBefore.dy + 6);
    motion.sync(_layout([parent, child, fresh], [_edge('parent', 'child')]));
    for (var i = 0; i < 80; i++) {
      motion.advance();
    }

    final parentShift = motion.topLeft(parent) - parentBefore;
    final childShift = motion.topLeft(child) - childBefore;
    expect(parentShift.distance, greaterThan(20));
    expect(childShift.dx, closeTo(parentShift.dx, 0.5));
    expect(childShift.dy, closeTo(parentShift.dy, 0.5));
    expect(motion.topLeft(fresh).dx, closeTo(parentBefore.dx + 8, 0.5));
    expect(motion.topLeft(fresh).dy, closeTo(parentBefore.dy + 6, 0.5));
    final line = motion.follow([_edge('parent', 'child')]).single;
    expect(line.control1, line.start);
    expect(line.control2, line.end);
  });

  test('a removed child folds back into its parent and then leaves', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    final parent = _node('parent', 0, 0);
    final child = _node('child', 220, 0);
    motion.sync(_layout([parent, child], [_edge('parent', 'child')]));
    expect(motion.topLeft(child), const Offset(220, 0));

    motion.sync(_layout([parent], const []));
    expect(motion.departingNodes.map((node) => node.id), ['child']);
    expect(motion.topLeft(child).dx, closeTo(220, 0.5));

    for (var i = 0; i < 8; i++) {
      motion.advance();
    }
    expect(motion.topLeft(child).dx, lessThan(200));
    expect(motion.topLeft(parent), const Offset(0, 0));

    for (var i = 0; i < 80; i++) {
      motion.advance();
    }
    expect(motion.departingNodes, isEmpty);
    expect(motion.topLeft(parent), const Offset(0, 0));
  });

  test(
    'a later stage still opens under the problem after an earlier one is moved',
    () {
      final motion = LatticeMotion(random: math.Random(1));
      addTearDown(motion.dispose);
      final problem = _problem('p', 40, 40);
      final first = _stage('p', ResearchStage.thesisQuestion, 50, 220);
      motion.sync(_layout([problem, first], [_edge(problem.id, first.id)]));
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }
      final problemHome = motion.topLeft(problem);
      motion.beginDragScene(first.id, motion.topLeft(first));
      motion.updateDragScene(const Offset(640, 40));
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }
      motion.endDrag();
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }

      final second = _stage('p', ResearchStage.relevance, 50, 336);
      motion.sync(
        _layout(
          [problem, first, second],
          [_edge(problem.id, first.id), _edge(first.id, second.id)],
        ),
      );
      for (var i = 0; i < 80; i++) {
        motion.advance();
      }
      expect(
        motion.topLeft(second),
        problemHome + const Offset(50 - 40, 336 - 40),
      );
      expect(motion.topLeft(problem), problemHome);
    },
  );

  test(
    'a record opens from its stage, not from a record that was dragged aside',
    () {
      final motion = LatticeMotion(random: math.Random(1));
      addTearDown(motion.dispose);
      final problem = _problem('p', 40, 40);
      final stage = _stage('p', ResearchStage.relevance, 50, 220);
      final first = _record('one', 'p', ResearchStage.relevance, 270, 220);
      motion.sync(
        _layout(
          [problem, stage, first],
          [_edge(problem.id, stage.id), _edge(stage.id, first.id)],
        ),
      );
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }
      final stageHome = motion.topLeft(stage);
      motion.beginDragScene(first.id, motion.topLeft(first));
      motion.updateDragScene(const Offset(270, 520));
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }
      motion.endDrag();
      for (var i = 0; i < 40; i++) {
        motion.advance();
      }

      final second = _record('two', 'p', ResearchStage.relevance, 440, 220);
      motion.sync(
        _layout(
          [problem, stage, first, second],
          [
            _edge(problem.id, stage.id),
            _edge(stage.id, first.id),
            _edge(first.id, second.id),
          ],
        ),
      );
      for (var i = 0; i < 80; i++) {
        motion.advance();
      }
      expect(
        motion.topLeft(second),
        stageHome + const Offset(440 - 50, 220 - 220),
      );
    },
  );

  test('a pointer on a circle does not count as a tap outside the popup', () {
    final motion = LatticeMotion();
    addTearDown(motion.dispose);
    motion.claimPointer();
    motion.armDismiss(Offset.zero);
    expect(motion.takeDismiss(const Offset(2, 2)), isFalse);

    motion.armDismiss(const Offset(10, 10));
    motion.trackDismiss(const Offset(40, 10));
    expect(motion.takeDismiss(const Offset(40, 10)), isFalse);

    motion.armDismiss(const Offset(10, 10));
    expect(motion.takeDismiss(const Offset(14, 12)), isTrue);
  });
}

bool _restsOn(Offset a, Size aSize, Offset b, Size bSize) {
  const gap = 16.0;
  return a.dx < b.dx + bSize.width + gap &&
      b.dx < a.dx + aSize.width + gap &&
      a.dy < b.dy + bSize.height + gap &&
      b.dy < a.dy + aSize.height + gap;
}

Size _boxOf(LayoutNode node) {
  return Size(
    node.width,
    math.max(node.height, LatticeMetrics.heightFor(node.stage)),
  );
}

LayoutNode _problem(String id, double x, double y) {
  return LayoutNode(
    id: id,
    candidateId: id,
    stage: ResearchStage.thesisProblem,
    title: id,
    summary: id,
    x: x,
    y: y,
    width: 168,
    height: 156,
    childCount: 1,
    expanded: false,
  );
}

GraphLayout _layout(List<LayoutNode> nodes, List<RoutedEdge> edges) {
  return GraphLayout(
    nodes: nodes,
    edges: edges,
    bands: const [],
    width: 900,
    height: 700,
  );
}

RoutedEdge _edge(String source, String target) {
  return RoutedEdge(
    id: '$source->$target',
    sourceId: source,
    targetId: target,
    start: const GraphPoint(0, 0),
    control1: const GraphPoint(0, 0),
    control2: const GraphPoint(1, 0),
    end: const GraphPoint(1, 0),
    dashed: false,
    crossLink: false,
  );
}

bool _lineHits(Offset a, Offset b, Offset topLeft, Size size) {
  final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
  if (rect.contains(a) || rect.contains(b)) return true;
  final corners = [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
  for (var i = 0; i < 4; i++) {
    if (_linesCross(a, b, corners[i], corners[(i + 1) % 4])) return true;
  }
  return false;
}

bool _linesCross(Offset a, Offset b, Offset c, Offset d) {
  double cross(Offset p, Offset q) => p.dx * q.dy - p.dy * q.dx;
  final d1 = cross(b - a, c - a);
  final d2 = cross(b - a, d - a);
  final d3 = cross(d - c, a - c);
  final d4 = cross(d - c, b - c);
  const eps = 0.05;
  return ((d1 > eps && d2 < -eps) || (d1 < -eps && d2 > eps)) &&
      ((d3 > eps && d4 < -eps) || (d3 < -eps && d4 > eps));
}

LayoutNode _stage(String candidateId, ResearchStage stage, double x, double y) {
  return LayoutNode(
    id: StageGroup.idFor(candidateId, stage),
    candidateId: candidateId,
    stage: stage,
    title: stage.name,
    summary: stage.name,
    x: x,
    y: y,
    width: 148,
    height: 94,
    childCount: 1,
    expanded: false,
  );
}

LayoutNode _record(
  String id,
  String candidateId,
  ResearchStage stage,
  double x,
  double y,
) {
  return LayoutNode(
    id: id,
    candidateId: candidateId,
    stage: stage,
    title: id,
    summary: id,
    x: x,
    y: y,
    width: 148,
    height: 94,
    childCount: 0,
    expanded: false,
  );
}

LayoutNode _node(String id, double x, double y) {
  return LayoutNode(
    id: id,
    candidateId: 'candidate',
    stage: ResearchStage.relevance,
    title: id,
    summary: id,
    x: x,
    y: y,
    width: 148,
    height: 110,
    childCount: 0,
    expanded: false,
  );
}
