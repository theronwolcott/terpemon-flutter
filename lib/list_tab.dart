import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/transparent_white_image_provider.dart';
import 'package:terpiez/api_service.dart';
import 'creature.dart';
import 'creature_details.dart';

class ListTab extends StatelessWidget {
  late List<Captured> caught;

  ListTab({super.key});

  Future<void> fetchData() async {
    var apiService = ApiService();
    caught = await apiService.fetchList<Captured>(
      'creatures/list-captured',
      (data) => Captured.fromMap(data),
    );
  }

  @override
  Widget build(BuildContext context) {
    //var creatureState = context.watch<CreatureState>();
    return FutureBuilder<void>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var caughtSpeciesList = caught
              .map((element) => element.creature.species)
              .toSet()
              .toList();
          caughtSpeciesList.sort((a, b) => a.name.compareTo(b.name));

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
                            child: Image.network(
                              dotenv.env['API_ROOT']! +
                                  caughtSpeciesList[index].image,
                              height: 80,
                              width: 80,
                            ),
                            // Image.file(
                            //     File(caughtSpeciesList[index].thumbnailPath)),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatureDetails(
                                    species: caughtSpeciesList[index],
                                    caught: caught
                                        .where((c) =>
                                            c.creature.species.id ==
                                            caughtSpeciesList[index].id)
                                        .toList(),
                                  ),
                                ));
                          });
                    },
                  ),
          );
        }
      },
    );
  }
}
