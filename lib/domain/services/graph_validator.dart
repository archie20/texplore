import '../enums/evidence_status.dart';
import '../enums/research_stage.dart';
import '../enums/verification_status.dart';
import '../models/catalogue.dart';
import '../models/candidate.dart';
import '../models/evidence_link.dart';
import '../models/publication.dart';
import '../models/research_node.dart';
import 'schema_version.dart';

class ValidationReport {
  const ValidationReport({
    required this.fatal,
    required this.issues,
    required this.invalidCandidateIds,
    this.fatalMessage,
  });

  final bool fatal;
  final String? fatalMessage;
  final List<ValidationIssue> issues;
  final Set<String> invalidCandidateIds;
}

class GraphValidator {
  const GraphValidator();

  static final doiPattern = RegExp(r'^10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$');

  ValidationReport validate(ParsedCatalogue parsed) {
    final issues = <ValidationIssue>[...parsed.parseIssues];
    final schemaFailure = _schemaFailures(parsed);
    if (schemaFailure != null) {
      return ValidationReport(
        fatal: true,
        fatalMessage: schemaFailure.message,
        issues: [
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'schema_version',
            message: schemaFailure.message,
            candidateId: schemaFailure.candidateId,
          ),
          ...issues,
        ],
        invalidCandidateIds: {
          for (final item in parsed.candidates) item.candidate.id,
        },
      );
    }

