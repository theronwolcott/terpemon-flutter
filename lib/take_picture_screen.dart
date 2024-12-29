import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/location_state.dart';
import 'package:terpiez/test.dart';

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

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  Future<void> handleCatch(Creature creature) async {
    print("handleCatch()");
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await _controller.takePicture();

      if (!context.mounted) return;

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
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          // child: WeatherScene.sunset.sceneWidget),
          child: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: _controller.value.previewSize!
                        .height, // Swap width and height for rotation
                    width: _controller.value.previewSize!.width,

                    child: CameraPreview(_controller),
                  ),
                );
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
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
