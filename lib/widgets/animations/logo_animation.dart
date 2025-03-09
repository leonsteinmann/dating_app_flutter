import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LogoAnimation extends StatelessWidget {
  final boxSize;
  final logoSize;
  LogoAnimation(this.boxSize, this.logoSize);

  /// Adding Color, Size
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: boxSize,
      child: SizedBox.square(
          dimension: logoSize,
          child: RiveAnimation.asset(
            "assets/icons/logo_animation.riv",
          )),
    );
  }
}
