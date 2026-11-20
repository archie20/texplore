import 'package:thesis_topics/domain/enums/evidence_status.dart';
import 'package:thesis_topics/domain/enums/relationship_type.dart';
import 'package:thesis_topics/domain/enums/research_stage.dart';
import 'package:thesis_topics/domain/enums/verification_status.dart';
import 'package:thesis_topics/domain/models/candidate.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/domain/models/evidence_link.dart';
import 'package:thesis_topics/domain/models/publication.dart';
import 'package:thesis_topics/domain/models/research_node.dart';
import 'package:thesis_topics/domain/services/graph_validator.dart';

Publication testPublication({
  String id = 'pub-1',
  String title = 'Example study',
  String? doi = '10.1000/example',
  String? url = 'https://example.org/paper',
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  int? year = 2024,
  List<String> authors = const ['Author, A.'],
}) {
  return Publication(
    id: id,
    title: title,
    authors: authors,
    year: year,
    doi: doi,
    url: url,
    publicationType: PublicationType.journalArticle,
    verificationStatus: verificationStatus,
    venue: 'Example venue',
  );
}

ResearchNode testNode({
  required String id,
  String candidateId = 'candidate-a',
  required ResearchStage stage,
  String? parentId,
  List<String> childIds = const [],
  int sortOrder = 0,
  EvidenceStatus evidenceStatus = EvidenceStatus.unverified,
  String? title,
  List<String> tags = const [],
}) {
  return ResearchNode(
    id: id,
    candidateId: candidateId,
    stage: stage,
    title: title ?? id,
    summary: 'Summary of $id',
    detail: 'Detail of $id',
    parentId: parentId,
    childIds: childIds,
    evidenceStatus: evidenceStatus,
    evidenceLinkIds: const [],
    relatedNodeIds: const [],
    tags: tags,
    sortOrder: sortOrder,
    notes: const [],
    assumptions: const [],
    risks: const [],
    validationRequirements: const [],
    gapStrength: stage == ResearchStage.literatureGaps
        ? GapStrength.unconfirmed
        : null,
  );
}

/// A valid nine-stage chain: problem, question, relevance, outcome, area,
/// status quo, gap, topic, research question.
Catalogue chainCatalogue({
  String candidateId = 'candidate-a',
  String prefix = 'n',
  CandidatePriority priority = CandidatePriority.primary,
  List<Publication> publications = const [],
  List<EvidenceLink>? evidenceLinks,
  EvidenceStatus gapStatus = EvidenceStatus.unverified,
}) {
  final nodes = [
    testNode(
      id: '$prefix-problem',
      candidateId: candidateId,
      stage: ResearchStage.thesisProblem,
      childIds: ['$prefix-question'],
    ),
    testNode(
      id: '$prefix-question',
      candidateId: candidateId,
      stage: ResearchStage.thesisQuestion,
      parentId: '$prefix-problem',
      childIds: ['$prefix-relevance', '$prefix-outcome', '$prefix-area'],
    ),
    testNode(
      id: '$prefix-relevance',
      candidateId: candidateId,
      stage: ResearchStage.relevance,
      parentId: '$prefix-question',
      sortOrder: 0,
    ),
    testNode(
      id: '$prefix-outcome',
      candidateId: candidateId,
      stage: ResearchStage.expectedOutcomes,
      parentId: '$prefix-question',
      sortOrder: 1,
      title: 'An outcome',
    ),
    testNode(
      id: '$prefix-area',
      candidateId: candidateId,
      stage: ResearchStage.thesisAreas,
      parentId: '$prefix-question',
      childIds: ['$prefix-status'],
      sortOrder: 2,
    ),
    testNode(
      id: '$prefix-status',
      candidateId: candidateId,
      stage: ResearchStage.currentStatusQuo,
      parentId: '$prefix-area',
      childIds: ['$prefix-gap'],
    ),
    testNode(
      id: '$prefix-gap',
      candidateId: candidateId,
      stage: ResearchStage.literatureGaps,
      parentId: '$prefix-status',
      childIds: ['$prefix-topic'],
      evidenceStatus: gapStatus,
      title: 'A possible gap',
    ),
    testNode(
      id: '$prefix-topic',
      candidateId: candidateId,
      stage: ResearchStage.potentialTopics,
      parentId: '$prefix-gap',
      childIds: ['$prefix-rq'],
    ),
    testNode(
      id: '$prefix-rq',
      candidateId: candidateId,
      stage: ResearchStage.researchQuestions,
      parentId: '$prefix-topic',
      title: 'What would show the gap has been addressed?',
    ),
  ];
  final links =
      evidenceLinks ??
      [
        EvidenceLink(
          id: '$prefix-evidence',
          nodeId: '$prefix-gap',
          publicationId:
              (publications.isEmpty ? testPublication() : publications.first)
                  .id,
          relationship: EvidenceRelationship.supportsContext,
          claim: 'The source describes a related method.',
          evidenceStrength: EvidenceStrength.indirect,
          verificationStatus: VerificationStatus.unverified,
        ),
      ];
  final pubs = publications.isEmpty ? [testPublication()] : publications;
  final candidate = Candidate(
    id: candidateId,
    title: 'Candidate A',
    shortTitle: 'Candidate A',
    summary: 'A bounded problem.',
    shortDescription: 'Short description.',
    priority: priority,
    maturity: CandidateMaturity.promising,
    rootNodeId: '$prefix-problem',
    tags: const ['test'],
    openDecisions: const ['Choose a scope.'],
    readiness: const [],
    nodes: nodes,
    crossLinks: const [],
    evidenceLinks: links,
    technicalContribution: 'A measurable evaluation method.',
    ghanaianRelevance: 'Relevant to a Ghanaian setting.',
  );
  final parsed = ParsedCatalogue(
    schemaVersion: Catalogue.supportedSchemaVersion,
    title: 'Test catalogue',
    candidates: [ParsedCandidate(candidate: candidate, schemaVersion: '1.0.0')],
    publications: pubs,
  );
  final validator = const GraphValidator();
  final report = validator.validate(parsed);
  return validator.assemble(parsed, report);
}

