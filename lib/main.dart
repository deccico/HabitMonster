import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/monster_state.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final monster = MonsterState();
  // Load persisted progress before the first frame so the UI opens in the
  // correct state (including any remaining cooldown after an app restart).
  await monster.load();

  runApp(
    ChangeNotifierProvider<MonsterState>.value(
      value: monster,
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
      home: const SplashScreen(),
    );
  }
}
