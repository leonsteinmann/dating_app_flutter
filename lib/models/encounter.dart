import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Encounter with ChangeNotifier{

  String? idEncounter;
  List? users;
  GeoPoint? geoPoint;
  Timestamp? timestamp;

  Encounter(String idUser, List users, GeoPoint geoPoint, Timestamp timestamp) {
    this.idEncounter = idEncounter;
    this.users = users;
    this.geoPoint = geoPoint;
    this.timestamp = timestamp;
  }

  /*Encounter({this.idEncounter, this.users, this.geoPoint, this.timestamp});

  factory Encounter.fromFireStore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data()!;

    return Encounter(
      idEncounter: data['idEncounter'],
      users: data["users"],
      geoPoint: data['geoPoint'],
      timestamp: data['geoPoint'],
    );
  }*/

  Encounter fromMap(Map<dynamic, dynamic> map) {
    Encounter encounter = new Encounter(
      map['idEncounter'],
      map['users'],
      map['geoPoint'],
      map['timestamp'],
    );
    return encounter;
  }

  Encounter fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return fromMap(snapshot.data()!);
  }

  Encounter.fromMap(Map<dynamic, dynamic> map)
      : idEncounter = map['idEncounter'],
        users = map['users'],
        geoPoint = map['geoPoint'],
        timestamp = map['timestamp'];

  Encounter.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot): this.fromMap(snapshot.data()!);

}