/// How firmly a node's claim is established. Appendix A7.
enum EvidenceStatus {
  verified('verified', 'Verified'),
  abstractChecked('abstract_checked', 'Abstract checked'),
  metadataChecked('metadata_checked', 'Metadata checked'),
  unverified('unverified', 'Unverified'),
  hypothesis('hypothesis', 'Hypothesis'),
  needsLiterature('needs_literature', 'Needs literature'),
  superseded('superseded', 'Superseded');

  const EvidenceStatus(this.wire, this.label);

  final String wire;
  final String label;

  static EvidenceStatus? parse(String? value) {
    if (value == null) return null;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }

  bool get isChecked =>
      this == verified || this == abstractChecked || this == metadataChecked;
}

/// Optional strength label for a literature-gap node. Section 3.4.
enum GapStrength {
  strong('strong', 'Strong'),
  moderate('moderate', 'Moderate'),
  weak('weak', 'Weak'),
  unconfirmed('unconfirmed', 'Unconfirmed');

  const GapStrength(this.wire, this.label);

  final String wire;
  final String label;

  static GapStrength? parse(String? value) {
    if (value == null) return null;
    for (final strength in values) {
      if (strength.wire == value) return strength;
    }
    return null;
  }
}

/// How directly an evidence link supports its claim. Appendix A5.
enum EvidenceStrength {
  direct('direct', 'Direct'),
  indirect('indirect', 'Indirect'),
  contextual('contextual', 'Contextual'),
  uncertain('uncertain', 'Uncertain');

  const EvidenceStrength(this.wire, this.label);

  final String wire;
  final String label;

  static EvidenceStrength? parse(String? value) {
    if (value == null) return null;
    for (final strength in values) {
      if (strength.wire == value) return strength;
    }
    return null;
  }
}
