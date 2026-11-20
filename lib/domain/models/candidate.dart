import 'package:equatable/equatable.dart';

import '../../core/utils/json_readers.dart';
import '../enums/relationship_type.dart';
import 'evidence_link.dart';
import 'research_node.dart';

class Feasibility extends Equatable {
  const Feasibility({required this.rating, required this.rationale});

  /// A planning label such as low, medium, or high. Not a measured score.
  final String rating;
  final String rationale;

  factory Feasibility.fromJson(Map<String, Object?> json, String path) {
    return Feasibility(
      rating: JsonReaders.string(json, 'rating', path),
      rationale: JsonReaders.string(json, 'rationale', path),
    );
  }

  @override
  List<Object?> get props => [rating, rationale];
}

class ReadinessCheck extends Equatable {
  const ReadinessCheck({
    required this.id,
    required this.label,
    required this.met,
    required this.note,
  });

  final String id;
  final String label;
  final bool met;
  final String note;

  factory ReadinessCheck.fromJson(Map<String, Object?> json, String path) {
    return ReadinessCheck(
      id: JsonReaders.string(json, 'id', path),
      label: JsonReaders.string(json, 'label', path),
      met: JsonReaders.optionalBool(json, 'met', path),
      note: JsonReaders.optionalString(json, 'note', path) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, label, met, note];
}

class Candidate extends Equatable {
  const Candidate({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.shortDescription,
    required this.priority,
    required this.maturity,
    required this.rootNodeId,
    required this.tags,
    required this.openDecisions,
    required this.readiness,
    required this.nodes,
    required this.crossLinks,
    required this.evidenceLinks,
    this.workingTitle,
    this.ghanaianRelevance,
    this.technicalContribution,
    this.feasibility,
    this.dataRequirements,
    this.evaluationDesign,
    this.majorRisks = const [],
    this.lastReviewed,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String? workingTitle;
  final String summary;
  final String shortDescription;
  final CandidatePriority priority;
  final CandidateMaturity maturity;
  final String? ghanaianRelevance;
  final String? technicalContribution;
  final Feasibility? feasibility;
  final String? dataRequirements;
  final String? evaluationDesign;
  final List<String> majorRisks;
  final String rootNodeId;
  final List<String> tags;
  final List<String> openDecisions;
  final List<ReadinessCheck> readiness;
  final String? lastReviewed;
  final List<ResearchNode> nodes;
  final List<GraphEdge> crossLinks;
  final List<EvidenceLink> evidenceLinks;

  ResearchNode? get root {
    for (final node in nodes) {
      if (node.id == rootNodeId) return node;
    }
    return null;
  }

  factory Candidate.fromJson(Map<String, Object?> json, String path) {
    final priority = CandidatePriority.parse(
      JsonReaders.optionalString(json, 'priority', path),
    );
    if (priority == null) {
      throw FormatException('Unknown or missing priority at $path.priority.');
    }
    final maturity = CandidateMaturity.parse(
      JsonReaders.optionalString(json, 'status', path),
    );
    if (maturity == null) {
      throw FormatException('Unknown or missing status at $path.status.');
    }
    Feasibility? feasibility;
    final feasibilityJson = json['feasibility'];
    if (feasibilityJson != null) {
      feasibility = Feasibility.fromJson(
        JsonReaders.map(feasibilityJson, '$path.feasibility'),
        '$path.feasibility',
      );
    }
    final readiness = <ReadinessCheck>[];
    final readinessJson = json['readiness'];
    if (readinessJson != null) {
      final items = JsonReaders.list(readinessJson, '$path.readiness');
      for (var i = 0; i < items.length; i++) {
        readiness.add(
          ReadinessCheck.fromJson(
            JsonReaders.map(items[i], '$path.readiness[$i]'),
            '$path.readiness[$i]',
          ),
        );
      }
    }
    return Candidate(
      id: JsonReaders.string(json, 'id', path),
      title: JsonReaders.string(json, 'title', path),
      shortTitle: JsonReaders.string(json, 'shortTitle', path),
      workingTitle: JsonReaders.optionalString(json, 'workingTitle', path),
      summary: JsonReaders.optionalString(json, 'summary', path) ?? '',
      shortDescription:
          JsonReaders.optionalString(json, 'shortDescription', path) ?? '',
      priority: priority,
      maturity: maturity,
      ghanaianRelevance: JsonReaders.optionalString(
        json,
        'ghanaianRelevance',
        path,
      ),
      technicalContribution: JsonReaders.optionalString(
        json,
        'technicalContribution',
        path,
      ),
      feasibility: feasibility,
      dataRequirements: JsonReaders.optionalString(
        json,
        'dataRequirements',
        path,
      ),
      evaluationDesign: JsonReaders.optionalString(
        json,
        'evaluationDesign',
        path,
      ),
      majorRisks: JsonReaders.stringList(json, 'majorRisks', path),
      rootNodeId: JsonReaders.string(json, 'rootNodeId', path),
      tags: JsonReaders.stringList(json, 'tags', path),
      openDecisions: JsonReaders.stringList(json, 'openDecisions', path),
      readiness: readiness,
      lastReviewed: JsonReaders.optionalString(json, 'lastReviewed', path),
      nodes: const [],
      crossLinks: const [],
      evidenceLinks: const [],
    );
  }

  Candidate copyWith({
    List<ResearchNode>? nodes,
    List<GraphEdge>? crossLinks,
    List<EvidenceLink>? evidenceLinks,
  }) {
    return Candidate(
      id: id,
      title: title,
      shortTitle: shortTitle,
      workingTitle: workingTitle,
      summary: summary,
      shortDescription: shortDescription,
      priority: priority,
      maturity: maturity,
      ghanaianRelevance: ghanaianRelevance,
      technicalContribution: technicalContribution,
      feasibility: feasibility,
      dataRequirements: dataRequirements,
      evaluationDesign: evaluationDesign,
      majorRisks: majorRisks,
      rootNodeId: rootNodeId,
      tags: tags,
      openDecisions: openDecisions,
      readiness: readiness,
      lastReviewed: lastReviewed,
      nodes: nodes ?? this.nodes,
      crossLinks: crossLinks ?? this.crossLinks,
      evidenceLinks: evidenceLinks ?? this.evidenceLinks,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    shortTitle,
    workingTitle,
    summary,
    shortDescription,
    priority,
    maturity,
    ghanaianRelevance,
    technicalContribution,
    feasibility,
    dataRequirements,
    evaluationDesign,
    majorRisks,
    rootNodeId,
    tags,
    openDecisions,
    readiness,
    lastReviewed,
    nodes,
    crossLinks,
    evidenceLinks,
  ];
}
