import 'dart:io';

import 'package:flutter/material.dart';
import 'catch_creature.dart';
import 'compass.dart';
import 'creature_target.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:camera/camera.dart';
import 'camera_state.dart';
import 'creature.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> with WidgetsBindingObserver {
  final CameraState _cameraState = CameraState(); // Singleton instance
  late Future<CameraController?> _cameraFuture; // Store camera future

  @override
  void initState() {
    print("MainTab.initState()");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraFuture = _cameraState.getController(); // Initialize camera
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print("MainTab.dispose()");
    // Optional: Dispose if needed for cleanup (depends on singleton use)
    _cameraState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release the camera resource when app is backgrounded
      _cameraState.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize camera when app resumes
      setState(() {
        _cameraFuture = _cameraState.getController(); // Retry initialization
      });
    }
  }

  Future<void> handleCatch(Creature creature) async {
    print("handleCatch()");
    try {
      final controller = await _cameraFuture;
      final image = await controller!.takePicture();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CatchCreature(
            image: image,
            creature: creature,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return Stack(children: [
      SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        // child: WeatherScene.sunset.sceneWidget),
        child: FutureBuilder<CameraController?>(
            future: _cameraFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator()); // Loading
              } else if (snapshot.hasError || !snapshot.hasData) {
                return WeatherScene.sunset.sceneWidget; // Error
              }
              final controller = snapshot.data!;
              return FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  height: controller.value.previewSize!
                      .height, // Swap width and height for rotation
                  width: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              );
            }),
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
                child: Container(
                  height: 200,
                  width: 200,
                  child: Transform(
                    // https://blog.codemagic.io/flutter-matrix4-perspective-transformations/
                    transform: Matrix4.identity()
                    //..setEntry(3, 1, -0.002)
                    //..setEntry(1, 1, 0.85),
                    ,
                    alignment: FractionalOffset.center,
                    child: Compass(heading: 0.0),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    ]);
  }
}
