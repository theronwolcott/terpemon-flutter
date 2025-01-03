import 'dart:collection';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'creature.dart';
import 'location_state.dart';

class CreatureState extends ChangeNotifier {
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
      var position = _locationState.currentPosition;
      var newTile = _getTile(position!.latitude, position!.longitude);
      if (newTile != _currentTile) {
        _currentTile = newTile;
        _loadCreatures();
      }
    });
    // await _loadCreatures();
  }

  Future<void> _loadCreatures() async {
    _species = await _apiService.fetchList<CreatureSpecies>(
      'species/list',
      (data) => CreatureSpecies.fromMap(data, data['id']),
    );
    final position = await _locationState.getCurrentPositionAsync();
    _wild = await _apiService.fetchList<Creature>(
      'creatures/get-by-lat-lng',
      (data) => Creature.fromMap(data),
      body: {
        "lat": position.latitude,
        "lng": position.longitude,
      },
    );
    notifyListeners();
  }

  CreatureSpecies lookup(int id) {
    return _species.firstWhere((species) => species.id == id);
  }

  static (int, int) _getTile(double latitude, double longitude) {
    double step = 20;
    int lat = (((latitude * 1000) / step) * step).floor();
    int lng = (((longitude * 1000) / step) * step).floor();
    return (lat, lng);
  }

  int get caughtCount => _caughtCount;
  UnmodifiableListView<Creature> get wild => UnmodifiableListView(_wild);
  UnmodifiableListView<Creature> get caught => UnmodifiableListView(_caught);
  UnmodifiableListView<CreatureSpecies> get species =>
      UnmodifiableListView(_species);

  void catchCreature(Creature creature) {
    if (_wild.remove(creature)) {
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
