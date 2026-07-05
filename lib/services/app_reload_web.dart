import 'package:web/web.dart' as web;

/// Hard-reload the page so the browser fetches the freshly deployed bundle
/// (hosting serves everything with no-cache, so a reload is always current).
void reloadApp() {
  web.window.location.reload();
}
