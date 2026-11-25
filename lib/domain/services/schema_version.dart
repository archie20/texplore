import '../models/catalogue.dart';

/// Strict file-level schema version checks for the catalogue.
class SchemaVersion {
  const SchemaVersion._();

  /// Returns null when [value] exactly matches [Catalogue.supportedSchemaVersion].
  /// Otherwise returns an actionable error message naming [path].
  static String? mismatchMessage(String? value, {required String path}) {
    final found = describe(value);
    if (value != null &&
        value == Catalogue.supportedSchemaVersion) {
      return null;
    }
    return 'Schema version $found in $path is not supported. '
        'Expected ${Catalogue.supportedSchemaVersion}.';
  }

  static bool isSupported(String? value) {
    return value != null && value == Catalogue.supportedSchemaVersion;
  }

  static String describe(String? value) {
    if (value == null) return '(missing)';
    if (value.trim().isEmpty) return '(empty)';
    return '"$value"';
  }
}
