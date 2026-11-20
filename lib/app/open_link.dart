import 'package:url_launcher/url_launcher.dart';

/// Opens a DOI or URL outside the app. Returns false when the address is
/// missing or the platform refuses it.
Future<bool> openExternal(Uri? uri) async {
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
