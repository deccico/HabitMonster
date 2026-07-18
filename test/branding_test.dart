import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app is published at https://task-monster.ink as "Task Monster".
/// These tests pin the branding and the hosted privacy policy so a stray
/// rename (or a regenerated platform file) can't ship inconsistent names.
void main() {
  group('Task Monster branding', () {
    test('pubspec uses the task_monster package name and asset', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, startsWith('name: task_monster'));
      expect(pubspec, contains('assets/images/task-monster.png'));
      expect(pubspec, isNot(contains('habit_monster')));
    });

    test('web page is titled Task Monster', () {
      final index = File('web/index.html').readAsStringSync();
      expect(index, contains('<title>Task Monster</title>'));
      expect(index, isNot(contains('habit_monster')));
    });

    test('PWA manifest is named Task Monster', () {
      final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(manifest['name'], 'Task Monster');
      expect(manifest['short_name'], 'Task Monster');
    });

    test('Android launcher label and application id match the brand', () {
      final androidManifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(androidManifest, contains('android:label="Task Monster"'));
      final gradle =
          File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "com.darumatic.task_monster"'));
      expect(gradle, contains('namespace = "com.darumatic.task_monster"'));
    });

    test('CI check targets the renamed TaskMonster GitHub repo', () {
      final checkCi = File('scripts/check_ci.sh').readAsStringSync();
      expect(checkCi, contains('repo="deccico/TaskMonster"'));
    });

    test('release script deploys with the project-scoped credential', () {
      final release = File('scripts/release.sh').readAsStringSync();
      expect(
        release,
        contains('GOOGLE_APPLICATION_CREDENTIALS='
            '"\$HOME/.secrets/task-monster-firebase.json"'),
      );
    });

    test('privacy policy page ships with the web app', () {
      final privacy = File('web/privacy.html').readAsStringSync();
      expect(privacy, contains('Task Monster — Privacy Policy'));
      expect(privacy, contains('hello@darumatic.com'));
      expect(privacy, isNot(contains('Habit Monster')));
    });
  });
}
