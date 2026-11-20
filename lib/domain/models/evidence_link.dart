import 'package:equatable/equatable.dart';

import '../../core/utils/json_readers.dart';
import '../enums/evidence_status.dart';
import '../enums/relationship_type.dart';
import '../enums/verification_status.dart';

class EvidenceLink extends Equatable {
  const EvidenceLink({
    required this.id,
    required this.nodeId,
    required this.publicationId,
    required this.relationship,
    required this.claim,
    required this.evidenceStrength,
    required this.verificationStatus,
    this.limitation,
    this.pageOrSection,
    this.notes,
    this.confidence,
  });

  final String id;
  final String nodeId;
  final String publicationId;
  final EvidenceRelationship relationship;
  final String claim;
  final String? limitation;
  final EvidenceStrength evidenceStrength;
  final VerificationStatus verificationStatus;
  final String? pageOrSection;
  final String? notes;
  final String? confidence;

  factory EvidenceLink.fromJson(Map<String, Object?> json, String path) {
    final relationship = EvidenceRelationship.parse(
      JsonReaders.optionalString(json, 'relationship', path),
    );
    if (relationship == null) {
      throw FormatException(
        'Unknown or missing relationship at $path.relationship.',
      );
    }
    final strength = EvidenceStrength.parse(
      JsonReaders.optionalString(json, 'evidenceStrength', path),
    );
    if (strength == null) {
      throw FormatException(
        'Unknown or missing evidenceStrength at $path.evidenceStrength.',
      );
    }
    final verification = VerificationStatus.parse(
      JsonReaders.optionalString(json, 'verificationStatus', path),
    );
    if (verification == null) {
      throw FormatException(
        'Unknown or missing verificationStatus at $path.verificationStatus.',
      );
    }
    return EvidenceLink(
      id: JsonReaders.string(json, 'id', path),
      nodeId: JsonReaders.string(json, 'nodeId', path),
      publicationId: JsonReaders.string(json, 'publicationId', path),
      relationship: relationship,
      claim: JsonReaders.string(json, 'claim', path),
      limitation: JsonReaders.optionalString(json, 'limitation', path),
      evidenceStrength: strength,
      verificationStatus: verification,
      pageOrSection: JsonReaders.optionalString(json, 'pageOrSection', path),
      notes: JsonReaders.optionalString(json, 'notes', path),
      confidence: JsonReaders.optionalString(json, 'confidence', path),
    );
  }

  @override
  List<Object?> get props => [
    id,
    nodeId,
    publicationId,
    relationship,
    claim,
    limitation,
    evidenceStrength,
    verificationStatus,
    pageOrSection,
    notes,
    confidence,
  ];
}

class GraphEdge extends Equatable {
  const GraphEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.relationshipType,
    this.visualStyle = 'dashed',
  });

  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final CrossLinkType relationshipType;
  final String visualStyle;

  factory GraphEdge.fromJson(Map<String, Object?> json, String path) {
    final type = CrossLinkType.parse(
      JsonReaders.optionalString(json, 'relationshipType', path),
    );
    if (type == null) {
      throw FormatException(
        'Unknown or missing relationshipType at $path.relationshipType.',
      );
    }
    return GraphEdge(
      id: JsonReaders.string(json, 'id', path),
      sourceNodeId: JsonReaders.string(json, 'sourceNodeId', path),
      targetNodeId: JsonReaders.string(json, 'targetNodeId', path),
      relationshipType: type,
      visualStyle:
          JsonReaders.optionalString(json, 'visualStyle', path) ?? 'dashed',
    );
  }

  @override
  List<Object?> get props => [
    id,
    sourceNodeId,
    targetNodeId,
    relationshipType,
    visualStyle,
  ];
}
