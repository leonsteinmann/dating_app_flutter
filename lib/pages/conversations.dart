import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating_app_flutter/models/conversation.dart';
import 'package:dating_app_flutter/pages/chat.dart';
import 'package:dating_app_flutter/services/database.dart';
import 'package:dating_app_flutter/values/colors.dart';
import 'package:dating_app_flutter/values/dimensions.dart';
import 'package:dating_app_flutter/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationsPage extends StatefulWidget {
  @override
  State createState() {
    return _ConversationsPageState();
  }
}

class _ConversationsPageState extends State<ConversationsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDeclineConversation(String idConversation) async {
    final declineConversationRequest = FirebaseFunctions.instanceFor(
      region: "europe-west3",
    ).httpsCallable('declineConversation');
    final message = {'idConversation': idConversation};
    print(message);
    await declineConversationRequest(message).then((result) => {print(result)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: standardPadding),
        child:
            (FirebaseAuth.instance.currentUser == null)
                ? Center(child: Text("Bitte anmelden"))
                : StreamBuilder(
                  stream: Database.streamConversations(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<Conversation>> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                        child: Text(
                          "Etwas ist schief gelaufen...",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.length == 0) {
                      return Center(
                        child: Text(
                          "Noch keine Nachrichten",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          "Snapshot has no data",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return new ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder:
                          (context, index) =>
                              buildChatEntry(context, snapshot.data![index]),
                    );
                  },
                ),
      ),
    );
  }

  Widget buildChatEntry(BuildContext context, Conversation conversation) {
    final dateFormat = DateFormat('HH:mm');
    final peerUserId =
        (FirebaseAuth.instance.currentUser!.uid == conversation.users![0])
            ? conversation.users![1]
            : conversation.users![0];
    final currUserId = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(conversation: conversation),
                ),
              );
            },
            child: UserProfileImageFutureBuilder(peerUserId, size: 28.0),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(conversation: conversation),
                ),
              );
            },
            child: UserProfileNameFutureBuilder(
              peerUserId,
              textStyle: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          subtitle: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(conversation: conversation),
                ),
              );
            },
            child: Text(
              "${conversation.lastMessage!.content!}",
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing:
              (conversation.accepted!)
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            conversation
                                .lastMessage!
                                .timestamp!
                                .millisecondsSinceEpoch,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 10.0,
                          color: explanationTextColor,
                        ),
                      ),
                      SizedBox(height: standardPadding),
                      SizedBox(
                        width: 15,
                        height: 15,
                        child:
                            (!(conversation.lastMessage!.read!) &&
                                    FirebaseAuth.instance.currentUser!.uid ==
                                        conversation.lastMessage!.idTo)
                                ? CircleAvatar(
                                  radius: 8,
                                  backgroundColor: mainRed,
                                )
                                : Container(),
                      ),
                    ],
                  )
                  : SizedBox(
                    width: 100,
                    height: 50,
                    child:
                        (conversation.lastMessage!.idFrom == currUserId)
                            ? Column(
                              children: [
                                Text(
                                  "Anfrage ausstehend",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.0,
                                    color: explanationTextColor,
                                  ),
                                ),
                              ],
                            )
                            : Container(
                              decoration: new BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: mainRedLight,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _onDeclineConversation(
                                        conversation.idConversation!,
                                      );
                                    },
                                    icon: Icon(Icons.close, color: mainRed),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Database.acceptConversationRequest(
                                        conversation,
                                      );
                                    },
                                    icon: Icon(Icons.done, color: mainGreen),
                                  ),
                                ],
                              ),
                            ),
                  ),
        ),
        SizedBox(height: 10),
        /*Row(
          children: [
            SizedBox(width: 10,),
            SizedBox(
              width: 60,
              height: 1,
              child: Container(color: lightGray,),
            ),
          ],
        )*/
      ],
    );
  }
}
