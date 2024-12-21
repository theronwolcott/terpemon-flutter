import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationState extends ChangeNotifier {
  static final LocationState _instance = LocationState._internal();

  factory LocationState() => _instance;

  LocationState._internal() {
    _listenToPosition();
  }

  Position? _currentPosition;
  Completer<Position>? _positionCompleter;

  Position? get currentPosition {
    return _currentPosition;
  }

  Future<Position> getCurrentPositionAsync() async {
    if (_currentPosition != null) {
      return _currentPosition!;
    } else {
      // If position is not yet available, return a Future that will complete when the position is obtained
      _positionCompleter ??= Completer<Position>();
      return _positionCompleter!.future;
    }
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

      // If a Completer exists, complete it with the new position
      if (_positionCompleter != null && !_positionCompleter!.isCompleted) {
        _positionCompleter!.complete(position);
      }
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
