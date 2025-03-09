import 'package:datingapp/services/database.dart';
import 'package:flutter/material.dart';

class OwnProfileImagePage extends StatefulWidget {
  OwnProfileImagePage(this.uid);

  final String uid;

  @override
  _OwnProfileImagePageState createState() => _OwnProfileImagePageState();
}

class _OwnProfileImagePageState extends State<OwnProfileImagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Hero(
          tag: "ownProfileImage",
          child: FutureBuilder<Image>(
            future: Database.getProfileImage(widget.uid),
            builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
              return Image(
                image: snapshot.data!.image,
              );
            },
          ),
        ),
      ),
    );
  }
}

class PeerProfileImagePage extends StatefulWidget {
  PeerProfileImagePage(this.uid);

  final String uid;

  @override
  _PeerProfileImagePageState createState() => _PeerProfileImagePageState();
}

class _PeerProfileImagePageState extends State<PeerProfileImagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder<Image>(
          future: Database.getProfileImage(widget.uid),
          builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
            return Image(
              image: snapshot.data!.image,
            );
          },
        ),
      ),
    );
  }
}
