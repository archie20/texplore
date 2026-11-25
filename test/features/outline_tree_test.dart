import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/features/explorer/application/explorer_filters.dart';
import 'package:thesis_topics/features/outline/outline_tree.dart';

import '../support/catalogue_factory.dart';

void main() {
  test('outline depth follows parent-child hierarchy, not stage order', () {
    final catalogue = chainCatalogue();
    final rows = OutlineTree.build(
      catalogue: catalogue,
      expandedIds: {
        'n-problem',
        'n-question',
        'n-area',
        'n-status',
        'n-gap',
        'n-topic',
      },
    );
    expect(rows.map((row) => row.node.id).toList(), [
      'n-problem',
      'n-question',
      'n-relevance',
      'n-outcome',
      'n-area',
      'n-status',
      'n-gap',
      'n-topic',
      'n-rq',
    ]);
    expect(rows.map((row) => row.depth).toList(), [0, 1, 2, 2, 2, 3, 4, 5, 6]);
    expect(
      rows.every((row) => row.node.stage.label.isNotEmpty),
      isTrue,
    );
  });

  test('a child stays under its parent even when stages differ', () {
    final catalogue = chainCatalogue();
    final rows = OutlineTree.build(
      catalogue: catalogue,
      expandedIds: {'n-problem', 'n-question', 'n-area'},
    );
    final ids = rows.map((row) => row.node.id).toList();
    final area = ids.indexOf('n-area');
    final status = ids.indexOf('n-status');
    expect(status, greaterThan(area));
    expect(rows[status].depth, rows[area].depth + 1);
    expect(rows[status].node.stage, ResearchStage.currentStatusQuo);
    expect(rows[area].node.stage, ResearchStage.thesisAreas);
  });

  test('filtering keeps ancestors as context without reparenting', () {
    final catalogue = chainCatalogue();
    final rows = OutlineTree.build(
      catalogue: catalogue,
      expandedIds: const {},
      filters: const ExplorerFilters(
        stages: {ResearchStage.researchQuestions},
        hideNonMatching: true,
      ),
    );
    expect(rows.map((row) => row.node.id), [
      'n-problem',
      'n-question',
      'n-area',
      'n-status',
      'n-gap',
      'n-topic',
      'n-rq',
    ]);
    expect(rows.where((row) => row.contextOnly).map((row) => row.node.id), [
      'n-problem',
      'n-question',
      'n-area',
      'n-status',
      'n-gap',
      'n-topic',
    ]);
    expect(rows.last.contextOnly, isFalse);
    expect(rows.last.node.id, 'n-rq');
  });

  test('multiple candidates stay separated', () {
    final a = chainCatalogue();
    final b = chainCatalogue(
      candidateId: 'candidate-b',
      prefix: 'b',
      publications: [testPublication(id: 'pub-b', doi: '10.1000/b')],
    );
    final catalogue = Catalogue(
      schemaVersion: a.schemaVersion,
      title: a.title,
      candidates: [...a.candidates, ...b.candidates],
      nodes: {...a.nodes, ...b.nodes},
      publications: {...a.publications, ...b.publications},
      evidenceLinks: {...a.evidenceLinks, ...b.evidenceLinks},
      crossLinks: const [],
    );
    final rows = OutlineTree.build(
      catalogue: catalogue,
      expandedIds: const {},
    );
    expect(rows.map((row) => row.node.id), ['n-problem', 'b-problem']);
  });
}
