import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/background_monitor.dart';
import 'package:terpiez/creature.dart';
import 'package:terpiez/creature_state.dart';
import 'package:terpiez/finder_tab.dart';
import 'package:terpiez/list_tab.dart';
import 'package:terpiez/redis_manager.dart';
import 'package:terpiez/statistics_tab.dart';
import 'package:terpiez/user_state.dart';
import 'package:uuid/uuid.dart';
import 'package:weather_animation/weather_animation.dart';
import 'globals.dart';
import 'location_state.dart';
import 'terpiez_map.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();

final InitializationSettings initializationSettings = InitializationSettings(
  iOS: initializationSettingsDarwin,
  macOS: initializationSettingsDarwin,
);
int initTabIndex = 0;
bool isForeground = true;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      initTabIndex = 1;
    },
  );
  await dotenv.load(fileName: '.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _creatureState = CreatureState();
  final _userState = UserState();
  final _locationState = LocationState();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CreatureState>(create: (_) => _creatureState),
        ChangeNotifierProvider<UserState>(create: (_) => _userState),
        ChangeNotifierProvider<LocationState>(create: (_) => _locationState),
      ],
      child: MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Terpiez',
          home: DefaultTabController(
              initialIndex: 1,
              length: 3,
              child: Scaffold(
                  drawer: Drawer(
                    child: ListView(
                      // Important: Remove any padding from the ListView.
                      padding: EdgeInsets.zero,
                      children: [
                        const DrawerHeader(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 73, 86, 97),
                          ),
                          child: Text('Settings'),
                        ),
                        SoundTile(),
                        ResetUserPrefs(),
                      ],
                    ),
                  ),
                  appBar: AppBar(
                      title: const Text('Terpiez'),
                      bottom: const TabBar(
                        tabs: [
                          Tab(
                              text: 'Statistics',
                              icon: Icon(Icons.query_stats)),
                          Tab(text: 'Finder', icon: Icon(Icons.search)),
                          Tab(text: 'Caught', icon: Icon(Icons.list)),
                        ],
                      )),
                  floatingActionButton: BackgroundMonitor(),
                  body: TabBarView(
                    children: [
                      StatisticsTab(),
                      TerpiezMap(),
                      ListTab(),
                    ],
                  )))),
    );
  }
}

class ResetUserPrefs extends StatelessWidget {
  const ResetUserPrefs({
    super.key,
  });

  _showConfirmationDialog(BuildContext context) {
    var userState = context.read<UserState>();
    var creatureState = context.read<CreatureState>();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Reset"),
            content: Text(
                'Are you sure you want to reset your account? All current data will be lost.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel')),
              TextButton(
                onPressed: () {
                  //erase
                  userState.reset();
                  creatureState.resetCreatures();
                  Navigator.of(context).pop();
                },
                child: Text('Erase'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: const Text('Clear User Settings'),
      onTap: () {
        Navigator.pop(context);
        _showConfirmationDialog(context);
      },
    );
  }
}

class SoundTile extends StatefulWidget {
  const SoundTile({
    super.key,
  });

  @override
  State<SoundTile> createState() => _SoundTileState();
}

class _SoundTileState extends State<SoundTile> {
  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserState>();
    var initSoundOn = userState.isSoundOn;

    return ListTile(
      title: const Text('Sound'),
      leading: Icon(Icons.volume_up),
      trailing: Switch(
          value: initSoundOn,
          onChanged: (value) {
            setState(() {
              userState.isSoundOn = value;
            });
          }),
      onTap: () {
        // Update the state of the app.
        // ...
      },
    );
  }
}
