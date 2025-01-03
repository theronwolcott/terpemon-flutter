import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_animation/weather_animation.dart';
import 'location_state.dart';

import 'catch_creature.dart';
import 'compass.dart';
import 'creature.dart';
import 'creature_state.dart';
import 'creature_target.dart';
import 'nearest_creature.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription? camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController? _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    if (widget.camera != null) {
      _controller = CameraController(
        widget.camera!,
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller!.initialize();
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> handleCatch(Creature creature) async {
    // print("handleCatch()");
    XFile? image;
    try {
      if (_controller != null) {
        // Ensure that the camera is initialized.
        await _initializeControllerFuture;

        // Attempt to take a picture and get the file `image`
        // where it was saved.
        image = await _controller!.takePicture();

        if (!context.mounted) return;
      }
      // If the picture was taken, display it on a new screen.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CatchCreature(
            image: image,
            creature: creature,
          ),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_controller != null)
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final previewSize = _controller!.value.previewSize!;
                final deviceRatio = MediaQuery.of(context).size.aspectRatio;
                final previewRatio = previewSize.height / previewSize.width;

                return Transform.scale(
                  scale: previewRatio > deviceRatio
                      ? previewRatio / deviceRatio
                      : deviceRatio / previewRatio,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: previewRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          )
        else
          WeatherScene.sunset.sceneWidget,
        // Container(color: Colors.white), // White background when no camera.

        Center(
          child: Column(
            children: [
              Expanded(
                child: CreatureTarget(
                  catchCallback: handleCatch,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: new Color.fromRGBO(255, 255, 255, 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Compass(heading: 0.0),
                      ),
                      CompassCreatureDistance(),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ],
    );
  }
}

class CompassCreatureDistance extends StatelessWidget {
  const CompassCreatureDistance({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);
    if (nearestCreature.creature == null) {
      return const Text("Searching...");
    } else {
      return Text(
        "${nearestCreature.distance.round()}m - ${nearestCreature.creature!.species.name}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }
}
