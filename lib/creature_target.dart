import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:terpiez/animated_bouncing_creature.dart';
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

  @override
  Widget build(BuildContext context) {
    // Duration duration = const Duration(milliseconds: 300);
    bool visible = false;
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    NearestCreature nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    double distance = nearestCreature.distance;
    double scale = 1.0;
    if (distance > 100) {
      scale = 0.1;
    } else if (scale > 10) {
      scale = (110 - distance) / 100.0;
    }
    scale = 1.0;

    double compassHeading = locationState.currentPosition?.heading ?? 0;
    double creatureBearing = nearestCreature.bearing;
    double creatureHeading = (compassHeading + creatureBearing);
    if (creatureHeading > 180) creatureHeading -= 360;

    int span = 45;
    double offsetX = creatureHeading / span / 2;

    if (offsetX > -0.2 && offsetX < 0.2) {
      //} && distance < 25) {
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
          height: 250,
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
              transform: Matrix4.identity()
                ..scale(scale)
                ..translate(animatedOffset * MediaQuery.of(context).size.width),
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
          visible: true, //visible,
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