    final invalid = <String>{};
    final publicationIds = <String>{};
    final publications = <String, Publication>{};
    for (final publication in parsed.publications) {
      if (!publicationIds.add(publication.id)) {
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'duplicate_id',
            message: 'Duplicate publication id "${publication.id}".',
            publicationId: publication.id,
          ),
        );
        continue;
      }
      publications[publication.id] = publication;
      _checkPublication(publication, issues);
    }

    final nodeOwners = <String, String>{};
    final nodes = <String, ResearchNode>{};
    for (final parsedCandidate in parsed.candidates) {
      final candidate = parsedCandidate.candidate;
      for (final node in candidate.nodes) {
        if (nodes.containsKey(node.id)) {
          invalid.add(candidate.id);
          invalid.add(nodeOwners[node.id] ?? candidate.id);
          issues.add(
            ValidationIssue(
              severity: IssueSeverity.error,
              code: 'duplicate_id',
              message: 'Duplicate node id "${node.id}".',
              candidateId: candidate.id,
              nodeId: node.id,
            ),
          );
        } else {
          nodes[node.id] = node;
          nodeOwners[node.id] = candidate.id;
        }
      }
    }

    final seenCandidates = <String>{};
    for (final parsedCandidate in parsed.candidates) {
      final candidate = parsedCandidate.candidate;
      if (!seenCandidates.add(candidate.id)) {
        invalid.add(candidate.id);
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'duplicate_id',
            message: 'Duplicate candidate id "${candidate.id}".',
            candidateId: candidate.id,
          ),
        );
        continue;
      }
      _validateCandidate(
        candidate: candidate,
        nodes: nodes,
        publications: publications,
        issues: issues,
        invalid: invalid,
      );
    }

    final linkIds = <String>{};
    for (final parsedCandidate in parsed.candidates) {
      for (final link in parsedCandidate.candidate.evidenceLinks) {
        if (!linkIds.add(link.id)) {
          issues.add(
            ValidationIssue(
              severity: IssueSeverity.error,
              code: 'duplicate_id',
              message: 'Duplicate evidence link id "${link.id}".',
              evidenceLinkId: link.id,
              candidateId: parsedCandidate.candidate.id,
            ),
          );
          invalid.add(parsedCandidate.candidate.id);
        }
      }
    }

    return ValidationReport(
      fatal: false,
      issues: issues,
      invalidCandidateIds: invalid,
    );
  }

  _SchemaFailure? _schemaFailures(ParsedCatalogue parsed) {
    final manifestError = SchemaVersion.mismatchMessage(
      parsed.schemaVersion,
      path: 'assets/data/manifest.json',
    );
    if (manifestError != null) {
      return _SchemaFailure(manifestError);
    }

    for (final file in parsed.publicationFiles) {
      final error = SchemaVersion.mismatchMessage(
        file.schemaVersion,
        path: file.source,
      );
      if (error != null) return _SchemaFailure(error);
    }

    // When publicationFiles is empty (unit tests that pass publications
    // directly), skip per-file checks and rely on candidate/manifest only.
    for (final parsedCandidate in parsed.candidates) {
      final path = parsedCandidate.source ??
          'candidate:${parsedCandidate.candidate.id}';
      final error = SchemaVersion.mismatchMessage(
        parsedCandidate.schemaVersion,
        path: path,
      );
      if (error != null) {
        return _SchemaFailure(error, candidateId: parsedCandidate.candidate.id);
      }
    }
    return null;
  }

  Catalogue assemble(ParsedCatalogue parsed, ValidationReport report) {
    final invalid = report.invalidCandidateIds;
    final candidates = <Candidate>[];
    final nodes = <String, ResearchNode>{};
    final links = <String, EvidenceLink>{};
    final edges = <GraphEdge>[];
    final excluded = <ExcludedCandidate>[];

    for (final parsedCandidate in parsed.candidates) {
      final candidate = parsedCandidate.candidate;
      final candidateIssues = [
        for (final issue in report.issues)
          if (issue.candidateId == candidate.id) issue,
      ];
      if (invalid.contains(candidate.id)) {
        excluded.add(
          ExcludedCandidate(
            id: candidate.id,
            title: candidate.title,
            issues: candidateIssues.where((issue) => issue.isError).toList(),
          ),
        );
        continue;
      }
      candidates.add(candidate);
      for (final node in candidate.nodes) {
        nodes[node.id] = node;
      }
      for (final link in candidate.evidenceLinks) {
        links[link.id] = link;
      }
      edges.addAll(candidate.crossLinks);
    }

    final publications = <String, Publication>{};
    final seen = <String>{};
    for (final publication in parsed.publications) {
      if (seen.add(publication.id)) publications[publication.id] = publication;
    }

    return Catalogue(
      schemaVersion: parsed.schemaVersion ?? '',
      title: parsed.title,
      lastReviewed: parsed.lastReviewed,
      candidates: candidates,
      nodes: nodes,
      publications: publications,
      evidenceLinks: links,
      crossLinks: edges,
      issues: report.issues,
      excluded: excluded,
    );
  }

  void _validateCandidate({
    required Candidate candidate,
    required Map<String, ResearchNode> nodes,
    required Map<String, Publication> publications,
    required List<ValidationIssue> issues,
    required Set<String> invalid,
  }) {
    final own = candidate.nodes;
    final byId = {for (final node in own) node.id: node};
    var failed = false;

    void error(String code, String message, {String? nodeId, String? linkId}) {
      failed = true;
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          code: code,
          message: message,
          candidateId: candidate.id,
          nodeId: nodeId,
          evidenceLinkId: linkId,
        ),
      );
    }

    void warn(String code, String message, {String? nodeId}) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.warning,
          code: code,
          message: message,
          candidateId: candidate.id,
          nodeId: nodeId,
        ),
      );
    }

    final roots = own.where((node) => node.parentId == null).toList();
    if (roots.length != 1 || roots.single.id != candidate.rootNodeId) {
      error(
        'root',
        'Candidate "${candidate.id}" must have exactly one root, '
            'and rootNodeId must point at it.',
      );
    } else if (roots.single.stage != ResearchStage.thesisProblem) {
      error(
        'root_stage',
        'Root "${roots.single.id}" must use stage thesis_problem.',
        nodeId: roots.single.id,
      );
    }

    for (final node in own) {
      if (node.candidateId != candidate.id) {
        error(
          'candidate_mismatch',
          'Node "${node.id}" belongs to "${node.candidateId}", not "${candidate.id}".',
          nodeId: node.id,
        );
      }
      if (node.summary.isEmpty) {
        warn(
          'empty_summary',
          'Node "${node.id}" has an empty summary.',
          nodeId: node.id,
        );
      }
      if (node.stage == ResearchStage.literatureGaps &&
          node.gapStrength == null) {
        warn(
          'gap_strength',
          'Gap "${node.id}" has no gapStrength label.',
          nodeId: node.id,
        );
      }
      if (node.parentId != null) {
        final parent = byId[node.parentId!];
        if (parent == null) {
          error(
            'broken_parent',
            'Node "${node.id}" parent "${node.parentId}" does not exist in this candidate.',
            nodeId: node.id,
          );
        } else {
          if (!parent.childIds.contains(node.id)) {
            error(
              'not_reciprocal',
              'Node "${node.id}" names parent "${parent.id}", but that parent does not list it as a child.',
              nodeId: node.id,
            );
          }
          if (!parent.stage.canParent(node.stage)) {
            error(
              'stage_order',
              'Edge ${parent.stage.wire} -> ${node.stage.wire} on "${node.id}" skips or reverses the research sequence.',
              nodeId: node.id,
            );
          }
        }
      }
      for (final childId in node.childIds) {
        final child = byId[childId];
        if (child == null) {
          error(
            'broken_child',
            'Node "${node.id}" lists missing child "$childId".',
            nodeId: node.id,
          );
        } else if (child.parentId != node.id) {
          error(
            'not_reciprocal',
            'Node "${node.id}" lists child "$childId", but that child has a different parent.',
            nodeId: node.id,
          );
        }
      }
      if (node.childIds.toSet().length != node.childIds.length) {
        error(
          'duplicate_child',
          'Node "${node.id}" lists a child more than once.',
          nodeId: node.id,
        );
      }
    }

    if (_hasCycle(own)) {
      error('cycle', 'Candidate "${candidate.id}" hierarchy contains a cycle.');
    }

    final linksByNode = <String, List<EvidenceLink>>{};
    for (final link in candidate.evidenceLinks) {
      final node = nodes[link.nodeId];
      if (node == null || node.candidateId != candidate.id) {
        error(
          'dangling_evidence',
          'Evidence link "${link.id}" points at missing node "${link.nodeId}".',
          linkId: link.id,
        );
      } else {
        linksByNode.putIfAbsent(link.nodeId, () => []).add(link);
      }
      if (!publications.containsKey(link.publicationId)) {
        error(
          'dangling_evidence',
          'Evidence link "${link.id}" points at missing publication "${link.publicationId}".',
          linkId: link.id,
          nodeId: link.nodeId,
        );
      }
      if (link.verificationStatus == VerificationStatus.verifiedFullText &&
          (link.notes == null || link.notes!.trim().isEmpty)) {
        error(
          'verified_without_note',
          'Evidence link "${link.id}" is marked verified but has no verification note.',
          linkId: link.id,
          nodeId: link.nodeId,
        );
      }
    }

    for (final node in own) {
      if (node.stage == ResearchStage.literatureGaps) {
        final links = linksByNode[node.id] ?? const <EvidenceLink>[];
        final allowedWithoutLink =
            node.evidenceStatus == EvidenceStatus.needsLiterature ||
            node.evidenceStatus == EvidenceStatus.hypothesis;
        if (links.isEmpty && !allowedWithoutLink) {
          error(
            'gap_without_evidence',
            'Gap "${node.id}" needs an evidence link, or evidenceStatus needs_literature or hypothesis.',
            nodeId: node.id,
          );
        }
      }
      if (node.stage == ResearchStage.potentialTopics &&
          !_hasAncestorStage(node, byId, ResearchStage.literatureGaps) &&
          !node.exploratory) {
        error(
          'topic_without_gap',
          'Topic "${node.id}" is not connected to a literature gap and is not marked exploratory.',
          nodeId: node.id,
        );
      }
      if (node.stage == ResearchStage.researchQuestions &&
          !_hasAncestorStage(node, byId, ResearchStage.potentialTopics)) {
        error(
          'question_without_topic',
          'Research question "${node.id}" is not connected to a potential topic.',
          nodeId: node.id,
        );
      }
    }

    for (final edge in candidate.crossLinks) {
      final source = byId[edge.sourceNodeId];
      final target = nodes[edge.targetNodeId];
      if (source == null || target == null) {
        error(
          'broken_cross_link',
          'Cross-link "${edge.id}" has a missing endpoint.',
        );
      }
    }

    if (failed) invalid.add(candidate.id);
  }

  void _checkPublication(
    Publication publication,
    List<ValidationIssue> issues,
  ) {
    final doi = publication.doi;
    if (doi != null && doi.isNotEmpty && !doiPattern.hasMatch(doi)) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          code: 'bad_doi',
          message:
              'Publication "${publication.id}" has a DOI that is not syntactically valid.',
          publicationId: publication.id,
        ),
      );
    }
    final url = publication.url;
    if (url != null && url.isNotEmpty && !_validUrl(url)) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          code: 'bad_url',
          message:
              'Publication "${publication.id}" has a URL that is not an http(s) URL.',
          publicationId: publication.id,
        ),
      );
    }
  }

  bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool _hasCycle(List<ResearchNode> nodes) {
    final byId = {for (final node in nodes) node.id: node};
    const visiting = 1;
    const done = 2;
    final state = <String, int>{};

    bool visit(String id) {
      final mark = state[id] ?? 0;
      if (mark == done) return false;
      if (mark == visiting) return true;
      state[id] = visiting;
      final node = byId[id];
      if (node != null) {
        for (final childId in node.childIds) {
          if (byId.containsKey(childId) && visit(childId)) return true;
        }
      }
      state[id] = done;
      return false;
    }

    for (final node in nodes) {
      if (visit(node.id)) return true;
    }
    return false;
  }

  bool _hasAncestorStage(
    ResearchNode node,
    Map<String, ResearchNode> byId,
    ResearchStage stage,
  ) {
    var parentId = node.parentId;
    final seen = <String>{};
    while (parentId != null && seen.add(parentId)) {
      final parent = byId[parentId];
      if (parent == null) return false;
      if (parent.stage == stage) return true;
      parentId = parent.parentId;
    }
    return false;
  }
}

class _SchemaFailure {
  const _SchemaFailure(this.message, {this.candidateId});

  final String message;
  final String? candidateId;
}
