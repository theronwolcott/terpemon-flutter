import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserState extends ChangeNotifier {
  /* UserState tracks the user's id, whether or not they have sound on,
  and if they want to reset their account */
  static final UserState _instance = UserState._internal();

  factory UserState() => _instance;

  UserState._internal() {
    _loadUser();
  }

  String _id = "0";
  DateTime _startDate = DateTime.now();
  bool _isSoundOn = true;
  String uuidKey = 'UserState.uuid';
  String dateKey = 'UserState.date';
  String isSoundOnKey = 'UserState.isSoundOn';
  late SharedPreferences prefs;

  Future<void> _loadUser() async {
    // SharedPreferences saves this info locally (like a cookie)
    prefs = await SharedPreferences.getInstance();
    var uuidFromDisk = prefs.getString(uuidKey);
    var dateFromDisk = prefs.getString(dateKey);
    var isSoundOnFromDisk = prefs.getBool(isSoundOnKey);

    if (uuidFromDisk == null) {
      _id = const Uuid().v4();
      prefs.setString(uuidKey, _id);
    } else {
      _id = uuidFromDisk;
    }

    if (dateFromDisk == null) {
      _startDate = DateTime.now();
      prefs.setString(dateKey, _startDate.toIso8601String());
    } else {
      _startDate = DateTime.tryParse(dateFromDisk) ?? DateTime.now();
    }

    if (isSoundOnFromDisk == null) {
      _isSoundOn = true;
      prefs.setBool(isSoundOnKey, _isSoundOn);
    } else {
      _isSoundOn = isSoundOnFromDisk;
    }
    notifyListeners();
  }

  void reset() {
    _id = const Uuid().v4();
    prefs.setString(uuidKey, _id);
    _startDate = DateTime.now();
    prefs.setString(dateKey, _startDate.toIso8601String());
    _isSoundOn = true;
    prefs.setBool(isSoundOnKey, _isSoundOn);
    notifyListeners();
  }

  String get id => _id;
  int get playtime => DateTime.now().difference(_startDate).inDays;
  bool get isSoundOn => _isSoundOn;

  set isSoundOn(bool isSoundOn) {
    _isSoundOn = isSoundOn;
    prefs.setBool(isSoundOnKey, _isSoundOn);
  }
}
