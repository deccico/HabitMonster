import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell scripts in scripts/ are valid bash', () {
    final scripts = Directory('scripts')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sh'))
        .toList();
    expect(scripts, isNotEmpty);
    for (final script in scripts) {
      final result = Process.runSync('bash', ['-n', script.path]);
      expect(result.exitCode, 0,
          reason: '${script.path} failed bash -n:\n${result.stderr}');
    }
  });

  test('release_android.sh bootstraps tools for both release machines', () {
    final body = File('scripts/release_android.sh').readAsStringSync();
    // Mac needs Homebrew flutter and a JDK for keytool; the VPS uses
    // /opt/flutter. A missing branch means releases break on that machine.
    expect(body, contains('Darwin'));
    expect(body, contains('JAVA_HOME'));
    expect(body, contains('/opt/homebrew/bin'));
    expect(body, contains('/opt/flutter/bin'));
  });
}
