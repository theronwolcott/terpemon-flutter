# Terpémon (AR Mobile Game)

<img align="right" width="365" height="720" src="images/Sequence_01.gif">

A location-based augmented reality mobile game inspired by Pokémon GO, themed around the University of Maryland. Players can explore the world around them -- anywhere on Earth -- to find, catch and collect unique creatures using their mobile device's camera and location services. I developed both the front-end (this project, for iOS and Android) and the back-end (in Node, with MongoDB).

Back-End Project: https://github.com/theronwolcott/terpemon-node

### Features

- **Real-time Location Tracking**: Uses GPS to track player movement and discover nearby creatures
- **Augmented Reality**: Catch creatures using your device's camera in an augmented reality experience
- **Rock-Paper-Scissors Battle System**: Unique catching mechanism where players battle creatures using rock-paper-scissors
- **Interactive Map**: Shows nearby creatures and allows players to navigate to battle and catch
- **Creature Collection**: Track and view your captured creatures with detailed statistics
- **Weather Integration**: Each creature has preferred weather conditions
- **Compass Navigation**: Use the built-in compass to home in on the nearest creature as you get close

### Technical Implementation

- **State Management**: Uses Provider pattern for efficient state management across the application
- **Location Services**: Implements Geolocator for precise GPS tracking and distance/heading calculations
- **Augmented Reality**: Utilizes ARKit for real-world interaction with creatures as you approach
- **Maps**: Integrates OpenStreetMap for interactive mapping with live updates as you move
- **Animations**: Custom animations for creature movements and interactions
- **Sensor Integration**: Uses device compass and accelerometer for creature tracking
- **Local Storage**: Manages user preferences and cached data
- **API Services**: Centralized layer to communicate with back-end APIs

## Architecture

### State Management Singletons

#### User State [./lib/user_state.dart](./lib/user_state.dart)

- Stores state data for the current user in **Local Storage**
- Creates and maintains a **uuid** for the current user
- Stores user preferences, including **sound on/off**
- Extends [**ChangeNotifier**](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) (a form of _Observable_) to make is easy to subscribe to its changes
- Available to other classes or views as a singleton: **UserState()**

#### Location State [./lib/location_state.dart](./lib/location_state.dart)

- Uses device Geolocation services to monitor current location
- Offers a synchronous property and asynchronous method to get the current location
- Extends [**ChangeNotifier**](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) to make is easy to subscribe to its changes
- Subscribers notified on each location change
- Views using **.watch()** will rebuild with each location change (e.g. a view showing how far away the nearest creature is right now)
- Available to other classes or views as a singleton: **LocationState()**

#### Creature State [./lib/creature_state.dart](./lib/creature_state.dart)

- Maintains the current state of "creatures" around the user
- On app start, asynchronously loads and caches the full slate of all possible **Creature Species** in the universe (e.g. name, description, stats, image)
- As your location changes (it subscribes to changes from **LocationState()** above), it calls the API to load the nearest creatures from the server, notifying its subscribers
- Extends [**ChangeNotifier**](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) to make is easy to subscribe to its changes (e.g. when a creature is caught)
- Views using **.watch()** will rebuild with each creature change (e.g. a view showing how far away the nearest creature is right now)
- Available to other classes or views as a singleton: **CreatureState()**

### Data Models [./lib/creature.dart](./lib/creature.dart)

#### CreatureSpecies

There are 16 species of Terpémon in the universe, some common, some rare.

```
class CreatureSpecies {
  int id;                          // unique id for this species
  String name;                     // name of the species
  String description;              // species description
  String image = '';               // image URI
  int bestOf = 1;                  // how many games to beat them?
  double winPct = 0.5;             // how likely is this species to beat the user?
  late WeatherScene weather;       // the favorite weather of the species
  CreatureStats stats;             // species stats
 }
```

#### Creature

Each **Creature** only exists once. It has a unique hash, it's own first name (e.g. "Alphonse") and exists at a particular latitude and longitude in the real world.

```
class Creature {
  LatLng location;                 // the location of this creature (lat/lng)
  CreatureSpecies species;         // the CreatureSpecies of this creature
  String hash;                     // the unique hash of this creature
  String name;                     // their individual name (not the name of their species)
}
```

#### Captured

Each instance represents a single **Creature** captured by a single user at a single time.

```
class Captured {
  DateTime timestamp;              // the date/time the creature was captured
  int weather_code;                // the weather at the time of the capture (future use)
  Creature creature;               // the creature that was captured
}
```

## Primary Views

