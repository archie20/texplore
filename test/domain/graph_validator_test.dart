import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/domain/enums/evidence_status.dart';
import 'package:thesis_topics/domain/enums/relationship_type.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/enums/verification_status.dart';
import 'package:thesis_topics/domain/models/candidate.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/domain/models/evidence_link.dart';
import 'package:thesis_topics/domain/models/publication.dart';
import 'package:thesis_topics/domain/services/graph_queries.dart';
import 'package:thesis_topics/domain/services/graph_validator.dart';

import '../support/catalogue_factory.dart';

void main() {
  const validator = GraphValidator();

  ParsedCatalogue parsedFrom(
    Candidate candidate, {
    List<Publication>? publications,
    String? schema,
  }) {
    return ParsedCatalogue(
      schemaVersion: schema ?? Catalogue.supportedSchemaVersion,
      title: 'Test',
      candidates: [
        ParsedCandidate(candidate: candidate, schemaVersion: schema ?? '1.0.0'),
      ],
      publications: publications ?? [testPublication()],
    );
  }

  Candidate validCandidate() => chainCatalogue().candidates.single;

  test('a valid candidate loads without errors', () {
    final catalogue = chainCatalogue();
    expect(catalogue.excluded, isEmpty);
    expect(catalogue.candidates, hasLength(1));
    expect(catalogue.issues.where((issue) => issue.isError), isEmpty);
  });

  test('duplicate node ids are detected', () {
    final candidate = validCandidate();
    final duplicate = candidate.nodes.first;
    final broken = candidate.copyWith(nodes: [...candidate.nodes, duplicate]);
    final other = Candidate(
      id: 'other',
      title: 'Other',
      shortTitle: 'Other',
      summary: '',
      shortDescription: '',
      priority: CandidatePriority.alternative,
      maturity: CandidateMaturity.exploratory,
      rootNodeId: duplicate.id,
      tags: const [],
      openDecisions: const [],
      readiness: const [],
      nodes: [duplicate],
      crossLinks: const [],
      evidenceLinks: const [],
    );
    final report = validator.validate(
      ParsedCatalogue(
        schemaVersion: '1.0.0',
        title: 'Test',
        candidates: [
          ParsedCandidate(candidate: broken, schemaVersion: '1.0.0'),
          ParsedCandidate(candidate: other, schemaVersion: '1.0.0'),
        ],
        publications: [testPublication()],
      ),
    );
    expect(report.issues.map((issue) => issue.code), contains('duplicate_id'));
    expect(report.invalidCandidateIds, containsAll(['candidate-a', 'other']));
  });

  test('broken parent references are detected', () {
    final node = testNode(
      id: 'orphan',
      stage: ResearchStage.thesisQuestion,
      parentId: 'missing',
    );
    final root = testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: const [],
    );
    final candidate = Candidate(
      id: validCandidate().id,
      title: validCandidate().title,
      shortTitle: validCandidate().shortTitle,
      summary: '',
      shortDescription: '',
      priority: CandidatePriority.primary,
      maturity: CandidateMaturity.promising,
      rootNodeId: 'root',
      tags: const [],
      openDecisions: const [],
      readiness: const [],
      nodes: [root, node],
      crossLinks: const [],
      evidenceLinks: const [],
    );
    final report = validator.validate(parsedFrom(candidate));
    expect(report.issues.map((issue) => issue.code), contains('broken_parent'));
  });

  test('non-reciprocal parent and child links are detected', () {
    final root = testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: const ['child'],
    );
    final child = testNode(
      id: 'child',
      stage: ResearchStage.thesisQuestion,
      parentId: null,
    );
    final candidate = validCandidate().copyWith(
      nodes: [root, child],
      evidenceLinks: const [],
    );
    final report = validator.validate(parsedFrom(candidate));
    expect(
      report.issues.map((issue) => issue.code),
      contains('not_reciprocal'),
    );
  });

  test('cycles are rejected', () {
    final a = testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: const ['loop'],
    );
    final b = testNode(
      id: 'loop',
      stage: ResearchStage.thesisProblem,
      parentId: 'root',
      childIds: const ['root'],
    );
    final candidate = validCandidate().copyWith(
      nodes: [a, b],
      evidenceLinks: const [],
    );
    final report = validator.validate(parsedFrom(candidate));
    expect(report.issues.map((issue) => issue.code), contains('cycle'));
  });

  test('a literature gap without evidence is flagged unless marked unconfirmed-style', () {
    final catalogue = chainCatalogue(
      evidenceLinks: const [],
      gapStatus: EvidenceStatus.unverified,
    );
    expect(catalogue.excluded, isNotEmpty);
    expect(
      catalogue.issues.map((issue) => issue.code),
      contains('gap_without_evidence'),
    );

    final allowed = chainCatalogue(
      evidenceLinks: const [],
      gapStatus: EvidenceStatus.hypothesis,
    );
    expect(allowed.excluded, isEmpty);
  });

  test('a potential topic without a gap is flagged unless exploratory', () {
    final root = testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: const ['topic'],
    );
    final topic = testNode(
      id: 'topic',
      stage: ResearchStage.potentialTopics,
      parentId: 'root',
    );
    final candidate = validCandidate().copyWith(
      nodes: [root, topic],
      evidenceLinks: const [],
    );
    final report = validator.validate(parsedFrom(candidate));
    expect(
      report.issues.map((issue) => issue.code),
      contains('topic_without_gap'),
    );
  });

  test('a publication can support more than one node', () {
    final catalogue = chainCatalogue(
      evidenceLinks: [
        EvidenceLink(
          id: 'e1',
          nodeId: 'n-gap',
          publicationId: 'pub-1',
          relationship: EvidenceRelationship.supportsContext,
          claim: 'First claim',
          evidenceStrength: EvidenceStrength.contextual,
          verificationStatus: VerificationStatus.unverified,
        ),
        EvidenceLink(
          id: 'e2',
          nodeId: 'n-status',
          publicationId: 'pub-1',
          relationship: EvidenceRelationship.supports,
          claim: 'Second claim',
          evidenceStrength: EvidenceStrength.direct,
          verificationStatus: VerificationStatus.unverified,
        ),
      ],
    );
    expect(catalogue.excluded, isEmpty);
    expect(catalogue.evidenceLinks, hasLength(2));
  });

  test('cross-links do not create hierarchy cycles', () {
    final base = validCandidate();
    final candidate = base.copyWith(
      crossLinks: [
        const GraphEdge(
          id: 'cross-1',
          sourceNodeId: 'n-rq',
          targetNodeId: 'n-problem',
          relationshipType: CrossLinkType.relatedTo,
        ),
      ],
    );
    final report = validator.validate(parsedFrom(candidate));
    expect(report.issues.where((issue) => issue.code == 'cycle'), isEmpty);
    expect(report.invalidCandidateIds, isEmpty);
  });

  test('invalid stage skips are rejected and allowed skips are kept', () {
    final skip = validCandidate();
    final report = validator.validate(parsedFrom(skip));
    expect(
      report.issues.where((issue) => issue.code == 'stage_order'),
      isEmpty,
    );

    final root = testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: const ['gap'],
    );
    final gap = testNode(
      id: 'gap',
      stage: ResearchStage.literatureGaps,
      parentId: 'root',
      evidenceStatus: EvidenceStatus.hypothesis,
    );
    final bad = validCandidate().copyWith(
      nodes: [root, gap],
      evidenceLinks: const [],
    );
    final badReport = validator.validate(parsedFrom(bad));
    expect(
      badReport.issues.map((issue) => issue.code),
      contains('stage_order'),
    );
  });

  test('a bad DOI or URL is reported', () {
    final report = validator.validate(
      parsedFrom(
        validCandidate(),
        publications: [
          testPublication(doi: 'not-a-doi', url: 'ftp://example.com/file'),
        ],
      ),
    );
    expect(
      report.issues.map((issue) => issue.code),
      containsAll(['bad_doi', 'bad_url']),
    );
  });

  test('an unsupported schema version is fatal', () {
    final report = validator.validate(
      parsedFrom(validCandidate(), schema: '2.0.0'),
    );
    expect(report.fatal, isTrue);
    expect(report.fatalMessage, contains('2.0.0'));
  });

  test('path to root and descendants follow the hierarchy only', () {
    final catalogue = chainCatalogue();
    final path = GraphQueries.pathToRoot(
      catalogue,
      'n-rq',
    ).map((node) => node.id);
    expect(path, [
      'n-problem',
      'n-question',
      'n-area',
      'n-status',
      'n-gap',
      'n-topic',
      'n-rq',
    ]);
    expect(
      GraphQueries.descendantIds(catalogue, 'n-area'),
      containsAll(['n-status', 'n-gap', 'n-rq']),
    );
  });
}
