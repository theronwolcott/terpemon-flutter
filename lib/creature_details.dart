import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature.dart';
import 'package:terpiez/transparent_white_image_provider.dart';
import 'package:weather_animation/weather_animation.dart';

import 'creature_state.dart';

class CreatureDetails extends StatelessWidget {
  final CreatureSpecies species;
  const CreatureDetails({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var caught = creatureState.caught
        .where((creature) => creature.species.id == species.id);

    var points = caught.map((sp) => sp.location).toList();
    if (points.length == 1) {
      points
          .add(LatLng(points[0].latitude + 0.001, points[0].longitude + 0.001));
      points
          .add(LatLng(points[0].latitude - 0.001, points[0].longitude - 0.001));
    }
    var bounds = LatLngBounds.fromPoints(points);

    List<Marker> markers = <Marker>[];
    for (var c in caught) {
      markers.add(Marker(
        point: c.location,
        child: Image(
          image: TransparentWhiteImageProvider(species.thumbnailPath),
        ),
        // Image.file(File(species.thumbnailPath)),
        height: 80,
        width: 80,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(species.name),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: WeatherSceneWidget(
              weatherScene: species.weather,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: Column(
                children: [
                  Hero(
                    tag: species,
                    child: Image(
                      image: TransparentWhiteImageProvider(species.imagePath),
                      width: 300,
                    ),
                    // Image.file(
                    //   File(species.imagePath),
                    //   width: 300,
                    // ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(species.description),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                  'Avuncularity: ${species.stats.avuncularity}'),
                              Text('Destrucity: ${species.stats.destrucity}'),
                              Text('Panache: ${species.stats.panache}'),
                              Text('Spiciness: ${species.stats.spiciness}'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 400,
                            height: 400,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCameraFit:
                                    CameraFit.bounds(bounds: bounds),
                                minZoom: 16,
                                //initialCenter: LatLng(38.98615, -76.94306),
                                //initialZoom: 15,
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(markers: markers),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ),
          )
        ],
      ),
    );
  }
}
