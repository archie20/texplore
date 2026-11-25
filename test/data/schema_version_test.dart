import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/data/catalogue_repository.dart';
import 'package:thesis_topics/data/local_json_data_source.dart';
import 'package:thesis_topics/domain/models/catalogue.dart';
import 'package:thesis_topics/domain/services/graph_validator.dart';
import 'package:thesis_topics/domain/services/schema_version.dart';

import '../support/catalogue_factory.dart';

void main() {
  const validator = GraphValidator();

  Map<String, String> fixtureFiles({
    String? manifestVersion = '1.0.0',
    String? candidateVersion = '1.0.0',
    String? publicationVersion = '1.0.0',
  }) {
    final manifest = {
      if (manifestVersion != null) 'schemaVersion': manifestVersion,
      'catalogueTitle': 'Fixture',
      'candidates': ['assets/data/candidates/a.json'],
      'publications': ['assets/data/publications/p.json'],
    };
    final candidate = {
      if (candidateVersion != null) 'schemaVersion': candidateVersion,
      'candidate': {
        'id': 'a',
        'title': 'A',
        'shortTitle': 'A',
        'summary': 'Summary',
        'shortDescription': 'Short',
        'priority': 'primary',
        'status': 'promising',
        'rootNodeId': 'a-problem',
        'tags': <String>[],
        'openDecisions': <String>[],
        'readiness': <String>[],
      },
      'nodes': [
        {
          'id': 'a-problem',
          'candidateId': 'a',
          'stage': 'thesis_problem',
          'title': 'Problem',
          'summary': 'Summary',
          'detail': 'Detail',
          'parentId': null,
          'childIds': <String>[],
          'evidenceStatus': 'unverified',
          'evidenceLinkIds': <String>[],
          'relatedNodeIds': <String>[],
          'tags': <String>[],
          'sortOrder': 0,
          'notes': <String>[],
          'assumptions': <String>[],
          'risks': <String>[],
          'validationRequirements': <String>[],
        },
      ],
    };
    final publication = {
      if (publicationVersion != null) 'schemaVersion': publicationVersion,
      'publications': [
        {
          'id': 'pub-a',
          'title': 'Paper',
          'authors': ['Author'],
          'year': 2024,
          'publicationType': 'journal_article',
          'verificationStatus': 'unverified',
        },
      ],
    };
    return {
      'assets/data/manifest.json': jsonEncode(manifest),
      'assets/data/candidates/a.json': jsonEncode(candidate),
      'assets/data/publications/p.json': jsonEncode(publication),
    };
  }

  Future<CatalogueLoadResult> loadFixture(Map<String, String> files) {
    return CatalogueRepository(
      source: LocalJsonDataSource(
        read: (path) async {
          final body = files[path];
          if (body == null) throw StateError('missing $path');
          return body;
        },
      ),
    ).load();
  }

  test('supported versions load', () async {
    final result = await loadFixture(fixtureFiles());
    expect(result.fatal, isFalse, reason: result.fatalMessage);
    expect(result.catalogue.candidates, hasLength(1));
  });

  test('manifest missing version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(manifestVersion: null));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('manifest.json'));
    expect(result.fatalMessage, contains(Catalogue.supportedSchemaVersion));
  });

  test('manifest empty version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(manifestVersion: '  '));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('manifest.json'));
  });

  test('manifest unsupported version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(manifestVersion: '9.9.9'));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('9.9.9'));
    expect(result.fatalMessage, contains(Catalogue.supportedSchemaVersion));
  });

  test('candidate missing version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(candidateVersion: null));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('candidates/a.json'));
  });

  test('candidate empty version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(candidateVersion: ''));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('candidates/a.json'));
  });

  test('candidate unsupported version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(candidateVersion: '2.0.0'));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('2.0.0'));
  });

  test('publication missing version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(publicationVersion: null));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('publications/p.json'));
  });

  test('publication empty version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(publicationVersion: ' '));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('publications/p.json'));
  });

  test('publication unsupported version fails fatally', () async {
    final result = await loadFixture(fixtureFiles(publicationVersion: '0.1.0'));
    expect(result.fatal, isTrue);
    expect(result.fatalMessage, contains('0.1.0'));
  });

  test('SchemaVersion helper messages name path and expected version', () {
    expect(
      SchemaVersion.mismatchMessage(null, path: 'file.json'),
      allOf(
        contains('file.json'),
        contains('(missing)'),
        contains(Catalogue.supportedSchemaVersion),
      ),
    );
    expect(SchemaVersion.isSupported('1.0.0'), isTrue);
    expect(SchemaVersion.isSupported(null), isFalse);
  });

  test('validator rejects missing candidate schema even in memory fixtures', () {
    final candidate = chainCatalogue().candidates.single;
    final report = validator.validate(
      ParsedCatalogue(
        schemaVersion: Catalogue.supportedSchemaVersion,
        title: 'Test',
        candidates: [
          ParsedCandidate(candidate: candidate, schemaVersion: null),
        ],
        publications: [testPublication()],
      ),
    );
    expect(report.fatal, isTrue);
    expect(report.fatalMessage, contains('Schema version'));
    expect(report.fatalMessage, contains('candidate:candidate-a'));
  });
}
