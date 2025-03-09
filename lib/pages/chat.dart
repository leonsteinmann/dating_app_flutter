import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/models/conversation.dart';
import 'package:datingapp/models/message.dart';
import 'package:datingapp/services/database.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/values/themes.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'profile_Image_pages.dart';

class ChatPage extends StatefulWidget {
  ChatPage({required this.conversation});

  final Conversation conversation;

  @override
  State createState() {
    return _ChatPageState(conversation: conversation);
  }
}

class _ChatPageState extends State<ChatPage> {
  Conversation conversation = Conversation();
  String peerUserId = "";
  final currFBUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  _ChatPageState({required this.conversation});

  @override
  void initState() {
    super.initState();
    peerUserId =
        (FirebaseAuth.instance.currentUser!.uid == conversation.users![0])
            ? conversation.users![1]
            : conversation.users![0];
    if (!conversation.lastMessage!.read! &&
        conversation.lastMessage!.idTo == currFBUser.uid) {
      Database.updateMessageRead(conversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OwnProfileImagePage(peerUserId)));
            },
            child: Row(
              children: [
                UserProfileImageFutureBuilder(
                  peerUserId,
                  size: 20.0,
                ),
                SizedBox(
                  width: standardPadding,
                ),
                UserProfileNameFutureBuilder(
                  peerUserId,
                  textStyle:
                      Theme.of(context).textTheme.headlineLarge!.copyWith(
                            color: mainRed,
                          ),
                ),
              ],
            ),
          ),
          actions: [
            PopupMenuButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.more_vert, color: mainRed),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: GestureDetector(child: Text("Nutzer melden")),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder(
              stream: Database.streamConversation(conversation.idConversation!),
              builder:
                  (BuildContext context, AsyncSnapshot<Conversation> snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text("Etwas ist schief gelaufen..."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(child: Text("Snapshot has no data"));
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildMessages(theme, context, snapshot.data!),
                    (!snapshot.data!.accepted! &&
                            snapshot.data!.lastMessage!.idTo ==
                                FirebaseAuth.instance.currentUser!.uid)
                        ? buildAcceptButtons(context, snapshot.data!)
                        : Container(),
                    (snapshot.data!.userStatus![conversation.users![0]] ==
                                true &&
                            snapshot.data!
                                    .userStatus![conversation.users![1]] ==
                                true)
                        ? buildInput(theme)
                        : Container(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAcceptButtons(BuildContext context, Conversation con) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done,
                color: Colors.white,
              ),
              SizedBox(
                width: 5,
              ),
              Text('Anfrage akzeptieren'),
            ],
          ),
          onPressed: () {
            Database.acceptConversationRequest(con);
          },
        ),
        ElevatedButton(
          child: Text('Anfrage ablehnen'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget buildMessages(
      ThemeNotifier themeNotifier, BuildContext context, Conversation con) {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: StreamBuilder(
          stream: Database.streamConversationMessages(con.idConversation!),
          builder:
              (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error);
              return Center(child: Text("Etwas ist schief gelaufen..."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.length == 0) {
              print(snapshot.data);
              return Center(child: Text("Noch keine Nachrichten"));
            }
            print(snapshot.data!.length);
            return new ListView.builder(
              shrinkWrap: true,
              reverse: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => buildMessageEntry(
                  themeNotifier, index, snapshot.data![index]),
              controller: listScrollController,
            );
          },
        ),
      ),
    );
  }

  Widget buildMessageEntry(
      ThemeNotifier themeNotifier, int index, Message message) {
    if (message.idFrom == FirebaseAuth.instance.currentUser!.uid) {
      // Right (my message)
      return Container(
        margin: EdgeInsets.symmetric(
            vertical: standardPadding / 2, horizontal: standardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                decoration: new BoxDecoration(
                  color: (themeNotifier.themeMode == "dark")
                      ? ownMessageDarkScheme
                      : ownMessageLightScheme,
                  borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(chatBubbleRadius),
                    bottomLeft: const Radius.circular(chatBubbleRadius),
                    bottomRight: const Radius.circular(chatBubbleRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      offset: Offset(0.0, 1.0),
                      blurRadius: 3.0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(standardPadding * 1.5),
                child: Text(message.content!),
              ),
            ),
          ],
        ),
      );
    } else {
      // Left (peer message)
      return Container(
        margin: EdgeInsets.symmetric(
            vertical: standardPadding / 2, horizontal: standardPadding),
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Flexible(
                child: Container(
                  //width: MediaQuery.of(context).size.width*2/3,
                  decoration: new BoxDecoration(
                    color: (themeNotifier.themeMode == "dark")
                        ? peerMessageDarkScheme
                        : peerMessageLightScheme,
                    borderRadius: new BorderRadius.only(
                      topRight: const Radius.circular(chatBubbleRadius),
                      bottomRight: const Radius.circular(chatBubbleRadius),
                      bottomLeft: const Radius.circular(chatBubbleRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor,
                        offset: Offset(0.0, 1.0),
                        blurRadius: 3.0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(standardPadding * 1.5),
                  child: Text(message.content!),
                ),
              )
            ])
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    }
  }

  Widget buildInput(ThemeNotifier themeNotifier) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: new BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50), topRight: Radius.circular(50)),
          color: (themeNotifier.themeMode == "dark")
              ? ownMessageDarkScheme
              : ownMessageLightScheme),
      child: Row(
        children: <Widget>[
          // Edit text
          Flexible(
            child: Container(
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: TextField(
                    autofocus: true,
                    minLines: 1,
                    maxLines: 5,
                    controller: textEditingController,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Schreibe eine Nachricht',
                    ),
                  )),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.send,
                size: 25,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => onSendMessage(textEditingController.text),
            ),
          ),
        ],
      ),
    );
  }

  void onSendMessage(String content) {
    final peerUserId = (currFBUser.uid == conversation.users![0])
        ? conversation.users![1]
        : conversation.users![0];

    if (content.trim() != '') {
      textEditingController.clear();
      content = content.trim();
      Database.sendMessage(conversation.idConversation!, currFBUser.uid,
          peerUserId, content, Timestamp.now());
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}
