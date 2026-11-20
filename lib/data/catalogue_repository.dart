import '../domain/models/catalogue.dart';
import '../domain/services/graph_validator.dart';
import 'local_json_data_source.dart';

class CatalogueLoadResult {
  const CatalogueLoadResult({
    required this.catalogue,
    required this.fatal,
    this.fatalMessage,
  });

  final Catalogue catalogue;
  final bool fatal;
  final String? fatalMessage;
}

class CatalogueRepository {
  CatalogueRepository({LocalJsonDataSource? source, GraphValidator? validator})
    : _source = source ?? LocalJsonDataSource(),
      _validator = validator ?? const GraphValidator();

  final LocalJsonDataSource _source;
  final GraphValidator _validator;

  Future<CatalogueLoadResult> load() async {
    final parsed = await _source.load();
    final report = _validator.validate(parsed);
    if (report.fatal) {
      return CatalogueLoadResult(
        fatal: true,
        fatalMessage: report.fatalMessage,
        catalogue: Catalogue(
          schemaVersion: parsed.schemaVersion ?? '',
          title: parsed.title,
          candidates: const [],
          nodes: const {},
          publications: const {},
          evidenceLinks: const {},
          crossLinks: const [],
          issues: report.issues,
        ),
      );
    }
    return CatalogueLoadResult(
      fatal: false,
      catalogue: _validator.assemble(parsed, report),
    );
  }
}
