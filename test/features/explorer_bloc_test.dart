import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/evidence_status.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/features/explorer/application/explorer_bloc.dart';
import 'package:thesis_topics/features/explorer/application/explorer_event.dart';
import 'package:thesis_topics/features/explorer/application/explorer_filters.dart';
import 'package:thesis_topics/features/explorer/application/explorer_state.dart';
import 'package:thesis_topics/features/search/search_cubit.dart';
import 'package:thesis_topics/domain/services/search_index.dart';
import 'package:thesis_topics/domain/services/stage_group.dart';

import '../support/catalogue_factory.dart';

void main() {
  final catalogue = chainCatalogue();

  blocTest<ExplorerBloc, ExplorerState>(
    'collapsing an ancestor moves the selection onto it',
    build: () => ExplorerBloc(catalogue: catalogue),
    act: (bloc) {
      bloc
        ..add(const PathRevealed('n-rq'))
        ..add(const NodeSelected('n-rq'))
        ..add(
          NodeToggled(
            StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
          ),
        );
    },
    verify: (bloc) {
      expect(
        bloc.state.selectedNodeId,
        StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
      );
      expect(bloc.state.layout.nodeById('n-rq'), isNull);
      expect(
        bloc.state.expandedIds,
        isNot(
          contains(
            StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
          ),
        ),
      );
    },
  );

  test('selecting an open node keeps the same layout instance', () async {
    final bloc = ExplorerBloc(
      catalogue: catalogue,
      initialExpanded: {
        'n-problem',
        StageGroup.idFor('candidate-a', ResearchStage.relevance),
      },
    );
    final layout = bloc.state.layout;
    bloc.add(const NodeSelected('n-relevance'));
    await bloc.stream.first;
    expect(identical(bloc.state.layout, layout), isTrue);
    expect(bloc.state.selectedNodeId, 'n-relevance');
    await bloc.close();
  });

  blocTest<ExplorerBloc, ExplorerState>(
    'child nodes start collapsed until a parent is opened',
    build: () => ExplorerBloc(catalogue: catalogue),
    verify: (bloc) {
      expect(bloc.state.expandedIds, isEmpty);
      expect(bloc.state.layout.nodes.map((node) => node.id), ['n-problem']);
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'opening a thesis problem groups its stages, and a stage opens its records',
    build: () => ExplorerBloc(catalogue: catalogue),
    act: (bloc) {
      bloc
        ..add(const NodeSelected('n-problem'))
        ..add(
          NodeSelected(
            StageGroup.idFor('candidate-a', ResearchStage.thesisQuestion),
            centre: true,
          ),
        );
    },
    verify: (bloc) {
      final ids = bloc.state.layout.nodes.map((node) => node.id).toSet();
      expect(ids, contains('n-problem'));
      expect(
        ids,
        containsAll([
          StageGroup.idFor('candidate-a', ResearchStage.thesisQuestion),
          StageGroup.idFor('candidate-a', ResearchStage.relevance),
          StageGroup.idFor('candidate-a', ResearchStage.literatureGaps),
          'n-question',
        ]),
      );
      expect(ids, isNot(contains('n-relevance')));
      expect(bloc.state.inspectorOpen, isFalse);
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'a parent in another thesis problem collapses every other branch',
    build: () {
      final other = chainCatalogue(
        candidateId: 'candidate-b',
        prefix: 'b',
        publications: [testPublication(id: 'pub-b', doi: '10.1000/other')],
      );
      return ExplorerBloc(
        catalogue: Catalogue(
          schemaVersion: catalogue.schemaVersion,
          title: catalogue.title,
          candidates: [...catalogue.candidates, ...other.candidates],
          nodes: {...catalogue.nodes, ...other.nodes},
          publications: {...catalogue.publications, ...other.publications},
          evidenceLinks: {...catalogue.evidenceLinks, ...other.evidenceLinks},
          crossLinks: [...catalogue.crossLinks, ...other.crossLinks],
        ),
      );
    },
    act: (bloc) {
      bloc
        ..add(const NodeSelected('n-problem'))
        ..add(const NodeSelected('b-problem'));
    },
    verify: (bloc) {
      expect(bloc.state.expandedIds, {'b-problem'});
      final ids = bloc.state.layout.nodes.map((node) => node.id).toSet();
      expect(ids, contains('b-problem'));
      expect(
        ids,
        contains(StageGroup.idFor('candidate-b', ResearchStage.thesisQuestion)),
      );
      expect(ids, isNot(contains('n-problem')));
      expect(ids, isNot(contains('n-question')));
      expect(ids, isNot(contains('b-relevance')));
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'closing the popup asks the camera to zoom out',
    build: () => ExplorerBloc(catalogue: catalogue),
    act: (bloc) {
      bloc
        ..add(const NodeSelected('n-problem'))
        ..add(const InspectorClosed());
    },
    verify: (bloc) {
      expect(bloc.state.inspectorOpen, isFalse);
      expect(bloc.state.focusKind, FocusKind.zoomOut);
      expect(bloc.state.selectedNodeId, 'n-problem');
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'revealing a path opens the stage and auto-reveals ancestors',
    build: () => ExplorerBloc(catalogue: catalogue),
    act: (bloc) => bloc.add(const PathRevealed('n-rq')),
    verify: (bloc) {
      expect(
        bloc.state.expandedIds,
        containsAll([
          'n-problem',
          StageGroup.idFor('candidate-a', ResearchStage.researchQuestions),
        ]),
      );
      expect(bloc.state.expandedIds.contains('n-gap'), isFalse);
      expect(bloc.state.layout.nodeById('n-rq'), isNotNull);
      expect(bloc.state.layout.nodeById('n-gap'), isNotNull);
      expect(bloc.state.layout.nodeById('n-relevance'), isNull);
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'expanding a record reveals its actual children',
    build: () => ExplorerBloc(
      catalogue: catalogue,
      initialExpanded: {
        'n-problem',
        StageGroup.idFor('candidate-a', ResearchStage.literatureGaps),
      },
    ),
    act: (bloc) => bloc.add(const NodeToggled('n-gap')),
    verify: (bloc) {
      expect(bloc.state.expandedIds, contains('n-gap'));
      expect(bloc.state.layout.nodeById('n-topic'), isNotNull);
      expect(
        bloc.state.layout.edges.any(
          (edge) =>
              edge.structural &&
              edge.sourceId == 'n-gap' &&
              edge.targetId == 'n-topic',
        ),
        isTrue,
      );
    },
  );

  blocTest<ExplorerBloc, ExplorerState>(
    'filters combine with AND across groups and OR inside a group',
    build: () => ExplorerBloc(
      catalogue: catalogue,
      initialExpanded: {
        'n-problem',
        StageGroup.idFor('candidate-a', ResearchStage.thesisQuestion),
        StageGroup.idFor('candidate-a', ResearchStage.relevance),
        StageGroup.idFor('candidate-a', ResearchStage.expectedOutcomes),
      },
    ),
    act: (bloc) {
      bloc.add(
        const FiltersChanged(
          ExplorerFilters(
            stages: {ResearchStage.thesisQuestion, ResearchStage.relevance},
            evidenceStatuses: {EvidenceStatus.unverified},
            hideNonMatching: true,
          ),
        ),
      );
    },
    verify: (bloc) {
      final ids = bloc.state.layout.nodes.map((node) => node.id).toSet();
      expect(ids, contains('n-question'));
      expect(ids, contains('n-problem'));
      expect(ids, isNot(contains('n-outcome')));
    },
  );

  test('search debounces, groups, and skips superseded nodes', () async {
    final index = SearchIndex(catalogue);
    final cubit = SearchCubit(index, debounce: Duration.zero);
    cubit.queryChanged('outcome');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.hits.map((hit) => hit.nodeId), contains('n-outcome'));
    expect(cubit.state.hits.every((hit) => hit.groupLabel.isNotEmpty), isTrue);

    final hidden = testNode(
      id: 'n-outcome',
      stage: ResearchStage.expectedOutcomes,
      parentId: 'n-question',
      evidenceStatus: EvidenceStatus.superseded,
      title: 'Superseded outcome',
    );
    final withSuperseded = Catalogue(
      schemaVersion: catalogue.schemaVersion,
      title: catalogue.title,
      candidates: catalogue.candidates,
      nodes: {...catalogue.nodes, hidden.id: hidden},
      publications: catalogue.publications,
      evidenceLinks: catalogue.evidenceLinks,
      crossLinks: catalogue.crossLinks,
    );
    final supersededIndex = SearchIndex(withSuperseded);
    expect(supersededIndex.search('Superseded outcome'), isEmpty);
    expect(
      supersededIndex
          .search('Superseded outcome', includeSuperseded: true)
          .map((hit) => hit.nodeId),
      contains('n-outcome'),
    );
    await cubit.close();
  });
}
