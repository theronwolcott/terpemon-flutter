import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'background_monitor.dart';
import 'creature_state.dart';
import 'list_tab.dart';
import 'user_state.dart';
import 'globals.dart';
import 'location_state.dart';
import 'take_picture_screen.dart';
import 'terpemon_map.dart';

// FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// final DarwinInitializationSettings initializationSettingsDarwin =
//     DarwinInitializationSettings();

// final InitializationSettings initializationSettings = InitializationSettings(
//   iOS: initializationSettingsDarwin,
//   macOS: initializationSettingsDarwin,
// );
int initTabIndex = 0;
bool isForeground = true;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: (details) {
  //     initTabIndex = 1;
  //   },
  // );
  final cameras = await availableCameras();
  final CameraDescription? firstCamera = cameras.isEmpty ? null : cameras.first;
  await dotenv.load(fileName: '.env');
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.camera});
  final CameraDescription? camera;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PageController _pageController;

  final _creatureState = CreatureState();
  final _userState = UserState();
  final _locationState = LocationState();

  int _selectedIndex = 0; //New

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          title: 'Terpémon',
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 224, 58, 62),
            brightness: Brightness.light,
          )),
          home: Scaffold(
            drawer: Drawer(
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: const [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 224, 58, 62),
                    ),
                    child: Text('Settings'),
                  ),
                  SoundTile(),
                  ResetUserPrefs(),
                ],
              ),
            ),
            appBar: AppBar(
              title: const Text('Terpémon'),
            ),
            floatingActionButton: const BackgroundMonitor(),
            body: PageView(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                // const StatisticsTab(),
                // const MainTab(),
                TakePictureScreen(
                  camera: widget.camera,
                ),
                TerpemonMap(),
                ListTab(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                _pageController.jumpToPage(
                  // _pageController.animateToPage(
                  index,
                  // duration: const Duration(milliseconds: 300),
                  // curve: Curves.easeInOut,
                );
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Finder',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pets),
                  label: 'Creatures',
                ),
              ],
            ),
          )),
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
            title: const Text("Confirm Reset"),
            content: const Text(
                'Are you sure you want to reset your account? All current data will be lost.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  //erase
                  userState.reset();
                  creatureState.resetCreatures();
                  Navigator.of(context).pop();
                },
                child: const Text('Erase'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person),
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
      leading: const Icon(Icons.volume_up),
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
