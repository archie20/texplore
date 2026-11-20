/// How a publication relates to one specific claim. Appendix A5.
enum EvidenceRelationship {
  supports('supports', 'Supports'),
  challenges('challenges', 'Challenges'),
  extends_('extends', 'Extends'),
  contrastsWith('contrasts_with', 'Contrasts with'),
  supportsContext('supports_context', 'Supports context'),
  methodologicalPrecedent(
    'methodological_precedent',
    'Methodological precedent',
  ),
  datasetOrBenchmark('dataset_or_benchmark', 'Dataset or benchmark'),
  toolOrArtifact('tool_or_artifact', 'Tool or artifact');

  const EvidenceRelationship(this.wire, this.label);

  final String wire;
  final String label;

  static EvidenceRelationship? parse(String? value) {
    if (value == null) return null;
    for (final relationship in values) {
      if (relationship.wire == value) return relationship;
    }
    return null;
  }
}

/// A non-hierarchy link drawn as a secondary edge.
enum CrossLinkType {
  supports('supports', 'Supports'),
  derivedFrom('derived_from', 'Derived from'),
  relatedTo('related_to', 'Related to'),
  contrastsWith('contrasts_with', 'Contrasts with');

  const CrossLinkType(this.wire, this.label);

  final String wire;
  final String label;

  static CrossLinkType? parse(String? value) {
    if (value == null) return null;
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

enum PublicationType {
  journalArticle('journal_article', 'Journal article'),
  conferencePaper('conference_paper', 'Conference paper'),
  book('book', 'Book'),
  bookChapter('book_chapter', 'Book chapter'),
  thesis('thesis', 'Thesis'),
  preprint('preprint', 'Preprint'),
  technicalReport('technical_report', 'Technical report'),
  dataset('dataset', 'Dataset'),
  softwareOrArtifact('software_or_artifact', 'Software or artifact'),
  other('other', 'Other');

  const PublicationType(this.wire, this.label);

  final String wire;
  final String label;

  static PublicationType? parse(String? value) {
    if (value == null) return null;
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }

  bool get isPeerReviewedShape =>
      this == journalArticle ||
      this == conferencePaper ||
      this == book ||
      this == bookChapter ||
      this == thesis;
}

enum CandidatePriority {
  primary('primary', 'Primary'),
  alternative('alternative', 'Alternative'),
  exploratory('exploratory', 'Exploratory');

  const CandidatePriority(this.wire, this.label);

  final String wire;
  final String label;

  static CandidatePriority? parse(String? value) {
    if (value == null) return null;
    for (final priority in values) {
      if (priority.wire == value) return priority;
    }
    return null;
  }
}

enum CandidateMaturity {
  exploratory('exploratory', 'Exploratory'),
  promising('promising', 'Promising'),
  underReview('under_review', 'Under review'),
  shortlisted('shortlisted', 'Shortlisted'),
  notRecommended('not_recommended', 'Not recommended'),
  parked('parked', 'Parked');

  const CandidateMaturity(this.wire, this.label);

  final String wire;
  final String label;

  static CandidateMaturity? parse(String? value) {
    if (value == null) return null;
    for (final maturity in values) {
      if (maturity.wire == value) return maturity;
    }
    return null;
  }
}
