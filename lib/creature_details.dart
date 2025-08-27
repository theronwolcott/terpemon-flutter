import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'creature.dart';

import 'animated_bouncing_creature.dart';

class CreatureDetails extends StatelessWidget {
  final CreatureSpecies species;
  final List<Captured> caught; // only the ones of this same species
  const CreatureDetails(
      {super.key, required this.species, required this.caught});

  @override
  Widget build(BuildContext context) {
    // var creatureState = context.watch<CreatureState>();
    // var caught = creatureState.caught
    //     .where((creature) => creature.species.id == species.id);
    List<LatLng>? points;
    LatLngBounds? bounds;
    List<Marker>? markers;

    if (caught.isNotEmpty) {
      points = caught.map((c) => c.creature.location).toList();
      // make map bounds from points, so all points are on the map
      bounds = LatLngBounds.fromPoints(points);
      // extend bounds so markers aren't right on the edge of the map
      bounds = LatLngBounds(
          LatLng(bounds.southWest.latitude - 0.005,
              bounds.southWest.longitude - 0.005),
          LatLng(bounds.northEast.latitude + 0.005,
              bounds.northEast.longitude + 0.005));

      markers = <Marker>[];
      for (var c in caught
          .where((captured) => captured.creature.species.id == species.id)) {
        markers.add(Marker(
          point: c.creature.location,
          child: Image.network(
            dotenv.env['API_ROOT']! + c.creature.species.image,
          ),
          // Image.file(File(species.thumbnailPath)),
          height: 80,
          width: 80,
        ));
      }
    }
    //return Text("${caught.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text(species.name),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: species.weather.sceneWidget,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: Column(
                children: [
                  Hero(
                    tag: species,
                    child: AnimatedBouncingCreature(
                      species: species,
                      size: 300,
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
                        if (points != null && bounds != null && markers != null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 400,
                              height: 400,
                              //child: Text("hi"),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCameraFit:
                                      CameraFit.bounds(bounds: bounds),
                                  //minZoom: 16,
                                  //initialCenter: LatLng(38.98615, -76.94306),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'dev.terpemon.app',
                                    subdomains: const ['a', 'b', 'c'],
                                    additionalOptions: const {
                                      'attribution':
                                          '© OpenStreetMap contributors, © CARTO',
                                    },
                                  ),
                                  MarkerLayer(markers: markers),
                                ],
                              ),
                            ),
                          ),
                        if (points != null && bounds != null && markers != null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 400,
                              child: ListView.builder(
                                shrinkWrap:
                                    true, // Allow ListView to take only the required space
                                physics:
                                    const NeverScrollableScrollPhysics(), // Prevent independent scrolling
                                itemCount: caught.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(caught[index].creature.name),
                                    subtitle: Text(
                                        DateFormat("MMMM d 'at' h:mma")
                                            .format(caught[index].timestamp)),
                                    leading: Image.network(
                                      dotenv.env['API_ROOT']! +
                                          caught[index].creature.species.image,
                                      height: 80,
                                      width: 80,
                                    ),
                                  );
                                },
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
