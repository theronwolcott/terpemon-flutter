import 'dart:io';
import 'dart:math';
import 'package:Terpemon/user_state.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'animated_bouncing_creature.dart';
import 'creature.dart';
import 'creature_state.dart';

class CatchCreature extends StatefulWidget {
  const CatchCreature({
    super.key,
    this.image,
    required this.creature,
  });
  // Nullable incase we don't have a camera image to shows
  final ImageProvider? image;
  final Creature creature;

  @override
  State<CatchCreature> createState() => _CatchCreatureState();
}

class _CatchCreatureState extends State<CatchCreature> {
  final creatureState = CreatureState();
  late CatchGame game;
  late String creatureText;
  String creatureHand = "paper";
  // Can you see the creature or not
  bool creatureVisible = true;
  // Can you see its hand
  bool creatureHandVisible = false;
  // The jail when you catch it
  bool jailVisible = false;
  static const colors = {
    "blue": Color.fromARGB(255, 23, 137, 178),
    "yellow": Color.fromARGB(255, 193, 142, 22),
    "red": Color.fromARGB(255, 185, 34, 100),
    "gray": Color.fromARGB(255, 121, 121, 121),
  };
  var currentColors = ["blue", "yellow", "red"];
  // Are you allowed to tap the button
  bool canShoot = true;

  _CatchCreatureState();

