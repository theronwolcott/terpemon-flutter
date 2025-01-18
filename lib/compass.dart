import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:rxdart/rxdart.dart';
import 'nearest_creature.dart';
import 'creature_state.dart';
import 'location_state.dart';

class Compass extends StatefulWidget {
  double heading;

  Compass({super.key, this.heading = 0.0});

  @override
  State<Compass> createState() => _CompassState();
}

class _CompassState extends State<Compass> {
  // We track "turns" so the compass doesn't go back on itself
  double turns = 0;
  double previousHeading = 0;
  Duration duration = const Duration(milliseconds: 100);
  Curve curve = Curves.easeInOutQuad;

  @override
  Widget build(BuildContext context) {
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    // CompassModel compassValues = getCompassValues(
    //     locationState.currentPosition?.heading ??
    //         widget.heading); // updates previousHeading
    // turns = compassValues.turns;
    double compassSize = 200;
    double scale = 200 / 530;

    // The nearest creature's bearing from north (-180 -> 180)
    double creatureBearing = nearestCreature.bearing ?? 0.0;
    // This is how we position the creature on the compass
    // 90 because we need to have our circle start on the right
    var angle = (90.0 - creatureBearing) % 360.0;
    /* These are how we figure out the creature's position on the compass.
    Doing angle * pi / 180 is how we convert to radians. We multiply by 55 because 
    we want the creature 55 pixels off the center (in the same directions) */
    double creatureX = 55 * cos(angle * pi / 180.0);
    double creatureY = 55 * sin(angle * pi / 180.0);

    return StreamBuilder<CompassEvent>(
        // We want to rebuild based on an event stream
        stream:
            // We only want one event every tenth of a second at most
            FlutterCompass.events?.throttleTime(Duration(milliseconds: 100)),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Handle stream error gracefully
            return Center(child: Text("Compass data unavailable"));
          }

          double heading;

          // If we are waiting for the next heading still, we just keep whatever
          // one we currently have
          if (snapshot.connectionState == ConnectionState.waiting) {
            heading = previousHeading;
          } else {
            // Protect against nulls
            heading = snapshot.data?.heading == null
                ? previousHeading
                : snapshot.data!.heading!;
          }
          // Get the turns and angle for the current heading
          CompassModel compassValues = getCompassValues(heading);
          turns = compassValues.turns;

          return AnimatedRotation(
            turns: turns,
            duration: duration,
            curve: Curves.easeInOutQuad,
            // The actual thing we are rotating
            child: Stack(
              children: [
                // Compass rose with arrows
                Image.asset('assets/compass/base.png'),
                // NSEW rotate the opposite way so they stay upright
                Positioned(
                  left: 214 * scale,
                  top: 22 * scale,
                  child: AnimatedRotation(
                    turns: -turns,
                    duration: duration,
                    curve: curve,
                    child: Image(
                      image: const AssetImage('assets/compass/n.png'),
                      height: 76 * scale,
                    ),
                  ),
                ),
                Positioned(
                  left: 428 * scale,
                  top: 227 * scale,
                  child: AnimatedRotation(
                    turns: -turns,
                    duration: duration,
                    curve: curve,
                    child: Image(
                      image: const AssetImage('assets/compass/e.png'),
                      height: 76 * scale,
                    ),
                  ),
                ),
                Positioned(
                  left: 214 * scale,
                  top: 444 * scale,
                  child: AnimatedRotation(
                    turns: -turns,
                    duration: duration,
                    curve: curve,
                    child: Image(
                      image: const AssetImage('assets/compass/s.png'),
                      height: 76 * scale,
                    ),
                  ),
                ),
                Positioned(
                  left: 0 * scale,
                  top: 227 * scale,
                  child: AnimatedRotation(
                    turns: -turns,
                    duration: duration,
                    curve: curve,
                    child: Image(
                      image: const AssetImage('assets/compass/w.png'),
                      height: 76 * scale,
                    ),
                  ),
                ),
                // The creature on the compass
                if (nearestCreature.creature != null)
                  Positioned(
                    /* Because we are on a stack, our position is relative to the top left corner of the stack,
                    not the compass. First, we add half the compass size to move from the left to the center.
                    Then, we subtract 35 because the creature size is 70. We the image of our creature to be
                    centered. Now that a creature should be centered at the absolut center of the compass. Then 
                    we just add the x of our creature and subtract the y (because we start at the top).*/
                    left: (creatureX + (compassSize / 2) - 35),
                    top: (-creatureY + (compassSize / 2) - 35),
                    child: AnimatedRotation(
                      // To stay upright
                      turns: -turns,
                      duration: duration,
                      curve: curve,
                      child: Image.network(
                        dotenv.env['API_ROOT']! +
                            nearestCreature.creature!.species.image,
                        height: 70,
                      ),
                    ),
                  ),
              ],
            ),
          );
        });
  }

  CompassModel getCompassValues(double heading) {
    // Normalize heading to 0-360° range
    double normalizedHeading = heading % 360;
    while (normalizedHeading < 0) {
      normalizedHeading += 360;
    }
    // Calculate the shortest angle difference
    double diff = normalizedHeading - previousHeading;
    if (diff > 180) {
      diff -= 360; // Crossed 360° clockwise
    } else if (diff < -180) {
      diff += 360; // Crossed 0° counter-clockwise
    }

    // Update total turns because turns are based on 1 instead of 360
    turns -= diff / 360;

    // Store the current heading as the previous heading
    previousHeading = normalizedHeading;

    return CompassModel(turns: turns, angle: normalizedHeading);
  }
}

// model to store the sensor value
class CompassModel {
  double turns;
  double angle;
  CompassModel({required this.turns, required this.angle});
}
