import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature_state.dart';

class FinderTab extends StatelessWidget {
  const FinderTab({super.key});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Terpiez Finder',
              textScaler: TextScaler.linear(2.5),
            ),
            const Text(''),
            const Text(
              'Distance to Terpiez: 0.1 Miles',
              textScaler: TextScaler.linear(1.5),
            ),
            GestureDetector(
              onTap: () {
                //creatureState.catchCreature();
              },
              child: const Icon(Icons.map), //TerpiezMap(),
            ),
            const Text('(Placeholder image)'),
          ],
        ),
      ),
    );
  }
}
