import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/utils/json_readers.dart';
import '../domain/enums/relationship_type.dart';
import '../domain/models/candidate.dart';
import '../domain/models/catalogue.dart';
import '../domain/models/evidence_link.dart';
import '../domain/models/publication.dart';
import '../domain/models/research_node.dart';

typedef AssetReader = Future<String> Function(String path);

class LocalJsonDataSource {
  LocalJsonDataSource({AssetReader? read})
    : _read = read ?? rootBundle.loadString;

  final AssetReader _read;

  Future<ParsedCatalogue> load() async {
    final manifestRaw = await _read('assets/data/manifest.json');
    final manifest = JsonReaders.map(jsonDecode(manifestRaw), 'manifest');
    final title =
        JsonReaders.optionalString(manifest, 'catalogueTitle', 'manifest') ??
        'Thesis Topic Explorer';
    final schema = JsonReaders.optionalString(
      manifest,
      'schemaVersion',
      'manifest',
    );
    final lastReviewed = JsonReaders.optionalString(
      manifest,
      'lastReviewed',
      'manifest',
    );
    final issues = <ValidationIssue>[];

    final publicationFiles = <ParsedPublicationFile>[];
    final publications = <Publication>[];
    for (final path in JsonReaders.stringList(
      manifest,
      'publications',
      'manifest',
    )) {
      try {
        final file = await _readPublicationFile(path);
        publicationFiles.add(file);
        publications.addAll(file.publications);
      } on FormatException catch (error) {
        publicationFiles.add(
          ParsedPublicationFile(
            source: path,
            schemaVersion: null,
            publications: const [],
          ),
        );
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'parse',
            message: 'Could not read publications at $path: ${error.message}',
          ),
        );
      } catch (error) {
        publicationFiles.add(
          ParsedPublicationFile(
            source: path,
            schemaVersion: null,
            publications: const [],
          ),
        );
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'parse',
            message: 'Could not read publications at $path: $error',
          ),
        );
      }
    }

    final candidates = <ParsedCandidate>[];
    for (final path in JsonReaders.stringList(
      manifest,
      'candidates',
      'manifest',
    )) {
      try {
        candidates.add(await _readCandidate(path));
      } on FormatException catch (error) {
        candidates.add(_unreadable(path, error.message));
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'parse',
            message: error.message,
            candidateId: _idFromPath(path),
          ),
        );
      } catch (error) {
        candidates.add(_unreadable(path, '$error'));
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: 'parse',
            message: 'Could not read $path: $error',
            candidateId: _idFromPath(path),
          ),
        );
      }
    }

    return ParsedCatalogue(
      schemaVersion: schema,
      title: title,
      lastReviewed: lastReviewed,
      candidates: candidates,
      publications: publications,
      publicationFiles: publicationFiles,
      parseIssues: issues,
    );
  }

  Future<ParsedPublicationFile> _readPublicationFile(String path) async {
    final json = JsonReaders.map(jsonDecode(await _read(path)), path);
    final schema = _readSchemaVersion(json, path);
    final items = JsonReaders.list(json['publications'], '$path.publications');
    final publications = <Publication>[];
    for (var i = 0; i < items.length; i++) {
      publications.add(
        Publication.fromJson(
          JsonReaders.map(items[i], '$path.publications[$i]'),
          '$path.publications[$i]',
        ),
      );
    }
    return ParsedPublicationFile(
      source: path,
      schemaVersion: schema,
      publications: publications,
    );
  }

  Future<ParsedCandidate> _readCandidate(String path) async {
    final json = JsonReaders.map(jsonDecode(await _read(path)), path);
    final schema = _readSchemaVersion(json, path);
    final candidateJson = JsonReaders.map(json['candidate'], '$path.candidate');
    final candidate = Candidate.fromJson(candidateJson, '$path.candidate');
    final nodes = <ResearchNode>[];
    final nodeItems = JsonReaders.list(json['nodes'], '$path.nodes');
    for (var i = 0; i < nodeItems.length; i++) {
      nodes.add(
        ResearchNode.fromJson(
          JsonReaders.map(nodeItems[i], '$path.nodes[$i]'),
          '$path.nodes[$i]',
        ),
      );
    }
    final links = <EvidenceLink>[];
    if (json['evidenceLinks'] != null) {
      final items = JsonReaders.list(
        json['evidenceLinks'],
        '$path.evidenceLinks',
      );
      for (var i = 0; i < items.length; i++) {
        links.add(
          EvidenceLink.fromJson(
            JsonReaders.map(items[i], '$path.evidenceLinks[$i]'),
            '$path.evidenceLinks[$i]',
          ),
        );
      }
    }
    final edges = <GraphEdge>[];
    if (json['crossLinks'] != null) {
      final items = JsonReaders.list(json['crossLinks'], '$path.crossLinks');
      for (var i = 0; i < items.length; i++) {
        edges.add(
          GraphEdge.fromJson(
            JsonReaders.map(items[i], '$path.crossLinks[$i]'),
            '$path.crossLinks[$i]',
          ),
        );
      }
    }
    return ParsedCandidate(
      schemaVersion: schema,
      source: path,
      candidate: candidate.copyWith(
        nodes: nodes,
        evidenceLinks: links,
        crossLinks: edges,
      ),
    );
  }

  /// Reads schemaVersion without substituting a default. Null means missing.
  String? _readSchemaVersion(Map<String, Object?> json, String path) {
    if (!json.containsKey('schemaVersion') || json['schemaVersion'] == null) {
      return null;
    }
    final value = json['schemaVersion'];
    if (value is! String) {
      throw FormatException('Expected a string at $path.schemaVersion.');
    }
    return value;
  }

  ParsedCandidate _unreadable(String path, String message) {
    final id = _idFromPath(path);
    return ParsedCandidate(
      schemaVersion: null,
      source: path,
      candidate: Candidate(
        id: id,
        title: 'Unreadable candidate ($id)',
        shortTitle: id,
        summary: message,
        shortDescription: message,
        priority: CandidatePriority.exploratory,
        maturity: CandidateMaturity.exploratory,
        rootNodeId: '$id-missing-root',
        tags: const [],
        openDecisions: const [],
        readiness: const [],
        nodes: const [],
        crossLinks: const [],
        evidenceLinks: const [],
      ),
    );
  }

  String _idFromPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }
}
