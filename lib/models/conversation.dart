import 'package:dating_app_flutter/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  String? idConversation;
  List<dynamic>? users;
  Message? lastMessage;
  Map<String, dynamic>? userStatus;
  bool? accepted;

  Conversation({
    this.idConversation,
    this.users,
    this.lastMessage,
    this.userStatus,
    this.accepted,
  });

  factory Conversation.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Conversation(
      idConversation: doc.data()!['idConversation'],
      users: doc.data()!['users'],
      lastMessage: Message.fromMap(doc.data()!['lastMessage']),
      userStatus: doc.data()!['userStatus'],
      accepted: doc.data()!['accepted'],
    );
  }
}
