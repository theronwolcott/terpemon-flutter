import 'package:latlong2/latlong.dart';
import 'creature_state.dart';
import 'package:weather_animation/weather_animation.dart';

class Creature {
  LatLng location;
  CreatureSpecies species;
  String hash;
  String name;

  Creature(this.location, this.species, this.hash, this.name);

  /* Constructor takes a map of what the JSON is translated into before it is strongly typed,
   and makes a creature object from it */
  factory Creature.fromMap(Map<String, dynamic> map) {
    // Get a species object based on the id of the current map
    // Lookup takes an id and gets a single CreatureSpecies object back
    var species = CreatureState().lookup(map['id']);
    return Creature(
        LatLng(map['lat'], map['lng']), species, map['hash'], map['name']);
  }

  @override
  String toString() {
    String s =
        '[location: ${location.toString()}; species: ${species.toString()}; hash: $hash; name: $name]';
    return s;
  }

  // May not need this
  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'species': species.toJson(),
        'hash': hash,
        'name': name,
      };
}

/* For a creature we've captured, give it a timestamp and weather */
class Captured {
  DateTime timestamp;
  int weather_code;
  Creature creature;

  Captured(this.timestamp, this.weather_code, this.creature);

  factory Captured.fromMap(Map<String, dynamic> map) {
    return Captured(DateTime.parse(map['timestamp']), map['weather_code'],
        Creature.fromMap(map['creature']));
  }

  @override
  String toString() {
    String s =
        '[timestamp: ${timestamp.toString()}; weather_code: $weather_code; creature: ${creature.toString()}]';
    return s;
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'weather_code': weather_code,
        'creature': creature.toJson(),
      };
}

/* CreatureSpecies is how we are taking in creatures from the server */
class CreatureSpecies {
  int id;
  String name;
  String description;
  String image = '';
  int bestOf = 1;
  double winPct = 0.5;
  late WeatherScene weather;
  CreatureStats stats;

  CreatureSpecies(this.id, this.name, this.description, this.image, this.bestOf,
      this.winPct, this.stats) {
    // Choosing a weather based on the hash of the name
    weather = WeatherScene.values[name.hashCode % WeatherScene.values.length];
  }

  factory CreatureSpecies.fromMap(Map<String, dynamic> map) {
    return CreatureSpecies(
        map['id'],
        map['name'],
        map['description'],
        map['image'],
        map['bestOf'],
        map['winPct'],
        CreatureStats.fromMap(map['stats']));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image': image,
        'bestOf': bestOf,
        'winPct': winPct,
        'stats': stats.toJson(),
      };

  @override
  String toString() {
    String s =
        '[id: $id; name: $name; image: $image; bestOf: $bestOf; winPct: $winPct; stats: ${stats.toString()}]';
    return s;
  }
}

class CreatureStats {
  int avuncularity;
  int destrucity;
  int panache;
  int spiciness;

  CreatureStats(
      this.avuncularity, this.destrucity, this.panache, this.spiciness);

  factory CreatureStats.fromMap(Map<String, dynamic> map) {
    if (map['Avuncularity'] == null) {
      //lower case
      return CreatureStats(map['avuncularity'], map['destrucity'],
          map['panache'], map['spiciness']);
    } else {
      //upper case (Redis)
      return CreatureStats(map['Avuncularity'], map['Destrucity'],
          map['Panache'], map['Spiciness']);
    }
  }

  Map<String, dynamic> toJson() => {
        'avuncularity': avuncularity,
        'destrucity': destrucity,
        'panache': panache,
        'spiciness': spiciness,
      };

  @override
  String toString() {
    String s =
        '[avuncularity: $avuncularity; destrucity: $destrucity; panache: $panache; spiciness: $spiciness]';
    return s;
  }
}
