import 'package:geolocator/geolocator.dart';
import 'creature.dart';

class NearestCreature {
  Creature? creature;
  double distance = double.infinity;
  double bearing = 0;

  NearestCreature(List<Creature> list, Position? position) {
    // Which creature is closest to given position
    if (position != null && list.isNotEmpty) {
      for (var c in list) {
        var d = Geolocator.distanceBetween(c.location.latitude,
            c.location.longitude, position.latitude, position.longitude);
        if (creature == null || d < distance) {
          creature = c;
          distance = d;
        }
      }
      // Only use this in the compass
      bearing = Geolocator.bearingBetween(position.latitude, position.longitude,
          creature!.location.latitude, creature!.location.longitude);
    }
  }
}
