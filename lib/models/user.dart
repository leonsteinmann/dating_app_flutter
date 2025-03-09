import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppUser with ChangeNotifier {
  String? idUser;
  String? username;
  String? idProfilePicture;
  String? gender;
  String? searchingGender;
  String? description;
  Timestamp? birthday;
  List<dynamic>? encounters;
  List<dynamic>? pastEncounters;
  List<dynamic>? blockList;
  List<dynamic>? friendsList;

  AppUser(
      String idUser,
      String username,
      String idProfilePicture,
      String gender,
      String searchingGender,
      String description,
      Timestamp birthday,
      List<dynamic> encounters,
      List<dynamic> pastEncounters,
      List<dynamic> blockList,
      List<dynamic> friendsList) {
    this.idUser = idUser;
    this.username = username;
    this.idProfilePicture = idProfilePicture;
    this.gender = gender;
    this.searchingGender = searchingGender;
    this.description = description;
    this.birthday = birthday;
    this.encounters = encounters;
    this.pastEncounters = pastEncounters;
    this.blockList = blockList;
    this.friendsList = friendsList;
  }

  /*factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      idUser: data['idUser'],
      username: data['username'],
      idProfilePicture: data['idProfilePicture'],
      gender: data['gender'],
      searchingGender: data['searchingGender'],
      description: data['description'],
      age: data['age'],
    );
  }*/

  AppUser fromMap(Map<Object, dynamic> map) {
    AppUser user = new AppUser(
      map['idUser'],
      map['username'],
      map['idProfilePicture'],
      map['gender'],
      map['searchingGender'],
      (map.containsKey('description')) ? map['description'] : '',
      map['birthday'],
      map['encounters'],
      map['pastEncounters'],
      map['blockList'],
      map['friendsList'],
    );
    return user;
  }

  AppUser fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return fromMap(snapshot.data()!);
  }

  AppUser.fromMap(Map<Object, dynamic> map)
      : idUser = map['idUser'],
        username = map['username'],
        idProfilePicture = map['idProfilePicture'],
        gender = map['gender'],
        searchingGender = map['searchingGender'],
        description =
            (map.containsKey('description')) ? map['description'] : '',
        birthday = map['birthday'],
        encounters = map['encounters'],
        pastEncounters = map['pastEncounters'],
        blockList = map['blockList'],
        friendsList = map['friendsList'];

  AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : this.fromMap(snapshot.data()!);
}
