import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/location_state.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:terpiez/nearest_creature.dart';
import 'package:terpiez/shaker_manager.dart';

class TerpemonMap extends StatelessWidget {
  TerpemonMap({super.key});
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var locationState = context.read<LocationState>();

    var currentPosition = locationState.currentPosition;
    var initialCenter = const LatLng(38.98615, -76.94306);
    if (currentPosition == null) {
      locationState.getCurrentPositionAsync().then((pos) => {
            _mapController.move(
                LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom)
          });
    }

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    List<Marker> markers = <Marker>[];
    for (var c in creatureState.wild) {
      markers.add(Marker(
        point: c.location,
        child: GestureDetector(
          onTap: () {
            // Handle the tap action
            // _onMarkerTap(context, c);
            creatureState.catchCreature(c);
          },
          child: Image.network(dotenv.env['API_ROOT']! + c.species.image),
        ),
        height: 80,
        width: 80,
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16,
        keepAlive: true,
        interactionOptions: const InteractionOptions(
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
                  color: const Color.fromARGB(150, 255, 255, 255),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          dotenv.env['API_ROOT']! +
                              nearestCreature.creature!.species.image,
                          height: 80,
                          width: 80,
                        ),
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
            const Spacer(),
            Builder(builder: (context) {
              if (nearestCreature.distance <= 10) {
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
                            content: Image.network(dotenv.env['API_ROOT']! +
                                caughtCreature.species.image),
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
                      child: Image.network(
                        dotenv.env['API_ROOT']! +
                            nearestCreature.creature!.species.image,
                        height: 45,
                        width: 45,
                      ),
                    ),
                    label: const Text(
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
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: FloatingActionButton(
              onPressed: () {
                locationState.getCurrentPositionAsync().then((pos) => {
                      _mapController.move(LatLng(pos.latitude, pos.longitude),
                          _mapController.camera.zoom)
                    });
              },
              child: Icon(Icons.my_location),
            ),
          ),
        ),
      ],
    );
  }
}
