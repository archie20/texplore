/// How far a publication or evidence link has been checked. Appendix A5.
enum VerificationStatus {
  verifiedFullText('verified_full_text', 'Full text checked'),
  verifiedAbstract('verified_abstract', 'Abstract checked'),
  metadataVerified('metadata_verified', 'Metadata checked'),
  unverified('unverified', 'Unverified'),
  notAccessible('not_accessible', 'Not accessible'),
  disputed('disputed', 'Disputed');

  const VerificationStatus(this.wire, this.label);

  final String wire;
  final String label;

  static VerificationStatus? parse(String? value) {
    if (value == null) return null;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}
