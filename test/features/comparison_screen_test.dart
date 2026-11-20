import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:thesis_topics/app/theme/app_theme.dart';
import 'package:thesis_topics/data/catalogue_repository.dart';
import 'package:thesis_topics/domain/enums/relationship_type.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/models/candidate.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/features/comparison/comparison_cubit.dart';
import 'package:thesis_topics/features/comparison/comparison_screen.dart';
import 'package:thesis_topics/features/explorer/application/catalogue_cubit.dart';

import '../support/catalogue_factory.dart';

class _SeededCatalogueCubit extends CatalogueCubit {
  _SeededCatalogueCubit(Catalogue catalogue) : super(CatalogueRepository()) {
    emit(CatalogueLoaded(catalogue));
  }
}

void main() {
  testWidgets('comparison labels missing fields and does not rank candidates', (
    tester,
  ) async {
    final catalogue = _catalogue();
    final router = GoRouter(
      initialLocation: '/compare?ids=a,b',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => ComparisonScreen(
            initialIds: state.uri.queryParameters['ids'] ?? '',
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CatalogueCubit>(
            create: (_) => _SeededCatalogueCubit(catalogue),
          ),
          BlocProvider(create: (_) => ComparisonCubit()),
        ],
        child: FTheme(
          data: notebookTheme(Brightness.light),
          child: NotebookScope(
            colors: NotebookColors.light,
            child: WidgetsApp.router(
              color: const Color(0xFF2B4C7E),
              routerConfig: router,
              localizationsDelegates: FLocalizations.localizationsDelegates,
              supportedLocales: FLocalizations.supportedLocales,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Not specified'), findsWidgets);
    expect(find.text('A labelled dataset'), findsOneWidget);
    expect(
      find.textContaining('nothing here is a score or a ranking'),
      findsOneWidget,
    );
    expect(find.textContaining('Planning assessment'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Catalogue _catalogue() {
  Candidate make(String id, {String? data}) {
    final root = testNode(
      id: '$id-root',
      candidateId: id,
      stage: ResearchStage.thesisProblem,
      title: 'Problem $id',
    );
    return Candidate(
      id: id,
      title: 'Candidate $id',
      shortTitle: 'Candidate $id',
      summary: 'A bounded problem.',
      shortDescription: 'Short description.',
      priority: CandidatePriority.primary,
      maturity: CandidateMaturity.promising,
      rootNodeId: root.id,
      tags: const [],
      openDecisions: const [],
      readiness: const [],
      nodes: [root],
      crossLinks: const [],
      evidenceLinks: const [],
      dataRequirements: data,
      feasibility: const Feasibility(
        rating: 'medium',
        rationale: 'A planning note.',
      ),
    );
  }

  final a = make('a');
  final b = make('b', data: 'A labelled dataset');
  return Catalogue(
    schemaVersion: Catalogue.supportedSchemaVersion,
    title: 'Comparison fixture',
    candidates: [a, b],
    nodes: {
      for (final candidate in [a, b])
        for (final node in candidate.nodes) node.id: node,
    },
    publications: const {},
    evidenceLinks: const {},
    crossLinks: const [],
  );
}
