import 'package:url_launcher/url_launcher.dart';

/// Open the given URL in the device's browser (non-web platforms).
void openExternalUrl(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
