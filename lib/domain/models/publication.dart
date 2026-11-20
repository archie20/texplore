import 'package:equatable/equatable.dart';

import '../../core/utils/json_readers.dart';
import '../enums/relationship_type.dart';
import '../enums/verification_status.dart';

class Publication extends Equatable {
  const Publication({
    required this.id,
    required this.title,
    required this.authors,
    required this.publicationType,
    required this.verificationStatus,
    this.year,
    this.venue,
    this.volume,
    this.issue,
    this.pages,
    this.doi,
    this.url,
    this.abstractText,
    this.datasetOrArtifact,
    this.verificationNotes,
    this.relevanceNote,
    this.researchMethod,
    this.keyFindings,
    this.limitations,
    this.accessDate,
  });

  final String id;
  final String title;
  final List<String> authors;
  final int? year;
  final String? venue;
  final String? volume;
  final String? issue;
  final String? pages;
  final String? doi;
  final String? url;
  final String? abstractText;
  final PublicationType publicationType;
  final String? datasetOrArtifact;
  final VerificationStatus verificationStatus;
  final String? verificationNotes;
  final String? relevanceNote;
  final String? researchMethod;
  final String? keyFindings;
  final String? limitations;
  final String? accessDate;

  String get citationLabel {
    final who = authors.isEmpty ? 'Unknown author' : authors.join('; ');
    final when = year?.toString() ?? 'n.d.';
    return '$who ($when). $title';
  }

  Uri? get externalUri {
    if (doi != null && doi!.isNotEmpty) {
      return Uri.tryParse('https://doi.org/$doi');
    }
    if (url != null && url!.isNotEmpty) return Uri.tryParse(url!);
    return null;
  }

  factory Publication.fromJson(Map<String, Object?> json, String path) {
    final type = PublicationType.parse(
      JsonReaders.optionalString(json, 'publicationType', path),
    );
    if (type == null) {
      throw FormatException(
        'Unknown or missing publicationType at $path.publicationType.',
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
    return Publication(
      id: JsonReaders.string(json, 'id', path),
      title: JsonReaders.string(json, 'title', path),
      authors: JsonReaders.stringList(json, 'authors', path),
      year: JsonReaders.optionalInt(json, 'year', path),
      venue: JsonReaders.optionalString(json, 'venue', path),
      volume: JsonReaders.optionalString(json, 'volume', path),
      issue: JsonReaders.optionalString(json, 'issue', path),
      pages: JsonReaders.optionalString(json, 'pages', path),
      doi: JsonReaders.optionalString(json, 'doi', path),
      url: JsonReaders.optionalString(json, 'url', path),
      abstractText: JsonReaders.optionalString(json, 'abstract', path),
      publicationType: type,
      datasetOrArtifact: JsonReaders.optionalString(
        json,
        'datasetOrArtifact',
        path,
      ),
      verificationStatus: verification,
      verificationNotes: JsonReaders.optionalString(
        json,
        'verificationNotes',
        path,
      ),
      relevanceNote: JsonReaders.optionalString(json, 'relevanceNote', path),
      researchMethod: JsonReaders.optionalString(json, 'researchMethod', path),
      keyFindings: JsonReaders.optionalString(json, 'keyFindings', path),
      limitations: JsonReaders.optionalString(json, 'limitations', path),
      accessDate: JsonReaders.optionalString(json, 'accessDate', path),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    authors,
    year,
    venue,
    volume,
    issue,
    pages,
    doi,
    url,
    abstractText,
    publicationType,
    datasetOrArtifact,
    verificationStatus,
    verificationNotes,
    relevanceNote,
    researchMethod,
    keyFindings,
    limitations,
    accessDate,
  ];
}
