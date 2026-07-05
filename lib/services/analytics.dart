import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around [FirebaseAnalytics] that no-ops until [attach] is called.
///
/// Kept as a global so any widget can log without threading a Provider through,
/// and — crucially — so tests (which never initialise Firebase) stay safe: with
/// nothing attached, every [logEvent] call is silently ignored.
class Analytics {
  FirebaseAnalytics? _fa;

  /// Navigation observer for automatic `screen_view` events; null until attached.
  FirebaseAnalyticsObserver? observer;

  void attach(FirebaseAnalytics fa) {
    _fa = fa;
    observer = FirebaseAnalyticsObserver(analytics: fa);
  }

  void logEvent(String name, [Map<String, Object>? parameters]) {
    _fa?.logEvent(name: name, parameters: parameters);
  }
}

/// App-wide analytics sink.
final Analytics analytics = Analytics();
