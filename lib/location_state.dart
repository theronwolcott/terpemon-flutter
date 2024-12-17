import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationState extends ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition {
    return _currentPosition;
  }

  LocationState() {
    _listenToPosition();
  }

  Future<void> _listenToPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    )).listen((position) {
      _currentPosition = position;
      //debugPrint(_currentPosition.toString());
      notifyListeners();
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled. Please enable the services.');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
          'Location permissions are permanently disabled; we cannot request permission.');
      return false;
    }
    return true;
  }
}
