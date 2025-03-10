import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app_flutter/models/user.dart';
import 'package:dating_app_flutter/services/database.dart';
import 'package:flutter/material.dart';

class LocationModeSelector with ChangeNotifier {
  bool isLocationModeOn = false;
  String prevHash = "";
  DateTime lastUpdate = DateTime.now();

  void setIsLocationModeOn(bool _isLocationModeOn) async {
    isLocationModeOn = _isLocationModeOn;
    notifyListeners();
  }

  void setPrevHash(String _prevHash) async {
    prevHash = _prevHash;
    notifyListeners();
  }

  void setLastUpdate(DateTime _lastUpdate) async {
    lastUpdate = _lastUpdate;
    notifyListeners();
  }
}

class CurrUser with ChangeNotifier {
  AppUser? currUser = AppUser(
    "",
    "",
    "",
    "",
    "",
    "",
    Timestamp.now(),
    [],
    [],
    [],
    [],
  );

  void updateCurrentUser(uid) async {
    currUser = await Database.getAppUser(uid);
    notifyListeners();
  }

  void signOutCurrentUser() {
    currUser = null;
    notifyListeners();
  }
}
