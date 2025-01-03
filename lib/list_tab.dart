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
  late List<Captured> caught;
  late List<CreatureSpecies> species;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    species = CreatureState().species; // Get the synchronous list
  }

  Future<void> fetchData() async {
    var apiService = ApiService();
    caught = await apiService.fetchList<Captured>(
      'creatures/list-captured',
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
          child: CupertinoSegmentedControl<int>(
            groupValue: _selectedIndex,
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatureDetails(
                        species: list[index],
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
