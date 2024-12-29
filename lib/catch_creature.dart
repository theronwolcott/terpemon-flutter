import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'animated_bouncing_creature.dart';
import 'creature.dart';
import 'creature_state.dart';

class CatchCreature extends StatefulWidget {
  const CatchCreature({
    super.key,
    required this.image,
    required this.creature,
  });

  final XFile image;
  final Creature creature;

  @override
  State<CatchCreature> createState() => _CatchCreatureState();
}

class _CatchCreatureState extends State<CatchCreature> {
  final creatureState = CreatureState();
  late CatchGame game;
  late String creatureText;
  String creatureHand = "paper";
  bool creatureVisible = true;
  bool creatureHandVisible = false;
  bool jailVisible = false;
  static const colors = {
    "blue": Color.fromARGB(255, 23, 137, 178),
    "yellow": Color.fromARGB(255, 193, 142, 22),
    "red": Color.fromARGB(255, 185, 34, 100),
    "gray": Color.fromARGB(255, 121, 121, 121),
  };
  var currentColors = ["blue", "yellow", "red"];
  bool canShoot = true;

  _CatchCreatureState();

  @override
  void initState() {
    game = CatchGame(
        bestOf: widget.creature.species.bestOf,
        creatureWinPct: widget.creature.species.winPct);
    creatureText = "I'm ${widget.creature.name}";
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          creatureText = game.status.gameText;
        });
      }
    });
  }

  void shoot(RockPaperScissors user) {
    if (!canShoot) return;
    canShoot = false;
    setState(() {
      var (hand, roundResult, status) = game.shoot(user);
      creatureHand = hand.name;
      creatureHandVisible = true;
      creatureText = status.roundText;
      for (var hand in RockPaperScissors.values) {
        if (hand != user) {
          currentColors[hand.index] = "gray";
        }
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        resetState();
      }
    });
  }

  void resetState() {
    setState(() {
      creatureText = game.status.gameText;
      creatureHandVisible = false;
      if (game.status.result == 0) {
        currentColors = ["blue", "yellow", "red"];
        canShoot = true;
      } else if (game.status.result == -1) {
        //Lost
        currentColors = ["gray", "gray", "gray"];
        creatureVisible = false;
      } else if (game.status.result == 1) {
        //Won
        currentColors = ["gray", "gray", "gray"];
        jailVisible = true;
        creatureState.catchCreature(widget.creature);
      }
    });
    if (game.status.result != 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catch ${widget.creature.species.name}')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(children: [
        Positioned.fill(
            child: Image(
                image: FileImage(File(widget.image.path)), fit: BoxFit.cover)),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
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
                child: AnimatedBouncingCreature(
                  species: widget.creature.species,
                  size: 350.0,
                ),
              ),
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
                Positioned(
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
  String roundText = "";
  String gameText = "";
}

class CatchGame {
  final int bestOf;
  final double creatureWinPct;
  static final Random _random = Random(); // Static random generator
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

  (RockPaperScissors, int, CatchGameStatus) shoot(RockPaperScissors user) {
    var majority = (bestOf / 2).ceil();
    var x = _random.nextDouble(); // Use static random instance
    var winLevel = creatureWinPct * 0.667;
    var tieLevel = winLevel + 0.333;
    RockPaperScissors computer;
    int roundResult;
    if (x < winLevel) {
      computer = RockPaperScissors.values[(user.index + 1) % 3];
      roundResult = -1;
      status.computer++;
      if (status.computer >= majority) {
        status.result = -1;
        status.gameText = "I've Escaped";
      }
    } else if (x < tieLevel) {
      computer = RockPaperScissors.values[user.index];
      roundResult = 0;
    } else {
      computer = RockPaperScissors.values[(user.index - 1 + 3) % 3];
      roundResult = 1;
      status.user++;
      if (status.user >= majority) {
        status.result = 1;
        status.gameText = "Caught! Nooo!";
      }
    }
    status.roundText = throwResult(status, roundResult, _random);
    if (status.result == 0) {
      if (status.user == status.computer) {
        status.gameText = "Tied ${status.user}-${status.computer}";
      } else if (status.user > status.computer) {
        status.gameText = "${status.user}-${status.computer} You";
      } else {
        status.gameText = "I'm up ${status.computer}-${status.user}";
      }
    }
    return (computer, roundResult, status);
  }

  int winner(RockPaperScissors user, RockPaperScissors computer) {
    if (user == computer) return 0;
    if (user == RockPaperScissors.rock) {
      if (computer == RockPaperScissors.paper) return -1;
    }
    if (user == RockPaperScissors.paper) {
      if (computer == RockPaperScissors.scissors) return -1;
    }
    if (user == RockPaperScissors.scissors) {
      if (computer == RockPaperScissors.rock) return -1;
    }
    return 1;
  }

  static String throwResult(CatchGameStatus status, int result, Random random) {
    if (result == 0) {
      // tie
      var list = [
        'Hmm. A Tie.',
        'Same thought!',
        'Twins!',
      ];
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

enum RockPaperScissors {
  rock,
  paper,
  scissors,
}
