import '../../domain/enums/evidence_status.dart';

enum EvidenceBorder { solid, dashed, dotted }

EvidenceBorder evidenceBorderFor(EvidenceStatus status) {
  return switch (status) {
    EvidenceStatus.verified ||
    EvidenceStatus.abstractChecked ||
    EvidenceStatus.metadataChecked => EvidenceBorder.solid,
    EvidenceStatus.unverified ||
    EvidenceStatus.hypothesis ||
    EvidenceStatus.needsLiterature => EvidenceBorder.dashed,
    EvidenceStatus.superseded => EvidenceBorder.dotted,
  };
}
