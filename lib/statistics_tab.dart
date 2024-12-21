import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/api_service.dart';
import 'package:terpiez/compass.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/nearest_creature.dart';
import 'package:terpiez/user_state.dart';
import 'package:weather_animation/weather_animation.dart';

import 'creature.dart';
import 'location_state.dart';

class CreatureDistance {
  final Creature creature;
  final double distance;
  CreatureDistance(this.creature, this.distance);
}

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  Future<WeatherScene> fetchData() async {
    //await Future.delayed(Duration(seconds: 3));
    return WeatherScene.sunset;
  }

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var userState = context.watch<UserState>();
    var locationState = context.watch<LocationState>();

    NearestCreature nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    return Stack(children: [
      SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: FutureBuilder<WeatherScene>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Show loading
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return WeatherSceneWidget(
                  weatherScene: snapshot.data!,
                );
              }
            }),
      ),
      Padding(
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
              height: 200,
              width: 200,
              child: Compass(heading: 0.0),
            ),
          ],
        )),
      ),
    ]);
  }
}
