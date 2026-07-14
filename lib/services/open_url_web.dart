import 'package:web/web.dart' as web;

/// Open the given URL in a new browser tab.
void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}
