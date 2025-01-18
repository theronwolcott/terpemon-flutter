import 'package:Terpemon/creature.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'catch_creature.dart';
import 'creature_state.dart';
import 'location_state.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'nearest_creature.dart';

class TerpemonMap extends StatefulWidget {
  TerpemonMap({super.key});

  @override
  State<TerpemonMap> createState() => _TerpemonMapState();
}

class _TerpemonMapState extends State<TerpemonMap> {
  // Part of flutter_map
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // Initialize MapController here
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // When you tap on the nearest creature at the top, we want the screen to center on it
  void handleTapNearestCreature(Creature creature) {
    _mapController.move(
        // Move the map to put the creature at the center of it (keeping the zoom level)
        LatLng(creature.location.latitude, creature.location.longitude),
        _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    // We don't have to watch because the map doesn't handle our location beyond initally
    var locationState = context.read<LocationState>();

    var currentPosition = locationState.currentPosition;
    // Set center of map to current position
    var initialCenter = currentPosition == null
        ? const LatLng(38.98615, -76.94306)
        : LatLng(currentPosition.latitude, currentPosition.longitude);
    /* If we don't get a location synchronously, we do it asynchronously. 
    We can't center the map initially because we've already created it but we can
    move to our location once we get it asynchronously*/
    if (currentPosition == null) {
      locationState.getCurrentPositionAsync().then((pos) => {
            _mapController.move(
                LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom)
          });
    }
    // List of markers for our creatures
    List<Marker> markers = <Marker>[];
    for (var c in creatureState.wild) {
      markers.add(Marker(
        point: c.location,
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            await Navigator.of(context).push(
              MaterialPageRoute(
                // Right now for testing purposes you can tap on a creature to go to the CatchCreature screen
                builder: (context) => CatchCreature(
                  creature: c,
                ),
              ),
            );
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
        // Blue dot for our location on the map
        CurrentLocationLayer(),
        Column(
          children: [
            // The bar across the top with the nearest creature and its distance
            MapNearestCreature(
              callback: handleTapNearestCreature,
            ),
            const Spacer(),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            // Handling the button in the bottom right to center the map on our location if we want
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

// The widget for the bar across the top
class MapNearestCreature extends StatelessWidget {
  final Function(Creature)? callback;
  const MapNearestCreature({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    // Rebuild every time either our location changes or we have a new nearest creature
    var creatureState = context.watch<CreatureState>();
    var locationState = context.watch<LocationState>();

    // If we don't have a location just do nothing there
    var currentPosition = locationState.currentPosition;
    if (currentPosition == null) {
      return Container();
    }

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    return Builder(builder: (context) {
      if (nearestCreature.creature != null) {
        return Container(
          color: const Color.fromARGB(150, 255, 255, 255),
          child: Center(
            child: GestureDetector(
              onTap: () => {
                // We want to center on the nearest creature, we have already sent in that method
                if (callback != null && nearestCreature.creature != null)
                  {callback!(nearestCreature.creature!)}
              },
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
          ),
        );
      }
      // If we don't have a nearest creature for some reason do nothing
      return Container();
    });
  }
}
