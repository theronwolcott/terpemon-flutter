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

  void handleTapNearestCreature(Creature creature) {
    _mapController.move(
        LatLng(creature.location.latitude, creature.location.longitude),
        _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var locationState = context.read<LocationState>();

    var currentPosition = locationState.currentPosition;
    var initialCenter = currentPosition == null
        ? const LatLng(38.98615, -76.94306)
        : LatLng(currentPosition.latitude, currentPosition.longitude);
    if (currentPosition == null) {
      locationState.getCurrentPositionAsync().then((pos) => {
            _mapController.move(
                LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom)
          });
    }

    List<Marker> markers = <Marker>[];
    for (var c in creatureState.wild) {
      markers.add(Marker(
        point: c.location,
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            await Navigator.of(context).push(
              MaterialPageRoute(
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
        CurrentLocationLayer(),
        Column(
          children: [
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

class MapNearestCreature extends StatelessWidget {
  final Function(Creature)? callback;
  const MapNearestCreature({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var locationState = context.watch<LocationState>();

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
      return Container();
    });
  }
}
