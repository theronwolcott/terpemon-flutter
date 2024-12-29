import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'creature.dart';

class AnimatedBouncingCreature extends StatefulWidget {
  const AnimatedBouncingCreature({
    super.key,
    required this.species,
    this.size = 200,
  });

  final CreatureSpecies species;
  final double size;

  @override
  State<AnimatedBouncingCreature> createState() =>
      _AnimatedBouncingCreatureState();
}

class _AnimatedBouncingCreatureState extends State<AnimatedBouncingCreature>
    with SingleTickerProviderStateMixin {
  Key _key = UniqueKey();

  void _restartAnimation() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      key: _key,
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 2 * pi),
      builder: (BuildContext context, double value, Widget? child) {
        // Horizontal bounce (slow)
        double dx = sin(value) * 10;

        // Vertical bounce (twice as fast)
        double dy = sin(value * 2) * 10;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: SimpleShadow(
            opacity: 0.25,
            offset: const Offset(5, 5),
            sigma: 5,
            child: Image.network(
              dotenv.env['API_ROOT']! + widget.species.image,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
      onEnd: () {
        _restartAnimation(); // Restart animation
      },
    );
  }
}
