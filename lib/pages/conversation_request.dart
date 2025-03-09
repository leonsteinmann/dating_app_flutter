import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:datingapp/models/encounter.dart';
import 'package:datingapp/values/colors.dart';
import 'package:datingapp/values/dimensions.dart';
import 'package:datingapp/widgets/animations/flying_location_pin.dart';
import 'package:datingapp/widgets/images.dart';
import 'package:datingapp/values/themes.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConversationRequestPage extends StatefulWidget {
  ConversationRequestPage({required this.encounter});

  final Encounter encounter;

  @override
  State createState() {
    return _ConversationRequestPage(encounter: encounter);
  }
}

class _ConversationRequestPage extends State<ConversationRequestPage>
    with TickerProviderStateMixin {
  Encounter encounter =
      Encounter("", [], GeoPoint(0, 0), Timestamp.fromDate(DateTime.now()));

  String peerUserId = "";
  bool _hasSendRequest = false;
  bool _hasCreatedConversation = false;
  final currFBUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController textEditingController = TextEditingController();

  AnimationController? _pinController1;
  AnimationController? _pinController2;
  AnimationController? _pinController3;
  AnimationController? _pinController4;
  AnimationController? _pinController5;
  AnimationController? _pinController6;
  AnimationController? _pinController7;

  _ConversationRequestPage({required this.encounter});

  @override
  void initState() {
    super.initState();
    peerUserId = getPeerUser(encounter.users!);
    _pinController1 = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _pinController2 = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this);
    _pinController3 = AnimationController(
        duration: const Duration(milliseconds: 5000), vsync: this);
    _pinController4 = AnimationController(
        duration: const Duration(milliseconds: 4000), vsync: this);
    _pinController5 = AnimationController(
        duration: const Duration(milliseconds: 7500), vsync: this);
    _pinController6 = AnimationController(
        duration: const Duration(milliseconds: 4500), vsync: this);
    _pinController7 = AnimationController(
        duration: const Duration(milliseconds: 3300), vsync: this);
  }

  @override
  void dispose() {
    _pinController1!.dispose();
    _pinController2!.dispose();
    _pinController3!.dispose();
    _pinController4!.dispose();
    _pinController5!.dispose();
    _pinController6!.dispose();
    _pinController7!.dispose();
    super.dispose();
  }

  void startLocationPins() {
    _pinController1!.repeat();
    _pinController2!.repeat();
    _pinController3!.repeat();
    _pinController4!.repeat();
    _pinController5!.repeat();
    _pinController6!.repeat();
    _pinController7!.repeat();
  }

  void stopLocationPins() {
    _pinController1!.stop();
    _pinController2!.stop();
    _pinController3!.stop();
    _pinController4!.stop();
    _pinController5!.stop();
    _pinController6!.stop();
    _pinController7!.stop();
  }

  getPeerUser(List<dynamic> users) {
    if (users[0] == currFBUser.uid) {
      return users[1];
    } else {
      return users[0];
    }
  }

  void _onSendRequest(String content) async {
    final FirebaseFirestore _db = FirebaseFirestore.instance;

    setState(() {
      _hasSendRequest = true;
    });

    final createConversationRequest =
        FirebaseFunctions.instanceFor(region: "europe-west3")
            .httpsCallable('createConversation');
    final message = {
      'idConversation': encounter.idEncounter,
      'idFrom': currFBUser.uid,
      'idTo': peerUserId,
      'lastMessage': <String, dynamic>{
        'idMessage':
            "${currFBUser.uid + "_" + DateTime.now().millisecondsSinceEpoch.toString()}",
        'idFrom': currFBUser.uid,
        'idTo': getPeerUser(encounter.users!),
        'timestamp': Timestamp.fromDate(DateTime.now()).seconds,
        'content': content,
        'read': false
      },
    };
    print(message);
    await createConversationRequest(message).then((result) => {
          print(result),
        });

    final DocumentReference messageDoc = _db
        .collection('conversations')
        .doc(encounter.idEncounter)
        .collection('messages')
        .doc(
            "${currFBUser.uid + "_" + DateTime.now().millisecondsSinceEpoch.toString()}");

    _db.runTransaction((Transaction transaction) async {
      await transaction.set(
        messageDoc,
        <String, dynamic>{
          'content': content,
          'idFrom': currFBUser.uid,
          'idMessage':
              "${currFBUser.uid + "_" + DateTime.now().millisecondsSinceEpoch.toString()}",
          'idTo': peerUserId,
          'read': false,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        },
      );
    });
    setState(() {
      _hasCreatedConversation = true;
      startLocationPins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => Scaffold(
        appBar: AppBar(),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(children: [
              FlyingLocationPin(
                controller: _pinController1!,
                xRelativeOffset: 0.2,
                yOffset: 300,
                color: mainRed,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController2!,
                xRelativeOffset: 0.4,
                yOffset: 400,
                color: mainRedDark,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController3!,
                xRelativeOffset: 0.7,
                yOffset: 350,
                color: mainRedLight,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController4!,
                xRelativeOffset: 0.9,
                yOffset: 300,
                color: mainRed,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController5!,
                xRelativeOffset: 0.6,
                yOffset: 300,
                color: mainRed,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController6!,
                xRelativeOffset: 0.3,
                yOffset: 350,
                color: mainRedLight,
              )
            ]),
            Column(children: [
              FlyingLocationPin(
                controller: _pinController7!,
                xRelativeOffset: 0.8,
                yOffset: 300,
                color: mainRed,
              )
            ]),
            Padding(
              padding: const EdgeInsets.all(standardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //image
                  ListView(
                    shrinkWrap: true,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: standardPadding,
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: -28.5 * math.pi / 180,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        location_pin_custom(
                                            color: mainRed, size: 150.0),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10.0),
                                          child: UserProfileImageFutureBuilder(
                                            peerUserId,
                                            size: 40.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 85,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 85,
                                  ),
                                  Transform.rotate(
                                    angle: 28.5 * math.pi / 180,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        location_pin_custom(
                                            color: mainRed, size: 150.0),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10.0),
                                          child: UserProfileImageFutureBuilder(
                                            currFBUser.uid,
                                            size: 40.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            (!_hasCreatedConversation)
                                ? "Mach den ersten Schritt..."
                                : "Nachricht zugestellt!",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            (!_hasCreatedConversation)
                                ? "Mit der ersten Nachricht stellt du eine Kontaktanfrage."
                                : "Klasse! Der erste Schritt ist getan. Jetzt heißt es abwarten. \nAber Vorfreude ist ja bekanntlich die schönste Freude.",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: standardPadding * 2,
                          ),
                          (_hasSendRequest && !_hasCreatedConversation)
                              ? CircularProgressIndicator()
                              : Container(),
                          (_hasSendRequest && _hasCreatedConversation)
                              ? Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: standardPadding / 2,
                                      horizontal: standardPadding * 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Container(
                                            decoration: new BoxDecoration(
                                              color: (theme.themeMode == "dark")
                                                  ? ownMessageDarkScheme
                                                  : ownMessageLightScheme,
                                              borderRadius:
                                                  new BorderRadius.all(
                                                const Radius.circular(
                                                    chatBubbleRadius),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .shadowColor,
                                                  offset: Offset(0.0, 1.0),
                                                  blurRadius: 3.0,
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(
                                                standardPadding * 1.5),
                                            child: Text(
                                                textEditingController.text,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium)),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                  (!_hasSendRequest) ? buildInput() : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput() {
    return Container(
      margin: EdgeInsets.all(standardPadding),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
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
                onPressed: () => _onSendRequest(textEditingController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
