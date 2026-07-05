import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/monster_state.dart';
import 'models/parent_lock_state.dart';
import 'screens/splash_screen.dart';
import 'services/analytics.dart';
import 'services/update_checker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Analytics is non-critical: if Firebase fails to initialise the app still
  // runs, just without event collection.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    analytics.attach(FirebaseAnalytics.instance);
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  final monster = MonsterState();
  final parentLock = ParentLockState();
  // Load persisted progress before the first frame so the UI opens in the
  // correct state.
  await monster.load();
  await parentLock.load();

  // Poll version.json so long-lived tabs learn about new deploys (web only).
  final updateChecker = UpdateChecker()..start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MonsterState>.value(value: monster),
        ChangeNotifierProvider<ParentLockState>.value(value: parentLock),
        ChangeNotifierProvider<UpdateChecker>.value(value: updateChecker),
      ],
      child: const TaskMonsterApp(),
    ),
  );
}

class TaskMonsterApp extends StatelessWidget {
  const TaskMonsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Monster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
      ),
      navigatorObservers: <NavigatorObserver>[
        if (analytics.observer != null) analytics.observer!,
      ],
      home: const SplashScreen(),
    );
  }
}
