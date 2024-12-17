import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/location_state.dart';
import 'package:terpiez/main.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:terpiez/nearest_creature.dart';
import 'package:terpiez/shaker_manager.dart';
import 'package:terpiez/transparent_white_image_provider.dart';

class TerpiezMap extends StatelessWidget {
  TerpiezMap({super.key});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var locationState = context.watch<LocationState>();

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    List<Marker> markers = <Marker>[];
    if (nearestCreature.creature != null) {
      markers.add(Marker(
        point: nearestCreature.creature!.location,
        child: Image(
            image: TransparentWhiteImageProvider(
                nearestCreature.creature!.species.thumbnailPath)),
        // Image.file(File(nearestCreature.creature!.species.thumbnailPath)),
        height: 80,
        width: 80,
      ));
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(38.98615, -76.94306),
        initialZoom: 15,
        keepAlive: true,
        interactionOptions: InteractionOptions(
          enableMultiFingerGestureRace: true,
          flags: InteractiveFlag.doubleTapDragZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(markers: markers),
        CurrentLocationLayer(),
        Column(
          children: [
            Builder(builder: (context) {
              if (nearestCreature.creature != null) {
                return Container(
                  color: Color.fromARGB(150, 255, 255, 255),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                            image: TransparentWhiteImageProvider(nearestCreature
                                .creature!.species.thumbnailPath)),
                        // Image.file(
                        //   File(nearestCreature.creature!.species.thumbnailPath),
                        //   height: 40,
                        //   width: 40,
                        // ),
                        Text(
                          '${nearestCreature.creature!.species.name}: ${nearestCreature.distance.toStringAsFixed(0)}m',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Container();
            }),
            Spacer(),
            Builder(builder: (context) {
              if (nearestCreature.distance != null &&
                  nearestCreature.distance <= 10) {
                ShakeManager.getInstance().start(() {
                  if (nearestCreature.creature != null &&
                      ShakeManager.getInstance().didShake) {
                    var caughtCreature = nearestCreature.creature!;
                    creatureState.catchCreature(caughtCreature);
                    AudioPlayer().play(AssetSource('sounds/pop.mp3'));
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              title:
                                  Text("Caught ${caughtCreature.species.name}"),
                              content: Image(
                                image: TransparentWhiteImageProvider(
                                    caughtCreature.species.imagePath),
                              )
                              // Image.file(
                              //     File(caughtCreature.species.imagePath))
                              );
                        });
                  }
                  ShakeManager.getInstance().stop();
                });
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: ElevatedButton.icon(
                    icon: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image(
                        image: TransparentWhiteImageProvider(
                            nearestCreature.creature!.species.thumbnailPath),
                        //       )Image.file(
                        // File(nearestCreature.creature!.species.thumbnailPath),
                        height: 45,
                        width: 45,
                      ),
                    ),
                    label: Text(
                      'Shake to catch!',
                      textScaler: TextScaler.linear(1.8),
                    ),
                    onPressed: () {
                      // try {
                      //   await AudioPlayer().play(AssetSource('sounds/pop.mp3'));
                      // } catch (e) {
                      //   print("Error with sound: $e");
                      // }
                      return;
                    },
                  ),
                );
              }
              ShakeManager.getInstance().stop();
              return Container();
            }),
          ],
        ),
      ],
    );
  }
}
