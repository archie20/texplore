import '../enums/evidence_status.dart';
import '../models/catalogue.dart';

enum SearchHitKind { candidate, node, publication, evidence }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.candidateId,
    required this.title,
    required this.snippet,
    required this.matchedIn,
    required this.groupLabel,
    this.nodeId,
    this.publicationId,
    this.evidenceLinkId,
  });

  final SearchHitKind kind;
  final String candidateId;
  final String? nodeId;
  final String? publicationId;
  final String? evidenceLinkId;
  final String title;
  final String snippet;
  final String matchedIn;
  final String groupLabel;
}

class SearchIndex {
  const SearchIndex(this.catalogue);

  final Catalogue catalogue;

  static final _punctuation = RegExp(r"[^\p{L}\p{N}\s]+", unicode: true);
  static final _whitespace = RegExp(r'\s+');

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(_punctuation, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  List<SearchHit> search(String query, {bool includeSuperseded = false}) {
    final needle = normalize(query);
    if (needle.isEmpty) return const [];
    final hits = <SearchHit>[];

    for (final candidate in catalogue.candidates) {
      final fields = <String, String>{
        'title': candidate.title,
        'summary': candidate.summary,
        'description': candidate.shortDescription,
        if (candidate.technicalContribution != null)
          'contribution': candidate.technicalContribution!,
        'tags': candidate.tags.join(' '),
      };
      final match = _firstMatch(fields, needle);
      if (match != null) {
        hits.add(
          SearchHit(
            kind: SearchHitKind.candidate,
            candidateId: candidate.id,
            nodeId: candidate.rootNodeId,
            title: candidate.shortTitle,
            snippet: _snippet(match.$2, needle),
            matchedIn: match.$1,
            groupLabel: 'Candidate',
          ),
        );
      }
    }

    for (final node in catalogue.nodes.values) {
      if (node.evidenceStatus == EvidenceStatus.superseded &&
          !includeSuperseded) {
        continue;
      }
      final fields = <String, String>{
        'title': node.title,
        'summary': node.summary,
        'detail': node.detail,
        'tags': node.tags.join(' '),
        'notes': node.notes.join(' '),
      };
      final match = _firstMatch(fields, needle);
      if (match == null) continue;
      hits.add(
        SearchHit(
          kind: SearchHitKind.node,
          candidateId: node.candidateId,
          nodeId: node.id,
          title: node.title,
          snippet: _snippet(match.$2, needle),
          matchedIn: match.$1,
          groupLabel: node.stage.label,
        ),
      );
    }

    final publicationCandidates = _publicationCandidates();
    for (final publication in catalogue.publications.values) {
      final fields = <String, String>{
        'title': publication.title,
        'authors': publication.authors.join(' '),
        'venue': publication.venue ?? '',
        'year': publication.year?.toString() ?? '',
      };
      final match = _firstMatch(fields, needle);
      if (match == null) continue;
      final owners = publicationCandidates[publication.id] ?? const <String>{};
      if (owners.isEmpty) continue;
      for (final candidateId in owners) {
        hits.add(
          SearchHit(
            kind: SearchHitKind.publication,
            candidateId: candidateId,
            publicationId: publication.id,
            title: publication.title,
            snippet: _snippet(match.$2, needle),
            matchedIn: match.$1,
            groupLabel: 'Publication',
          ),
        );
      }
    }

    for (final link in catalogue.evidenceLinks.values) {
      final node = catalogue.nodes[link.nodeId];
      if (node == null) continue;
      if (node.evidenceStatus == EvidenceStatus.superseded &&
          !includeSuperseded) {
        continue;
      }
      final fields = <String, String>{
        'claim': link.claim,
        'limitation': link.limitation ?? '',
      };
      final match = _firstMatch(fields, needle);
      if (match == null) continue;
      hits.add(
        SearchHit(
          kind: SearchHitKind.evidence,
          candidateId: node.candidateId,
          nodeId: node.id,
          evidenceLinkId: link.id,
          publicationId: link.publicationId,
          title: node.title,
          snippet: _snippet(match.$2, needle),
          matchedIn: match.$1,
          groupLabel: 'Evidence',
        ),
      );
    }

    return hits;
  }

  (String, String)? _firstMatch(Map<String, String> fields, String needle) {
    for (final entry in fields.entries) {
      if (normalize(entry.value).contains(needle))
        return (entry.key, entry.value);
    }
    return null;
  }

  String _snippet(String source, String needle) {
    final normalized = normalize(source);
    final index = normalized.indexOf(needle);
    if (index < 0)
      return source.length <= 140 ? source : '${source.substring(0, 137)}...';
    final start = index <= 40 ? 0 : index - 40;
    final end = (index + needle.length + 80).clamp(0, normalized.length);
    final slice = normalized.substring(start, end).trim();
    final prefix = start == 0 ? '' : '...';
    final suffix = end == normalized.length ? '' : '...';
    return '$prefix$slice$suffix';
  }

  Map<String, Set<String>> _publicationCandidates() {
    final map = <String, Set<String>>{};
    for (final link in catalogue.evidenceLinks.values) {
      final node = catalogue.nodes[link.nodeId];
      if (node == null) continue;
      map.putIfAbsent(link.publicationId, () => {}).add(node.candidateId);
    }
    return map;
  }
}
