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

/* The entire main "finder" tab */

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
  // Making the camera work properly if it exists
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
    // Holds the frame of the camera when someone presses the catch button
    XFile? image;
    try {
      if (_controller != null) {
        // Ensure that the camera is initialized
        await _initializeControllerFuture;

        // Attempt to take a picture and get the file `image`
        // where it was saved
        image = await _controller!.takePicture();

        if (!context.mounted) return;
      }
      // If the picture was taken, display it on a new screen
      await Navigator.of(context).push(
        // Keeps track of back arrows and navigation and fills whole screen with widget
        MaterialPageRoute(
          // The actual CatchCreature widget
          builder: (context) => CatchCreature(
            image: image,
            creature: creature,
          ),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_controller != null)
          //
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // How big is the size (in pixels) of the camera preview
                final previewSize = _controller!.value.previewSize!;
                // The aspect ratio of the context (different for different phones)
                final deviceRatio = MediaQuery.of(context).size.aspectRatio;
                // Ratio of height to width of camera
                final previewRatio = previewSize.height / previewSize.width;

                // Make the camera fill the space entirely with no distortion
                return Transform.scale(
                  // Compare ratios and figure out how to modify the camera
                  scale: previewRatio > deviceRatio
                      ? previewRatio / deviceRatio
                      : deviceRatio / previewRatio,
                  child: Center(
                    // You can tell AspectRatio the ratio to enforce
                    child: AspectRatio(
                      aspectRatio: previewRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                );
              } else {
                // If the connectionState is not done yet
                return const Center(child: CircularProgressIndicator());
              }
            },
          )
        else
          // Just give the weather scene if there's no camera
          WeatherScene.sunset.sceneWidget,
        Center(
          child: Column(
            children: [
              // Take all space left over
              Expanded(
                // CreatureTarget widget on the camera
                child: CreatureTarget(
                  catchCallback: handleCatch,
                ),
              ),
              // Holds the compass
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
                        // The actual compass
                        child: Compass(heading: 0.0),
                      ),
                      // The nearest creature distance under compass
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

/* The words and or picture on the bottom of the compass */
class CompassCreatureDistance extends StatelessWidget {
  const CompassCreatureDistance({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Build every time these change we rebuild the widget
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
