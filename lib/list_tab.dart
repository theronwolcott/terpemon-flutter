import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/transparent_white_image_provider.dart';

import 'creature.dart';
import 'creature_details.dart';

class ListTab extends StatelessWidget {
  const ListTab({super.key});

  @override
  Widget build(BuildContext context) {
    var creatureState = context.watch<CreatureState>();
    var caughtSpeciesList =
        creatureState.caught.map((element) => element.species).toSet().toList();

    return Center(
      child: caughtSpeciesList.length == 0
          ? const Center(child: Text('No creatures caught yet'))
          : ListView.builder(
              itemCount: caughtSpeciesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                    title: Text(caughtSpeciesList[index].name),
                    leading: Hero(
                      tag: caughtSpeciesList[index],
                      child: Image(
                          image: TransparentWhiteImageProvider(
                              caughtSpeciesList[index].thumbnailPath)),
                      // Image.file(
                      //     File(caughtSpeciesList[index].thumbnailPath)),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatureDetails(
                                species: caughtSpeciesList[index]),
                          ));
                    });
              },
            ),
    );
  }
}
