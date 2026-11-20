import '../enums/research_stage.dart';
import '../enums/verification_status.dart';
import '../models/catalogue.dart';
import '../models/candidate.dart';
import '../models/research_node.dart';

class ComparisonCell {
  const ComparisonCell({
    required this.label,
    required this.value,
    required this.missing,
    this.nodeId,
  });

  final String label;
  final String value;
  final bool missing;
  final String? nodeId;
}

class ComparisonColumn {
  const ComparisonColumn({required this.candidate, required this.cells});

  final Candidate candidate;
  final List<ComparisonCell> cells;
}

class ComparisonService {
  const ComparisonService();

  static const notSpecified = 'Not specified';

  List<ComparisonColumn> compare(
    Catalogue catalogue,
    List<String> candidateIds,
  ) {
    return [
      for (final id in candidateIds)
        if (catalogue.candidateById(id) case final candidate?)
          ComparisonColumn(
            candidate: candidate,
            cells: _cells(catalogue, candidate),
          ),
    ];
  }

  List<ComparisonCell> _cells(Catalogue catalogue, Candidate candidate) {
    final question = _first(catalogue, candidate, ResearchStage.thesisQuestion);
    final outcomes = _all(catalogue, candidate, ResearchStage.expectedOutcomes);
    final risks = <String>[
      ...candidate.majorRisks,
      for (final node in candidate.nodes) ...node.risks,
    ];
    final readiness = _literatureReadiness(catalogue, candidate);
    return [
      _text('Problem', candidate.root?.title, candidate.rootNodeId),
      _text('Primary research question', question?.title, question?.id),
      _text('Technical contribution', candidate.technicalContribution, null),
      _text('Ghanaian relevance', candidate.ghanaianRelevance, null),
      _text(
        'Expected outcomes',
        outcomes.isEmpty ? null : outcomes.map((node) => node.title).join('\n'),
        outcomes.isEmpty ? null : outcomes.first.id,
      ),
      _text('Data and resource requirements', candidate.dataRequirements, null),
      _text('Evaluation design', candidate.evaluationDesign, null),
      _text(
        'Feasibility and major risks',
        _feasibility(candidate, risks),
        null,
      ),
      ComparisonCell(
        label: 'Literature readiness',
        value: readiness,
        missing: false,
      ),
      _text(
        'Unresolved evidence',
        candidate.openDecisions.isEmpty
            ? null
            : candidate.openDecisions.join('\n'),
        null,
      ),
    ];
  }

  ComparisonCell _text(String label, String? value, String? nodeId) {
    final missing = value == null || value.trim().isEmpty;
    return ComparisonCell(
      label: label,
      value: missing ? notSpecified : value,
      missing: missing,
      nodeId: nodeId,
    );
  }

  String? _feasibility(Candidate candidate, List<String> risks) {
    final parts = <String>[];
    final feasibility = candidate.feasibility;
    if (feasibility != null) {
      parts.add(
        'Planning assessment (${feasibility.rating}): ${feasibility.rationale}',
      );
    }
    if (risks.isNotEmpty) parts.add(risks.join('\n'));
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  String _literatureReadiness(Catalogue catalogue, Candidate candidate) {
    if (candidate.evidenceLinks.isEmpty) {
      return 'No evidence links recorded yet. This is not a judgement of novelty.';
    }
    final counts = <VerificationStatus, int>{};
    for (final link in candidate.evidenceLinks) {
      counts[link.verificationStatus] =
          (counts[link.verificationStatus] ?? 0) + 1;
    }
    final parts = [
      for (final status in VerificationStatus.values)
        if (counts[status] != null)
          '${counts[status]} ${status.label.toLowerCase()}',
    ];
    return '${parts.join(', ')}. Counts are not a ranking.';
  }

  ResearchNode? _first(
    Catalogue catalogue,
    Candidate candidate,
    ResearchStage stage,
  ) {
    final matches = _all(catalogue, candidate, stage);
    return matches.isEmpty ? null : matches.first;
  }

  List<ResearchNode> _all(
    Catalogue catalogue,
    Candidate candidate,
    ResearchStage stage,
  ) {
    final matches = [
      for (final node in candidate.nodes)
        if (node.stage == stage) node,
    ];
    matches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return matches;
  }
}
