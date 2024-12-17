import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redis/redis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/creature.dart';
import 'package:terpiez/redis_manager.dart';

class CreatureState extends ChangeNotifier {
  late int _caughtCount;
  final List<Creature> _wild = <Creature>[];
  final List<Creature> _caught = <Creature>[];
  final List<CreatureSpecies> _species = <CreatureSpecies>[];
  //final conn = RedisConnection();

  CreatureState() {
    _caughtCount = 0;
    _init();
  }

  void resetCreatures() {
    _caught.clear();
    _getLocations();
  }

  Future<void> _init() async {
    await _getLocations();
    await _loadCaught();
  }

  Future<void> _loadCaught() async {
    var pref = await SharedPreferences.getInstance();
    var jsonList = pref.getStringList('CreatureState.caught');
    if (jsonList != null) {
      for (var json in jsonList!) {
        var map = jsonDecode(json);
        String id = map['species']['id'] as String;
        var species = _species.where((element) => element.id == id).firstOrNull;
        var creature = Creature(LatLng.fromJson(map['location']), species!);
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
            species = CreatureSpecies.fromMap(map, location.id);
            _species.add(species!);
          });
          //print('redis: $species');
        }
        species!.thumbnailPath = await _getImage(species!.thumbnail, command);
        species!.imagePath = await _getImage(species!.image, command);
        LatLng loc = LatLng(location.lat, location.lon);
        //only add to wild if it has NOT already been caught
        var c = _caught
            .where((element) =>
                element.location.latitude == loc.latitude &&
                element.location.longitude == loc.longitude &&
                element.species.id == species!.id)
            .firstOrNull;
        if (c == null) {
          _wild.add(Creature(loc, species!));
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
      _caught.add(creature);
      _caughtCount++;
      _saveCaught();
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
