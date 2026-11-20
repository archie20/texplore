import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/services/graph_queries.dart';
import 'package:thesis_topics/domain/services/stage_group.dart';
import 'package:thesis_topics/features/explorer/application/explorer_filters.dart';
import 'package:thesis_topics/graph/layout/hierarchical_layout_engine.dart';
import 'package:thesis_topics/graph/layout/layout_node.dart';
import 'package:thesis_topics/graph/routing/straight_links.dart';

import '../support/catalogue_factory.dart';

void main() {
  final engine = HierarchicalLayoutEngine();

  test('stages open at irregular gaps around the problem', () {
    final catalogue = chainCatalogue();
    final expanded = {'n-problem'};
    final visible = GraphQueries.structurallyVisible(catalogue, expanded);
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: visible,
      expandedIds: expanded,
    );
    final problem = layout.nodeById('n-problem')!;
    final question = layout.nodeById(
      StageGroup.idFor('candidate-a', ResearchStage.thesisQuestion),
    )!;
    final relevance = layout.nodeById(
      StageGroup.idFor('candidate-a', ResearchStage.relevance),
    )!;
    final outcome = layout.nodeById(
      StageGroup.idFor('candidate-a', ResearchStage.expectedOutcomes),
    )!;
    final problemCenter = _center(problem);
    final distances = [
      question,
      relevance,
      outcome,
    ].map((node) => (_center(node) - problemCenter).distance).toList();
    final spread = distances.reduce(math.max) - distances.reduce(math.min);
    expect(spread, greaterThan(12));
    for (final distance in distances) {
      expect(distance, greaterThan(80));
      expect(distance, lessThan(580));
    }
    expect(question.x, isNot(closeTo(relevance.x, 1)));
    expect(_linked(layout, problem.id, question.id), isTrue);
    expect(_linked(layout, question.id, relevance.id), isFalse);
    expect(layout.nodeById('n-question'), isNull);
    expect(_linesStayClear(layout), isTrue);
    for (var i = 0; i < layout.nodes.length; i++) {
      for (var j = i + 1; j < layout.nodes.length; j++) {
        expect(
          layout.nodes[i].overlaps(layout.nodes[j]),
          isFalse,
          reason: '${layout.nodes[i].id} overlaps ${layout.nodes[j].id}',
        );
      }
    }
  });

  test('a collapsed branch reserves a single row', () {
    final catalogue = chainCatalogue();
    final collapsed = engine.layout(
      catalogue: catalogue,
      visibleIds: {'n-problem'},
      expandedIds: const {},
    );
    expect(collapsed.nodes, hasLength(1));
    expect(collapsed.nodes.single.height, HierarchicalLayoutEngine.rootHeight);

    final expanded = engine.layout(
      catalogue: catalogue,
      visibleIds: GraphQueries.structurallyVisible(catalogue, {'n-problem'}),
      expandedIds: {'n-problem'},
    );
    expect(expanded.nodes.length, greaterThan(1));
    final problem = expanded.nodeById('n-problem')!;
    final question = expanded.nodeById(
      StageGroup.idFor('candidate-a', ResearchStage.thesisQuestion),
    )!;
    expect((_center(question) - _center(problem)).distance, greaterThan(80));
  });

  test('connections are straight', () {
    final catalogue = chainCatalogue();
    final expanded = {
      'n-problem',
      for (final stage in ResearchStage.values)
        if (stage != ResearchStage.thesisProblem)
          StageGroup.idFor('candidate-a', stage),
    };
    final visible = GraphQueries.structurallyVisible(catalogue, expanded);
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: visible,
      expandedIds: expanded,
    );
    expect(layout.edges, isNotEmpty);
    for (final edge in layout.edges) {
      final cross =
          (edge.control1.x - edge.start.x) * (edge.end.y - edge.start.y) -
          (edge.control1.y - edge.start.y) * (edge.end.x - edge.start.x);
      expect(cross.abs(), lessThan(0.01), reason: edge.id);
    }
  });

  test('a stage opens its records with the same irregular placement', () {
    final catalogue = chainCatalogue();
    final stageId = StageGroup.idFor(
      'candidate-a',
      ResearchStage.thesisQuestion,
    );
    final expanded = {'n-problem', stageId};
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: GraphQueries.structurallyVisible(catalogue, expanded),
      expandedIds: expanded,
    );
    final problem = layout.nodeById('n-problem')!;
    final stage = layout.nodeById(stageId)!;
    final record = layout.nodeById('n-question')!;
    final next = layout.nodeById(
      StageGroup.idFor('candidate-a', ResearchStage.relevance),
    )!;
    final problemCenter = _center(problem);
    expect((_center(record) - _center(stage)).distance, greaterThan(40));
    expect((_center(record) - _center(stage)).distance, lessThan(580));
    expect(_linked(layout, stage.id, record.id), isTrue);
    expect(
      (_center(next) - problemCenter).distance,
      isNot(closeTo((_center(stage) - problemCenter).distance, 8)),
    );
    expect(layout.nodeById('n-relevance'), isNull);
    expect(_linesStayClear(layout), isTrue);
  });

  test('records in one stage use irregular gaps, not a fan', () {
    final catalogue = syntheticCatalogue(12);
    final areas = StageGroup.idFor('candidate-a', ResearchStage.thesisAreas);
    final expanded = {'root', areas};
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: GraphQueries.structurallyVisible(catalogue, expanded),
      expandedIds: expanded,
    );
    final closed = engine.layout(
      catalogue: catalogue,
      visibleIds: GraphQueries.structurallyVisible(catalogue, {'root'}),
      expandedIds: {'root'},
    );
    final stage = layout.nodeById(areas)!;
    final records = layout.nodes
        .where(
          (node) => node.id != areas && node.stage == ResearchStage.thesisAreas,
        )
        .toList();
    expect(records.length, greaterThan(1));
    final stageCenter = _center(stage);
    final distances = [
      for (final node in records) (_center(node) - stageCenter).distance,
    ];
    expect(distances.reduce(math.min), greaterThan(40));
    expect(distances.reduce(math.max), lessThan(580));
    final first = _center(records.first) - stageCenter;
    final second = _center(records.last) - stageCenter;
    final sameWay =
        (first.dx * second.dx + first.dy * second.dy) /
        (first.distance * second.distance);
    expect(sameWay, lessThan(0.98));
    for (final record in records) {
      expect(_linked(layout, stage.id, record.id), isTrue);
    }
    expect(_linked(layout, records.first.id, records.last.id), isFalse);
    for (final before in closed.nodes) {
      final after = layout.nodeById(before.id);
      expect(after, isNotNull);
      expect(after!.x, closeTo(before.x, 0.01));
      expect(after.y, closeTo(before.y, 0.01));
    }
    expect(_linesStayClear(layout), isTrue);
  });

  test('several open stages keep their records clear of each other', () {
    final catalogue = syntheticCatalogue(32);
    final expanded = {
      'root',
      for (final stage in ResearchStage.values)
        if (stage != ResearchStage.thesisProblem)
          StageGroup.idFor('candidate-a', stage),
    };
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: GraphQueries.structurallyVisible(catalogue, expanded),
      expandedIds: expanded,
    );
    expect(layout.nodes.length, greaterThan(20));
    final problem = layout.nodeById('root')!;
    for (final node in layout.nodes) {
      if (node.id == problem.id) continue;
      final parent = node.id.startsWith('stage:')
          ? problem
          : layout.nodes.firstWhere(
              (other) =>
                  other.id.startsWith('stage:') && other.stage == node.stage,
            );
      expect(
        (_center(node) - _center(parent)).distance,
        lessThan(580),
        reason: node.id,
      );
    }
  });

  test('layouts 1000 nodes near their parents, quickly', () {
    final catalogue = syntheticCatalogue(1000);
    expect(catalogue.nodes.length, greaterThanOrEqualTo(1000));
    final expanded = {
      'root',
      for (final stage in ResearchStage.values)
        if (stage != ResearchStage.thesisProblem)
          StageGroup.idFor('candidate-a', stage),
    };
    final visible = GraphQueries.structurallyVisible(catalogue, expanded);
    final watch = Stopwatch()..start();
    final layout = engine.layout(
      catalogue: catalogue,
      visibleIds: visible,
      expandedIds: expanded,
    );
    watch.stop();
    expect(layout.nodes.length, greaterThanOrEqualTo(1000));
    expect(watch.elapsedMilliseconds, lessThan(2000));
    final problem = layout.nodeById('root')!;
    for (final node in layout.nodes) {
      if (node.id == problem.id) continue;
      final parent = node.id.startsWith('stage:')
          ? problem
          : layout.nodes.firstWhere(
              (other) =>
                  other.id.startsWith('stage:') && other.stage == node.stage,
            );
      expect((_center(node) - _center(parent)).distance, lessThan(580));
    }
  });

  test('hide mode keeps ancestors of matches', () {
    final catalogue = chainCatalogue();
    final filters = ExplorerFilters(stages: {catalogue.nodes['n-rq']!.stage});
    final expanded = {
      'n-problem',
      StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
    };
    final structural = GraphQueries.structurallyVisible(catalogue, expanded);
    final matching = {
      for (final id in structural)
        if (catalogue.nodes[id] != null &&
            filters.matchesNode(catalogue, catalogue.nodes[id]!))
          id,
    };
    expect(matching, {'n-rq'});
  });
}

Offset _center(LayoutNode node) {
  return Offset(
    node.x + node.width / 2,
    node.y + LatticeMetrics.diameterFor(node.stage) / 2,
  );
}

bool _linked(GraphLayout layout, String from, String to) {
  return layout.edges.any(
    (edge) => !edge.crossLink && edge.sourceId == from && edge.targetId == to,
  );
}

bool _linesStayClear(GraphLayout layout) {
  const links = StraightLinks();
  final placed = {
    for (final node in layout.nodes) node.id: Offset(node.x, node.y),
  };
  for (final node in layout.nodes) {
    if (links.affects(
      node: node,
      at: placed[node.id]!,
      nodes: layout.nodes,
      edges: layout.edges,
      placed: placed,
    )) {
      final hit = [
        for (final edge in layout.edges)
          if (edge.sourceId == node.id || edge.targetId == node.id)
            edge.id
          else
            edge.id,
      ];
      fail('${node.id} sits on a straight link');
    }
  }
  return true;
}
