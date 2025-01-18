import 'dart:async';
import 'dart:math';

import 'package:Terpemon/creature_state.dart';
import 'package:Terpemon/nearest_creature.dart';
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vector_math/vector_math_64.dart';

import 'creature.dart';
import 'location_state.dart';

/* Key plugin is ARKit plugin which is specific for ios. 
This is basically a wrapper of the ARKit. Have to refactor
to use different ar stuff to work on android too */

class AR extends StatefulWidget {
  const AR({super.key});

  @override
  ARState createState() => ARState();
}

class ARState extends State<AR> {
  late ARKitController arkitController;
  // Nodes are things within the ar space that are anchored on a position in space
  final List<ARKitNode> nodes = [];
  late StreamSubscription<CompassEvent>? _compassSubscription;
  double? compassHeading;
  LocationState locationState = LocationState();
  Position? position;
  CreatureState creatureState = CreatureState();
  Creature? currentCreature;
  Timer? _currentTimer;

  @override
  void initState() {
    debugPrint("initState()");
    super.initState();
    // How we subscribe to the compass events, one event 0.5 seconds
    _compassSubscription = FlutterCompass.events
        ?.throttleTime(Duration(milliseconds: 500))
        .listen((event) {
      if (event.heading != null) {
        // Update our heading with what the compass gives us
        compassHeading = event.heading;
        evaluate("_compassSubscription");
      }
    });
    /* We addListener instead of using .watch() because we actually don't want 
    to rebuild this widget every time they change. Instead, we just want to 
    execute some code within the current widget so we have direct control over
    what happens, rather than giving it up to the rebuild method. This is similar
    to on the map, when we call .move() rather than rebuilding the entire map
    centered somewhere else. It wouldn't make sense to rebuild */
    creatureState.addListener(handleCreatureStateChange);
    locationState.addListener(handleLocationStateChange);
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    creatureState.removeListener(handleCreatureStateChange);
    locationState.removeListener(handleLocationStateChange);
    arkitController.dispose();
    super.dispose();
  }

  Future<ImageProvider<Object>> captureSnapshot(bool showNodes) async {
    // This captures the snapshot
    // Removing nodes gets rid of creatures so we have the blank picture
    if (!showNodes) {
      for (var node in nodes) {
        arkitController.remove(node.name);
      }
    }
    // Take the actual picture of EXACTLY what is on the screen (why we remove)
    // We could get a picture of the creature if we wanted to
    var snap = arkitController.snapshot();
    // Put the creature back after we take snap
    if (!showNodes) {
      for (var node in nodes) {
        arkitController.add(node);
      }
    }
    return snap;
  }

  void handleCreatureStateChange() async {
    // nearestCreature.creature!.location =
    //     LatLng(39.01246790748515, -77.11042471782032);
    evaluate("handleCreatureStateChange");
  }

  void handleLocationStateChange() {
    position = locationState.currentPosition!;
    evaluate("handleLocationStateChange");
  }

  /* Evaluate the creature, location and compass and decide whether or not to
  add a creature to the scene, update the current position, or replace one creature with another.
  Source is for debug purposes */
  void evaluate(String source) async {
    // Would only do when we boot up
    if (position == null || compassHeading == null) {
      return;
    }
    var nearestCreature = NearestCreature(creatureState.wild, position);
    if (nearestCreature.creature == null) {
      return;
    } else {
      // nearestCreature.creature!.location =
      //     LatLng(39.01247199159094, -77.1108217148138);
      // // LatLng(39.01246790748515, -77.11042471782032);
      currentCreature = nearestCreature.creature;
    }
    var currentNode = nodes.firstOrNull;
    var relativeBearing = getRelativeBearing(nearestCreature.bearing);
    if (relativeBearing == null) {
      return;
    }
    var vec = await calculatePositionRelativeToDevice(
        arkitController, nearestCreature.distance, relativeBearing!);
    if (vec == null) {
      return;
    }
    var plane = getPlane(nearestCreature.creature!);
    // no nodes at this point, add one for current creature
    if (currentNode == null) {
      // debugPrint("currentNode == null");
      placeAnchorAtPosition(
          arkitController, plane, vec!, nearestCreature.creature!.hash);
      // If we have a new nearest creature
    } else if (currentNode.name != nearestCreature.creature!.hash) {
      // remove old
      removeAllCreatures();
      // add new
      placeAnchorAtPosition(
          arkitController, plane, vec, nearestCreature.creature!.hash);
      /* Nearest creature is the same. If we wanted to just base the anchor on 
    the creature's position relative to our initial sensor readings when we open
    the tab, we could ignore this. However, the initial sensor readings can be 
    inaccurate, especially if we are indoors. You also could potentially have issues
    with the y axis. For example, if a creature is 100 meters away but up a 10m hill,
    we don't want the creature to be in the ground when we're on top of the hill */
    } else {
      // Current position is where creature is right now, vec is proposed new position
      var nodePositionDifference = vec.distanceTo(currentNode.position);
      var cameraPosition = await arkitController.cameraPosition();
      // Get the distance from the camera (our current position) to the creature
      var distanceToCamera = cameraPosition!.distanceTo(currentNode.position);
      // node is far away; update more liberally to get it right
      if (distanceToCamera > 100) {
        /* Creature wants to move by more than 5 meters. It's important to note that
        we are not evaluating the difference in proposed creature position to the last
        time we evaluating. We're evaluating based on the last time it actually moved 
        (where it currently is) */
        if (nodePositionDifference > 5) {
          animateNodePosition(arkitController, currentNode, vec);
        }
        // otherwise, once we get close, try to leave it where it us unless it's way off
      } else {
        if (nodePositionDifference > 20) {
          animateNodePosition(arkitController, currentNode, vec);
        }
      }
    }
  }

