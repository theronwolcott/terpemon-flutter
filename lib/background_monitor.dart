import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature.dart';
import 'package:terpiez/main.dart';

import 'creature_state.dart';
import 'location_state.dart';
import 'nearest_creature.dart';

class BackgroundMonitor extends StatefulWidget {
  const BackgroundMonitor({
    super.key,
  });

  @override
  State<BackgroundMonitor> createState() => _BackgroundMonitorState();
}

class _BackgroundMonitorState extends State<BackgroundMonitor>
    with WidgetsBindingObserver {
  late LocationState locationState;
  late CreatureState creatureState;
  Creature? currentCreature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    locationState = context.read<LocationState>();
    locationState.addListener(_onStateChange);
    creatureState = context.read<CreatureState>();
    creatureState.addListener(_onStateChange);
  }

  void _onStateChange() async {
    if (!isForeground) {
      // SharedPreferences preferences = await SharedPreferences.getInstance();
      // final log = preferences.getStringList('LocationWakeup.log') ?? <String>[];
      NearestCreature nearestCreature =
          NearestCreature(creatureState.wild, locationState.currentPosition);
      // log.add(
      //     "${DateTime.now().toIso8601String()}: ${locationState.currentPosition.toString()} (${nearestCreature.creature!.species.name})");
      // preferences.setStringList('LocationWakeup.log', log);
      if (nearestCreature.creature != null &&
          (currentCreature == null ||
              currentCreature != nearestCreature.creature) &&
          nearestCreature.distance < 20) {
        await flutterLocalNotificationsPlugin.show(
          (DateTime.now().hashCode).abs(),
          'Creature Nearby',
          'A ${nearestCreature.creature!.species.name} within 20m of your location, catch it!',
          const NotificationDetails(
            iOS: DarwinNotificationDetails(sound: "pop.mp3"),
          ),
        );
        currentCreature = nearestCreature.creature;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        isForeground = true;
        break;
      default:
        isForeground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); //empty
  }
}
