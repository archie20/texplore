import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/services/graph_queries.dart';
import 'package:thesis_topics/domain/services/stage_group.dart';

import '../support/catalogue_factory.dart';

void main() {
  test('stage entries are records whose parent is outside the stage', () {
    final catalogue = chainCatalogue();
    final entries = GraphQueries.stageEntries(
      catalogue,
      'candidate-a',
      ResearchStage.literatureGaps,
    );
    expect(entries.map((node) => node.id), ['n-gap']);
    expect(
      GraphQueries.stageEntries(
        catalogue,
        'candidate-a',
        ResearchStage.thesisAreas,
      ).map((node) => node.id),
      ['n-area'],
    );
  });

  test('opening a stage reveals entries, not every stage member via parent hub', () {
    final catalogue = chainCatalogue();
    final stageId = StageGroup.idFor(
      'candidate-a',
      ResearchStage.potentialTopics,
    );
    final visible = GraphQueries.structurallyVisible(catalogue, {
      'n-problem',
      stageId,
    });
    expect(visible, contains('n-topic'));
    expect(visible, contains('n-gap')); // auto-revealed ancestor
    expect(visible, isNot(contains('n-rq')));
    expect(visible, contains(stageId));
  });

  test('expanding a record reveals actual children across stages', () {
    final catalogue = chainCatalogue();
    final visible = GraphQueries.structurallyVisible(catalogue, {
      'n-problem',
      StageGroup.idFor('candidate-a', ResearchStage.literatureGaps),
      'n-gap',
    });
    expect(visible, contains('n-topic'));
    expect(visible, contains('n-gap'));
  });

  test('auto-reveal ancestors does not expand sibling branches', () {
    final catalogue = chainCatalogue();
    final visible = GraphQueries.structurallyVisible(catalogue, {
      'n-problem',
      StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
    });
    expect(visible, containsAll(['n-rq', 'n-topic', 'n-gap', 'n-question']));
    expect(visible, isNot(contains('n-relevance')));
    expect(visible, isNot(contains('n-outcome')));
  });

  test('routeIds follow the actual ancestor path', () {
    final catalogue = chainCatalogue();
    expect(
      GraphQueries.routeIds(catalogue, 'n-rq'),
      {
        'n-problem',
        'n-question',
        'n-area',
        'n-status',
        'n-gap',
        'n-topic',
        'n-rq',
      },
    );
  });

  test('canvasParentId uses the real parent when present', () {
    final catalogue = chainCatalogue();
    expect(GraphQueries.canvasParentId(catalogue, 'n-topic'), 'n-gap');
    expect(
      GraphQueries.canvasParentId(
        catalogue,
        StageGroup.idFor('candidate-a', ResearchStage.literatureGaps),
      ),
      'n-problem',
    );
  });

  test('children order by sortOrder then id', () {
    final catalogue = chainCatalogue();
    final kids = GraphQueries.children(catalogue, catalogue.nodes['n-question']!);
    expect(kids.map((node) => node.id), [
      'n-relevance',
      'n-outcome',
      'n-area',
    ]);
  });
}
