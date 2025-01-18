import 'package:Terpemon/ar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'location_state.dart';

import 'catch_creature.dart';
import 'compass.dart';
import 'creature_state.dart';
import 'nearest_creature.dart';

/* The entire main "finder" tab */

class FinderTab extends StatefulWidget {
  const FinderTab({super.key});

  @override
  FinderTabState createState() => FinderTabState();
}

class FinderTabState extends State<FinderTab> {
  // We can refer to arKey.currentState and call its methods within this class
  final GlobalKey<ARState> arKey = GlobalKey<ARState>();

  @override
  Widget build(BuildContext context) {
    bool buttonVisible = false;
    var locationState = context.watch<LocationState>();
    var creatureState = context.watch<CreatureState>();

    var nearestCreature =
        NearestCreature(creatureState.wild, locationState.currentPosition);

    // Is nearest creature within 25m to make the button appear to catch
    if (nearestCreature.creature != null && nearestCreature.distance < 25) {
      buttonVisible = true;
    }

    return Stack(
      children: [
        AR(
          // With this key, we are able to talk to this instance of our AR instance and call its methods
          key: arKey,
        ),
        Center(
          child: Column(
            children: [
              // Take all space left over
              Expanded(
                // CreatureTarget widget on the camera
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Visibility(
                    visible: buttonVisible,
                    child: ElevatedButton(
                      child: Text(
                          "Catch ${nearestCreature.creature == null ? "Creature" : nearestCreature.creature!.species.name}"),
                      onPressed: () async {
                        var image =
                            // We don't want to display the creature in our snapshot, we want our own
                            await arKey.currentState?.captureSnapshot(false);
                        if (image != null && nearestCreature.creature != null) {
                          await Navigator.of(context).push(
                            // Keeps track of back arrows and navigation and fills whole screen with widget
                            MaterialPageRoute(
                              // The actual CatchCreature widget
                              builder: (context) => CatchCreature(
                                image: image,
                                creature: nearestCreature.creature!,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              // Holds the compass
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: new Color.fromRGBO(255, 255, 255, 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        // The actual compass
                        child: Compass(heading: 0.0),
                      ),
                      // The nearest creature distance under compass
                      if (nearestCreature.creature == null)
                        const Text("Searching...")
                      else
                        Text(
                          "${nearestCreature.distance.round()}m - ${nearestCreature.creature!.species.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ],
    );
  }
}
