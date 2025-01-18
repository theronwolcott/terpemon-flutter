import 'dart:collection';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'creature.dart';
import 'location_state.dart';

class CreatureState extends ChangeNotifier {
  /* This is how we create a singleton */
  static final CreatureState _instance = CreatureState._internal();

  factory CreatureState() => _instance;

  CreatureState._internal() {
    _caughtCount = 0;
    _init();
  }

  final ApiService _apiService = ApiService();
  final LocationState _locationState = LocationState();

  late int _caughtCount;
  late List<Creature> _wild = <Creature>[];
  final List<Creature> _caught = <Creature>[];
  late List<CreatureSpecies> _species = <CreatureSpecies>[];
  // How we track which tile you're physically
  late (int, int) _currentTile;

  //final conn = RedisConnection();

  void resetCreatures() {
    _caught.clear();
  }

  Future<void> _init() async {
    // await _getLocations();
    // await _loadCaught();
    _currentTile = (0, 0);
    _locationState.addListener(() {
      // Track our position and our current tile
      var position = _locationState.currentPosition;
      var newTile = _getTile(position!.latitude, position!.longitude);
      // If it changes, we loadCreatures again
      if (newTile != _currentTile) {
        _currentTile = newTile;
        _loadCreatures();
      }
    });
    // await _loadCreatures();
  }

  Future<void> _loadCreatures() async {
    // How we get the species list
    _species = await _apiService.fetchList<CreatureSpecies>(
      'species/list',
      CreatureSpecies.fromMap,
    );
    final position = await _locationState.getCurrentPositionAsync();
    // Populate the wild creatures
    _wild = await _apiService.fetchList<Creature>(
      'creatures/get-by-lat-lng',
      /* We are assuming that we are able to call the Creature.fromMap 
      ASSUMING that data will fit it correctly and be a Map<String, dynamic> */
      Creature.fromMap,
      // Map<String, dynamic>
      body: {
        "lat": position.latitude,
        "lng": position.longitude,
      },
    );
    notifyListeners();
  }

  // Like findOne in js
  CreatureSpecies lookup(int id) {
    return _species.firstWhere((species) => species.id == id);
  }

  static (int, int) _getTile(double latitude, double longitude) {
    // 0.02 degrees of lat and lng. We use an int here so we don't have to deal with doubles
    double step = 20;
    /* Multiply by 1000 to use integers instead of decimals so we get three
    decimal places worth of precision. The step is very important. The step is how 
    we go down from a regular scale to the scale we want */
    int lat = (((latitude * 1000) / step)).floor();
    int lng = (((longitude * 1000) / step)).floor();
    return (lat, lng);
  }

  int get caughtCount => _caughtCount;
  UnmodifiableListView<Creature> get wild => UnmodifiableListView(_wild);
  UnmodifiableListView<Creature> get caught => UnmodifiableListView(_caught);
  UnmodifiableListView<CreatureSpecies> get species =>
      UnmodifiableListView(_species);

  /* This is where we actually catch a creature, and there are a few things
  we have to do */
  void catchCreature(Creature creature) {
    // Remove the creature from wild, if it was successful...
    if (_wild.remove(creature)) {
      // Tell the server we caught the creature so the web service adds it to caught
      _apiService.postRequest("creatures/catch", body: {
        'id': creature.species.id,
        'hash': creature.hash,
        'lat': creature.location.latitude,
        'lng': creature.location.longitude,
        'name': creature.name,
        'weather_code': 1, // placeholder
      });
      // _caught.add(creature);
      // _caughtCount++;
      // _saveCaught();
    }
    notifyListeners();
  }
}
