import 'package:firebase_messaging/firebase_messaging.dart';

/// Message route arguments.
class MessageArguments {
  MessageArguments(this.message, this.openedApplication);

  /// The RemoteMessage
  final RemoteMessage message;

  /// Whether this message caused the application to open.
  final bool openedApplication;
}
