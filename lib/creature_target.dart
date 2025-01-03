import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import 'animated_bouncing_creature.dart';
import 'creature.dart';
import 'creature_state.dart';
import 'location_state.dart';
import 'nearest_creature.dart';

class CreatureTarget extends StatefulWidget {
  final Function(Creature) catchCallback;
  const CreatureTarget({super.key, required this.catchCallback});

  @override
  State<CreatureTarget> createState() => _CreatureTargetState();
}

class _CreatureTargetState extends State<CreatureTarget> {
  double previousOffsetX = 0;
  double compassHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        if (mounted) {
          compassHeading = event.heading ?? 0;
        }
      });
    });
  }

  @override
  void dispose() {
    // Cancel the compass subscription to avoid memory leaks
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duration duration = const Duration(milliseconds: 300);
    bool visible = false;
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    NearestCreature nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    double distance = nearestCreature.distance;
    if (distance > 250) {
      return SizedBox(
        height: 10,
        width: 10,
      );
    }
    double scale = 1.0;
    if (distance > 100) {
      scale = 0.2;
    } else if (distance >= 10) {
      scale = 1.0 - ((distance - 10) / 90) * 0.8;
    }

    // double compassHeading = locationState.currentPosition?.heading ?? 0;
    double creatureBearing = nearestCreature.bearing;
    // debugPrint("creatureBearing: $creatureBearing");
    double creatureHeading = -(compassHeading - creatureBearing);
    if (creatureHeading > 180) creatureHeading -= 360;
    if (creatureHeading < -180) creatureHeading += 360;

    int span = 15;
    double offsetX = creatureHeading / span / 2;

    // debugPrint("$creatureHeading; $offsetX");

    if (offsetX > -0.2 && offsetX < 0.2 && distance < 25) {
      visible = true;
    } else {
      visible = false;
    }

    if (nearestCreature.creature == null) {
      return const SizedBox(height: 150, width: 150);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 300,
          child: TweenAnimationBuilder(
            tween: Tween<double>(
              begin: previousOffsetX,
              end: offsetX,
            ),
            duration: Duration(
                milliseconds: (300 * (previousOffsetX - offsetX).abs())
                    .round()
                    .clamp(100, 500)),
            onEnd: () {
              previousOffsetX = offsetX; // Update for next animation
            },
            builder: (context, double animatedOffset, child) => Transform(
              alignment: Alignment.bottomCenter, // Scale from the center
              transform: Matrix4.identity()
                ..scale(scale, scale, 1.0)
                ..translate(
                    animatedOffset * MediaQuery.of(context).size.width / scale),
              child: Center(
                child: Hero(
                  tag: nearestCreature.creature!.species,
                  child: AnimatedBouncingCreature(
                    species: nearestCreature.creature!.species,
                    size: 300,
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: visible,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: ElevatedButton(
            child: Text("Catch ${nearestCreature.creature!.species.name}"),
            onPressed: () {
              print("Catch");
              widget.catchCallback(nearestCreature.creature!);
            },
          ),
        ),
        const SizedBox(
          height: 30,
        )
      ],
    );
  }
}
