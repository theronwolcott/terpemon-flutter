import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/nearest_creature.dart';
import 'package:terpiez/transparent_white_image_provider.dart';
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
  Duration duration = const Duration(milliseconds: 500);
  Curve curve = Curves.easeInOutQuad;

  @override
  Widget build(BuildContext context) {
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    CompassModel compassValues = getCompassValues(
        locationState.currentPosition?.heading ??
            widget.heading); // updates previousHeading
    turns = compassValues.turns;
    double compassSize = 200;
    double scale = 200 / 530;

    double creatureBearing = nearestCreature.bearing ?? 0.0;
    var angle = (90.0 - creatureBearing) % 360.0;
    double creatureX = 55 * cos(angle * pi / 180.0);
    double creatureY = 55 * sin(angle * pi / 180.0);

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
  }

  ///calculating compass turn from heading value
  getCompassValues(double heading) {
    double direction = heading;
    direction = direction < 0 ? (360 + direction) : direction;

    double diff = direction - previousHeading;
    if (diff.abs() > 180) {
      if (previousHeading > direction) {
        diff = 360 - (direction - previousHeading).abs();
      } else {
        diff = (360 - (previousHeading - direction).abs()).toDouble();
        diff = diff * -1;
      }
    }
    turns += (diff / 360);
    previousHeading = direction;
    return CompassModel(turns: turns, angle: heading);
  }
}

/// model to store the sensor value
class CompassModel {
  double turns;
  double angle;
  CompassModel({required this.turns, required this.angle});
}
