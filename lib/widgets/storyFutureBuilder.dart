import 'dart:async';

import 'package:datingapp/services/database.dart';
import 'package:datingapp/widgets/userFutureBuilders.dart';
import 'package:flutter/material.dart';

class StoryFutureBuilder extends StatefulWidget {
  final size;
  final uid;
  StoryFutureBuilder(this.uid, {this.size = 30.0});

  @override
  State createState() {
    return _StoryFutureBuilderState(uid, size);
  }
}

class _StoryFutureBuilderState extends State<StoryFutureBuilder> {
  _StoryFutureBuilderState(this.uid, this.size);

  final uid;
  final double size;
  late Future<List<Map<String, dynamic>>> _futureImages;

  // timer
  int _pos = 0;
  Timer? _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (Timer t) {
      setState(() {
        if (_pos > 100) {
          _pos = 0;
        }
        _pos += 1;
      });
    });
    _futureImages = Database.getStoryImages(uid);
    super.initState();
    //print("IMAGEBUILDER INIT CALLED");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureImages,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData && snapshot.data!.length > 0) {
            final Map<String, dynamic> image =
                snapshot.data![_pos % snapshot.data!.length];
            return Stack(
              alignment: Alignment.topLeft,
              children: [
                Image.network(image['url']),
                Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: Column(
                      children: [
                        UserProfileImageFutureBuilder(uid),
                        SizedBox(
                          height: 5,
                        ),
                        UserProfileNameFutureBuilder(
                          uid,
                          textStyle: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    )),
              ],
            );
          } else {
            return SizedBox.square(
              dimension: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  UserProfileImageFutureBuilder(uid, size: 100.0),
                  SizedBox(
                    height: 10,
                  ),
                  UserProfileNameFutureBuilder(uid),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
