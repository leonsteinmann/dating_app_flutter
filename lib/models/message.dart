import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String? idMessage;
  String? content;
  String? idFrom;
  String? idTo;
  Timestamp? timestamp;
  bool? read;

  Message(
      {this.idMessage,
      this.content,
      this.idFrom,
      this.idTo,
      this.timestamp,
      this.read});

  factory Message.fromFireStore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Message(
      idMessage: doc.data()!['idMessage'],
      content: doc.data()!['content'],
      idFrom: doc.data()!['idFrom'],
      idTo: doc.data()!['idTo'],
      timestamp: doc.data()!['timestamp'],
      read: doc.data()!['read'],
    );
  }

  Message.fromMap(Map<String, dynamic> map)
      : idMessage = map['idMessage'],
        content = map['content'],
        idFrom = map['idFrom'],
        idTo = map['idTo'],
        timestamp = map['timestamp'],
        read = map['read'];
}
