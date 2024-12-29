import 'dart:async'; // For Completer
import 'package:camera/camera.dart';

class CameraState {
  // Singleton instance
  static final CameraState _instance = CameraState._internal();

  factory CameraState() {
    return _instance;
  }

  CameraState._internal();

  // Camera variables
  late CameraDescription _camera; // Marked as late for deferred initialization
  CameraController? _controller;
  bool _isInitialized = false;

  Completer<void>? _initializationCompleter; // Handles async initialization

  // Initialize the camera
  Future<void> _initializeCamera() async {
    // print('_initializeCamera()');
    if (_initializationCompleter != null &&
        !_initializationCompleter!.isCompleted) {
      await _initializationCompleter!
          .future; // Wait for any ongoing initialization
      return;
    }

    _initializationCompleter = Completer<void>(); // New initialization process

    try {
      final cameras = await availableCameras(); // Fetch cameras
      _camera = cameras.first; // Initialize _camera

      // Dispose existing controller if needed
      if (_controller != null) {
        await _controller!.dispose();
      }

      // Create and initialize the controller
      _controller = CameraController(_camera, ResolutionPreset.veryHigh);
      await _controller!.initialize();

      _isInitialized = true; // Mark as initialized
      _initializationCompleter!.complete(); // Complete initialization
    } catch (e) {
      print('Error initializing camera: $e');
      _controller = null;
      _isInitialized = false;
      _initializationCompleter!.completeError(e); // Complete with error
    }
  }

  // Get the controller
  Future<CameraController?> getController() async {
    if (!_isInitialized) {
      await _initializeCamera(); // Ensure initialization
    }
    return _controller;
  }

  // Dispose the camera
  Future<void> dispose() async {
    if (_isInitialized && _controller != null) {
      await _controller!.dispose();
      _isInitialized = false;
      _controller = null;
    }
  }

  // Force reinitialization
  Future<void> resetCamera() async {
    await dispose(); // Dispose old controller
    await _initializeCamera(); // Reinitialize
  }
}
