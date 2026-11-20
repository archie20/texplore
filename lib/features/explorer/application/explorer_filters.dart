import 'package:equatable/equatable.dart';

import '../../../domain/enums/evidence_status.dart';
import '../../../domain/enums/relationship_type.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/enums/verification_status.dart';
import '../../../domain/models/catalogue.dart';
import '../../../domain/models/research_node.dart';

class ExplorerFilters extends Equatable {
  const ExplorerFilters({
    this.candidateIds = const {},
    this.stages = const {},
    this.evidenceStatuses = const {},
    this.verificationStatuses = const {},
    this.priorities = const {},
    this.tags = const {},
    this.hideNonMatching = false,
    this.includeSuperseded = false,
    this.showLiterature = false,
  });

  final Set<String> candidateIds;
  final Set<ResearchStage> stages;
  final Set<EvidenceStatus> evidenceStatuses;
  final Set<VerificationStatus> verificationStatuses;
  final Set<CandidatePriority> priorities;
  final Set<String> tags;
  final bool hideNonMatching;
  final bool includeSuperseded;
  final bool showLiterature;

  static const empty = ExplorerFilters();

  bool get constrainsNodes =>
      candidateIds.isNotEmpty ||
      stages.isNotEmpty ||
      evidenceStatuses.isNotEmpty ||
      verificationStatuses.isNotEmpty ||
      priorities.isNotEmpty ||
      tags.isNotEmpty;

  bool get isActive =>
      constrainsNodes || hideNonMatching || includeSuperseded || showLiterature;

  ExplorerFilters copyWith({
    Set<String>? candidateIds,
    Set<ResearchStage>? stages,
    Set<EvidenceStatus>? evidenceStatuses,
    Set<VerificationStatus>? verificationStatuses,
    Set<CandidatePriority>? priorities,
    Set<String>? tags,
    bool? hideNonMatching,
    bool? includeSuperseded,
    bool? showLiterature,
  }) {
    return ExplorerFilters(
      candidateIds: candidateIds ?? this.candidateIds,
      stages: stages ?? this.stages,
      evidenceStatuses: evidenceStatuses ?? this.evidenceStatuses,
      verificationStatuses: verificationStatuses ?? this.verificationStatuses,
      priorities: priorities ?? this.priorities,
      tags: tags ?? this.tags,
      hideNonMatching: hideNonMatching ?? this.hideNonMatching,
      includeSuperseded: includeSuperseded ?? this.includeSuperseded,
      showLiterature: showLiterature ?? this.showLiterature,
    );
  }

  /// Groups combine with AND. Values inside a group combine with OR.
  /// An empty group does not constrain.
  bool matchesNode(Catalogue catalogue, ResearchNode node) {
    if (candidateIds.isNotEmpty && !candidateIds.contains(node.candidateId))
      return false;
    if (stages.isNotEmpty && !stages.contains(node.stage)) return false;
    if (evidenceStatuses.isNotEmpty &&
        !evidenceStatuses.contains(node.evidenceStatus)) {
      return false;
    }
    if (priorities.isNotEmpty) {
      final priority = catalogue.candidateById(node.candidateId)?.priority;
      if (priority == null || !priorities.contains(priority)) return false;
    }
    if (tags.isNotEmpty) {
      final candidateTags =
          catalogue.candidateById(node.candidateId)?.tags ?? const [];
      final hit =
          node.tags.any(tags.contains) || candidateTags.any(tags.contains);
      if (!hit) return false;
    }
    if (verificationStatuses.isNotEmpty) {
      final links = catalogue.evidenceForNode(node.id);
      final hit = links.any((link) {
        final publication = catalogue.publications[link.publicationId];
        return publication != null &&
            verificationStatuses.contains(publication.verificationStatus);
      });
      if (!hit) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
    candidateIds,
    stages,
    evidenceStatuses,
    verificationStatuses,
    priorities,
    tags,
    hideNonMatching,
    includeSuperseded,
    showLiterature,
  ];
}
