import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:rxdart/rxdart.dart';
import 'nearest_creature.dart';
import 'transparent_white_image_provider.dart';
import 'creature_state.dart';
import 'location_state.dart';

class Compass extends StatefulWidget {
  double heading;

  Compass({super.key, this.heading = 0.0});

  @override
  State<Compass> createState() => _CompassState();
}

class _CompassState extends State<Compass> {
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

    double creatureBearing = nearestCreature.bearing ?? 0.0;
    var angle = (90.0 - creatureBearing) % 360.0;
    double creatureX = 55 * cos(angle * pi / 180.0);
    double creatureY = 55 * sin(angle * pi / 180.0);

    return StreamBuilder<CompassEvent>(
        stream:
            FlutterCompass.events?.throttleTime(Duration(milliseconds: 100)),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   // Show a loading indicator while waiting for stream data
          //   return Center(child: CircularProgressIndicator());
          // }

          if (snapshot.hasError) {
            // Handle stream error gracefully
            return Center(child: Text("Compass data unavailable"));
          }

          double heading;

          if (snapshot.connectionState == ConnectionState.waiting) {
            heading = previousHeading;
          } else {
            heading = snapshot.data?.heading == null
                ? previousHeading
                : snapshot.data!.heading!;
          }
          CompassModel compassValues = getCompassValues(heading);
          turns = compassValues.turns;

          // debugPrint(heading.toString());

          return AnimatedRotation(
            turns: turns,
            duration: duration,
            curve: Curves.easeInOutQuad,
            child: Stack(
              children: [
                Image.asset('assets/compass/base.png'),
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
                if (nearestCreature.creature != null)
                  Positioned(
                    left: (creatureX + (compassSize / 2) - 35),
                    top: (-creatureY + (compassSize / 2) - 35),
                    child: AnimatedRotation(
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
    if (normalizedHeading < 0) normalizedHeading += 360;

    // Calculate the shortest angle difference
    double diff = normalizedHeading - previousHeading;
    if (diff > 180) {
      diff -= 360; // Crossed 360° clockwise
    } else if (diff < -180) {
      diff += 360; // Crossed 0° counter-clockwise
    }

    // Update total turns
    turns -= diff / 360;

    // Store the current heading as the previous heading
    previousHeading = normalizedHeading;

    return CompassModel(turns: turns, angle: normalizedHeading);
  }
}

/// model to store the sensor value
class CompassModel {
  double turns;
  double angle;
  CompassModel({required this.turns, required this.angle});
}
