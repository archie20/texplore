import 'package:equatable/equatable.dart';

import '../enums/evidence_status.dart';
import '../enums/research_stage.dart';
import '../../core/utils/json_readers.dart';

class ResearchNode extends Equatable {
  const ResearchNode({
    required this.id,
    required this.candidateId,
    required this.stage,
    required this.title,
    required this.summary,
    required this.detail,
    required this.parentId,
    required this.childIds,
    required this.evidenceStatus,
    required this.evidenceLinkIds,
    required this.relatedNodeIds,
    required this.tags,
    required this.sortOrder,
    required this.notes,
    required this.assumptions,
    required this.risks,
    required this.validationRequirements,
    this.gapStrength,
    this.priority,
    this.lastReviewed,
  });

  final String id;
  final String candidateId;
  final ResearchStage stage;
  final String title;

  /// Canvas line. An empty string is an intentional blank; null is not used.
  final String summary;

  /// Inspector text. Empty means the fuller explanation has not been written.
  final String detail;
  final String? parentId;
  final List<String> childIds;
  final EvidenceStatus evidenceStatus;
  final List<String> evidenceLinkIds;
  final List<String> relatedNodeIds;
  final List<String> tags;
  final int sortOrder;
  final List<String> notes;
  final List<String> assumptions;
  final List<String> risks;
  final List<String> validationRequirements;
  final GapStrength? gapStrength;
  final String? priority;
  final String? lastReviewed;

  bool get exploratory =>
      tags.contains('exploratory') ||
      evidenceStatus == EvidenceStatus.hypothesis;

  factory ResearchNode.fromJson(Map<String, Object?> json, String path) {
    final stage = ResearchStage.parse(
      JsonReaders.optionalString(json, 'stage', path),
    );
    if (stage == null) {
      throw FormatException('Unknown or missing stage at $path.stage.');
    }
    final status = EvidenceStatus.parse(
      JsonReaders.optionalString(json, 'evidenceStatus', path),
    );
    if (status == null) {
      throw FormatException(
        'Unknown or missing evidenceStatus at $path.evidenceStatus.',
      );
    }
    final gapWire = JsonReaders.optionalString(json, 'gapStrength', path);
    final gap = GapStrength.parse(gapWire);
    if (gapWire != null && gap == null) {
      throw FormatException('Unknown gapStrength at $path.gapStrength.');
    }
    final summary = JsonReaders.optionalString(json, 'summary', path);
    final detail = JsonReaders.optionalString(json, 'detail', path);
    return ResearchNode(
      id: JsonReaders.string(json, 'id', path),
      candidateId: JsonReaders.string(json, 'candidateId', path),
      stage: stage,
      title: JsonReaders.string(json, 'title', path),
      summary: summary ?? '',
      detail: detail ?? '',
      parentId: JsonReaders.optionalString(json, 'parentId', path),
      childIds: JsonReaders.stringList(json, 'childIds', path),
      evidenceStatus: status,
      evidenceLinkIds: JsonReaders.stringList(json, 'evidenceLinkIds', path),
      relatedNodeIds: JsonReaders.stringList(json, 'relatedNodeIds', path),
      tags: JsonReaders.stringList(json, 'tags', path),
      sortOrder: JsonReaders.optionalInt(json, 'sortOrder', path) ?? 0,
      notes: JsonReaders.stringList(json, 'notes', path),
      assumptions: JsonReaders.stringList(json, 'assumptions', path),
      risks: JsonReaders.stringList(json, 'risks', path),
      validationRequirements: JsonReaders.stringList(
        json,
        'validationRequirements',
        path,
      ),
      gapStrength: gap,
      priority: JsonReaders.optionalString(json, 'priority', path),
      lastReviewed: JsonReaders.optionalString(json, 'lastReviewed', path),
    );
  }

  @override
  List<Object?> get props => [
    id,
    candidateId,
    stage,
    title,
    summary,
    detail,
    parentId,
    childIds,
    evidenceStatus,
    evidenceLinkIds,
    relatedNodeIds,
    tags,
    sortOrder,
    notes,
    assumptions,
    risks,
    validationRequirements,
    gapStrength,
    priority,
    lastReviewed,
  ];
}
