import 'package:equatable/equatable.dart';

import '../enums/relationship_type.dart';
import 'candidate.dart';
import 'evidence_link.dart';
import 'publication.dart';
import 'research_node.dart';

enum IssueSeverity { error, warning }

class ValidationIssue extends Equatable {
  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.candidateId,
    this.nodeId,
    this.publicationId,
    this.evidenceLinkId,
  });

  final IssueSeverity severity;
  final String code;
  final String message;
  final String? candidateId;
  final String? nodeId;
  final String? publicationId;
  final String? evidenceLinkId;

  bool get isError => severity == IssueSeverity.error;

  @override
  List<Object?> get props => [
    severity,
    code,
    message,
    candidateId,
    nodeId,
    publicationId,
    evidenceLinkId,
  ];
}

class ExcludedCandidate extends Equatable {
  const ExcludedCandidate({
    required this.id,
    required this.title,
    required this.issues,
  });

  final String id;
  final String title;
  final List<ValidationIssue> issues;

  @override
  List<Object?> get props => [id, title, issues];
}

class Catalogue extends Equatable {
  const Catalogue({
    required this.schemaVersion,
    required this.title,
    required this.candidates,
    required this.nodes,
    required this.publications,
    required this.evidenceLinks,
    required this.crossLinks,
    this.lastReviewed,
    this.issues = const [],
    this.excluded = const [],
  });

  static const supportedSchemaVersion = '1.0.0';

  final String schemaVersion;
  final String title;
  final String? lastReviewed;
  final List<Candidate> candidates;
  final Map<String, ResearchNode> nodes;
  final Map<String, Publication> publications;
  final Map<String, EvidenceLink> evidenceLinks;
  final List<GraphEdge> crossLinks;
  final List<ValidationIssue> issues;
  final List<ExcludedCandidate> excluded;

  List<ValidationIssue> get warnings => [
    for (final issue in issues)
      if (!issue.isError) issue,
  ];

  Candidate? candidateById(String id) {
    for (final candidate in candidates) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  List<EvidenceLink> evidenceForNode(String nodeId) {
    return [
      for (final link in evidenceLinks.values)
        if (link.nodeId == nodeId) link,
    ];
  }

  List<Candidate> get primaryCandidates => [
    for (final candidate in candidates)
      if (candidate.priority == CandidatePriority.primary) candidate,
  ];

  List<Candidate> get alternativeCandidates => [
    for (final candidate in candidates)
      if (candidate.priority != CandidatePriority.primary) candidate,
  ];

  @override
  List<Object?> get props => [
    schemaVersion,
    title,
    lastReviewed,
    candidates,
    nodes,
    publications,
    evidenceLinks,
    crossLinks,
    issues,
    excluded,
  ];
}

/// A candidate file after parsing, before validation decides whether it renders.
class ParsedCandidate {
  const ParsedCandidate({
    required this.candidate,
    required this.schemaVersion,
    this.source,
  });

  final Candidate candidate;
  final String? schemaVersion;
  final String? source;
}

/// A publication JSON file after decoding, before its records are accepted.
class ParsedPublicationFile {
  const ParsedPublicationFile({
    required this.source,
    required this.schemaVersion,
    required this.publications,
  });

  final String source;
  final String? schemaVersion;
  final List<Publication> publications;
}

class ParsedCatalogue {
  const ParsedCatalogue({
    required this.schemaVersion,
    required this.title,
    required this.candidates,
    required this.publications,
    this.publicationFiles = const [],
    this.lastReviewed,
    this.parseIssues = const [],
  });

  final String? schemaVersion;
  final String title;
  final String? lastReviewed;
  final List<ParsedCandidate> candidates;
  final List<Publication> publications;
  final List<ParsedPublicationFile> publicationFiles;
  final List<ValidationIssue> parseIssues;
}
