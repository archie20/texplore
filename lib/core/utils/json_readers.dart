/// Small readers that keep a path in every error so a bad record can be named.
class JsonReaders {
  const JsonReaders._();

  static Map<String, Object?> map(Object? value, String path) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    throw FormatException('Expected an object at $path.');
  }

  static List<Object?> list(Object? value, String path) {
    if (value is List) return value;
    throw FormatException('Expected a list at $path.');
  }

  static String string(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected a non-empty string at $path.$key.');
  }

  static String? optionalString(
    Map<String, Object?> json,
    String key,
    String path,
  ) {
    if (!json.containsKey(key) || json[key] == null) return null;
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected a string or null at $path.$key.');
  }

  static int? optionalInt(Map<String, Object?> json, String key, String path) {
    if (!json.containsKey(key) || json[key] == null) return null;
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected an integer or null at $path.$key.');
  }

  static bool optionalBool(
    Map<String, Object?> json,
    String key,
    String path, {
    bool fallback = false,
  }) {
    if (!json.containsKey(key) || json[key] == null) return fallback;
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Expected a boolean at $path.$key.');
  }

  static List<String> stringList(
    Map<String, Object?> json,
    String key,
    String path,
  ) {
    if (!json.containsKey(key) || json[key] == null) return const [];
    final value = json[key];
    if (value is! List) {
      throw FormatException('Expected a list of strings at $path.$key.');
    }
    final result = <String>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! String) {
        throw FormatException('Expected a string at $path.$key[$i].');
      }
      result.add(entry);
    }
    return result;
  }
}