  ARKitPlane getPlane(Creature creature) {
    // Load your image asset
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.image(
          'assets/creatures/${creature.species.id}.png'),
    );

    // Create a plane to display the image
    final plane = ARKitPlane(
      width: 2.0, // Adjust the width of the plane
      height: 2.0, // Adjust the height of the plane
      materials: [material],
    );
    return plane;
  }

  /* We have to combine our orientation with the creatures bearing.
  For example, if a creature has a bearing of -90 (West), but we are facing
  east, the creature's relative bearing is 180. This gets us the relative bearing
  from where the phone is facing */
  double? getRelativeBearing(double bearing) {
    if (compassHeading == null) return null;
    double relativeBearing = -(compassHeading! - bearing);

    if (relativeBearing > 180) relativeBearing -= 360;
    if (relativeBearing < -180) relativeBearing += 360;

    return relativeBearing;
  }

  void removeAllCreatures() {
    for (var node in nodes) {
      arkitController.remove(node.name);
    }
    nodes.clear();
  }

  onARKitViewCreated(ARKitController controller) async {
    arkitController = controller;
    // Set up the onNodeTap callback
    arkitController.onNodeTap = (List<String> tappedNodeNames) {
      for (final nodeName in tappedNodeNames) {
        print('Tapped on node: $nodeName');
      }
    };
    evaluate("onARKitViewCreated");

    // runs every frame
    arkitController.updateAtTime = (result) async {
      // keep them pointed toward the camera (since they are a plane/image not a 3d object )
      if (nodes.isNotEmpty) {
        await alignPlaneToCamera(arkitController, nodes);
      }
    };
  }

  @override
  Widget build(BuildContext context) => ARKitSceneView(
        onARKitViewCreated: onARKitViewCreated,
        enableTapRecognizer: true,
      );
  /* This function takes a real world distance and bearing (direction) 
  and evaluates coordinates in 3d space in the ar view. The way that coordinates work
  here is that when we open our phone, the direction we are facing is the positive z axis. 
  This means that every single time we hope our phone, the coordinate system is different
  in real space even though it is the same relative to our phone */
  Future<Vector3?> calculatePositionRelativeToDevice(
      ARKitController arkitController,
      double distance,
      double relativeBearing) async {
    // Step 1: Get the camera's transform (position and rotation) at the moment of the function call
    final Matrix4? cameraTransform =
        /* This basically tells us how the phone has moved since the moment of initialization.
        pointOfViewTransform() tells us what has changed since we open the phone */
        await arkitController.pointOfViewTransform();
    if (cameraTransform == null) return null;

    // Extract the camera's position (x, y, z) from the transform
    // Turns matrix into List
    final List<double> values = cameraTransform.storage;
    final double cameraX = values[12]; // Camera's X position in AR world
    final double cameraY = values[13]; // Camera's Y position (height)
    final double cameraZ = values[14]; // Camera's Z position in AR world

    // Step 2: Get the camera's rotation matrix (heading)
    // This tells us how
    final rotationMatrix = cameraTransform.getRotation();

    // Step 3: Convert the relative bearing from degrees to radians
    // Convert the relative bearing (in degrees) to radians for trigonometric calculations
    final double bearingInRadians = (relativeBearing) * pi / 180;

    // Step 4: Apply the camera's rotation to the relative bearing
    // Now apply the camera's rotation (heading) to the relative bearing.
    // Assuming the device's front is aligned with the positive Z axis:

    // Get the yaw (rotation around the y-axis) from the camera's rotation matrix.
    // This assumes the rotation matrix is set up such that the yaw corresponds to the rotation we want to apply.
    double cameraYaw = 0;
    if (rotationMatrix != null) {
      cameraYaw = atan2(rotationMatrix.entry(0, 2), rotationMatrix.entry(2, 2));
    }

    // Now adjust the bearing based on the camera's yaw
    final adjustedBearingInRadians = bearingInRadians - cameraYaw;

    // Step 5: Calculate the x and z coordinates for the anchor
    // Use sine and cosine to place the anchor at the correct offset from the camera's position
    final double xOffset = distance * sin(adjustedBearingInRadians);
    // final double zOffset = distance * cos(adjustedBearingInRadians);
    final double zOffset = -distance * cos(adjustedBearingInRadians);

    // Step 6: Compute the final position of the anchor
    final double anchorX = cameraX + xOffset;
    final double anchorZ = cameraZ + zOffset;

    return Vector3(anchorX, cameraY, anchorZ);
  }

  Future<ARKitNode?> placeAnchorAtPosition(ARKitController arkitController,
      ARKitGeometry? geometry, Vector3 position, String name) async {
    debugPrint("placeAnchorAtPosition: $geometry; $position; $name");
    final anchorNode = ARKitNode(
      position: position,
      geometry: geometry,
      name: name,
    );

    // Add the node to the AR scene
    await arkitController.add(anchorNode);
    nodes.add(anchorNode);
    return anchorNode;
  }

  Future<bool> isNodeOnScreen(
      ARKitController arkitController, ARKitNode node) async {
    // Step 1: Get the node's position
    final Vector3 nodePosition = node.position;

    // Step 2: Get the camera's projection matrix
    final Matrix4? projectionMatrix =
        await arkitController.cameraProjectionMatrix();
    if (projectionMatrix == null) return false;

    // Step 3: Transform the node's position into clip space
    final Vector4 clipSpacePosition = projectionMatrix.transform(Vector4(
      nodePosition.x,
      nodePosition.y,
      nodePosition.z,
      1.0,
    ));

    // Step 4: Convert to normalized device coordinates (NDC)
    if (clipSpacePosition.w == 0.0) return false; // Avoid division by zero
    final double ndcX = clipSpacePosition.x / clipSpacePosition.w;
    final double ndcY = clipSpacePosition.y / clipSpacePosition.w;
    final double ndcZ = clipSpacePosition.z / clipSpacePosition.w;

    // Step 5: Check if the node is within the NDC bounds
    final bool isOnScreen = (ndcX >= -1.0 && ndcX <= 1.0) &&
        (ndcY >= -1.0 && ndcY <= 1.0) &&
        (ndcZ >= 0.0 && ndcZ <= 1.0);

    return isOnScreen;
  }

  void animateNodePosition(
      ARKitController controller, ARKitNode node, Vector3 targetPosition,
      {Duration duration = const Duration(seconds: 1)}) {
    // Cancel any ongoing animation
    _currentTimer?.cancel();

    // Get the current position of the node
    final Vector3 startPosition = node.position;

    // Animation duration and steps
    final int steps = 60; // Number of frames
    final double stepDuration = duration.inMilliseconds / steps;

    // Interpolation
    int currentStep = 0;
    _currentTimer = Timer.periodic(
      Duration(milliseconds: stepDuration.toInt()),
      (timer) {
        if (currentStep >= steps) {
          timer.cancel();
          _currentTimer = null; // Clear the reference
          return;
        }

        // Calculate the interpolated position
        final double t = currentStep / steps; // Progress (0.0 to 1.0)
        final Vector3 interpolatedPosition = Vector3(
          lerp(startPosition.x, targetPosition.x, t),
          lerp(startPosition.y, targetPosition.y, t),
          lerp(startPosition.z, targetPosition.z, t),
        );

        // Update the node's position
        node.position = interpolatedPosition;

        // Increment the step
        currentStep++;
      },
    );
  }

  // Helper function for linear interpolation
  double lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  Future<void> alignPlaneToCamera(
      ARKitController arkitController, List<ARKitNode> planeNodes) async {
    // Get the camera transform matrix
    final Matrix4? cameraTransform =
        await arkitController.pointOfViewTransform();
    if (cameraTransform == null) return;

    // Get the camera's position and rotation
    final cameraPosition = cameraTransform.getTranslation();
    // final cameraRotation = cameraTransform.getRotation();

    // Extract camera position
    final cameraX = cameraPosition.x;
    final cameraZ = cameraPosition.z;

    for (var planeNode in planeNodes) {
      // Extract plane position
      final planePosition = planeNode.position;

      // Calculate the angle to rotate the plane around the Y-axis
      final double angleToCamera = atan2(
        cameraX - planePosition.x,
        cameraZ - planePosition.z,
      );

      // Set the plane's rotation (only around the Y-axis)
      planeNode.eulerAngles = Vector3(angleToCamera, 0, 0);
    }
  }
}
