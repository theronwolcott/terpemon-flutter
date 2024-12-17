import 'package:latlong2/latlong.dart';
import 'package:weather_animation/weather_animation.dart';

class Creature {
  LatLng location;
  CreatureSpecies species;

  Creature(this.location, this.species);

  @override
  String toString() {
    String s =
        '[location: ${location.toString()}; species: ${species.toString()}]';
    return s;
  }

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'species': species.toJson(),
      };
}

class CreatureSpecies {
  String id;
  String name;
  String description;
  String thumbnail;
  String thumbnailPath = '';
  String image;
  String imagePath = '';
  late WeatherScene weather;
  CreatureStats stats;

  CreatureSpecies(this.id, this.name, this.description, this.thumbnail,
      this.image, this.stats) {
    weather = WeatherScene.values[name.hashCode % WeatherScene.values.length];
  }

  factory CreatureSpecies.fromMap(Map<String, dynamic> map, String id) {
    return CreatureSpecies(id, map['name'], map['description'],
        map['thumbnail'], map['image'], CreatureStats.fromMap(map['stats']));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'thumbnail': thumbnail,
        'image': image,
        'stats': stats.toJson(),
      };

  @override
  String toString() {
    String s =
        '[id: ${id}; name: ${name}; thumbnail: $thumbnail; image: $image; stats: ${stats.toString()}]';
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
