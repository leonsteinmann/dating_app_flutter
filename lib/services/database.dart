import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/models/conversation.dart';
import 'package:datingapp/models/encounter.dart';
import 'package:datingapp/models/message.dart';
import 'package:datingapp/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class Database {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Encounter> getEncounter(String encounterID) async {
    Encounter encounter = Encounter("", [], GeoPoint(21, 48), Timestamp.now());
    try {
      await FirebaseFirestore.instance
          .collection('encounters')
          .doc(encounterID)
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> encounterSnapshot) {
        Encounter requestedEncounter =
            Encounter.fromSnapshot(encounterSnapshot);
        return encounter = requestedEncounter;
      });
      print("Got Encounter from Firestore: " + encounter.idEncounter!);
      return encounter;
    } catch (e) {
      print("error in getting Encounter");
      print(e);
      return encounter;
    }
  }

  static void moveEncounterToPastEncounters(idEncounter, String idUser) {
    final DocumentReference userReference = _db.collection('users').doc(idUser);
    List<dynamic> idEncounterList = [idEncounter];
    userReference.update({
      "encounters": FieldValue.arrayRemove(idEncounterList),
      "pastEncounters": FieldValue.arrayUnion(idEncounterList),
    });
  }

  static Stream<Conversation> streamConversation(String cid) {
    return _db.collection('conversations').doc(cid).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> doc) =>
            Conversation.fromFireStore(doc));
  }

  static Stream<List<Conversation>> streamConversations(String uid) {
    return _db
        .collection('conversations')
        .orderBy('lastMessage.timestamp', descending: true)
        .where('users', arrayContains: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> list) => list.docs
            .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
                Conversation.fromFireStore(doc))
            .toList());
  }

  static Stream<List<Message>> streamConversationMessages(
    String idConversation,
  ) {
    print('streamed messages');
    return _db
        .collection('conversations')
        .doc(idConversation)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> list) => list.docs
            .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
                Message.fromFireStore(doc))
            .toList());
  }

  static void updateMessageRead(Conversation conversation) {
    final DocumentReference documentReference =
        _db.collection('conversations').doc(conversation.idConversation);

    documentReference.update({
      'lastMessage': {
        'idMessage': conversation.lastMessage!.idMessage,
        'content': conversation.lastMessage!.content,
        'idFrom': conversation.lastMessage!.idFrom,
        'idTo': conversation.lastMessage!.idTo,
        'timestamp': conversation.lastMessage!.timestamp,
        'read': true,
      },
    });
  }

  static void acceptConversationRequest(Conversation conversation) {
    final DocumentReference documentReference =
        _db.collection('conversations').doc(conversation.idConversation);

    documentReference.update({
      "accepted": true,
      "userStatus.${FirebaseAuth.instance.currentUser!.uid}": true,
    });
  }

  static void sendMessage(
    String idConversation,
    String idFrom,
    String idTo,
    String content,
    Timestamp timestamp,
  ) {
    final DocumentReference conversationDoc =
        _db.collection('conversations').doc(idConversation);

    conversationDoc.update(<String, dynamic>{
      'lastMessage': <String, dynamic>{
        'idMessage':
            "${idFrom + "_" + timestamp.millisecondsSinceEpoch.toString()}",
        'idFrom': idFrom,
        'idTo': idTo,
        'timestamp': timestamp,
        'content': content,
        'read': false
      },
    }).then((dynamic success) {
      final DocumentReference messageDoc = _db
          .collection('conversations')
          .doc(idConversation)
          .collection('messages')
          .doc("${idFrom + "_" + timestamp.millisecondsSinceEpoch.toString()}");

      _db.runTransaction((Transaction transaction) async {
        await transaction.set(
          messageDoc,
          <String, dynamic>{
            'content': content,
            'idFrom': idFrom,
            'idMessage':
                "${idFrom + "_" + timestamp.millisecondsSinceEpoch.toString()}",
            'idTo': idTo,
            'read': false,
            'timestamp': timestamp,
          },
        );
      });
    });
  }

  // User
  static Future<AppUser> getAppUser(String uid) async {
    AppUser dummyUser =
        AppUser("", "", "", "", "", "", Timestamp.now(), [], [], [], []);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> userSnapshot) {
        AppUser requestedUser = AppUser.fromSnapshot(userSnapshot);
        return dummyUser = requestedUser;
      });
      print("Got User from Firestore: " + dummyUser.username!);
      return dummyUser;
    } catch (e) {
      print("error getting user form firestore");
      print(e);
      return dummyUser;
    }
  }

  static Stream<List<AppUser>> getAppUsersByList(List<String> userIds) {
    final List<Stream<AppUser>> streams = [];
    for (String id in userIds) {
      streams.add(_db.collection('users').doc(id).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> snap) =>
              AppUser.fromMap(snap.data()!)));
    }
    return StreamZip<AppUser>(streams).asBroadcastStream();
  }

  static Future<Image> getProfileImage(String uid,
      {String? profilePictureId}) async {
    Image image = Image.asset(
      "assets/images/default_profile_picture.png",
      height: 40.0,
      width: 40.0,
    );

    Directory extStorageDir = await getTemporaryDirectory();

    final userDir = Directory('${extStorageDir.path}/users');
    if (!(await userDir.exists())) {
      await userDir.create();
    }

    final userImageDir = Directory('${extStorageDir.path}/users/$uid');
    if (await userImageDir.exists()) {
      final List<FileSystemEntity> userImageDirList = userImageDir.listSync();

      if (profilePictureId != null) {
        //check if newest picture is downloaded. If not, download it and replace it
        for (var entity in userImageDirList) {
          if (entity is File) {
            List<String> imageFilePathParts = entity.path.split("/");
            if (imageFilePathParts.last == profilePictureId.split(".")[0]) {
              return image = Image.file(entity);
            }
          }
        }
        //Picture was not found. Download it and delete older pictures
        final File newUserProfileImage =
            File('${extStorageDir.path}/users/$uid/$profilePictureId.jpg');
        try {
          final Reference userProfileImageRef = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(uid)
              .child('$uid.jpg');
          await userProfileImageRef.writeToFile(newUserProfileImage);
          //Delete older pictures
          for (var entity in userImageDirList) {
            if (entity is File && entity.path != newUserProfileImage.path) {
              entity.delete();
            }
          }
          return image = Image.file(newUserProfileImage);
        } catch (e) {
          //user has deleted the picture, also delete all from cache and return default picture.
          for (var entity in userImageDirList) {
            if (entity is File) {
              await entity.delete();
            }
          }
          return image = Image.asset(
            "assets/images/default_profile_picture.png",
            height: 40.0,
            width: 40.0,
          );
        }
      } else {
        if (userImageDirList.length > 0) {
          final userImageFile = userImageDirList[0];
          if (userImageFile is File) {
            return Image.file(userImageFile);
          }
        } else {
          return image = Image.asset(
            "assets/images/default_profile_picture.png",
            height: 70,
            width: 70,
          );
        }
      }
    } else {
      //No picture of the user has been downloaded yet.
      //print("UserImageDir not found. Creating new one...");
      await userImageDir.create();
      if (profilePictureId == null) {
        profilePictureId = "${uid}_0";
      }
      final File newUserProfileImage =
          File('${extStorageDir.path}/users/$uid/$profilePictureId.jpg');
      try {
        final Reference userProfileImageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(uid)
            .child('$uid.jpg');
        await userProfileImageRef.writeToFile(newUserProfileImage);
        //print("Wrote image to file");
        return image = Image.file(newUserProfileImage);
      } catch (e) {
        //print("Error when downloading user picture: $e");
        return image = Image.asset(
          "assets/images/default_profile_picture.png",
          height: 70,
          width: 70,
        );
      }
    }
    return image;
  }

  static Future<List<Map<String, dynamic>>> getStoryImages(String uid) async {
    List<Map<String, dynamic>> files = [];

    final Reference userStoryRef =
        FirebaseStorage.instance.ref().child('users').child(uid).child('story');
    final results = await userStoryRef.listAll();

    await Future.forEach<Reference>(results.items, (file) async {
      final String fileUrl = await file.getDownloadURL();
      final FullMetadata fileMeta = await file.getMetadata();
      files.add({
        "url": fileUrl,
        "path": file.fullPath,
        "name": file.name,
        "uploaded_by": fileMeta.customMetadata?['uploaded_by'] ?? 'Nobody',
        "description":
            fileMeta.customMetadata?['description'] ?? 'No description'
      });
      files.sort((b, a) => a['name'].compareTo(b['name']));
    });
    return files;
  }
}
