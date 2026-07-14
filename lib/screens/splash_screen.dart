import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'home_screen.dart';

/// Animated loading screen shown on launch. A monster emoji rapidly "evolves"
/// through a few stages while the title shimmers in, then we transition to the
/// main [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // A quick evolution montage for the loading animation.
  static const List<String> _montage = <String>['🥚', '🐣', '🦎', '🐉', '🌌'];

  int _index = 0;
  Timer? _cycleTimer;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    // Cycle the emoji every ~450ms for a lively "growing" effect.
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _montage.length);
    });
    // Move on to the app after the intro plays.
    _navTimer = Timer(const Duration(milliseconds: 2600), _goToApp);
  }

  void _goToApp() {
    _cycleTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 130,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    _montage[_index],
                    key: ValueKey<int>(_index),
                    style: const TextStyle(fontSize: 110),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                    'Task Monster',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .shimmer(
                    delay: 400.ms,
                    duration: 1400.ms,
                    color: Colors.amber,
                  ),
              const SizedBox(height: 8),
              Text(
                'Evolve by doing.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 700.ms),
              const SizedBox(height: 40),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(minHeight: 6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
