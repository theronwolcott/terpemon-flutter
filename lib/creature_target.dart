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
  // We call this function when they click the catch button, passing back the current creature
  final Function(Creature) catchCallback;
  const CreatureTarget({super.key, required this.catchCallback});

  @override
  State<CreatureTarget> createState() => _CreatureTargetState();
}

class _CreatureTargetState extends State<CreatureTarget> {
  // Hold left to right offset and compass heading as they change
  double previousOffsetX = 0;
  double compassHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    // Update compassHeading with current heading while widget is open
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
    // Is catch button visible or not
    bool visible = false;
    // Rebuild if location or creatures change
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    NearestCreature nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    double distance = nearestCreature.distance;
    // Only show at all if within 250 meters
    if (distance > 250) {
      // Invisible box
      return SizedBox(
        height: 10,
        width: 10,
      );
    }
    // Start as full size
    double scale = 1.0;
    // If further than 100m, make him tiny
    if (distance > 100) {
      scale = 0.2;
    } else if (distance >= 10) {
      // Gradually scale him up from 0.2 to 1.0 scale from 100m -> 10m
      scale = 1.0 - ((distance - 10) / 90) * 0.8;
    }

    // double compassHeading = locationState.currentPosition?.heading ?? 0;
    double creatureBearing = nearestCreature.bearing;
    // debugPrint("creatureBearing: $creatureBearing");
    // Combining the compass heading and nearest creature bearing to find out what
    // direction the creature is relative to where we're facing
    double creatureHeading = -(compassHeading - creatureBearing);
    if (creatureHeading > 180) creatureHeading -= 360;
    if (creatureHeading < -180) creatureHeading += 360;

    int span = 15;
    // Figure out how many degrees we want to show on camera
    double offsetX = creatureHeading / span / 2;

    // debugPrint("$creatureHeading; $offsetX");

    // On screen is anywhere between -1 and 1 based on animationOffset
    // We want to show it only in the middle 20% of the screen
    // And, if he is within 25m, we can show the button
    if (offsetX > -0.2 && offsetX < 0.2 && distance < 25) {
      visible = true;
    } else {
      visible = false;
    }

    // If there isn't a nearest creature for some reason
    if (nearestCreature.creature == null) {
      return const SizedBox(height: 150, width: 150);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The creature actually exists here
        SizedBox(
          //  The whole size of the screen
          width: MediaQuery.of(context).size.width,
          height: 300,
          // Flutter animation control that animates from one point to another
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
              // print("Catch");
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
