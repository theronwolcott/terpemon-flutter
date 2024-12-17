import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redis/redis.dart';
import 'package:terpiez/globals.dart';
import 'package:terpiez/main.dart';

class RedisManager {
  static RedisManager? _instance;
  final Completer _completer = Completer();
  Command? _command;
  final conn = RedisConnection();
  bool _isConnected = true;

  RedisManager._internal() {
    // Initialize the connection and authentication process in the constructor
    connectAndAuthenticate();
  }

  static RedisManager getInstance() {
    _instance ??= RedisManager._internal();
    return _instance!;
  }

  // Combines connection and authentication logic
  Future<void> connectAndAuthenticate() async {
    try {
      await conn
          .connect(
              dotenv.env['REDIS_HOST'], int.parse(dotenv.env['REDIS_PORT']!))
          .then((Command command) {
        _command = command;
        authenticate();
      });
    } catch (e) {
      if (_isConnected) {
        scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text("Redis connection lost")));
        _isConnected = false;
      }
      //throw Exception('Failed to connect or authenticate to Redis: $e');
    }
  }

  // Handles the authentication
  Future<void> authenticate() async {
    _command!.send_object(
        ["AUTH", dotenv.env['REDIS_USER'], dotenv.env['REDIS_PASSWORD']]).then(
      (value) {
        _completer.complete();
        _isConnected = true;
        // start monitoring
        _startMonitoring();
      },
    );
  }

  void _startMonitoring() {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (!isForeground) {
        return;
      }
      bool isAlive = await _isConnectionAlive();

      // if (_isConnected) {
      //   _connectionStream.add('connected');
      //   _isConnected = false;
      // } else {
      //   _connectionStream.add('disconnected');
      //   _isConnected = true;
      // }
      if (isAlive) {
        if (!_isConnected) {
          // snackbar connection restored
          scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text("Redis connection restored")));
          _isConnected = true;
        }
      } else {
        if (_isConnected) {
          // snackbar connection lost
          scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text("Redis connection lost")));
          _isConnected = false;
        }
        connectAndAuthenticate();
      }
    });
  }

  Future<bool> _isConnectionAlive() async {
    Completer<bool> completer = Completer<bool>();
    try {
      await _command!.send_object(
          ["JSON.GET", "terpiez", '099fdbe454ef4c8182a29d8ac643b223']).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          completer.complete(false);
        },
      );
      if (!completer.isCompleted) completer.complete(true);
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  Future<Command> getCommand() async {
    await _completer
        .future; // Wait until the connection and authentication are complete
    return _command!; // Return the command object
  }

  void dispose() {
    _command!.get_connection().close();
  }
}