<img align="right" width="365" height="720" src="images/Sequence_02.gif">

### Main [./lib/main.dart](./lib/main.dart)

- Manages the tab controller and owns the hamburger menu
- Wires up the three **Providers** to make it easy for sub-views to watch for, and react to, state changes: **UserState()**, **LocationState()** and **CreatureState()**

### Finder (AR) Tab [./lib/ar.dart](./lib/ar.dart)

- Owns the ARKit implementation as the primary view
- Subscribes to **LocationState()** and **CreatureState()** changes to update the "nearest creature" as state changes
- Subscribes to **Compass heading change stream** to update the position of the nearest creature in 3D space as the device rotates
- Shows the "Capture Creature" button when the creature is near enough and in our sights
- Integrates the real-time **Compass** view overlayed on top of the AR view

#### Compass [./lib/compass.dart](./lib/compass.dart)

- Uses a [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html) tied to the **Compass heading change stream** to update the view smoothly as the device rotates
- An [AnimatedRotation](https://api.flutter.dev/flutter/widgets/AnimatedRotation-class.html) widget holds the compass and rotates to match the real-world heading relative to the device
  - Five more AnimatedRotation widgets hold the "N", "S", "E", "W" and "nearest creature" images and _counter-rotate_ to always appear locked to the device as the compass rotates under them (this effect ended up working well!)
- Subscribes to **LocationState()** and **CreatureState()** changes to update the "nearest creature" as state changes (to show the proper species in the proper position around the compass)

#### Catch Creature [./lib/catch_creature.dart](./lib/catch_creature.dart)

- Implements the rock-paper-scissors catch game
- Is initialized with an image from the AR view at the moment the user hit the "catch" button. This image serves as the view background.
- [Animated (bouncing)](./lib/animated_bouncing_creature.dart) version of the creature as you battle
- Creature stats (i.e. _bestOf_ and _winPct_) drive the game
- Random result each throw, but weighted to the _winPct_ of the species you are battling
- Creature responds to each throw, win/lose/draw, and keeps you updated on the overall state of the battle (e.g. best of seven)
- **CreatureState()** is updated if you win and capture the creature (calling the API and notifying all subscribers to update their views)

### Map Tab [./lib/terpemon_map.dart](./lib/terpemon_map.dart)

- Shows the user's current position and all nearby creatures as icons on the map
- Uses [OpenStreetMaps](https://www.openstreetmap.org/) and the [flutter_map](https://docs.fleaflet.dev/) plugin
- Subscribes to **LocationState()** and **CreatureState()** changes to update as state changes (e.g. as the user moves around and new creatures are discovered; or as the are caught)
- Zooms to the user's current location at launch
- Remembers map position as the view is re-loaded
- Sub-view shows the "nearest creature" -- and its distance away -- at the top of the screen

### Creatures Tab [./lib/list_tab.dart](./lib/list_tab.dart)

- Two tabs -- _All Creatures_ and _Caught_
- _All Creatures_ uses a [ListView.builder](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html) to show all the species available in the game -- retrieved from **LocationState()**
- _Caught_ calls an API on the server to get the up-to-date list of creatures caught by the current user
  - Only species caught by the current user are listed, and each species only once, no matter how many individual creatures of that species have been caught
- Tapping on a species pushes the **Creature Details** view onto the stack

#### Creature Details [./lib/creature_details.dart](./lib/creature_details.dart)

- Initialized with a single CreatureSpecies and (optionally) a list of _caught_ creatures of that species
- Background animation shows the species' favorite weather conditions (rainy, snowy, sunny, windy, etc.)
- [Animated (bouncing)](./lib/animated_bouncing_creature.dart) version of the creature at the top
- Description and stats
- Static map (also [OpenStreetMaps](https://www.openstreetmap.org/) and the [flutter_map](https://docs.fleaflet.dev/) ) showing the location of every creature of this species you've caught in the past
- Includes a list of those caught creatures with their name and the date of capture
- "Back arrow" pops this view off the stack

## Future Improvements

- [ ] Multiplayer battles
- [ ] Trading system
- [ ] More complex creature behaviors
- [ ] Enhanced AR features
- [ ] Social features
- [ ] Achievement system

## Contact

Theron Wolcott - theronwolcott@gmail.com

Project Link: [https://github.com/theronwolcott/terpemon-flutter](https://github.com/yourusername/terpemon-flutter)  
Back-End Link: [https://github.com/theronwolcott/terpemon-node](https://github.com/yourusername/terpemon-node)