Catalogue syntheticCatalogue(int nodeCount) {
  final areas = ((nodeCount - 2) / 5).ceil().clamp(1, 100000);
  final nodes = <ResearchNode>[
    testNode(
      id: 'root',
      stage: ResearchStage.thesisProblem,
      childIds: ['question'],
    ),
    testNode(
      id: 'question',
      stage: ResearchStage.thesisQuestion,
      parentId: 'root',
      childIds: [for (var i = 0; i < areas; i++) 'area-$i'],
    ),
  ];
  for (var i = 0; i < areas; i++) {
    nodes.addAll([
      testNode(
        id: 'area-$i',
        stage: ResearchStage.thesisAreas,
        parentId: 'question',
        childIds: ['status-$i'],
        sortOrder: i,
      ),
      testNode(
        id: 'status-$i',
        stage: ResearchStage.currentStatusQuo,
        parentId: 'area-$i',
        childIds: ['gap-$i'],
      ),
      testNode(
        id: 'gap-$i',
        stage: ResearchStage.literatureGaps,
        parentId: 'status-$i',
        childIds: ['topic-$i'],
        evidenceStatus: EvidenceStatus.hypothesis,
      ),
      testNode(
        id: 'topic-$i',
        stage: ResearchStage.potentialTopics,
        parentId: 'gap-$i',
        childIds: ['rq-$i'],
        tags: const ['exploratory'],
      ),
      testNode(
        id: 'rq-$i',
        stage: ResearchStage.researchQuestions,
        parentId: 'topic-$i',
      ),
    ]);
  }
  final candidate = Candidate(
    id: 'synthetic',
    title: 'Synthetic',
    shortTitle: 'Synthetic',
    summary: 'Generated for layout tests.',
    shortDescription: 'Generated.',
    priority: CandidatePriority.primary,
    maturity: CandidateMaturity.exploratory,
    rootNodeId: 'root',
    tags: const [],
    openDecisions: const [],
    readiness: const [],
    nodes: nodes,
    crossLinks: const [],
    evidenceLinks: const [],
  );
  return Catalogue(
    schemaVersion: Catalogue.supportedSchemaVersion,
    title: 'Synthetic',
    candidates: [candidate],
    nodes: {for (final node in nodes) node.id: node},
    publications: const {},
    evidenceLinks: const {},
    crossLinks: const [],
  );
}
