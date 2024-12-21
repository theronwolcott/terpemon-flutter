import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redis/redis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/api_service.dart';
import 'package:terpiez/creature.dart';
import 'package:terpiez/redis_manager.dart';
import 'location_state.dart';

class CreatureState extends ChangeNotifier {
  static final CreatureState _instance = CreatureState._internal();

  factory CreatureState() => _instance;

  CreatureState._internal() {
    _caughtCount = 0;
    _init();
  }

  final ApiService apiService = ApiService();
  late int _caughtCount;
  late List<Creature> _wild = <Creature>[];
  final List<Creature> _caught = <Creature>[];
  late List<CreatureSpecies> _species = <CreatureSpecies>[];
  //final conn = RedisConnection();

  void resetCreatures() {
    _caught.clear();
    _getLocations();
  }

  Future<void> _init() async {
    // await _getLocations();
    // await _loadCaught();
    await _loadCreatures();
  }

  Future<void> _loadCreatures() async {
    _species = await apiService.fetchList<CreatureSpecies>(
      'species/list',
      (data) => CreatureSpecies.fromMap(data, data['id']),
    );
    final locationState = LocationState();
    final position = await locationState.getCurrentPositionAsync();
    _wild = await apiService.fetchList<Creature>(
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

  Future<void> _loadCaught() async {
    var pref = await SharedPreferences.getInstance();
    var jsonList = pref.getStringList('CreatureState.caught');
    if (jsonList != null) {
      for (var json in jsonList!) {
        var map = jsonDecode(json);
        String id = map['species']['id'] as String;
        var species = _species.where((element) => element.id == id).firstOrNull;
        var creature =
            Creature(LatLng.fromJson(map['location']), species!, "1234", "ned");
        _caught.add(creature);
        //remove from wild
        _wild.removeWhere((element) =>
            element.location.latitude == creature.location.latitude &&
            element.location.longitude == creature.location.longitude &&
            element.species.id == creature.species.id);
      }
      notifyListeners();
    }
  }

  Future<void> _saveCaught() async {
    var pref = await SharedPreferences.getInstance();
    var jsonList =
        _caught.map((creature) => jsonEncode(creature.toJson())).toList();
    await pref.setStringList('CreatureState.caught', jsonList);
  }

  Future<void> _loadSpecies() async {
    var pref = await SharedPreferences.getInstance();
    //pref.remove('CreatureState.species');
    var jsonList = pref.getStringList('CreatureState.species');
    if (jsonList != null) {
      for (var json in jsonList!) {
        var map = jsonDecode(json);
        _species.add(CreatureSpecies.fromMap(map, map['id']));
      }
    }
  }

  Future<void> _saveSpecies() async {
    var pref = await SharedPreferences.getInstance();
    var jsonList =
        _species.map((species) => jsonEncode(species.toJson())).toList();
    await pref.setStringList('CreatureState.species', jsonList);
  }

  Future<void> _getLocations() async {
    await _loadSpecies();
    // redis
    var command = await RedisManager.getInstance().getCommand();
    await command
        .send_object(["JSON.GET", "locations"]).then((var response) async {
      List<dynamic> jsonData = jsonDecode(response);
      List<RedisLocation> locations = jsonData
          .map<RedisLocation>((json) => RedisLocation.fromMap(json))
          .toList();
      for (var location in locations) {
        //check list of species
        var species =
            _species.where((element) => element.id == location.id).firstOrNull;
        if (species == null) {
          await command.send_object(["JSON.GET", "terpiez", location.id]).then(
              (var response) async {
            var map = jsonDecode(response) as Map<String, dynamic>;
            //species = CreatureSpecies.fromMap(map, location.id);
            _species.add(species!);
          });
          //print('redis: $species');
        }
        species!.image = await _getImage(species!.image, command);
        LatLng loc = LatLng(location.lat, location.lon);
        //only add to wild if it has NOT already been caught
        var c = _caught
            .where((element) =>
                element.location.latitude == loc.latitude &&
                element.location.longitude == loc.longitude &&
                element.species.id == species!.id)
            .firstOrNull;
        if (c == null) {
          _wild.add(Creature(loc, species!, "1234", "ned"));
        }
      }
      notifyListeners();
      _saveSpecies();
    });
    return;
  }

  Future<String> _getImage(String key, Command command) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$key.jpg';
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      await command
          .send_object(["JSON.GET", "images", key]).then((var response) async {
        var stringResponse = (response as String);
        var cleanedResponse =
            stringResponse.substring(1, stringResponse.length - 1);
        var decodedBytes = base64Decode(cleanedResponse);
        await imageFile.writeAsBytes(decodedBytes);
      });
    }
    //print(imagePath);
    return imagePath;
  }

  int get caughtCount => _caughtCount;
  UnmodifiableListView<Creature> get wild => UnmodifiableListView(_wild);
  UnmodifiableListView<Creature> get caught => UnmodifiableListView(_caught);

  void catchCreature(Creature creature) {
    if (_wild.remove(creature)) {
      apiService.postRequest("creatures/catch", body: {
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

class RedisLocation {
  double lat;
  double lon;
  String id;

  RedisLocation(this.id, this.lat, this.lon);

  factory RedisLocation.fromMap(Map<String, dynamic> map) {
    return RedisLocation(map['id'], map['lat'], map['lon']);
  }
}
