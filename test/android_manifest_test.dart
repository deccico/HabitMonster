import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('advertising ID permission is stripped from the merged manifest', () {
    // The Play declaration says the app doesn't use advertising ID, and the
    // Families policy forbids sending the AAID for child audiences. The
    // play-services SDKs merge the permission in unless removed.
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
    expect(manifest, contains('tools:node="remove"'));
  });

  test('analytics ad signals stay disabled for the Families policy', () {
    expect(manifest, contains('google_analytics_adid_collection_enabled'));
    expect(manifest,
        contains('google_analytics_default_allow_ad_personalization_signals'));
  });
}
