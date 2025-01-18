import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'creature_state.dart';
import 'api_service.dart';
import 'creature_details.dart';
import 'creature.dart';

class ListTab extends StatefulWidget {
  const ListTab({super.key});

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  // Creatures we've caught before
  late List<Captured> caught;
  // List of all species so you can see basic info even if you haven't caught
  late List<CreatureSpecies> species;
  // Are you on all species or ones you've caught
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    species = CreatureState().species; // Get the synchronous list
  }

  Future<void> fetchData() async {
    var apiService = ApiService();
    // Get captured list for this person
    caught = await apiService.fetchList<Captured>(
      'creatures/list-captured',
      // Wrap the captured creatures with their time and weather
      (data) => Captured.fromMap(data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CupertinoSegmentedControl
        Padding(
          padding: const EdgeInsets.all(8.0),
          // Where you look at all species or ones you've caught
          child: CupertinoSegmentedControl<int>(
            groupValue: _selectedIndex,
            // Update selectedIndex when you tap
            onValueChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text('All Species'),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text('Caught'),
              ),
            },
          ),
        ),
        // Display appropriate list
        Expanded(
          child: _selectedIndex == 1
              ? FutureBuilder<void>(
                  future: fetchData(),
                  builder: (context, snapshot) {
                    // Loading image if still connecting
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      /* To make sure we only have one of every creature even if we've caught more.
                      Map gets just the species from the creatures we've caught. The toSet gets rid of duplicates.
                      Now we should have a list of only one for each species we've caught. Then we have to 
                      turn it back into a list */
                      var caughtSpeciesList = caught
                          .map((element) => element.creature.species)
                          .toSet()
                          .toList();
                      caughtSpeciesList
                          .sort((a, b) => a.name.compareTo(b.name));
                      return _buildListView(caughtSpeciesList);
                    }
                  },
                )
              // If selectedIndex is 0 we do the species
              : _buildListView(species),
        ),
      ],
    );
  }

  Widget _buildListView(List<CreatureSpecies> list) {
    return list.isEmpty
        ? const Center(child: Text('No creatures found'))
        : ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(list[index].name),
                leading: Hero(
                  tag: list[index],
                  child: Image.network(
                    dotenv.env['API_ROOT']! + list[index].image,
                    height: 80,
                    width: 80,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                // Open each creatures CreatureDetails page when we click on a ListTile
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatureDetails(
                        species: list[index],
                        // We want to send across the list of caught so that we can see it on the caught page
                        caught: _selectedIndex == 1
                            ? caught
                                .where((c) =>
                                    c.creature.species.id == list[index].id)
                                .toList()
                            : [],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}
