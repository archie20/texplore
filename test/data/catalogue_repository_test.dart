import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_topics/data/catalogue_repository.dart';
import 'package:thesis_topics/data/local_json_data_source.dart';
import 'package:thesis_topics/domain/enums/verification_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the seeded catalogue loads and keeps every candidate', () async {
    final repository = CatalogueRepository(
      source: LocalJsonDataSource(
        read: (path) async => File(path).readAsString(),
      ),
    );
    final result = await repository.load();
    expect(result.fatal, isFalse, reason: result.fatalMessage);
    expect(
      result.catalogue.excluded,
      isEmpty,
      reason: jsonEncode(result.catalogue.excluded),
    );
    expect(result.catalogue.candidates, hasLength(6));
    expect(result.catalogue.candidates.map((candidate) => candidate.id), [
      'kente',
      'crop',
      'adaptive',
      'se',
      'language',
      'context',
    ]);
    expect(
      result.catalogue.publications.values.every(
        (publication) =>
            publication.verificationStatus == VerificationStatus.unverified,
      ),
      isTrue,
    );
    expect(
      result.catalogue.publications.values.every(
        (publication) => publication.doi == null,
      ),
      isTrue,
    );
    final errors = result.catalogue.issues.where((issue) => issue.isError);
    expect(
      errors,
      isEmpty,
      reason: errors.map((issue) => issue.message).join('\n'),
    );
  });
}
