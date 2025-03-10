import 'package:dating_app_flutter/models/user.dart';
import 'package:dating_app_flutter/services/database.dart';
import 'package:dating_app_flutter/values/colors.dart';
import 'package:flutter/material.dart';

class UserProfileImageFutureBuilder extends StatefulWidget {
  final size;
  final uid;
  final profilePictureId;
  UserProfileImageFutureBuilder(
    this.uid, {
    this.size = 30.0,
    this.profilePictureId,
  });

  @override
  State createState() {
    return _UserProfileImageFutureBuilderState(uid, size, profilePictureId);
  }
}

class _UserProfileImageFutureBuilderState
    extends State<UserProfileImageFutureBuilder> {
  _UserProfileImageFutureBuilderState(
    this.uid,
    this.size,
    this._profilePictureId,
  );

  final uid;
  final double size;
  final String _profilePictureId;
  late Future<Image> _futureImage;

  @override
  void initState() {
    super.initState();
    _futureImage = Database.getProfileImage(
      uid,
      profilePictureId: _profilePictureId,
    );
    //print("IMAGEBUILDER INIT CALLED");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Image>(
      future: _futureImage,
      builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
        if (snapshot.hasData) {
          return CircleAvatar(
            radius: size,
            backgroundImage: (snapshot.data)!.image,
          );
        } else {
          return CircleAvatar(radius: size, backgroundColor: middleGray);
        }
      },
    );
  }
}

class UserProfileNameFutureBuilder extends StatefulWidget {
  final uid;
  final textStyle;
  UserProfileNameFutureBuilder(this.uid, {this.textStyle});

  @override
  State createState() {
    return _UserProfileNameFutureBuilderState(uid, textStyle);
  }
}

class _UserProfileNameFutureBuilderState
    extends State<UserProfileNameFutureBuilder> {
  final _textStyle;
  final _uid;
  late Future<AppUser> _futureUser;
  _UserProfileNameFutureBuilderState(this._uid, this._textStyle);

  @override
  void initState() {
    super.initState();
    _futureUser = Database.getAppUser(_uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: _futureUser,
      builder: (BuildContext context, AsyncSnapshot<AppUser> snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!.username!,
            style:
                (_textStyle != null)
                    ? _textStyle
                    : Theme.of(context).textTheme.headlineLarge,
          );
        } else {
          return Container(
            width: 50,
            height: 20,
            decoration: BoxDecoration(color: middleGray),
          );
        }
      },
    );
  }
}