  // Do this when the widget is first built
  @override
  void initState() {
    super.initState();
    // Start our game with the creature's stats
    game = CatchGame(
        bestOf: widget.creature.species.bestOf,
        creatureWinPct: widget.creature.species.winPct);
    // Make it display its name
    creatureText = "I'm ${widget.creature.name}";
    // Display its name for two seconds only
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          creatureText = game.status.gameText;
        });
      }
    });
  }

  /* When the user actually taps the button to play something */
  void shoot(RockPaperScissors user) {
    if (!canShoot) return;
    canShoot = false;
    // Static, makes a little vibration
    HapticFeedback.lightImpact();
    // For a stateful widget, we do these things in a setstate so it rebuilds immediately with them
    setState(() {
      // Call the shoot function on the game with whatever hand we played
      var (creatureThrew, roundResult, status) = game.shoot(user);
      // Creature's hand
      creatureHand = creatureThrew.name;
      // Display it
      creatureHandVisible = true;
      // Use returned game status
      creatureText = status.roundText;
      for (var hand in RockPaperScissors.values) {
        // Set the values in the colors array to be gray for the one we didn't pick
        if (hand != user) {
          currentColors[hand.index] = "gray";
        }
      }
    }); // Rebuild with this stuff ^
    // 2 seconds later, we go back to the default state (game state)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        resetState();
      }
    });
  }

  void resetState() {
    setState(() {
      // Go back to displaying the score instead of its reaction to throw
      creatureText = game.status.gameText;
      // Don't want to see its hand anymore
      creatureHandVisible = false;
      // Game is still going, we want to be able to play another round
      if (game.status.result == 0) {
        currentColors = ["blue", "yellow", "red"];
        canShoot = true;
      } else if (game.status.result == -1) {
        //Lost
        currentColors = ["gray", "gray", "gray"];
        creatureVisible = false;
        HapticFeedback.vibrate();
      } else if (game.status.result == 1) {
        //Won
        currentColors = ["gray", "gray", "gray"];
        jailVisible = true;
        // We call the catch method here
        creatureState.catchCreature(widget.creature);
      }
    });
    // If game is over, we want to pop the widget off the screen
    if (game.status.result != 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (game.status.result == -1) {
            _playSound("pop");
          }
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _playSound(String sound) async {
    if (UserState().isSoundOn) {
      final AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(AssetSource('sounds/$sound.mp3'));
      audioPlayer.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catch ${widget.creature.species.name}')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(children: [
        // Background
        Positioned.fill(
            // child: (true)
            child: (widget.image == null)
                ? widget.creature.species.weather.sceneWidget
                : Image(image: widget.image!, fit: BoxFit.cover)),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              // What is the creature saying
              creatureText,
              style: const TextStyle(
                  color: Colors.white,
                  height: 1,
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      // offset: Offset(10.0, 10.0),
                      blurRadius: 5.0,
                      color: Colors.black,
                    )
                  ]),
            ),
            Stack(alignment: Alignment.bottomCenter, children: [
              Visibility(
                visible: creatureVisible,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                // Creature itself is displayed here
                child: AnimatedBouncingCreature(
                  species: widget.creature.species,
                  size: 350.0,
                ),
              ),
              // Jail displayed here
              Visibility(
                visible: jailVisible,
                child: Image.asset(
                  "assets/creatures/jail.png",
                  height: 350,
                  width: 350,
                ),
              ),
            ]),
            const SizedBox(
              height: 30,
            ),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rock button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: MaterialButton(
                        onPressed: () {
                          shoot(RockPaperScissors.rock);
                        },
                        color: colors[currentColors[0]],
                        textColor: Colors.white,
                        //padding: EdgeInsets.all(16),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14.0),
                        child: Image.asset(
                          "assets/hands/rock.png",
                          height: 60,
                        ),
                      ),
                    ),
                    // Paper button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: MaterialButton(
                        onPressed: () {
                          shoot(RockPaperScissors.paper);
                        },
                        color: colors[currentColors[1]],
                        textColor: Colors.white,
                        //padding: EdgeInsets.all(16),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14.0),
                        child: Image.asset(
                          "assets/hands/paper.png",
                          height: 60,
                        ),
                      ),
                    ),
                    // Scissors button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: MaterialButton(
                        onPressed: () {
                          shoot(RockPaperScissors.scissors);
                        },
                        color: colors[currentColors[2]],
                        textColor: Colors.white,
                        //padding: EdgeInsets.all(16),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14.0),
                        child: Image.asset(
                          "assets/hands/scissors.png",
                          height: 60,
                        ),
                      ),
                    ),
                  ],
                ),
                // The creatures hand if we want to display it over the middle button
                Positioned(
                  // 60 above where it would normally be
                  bottom: 60,
                  child: Visibility(
                    visible: creatureHandVisible,
                    child: MaterialButton(
                      onPressed: () {},
                      color: Color.fromARGB(255, 51, 178, 23),
                      textColor: Colors.white,
                      //padding: EdgeInsets.all(16),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20.0),
                      child: Image.asset(
                        "assets/hands/$creatureHand.png",
                        height: 80,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}

class CatchGameStatus {
  int user = 0;
  int computer = 0;
  int result = 0;
  // Displays the message after each round
  String roundText = "";
  // Displays the score when game is in waiting
  String gameText = "";
}

class CatchGame {
  final int bestOf;
  final double creatureWinPct;
  // Static random generator
  static final Random _random = Random();
  CatchGameStatus status = CatchGameStatus();
  CatchGame({this.bestOf = 1, this.creatureWinPct = 0.5}) {
    if (bestOf > 1) {
      status.gameText = "Best of $bestOf";
    } else {
      status.gameText = "Shoot!";
    }
  }
  void reset() {
    status = CatchGameStatus();
  }

  // When the user actually picks a button we do this
  (RockPaperScissors, int, CatchGameStatus) shoot(RockPaperScissors user) {
    var majority = (bestOf / 2).ceil();
    // Random double between 0 and 1
    var x = _random.nextDouble(); // Use static random instance
    /* 66% of rounds end in a non-tie. Here, we are calculating the chance the creature wins.
    Because 66% of rounds are a non-tie, we portion it out based on the chance of the 
    creature winning */
    var winLevel = creatureWinPct * 0.667;
    // Always 33% chance for a tie
    var tieLevel = winLevel + 0.333;
    // Track which RPS we want the computer to play
    RockPaperScissors computer;
    int roundResult;
    // If we generate within 0 to the creature's winLevel, it wins
    if (x < winLevel) {
      // Choose the next value in the enum because creature won
      computer = RockPaperScissors.values[(user.index + 1) % 3];
      roundResult = -1;
      // Update the creature's score
      status.computer++;
      // If they win now
      if (status.computer >= majority) {
        // Creature won full game
        status.result = -1;
        status.gameText = "I've Escaped";
      }
      // In between winLevel and tieLevel, round is a tie
    } else if (x < tieLevel) {
      // Play the same value
      computer = RockPaperScissors.values[user.index];
      roundResult = 0;
      // User wins
    } else {
      // Get the previous value
      computer = RockPaperScissors.values[(user.index - 1 + 3) % 3];
      roundResult = 1;
      // Update user's score
      status.user++;
      // If we win now
      if (status.user >= majority) {
        // We win full game
        status.result = 1;
        status.gameText = "Caught! Nooo!";
      }
    }
    // Set the roundText to the creature's reaction
    status.roundText = throwResult(status, roundResult, _random);
    // Game is not over yet
    if (status.result == 0) {
      // If the game is now tied after this round
      if (status.user == status.computer) {
        status.gameText = "Tied ${status.user}-${status.computer}";
      } else if (status.user > status.computer) {
        // If we are now up
        status.gameText = "${status.user}-${status.computer} You";
      } else {
        // If creature is now up
        status.gameText = "I'm up ${status.computer}-${status.user}";
      }
    }
    // computer is so we can display what they played
    // roundResult maybe unecessary
    // status will inform the widget what to show
    return (computer, roundResult, status);
  }

  /* Figure out what the creature says */
  static String throwResult(CatchGameStatus status, int result, Random random) {
    if (result == 0) {
      // tie
      var list = [
        'Hmm. A Tie.',
        'Same thought!',
        'Twins!',
      ];
      // These randoms generate a random int from 0 to array length - 1
      return list[random.nextInt(list.length)];
    } else if (result == -1) {
      // creature won
      var list = [
        'Haha!',
        'Point for me!',
        'One for me!',
        'I win this one!',
      ];
      return list[random.nextInt(list.length)];
    } else if (result == 1) {
      // user won
      var list = [
        'Your point!',
        'Oof, nice one',
        'One for you',
        'I slipped!',
      ];
      return list[random.nextInt(list.length)];
    }
    return "";
  }
}

/* These are organized so the next one beats the previous one. So, 
if we want someone to win, we just pick the next one from .values */
enum RockPaperScissors {
  rock,
  paper,
  scissors,
}
