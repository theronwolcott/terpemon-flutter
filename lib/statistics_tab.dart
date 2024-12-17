import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/compass.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/nearest_creature.dart';
import 'package:terpiez/user_state.dart';

import 'creature.dart';
import 'location_state.dart';

class CreatureDistance {
  final Creature creature;
  final double distance;
  CreatureDistance(this.creature, this.distance);
}

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var userState = context.watch<UserState>();
    var locationState = context.watch<LocationState>();

    NearestCreature nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
          child: Column(
        children: [
          const Text(
            'Statistics',
            textScaler: TextScaler.linear(2.5),
          ),
          const Text(''),
          Text(
            'Terpiez Captured: ${creatureState.caught.length}',
            textScaler: const TextScaler.linear(1.5),
          ),
          Text(
            'Days Played: ${userState.playtime}',
            textScaler: const TextScaler.linear(1.5),
          ),
          Text('ID: ${userState.id}'),
          Builder(
            builder: (context) {
              if (locationState.currentPosition != null &&
                  nearestCreature.creature != null) {
                return Text(
                  '${nearestCreature.creature!.species.name}: ${nearestCreature.distance.toStringAsFixed(0)} meters',
                  textScaler: const TextScaler.linear(1.5),
                );
              } else if (nearestCreature.creature != null) {
                return Text(
                  'No wild creatures',
                  textScaler: const TextScaler.linear(1.5),
                );
              } else {
                return Text(
                  'Waiting for location',
                  textScaler: const TextScaler.linear(1.5),
                );
              }
            },
          ),
          SizedBox(
            child: Compass(heading: 0.0),
            height: 200,
            width: 200,
          ),
        ],
      )),
    );
  }
}
