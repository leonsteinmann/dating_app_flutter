import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlyingLocationPin extends StatelessWidget {
  FlyingLocationPin(
      {Key? key,
      required this.controller,
      required this.xRelativeOffset,
      required this.yOffset,
      required this.color})
      :

        // Each animation defined here transforms its value during the subset
        // of the controller's duration defined by the animation's interval.
        // For example the opacity animation transforms its value during
        // the first 10% of the controller's duration.

        yPosition = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.0,
              1.000,
              curve: Curves.easeIn,
            ),
          ),
        ),
        appearOpacity = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.000,
              0.300,
              curve: Curves.ease,
            ),
          ),
        ),
        dismissOpacity = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              0.900,
              1.000,
              curve: Curves.ease,
            ),
          ),
        ),
        super(key: key);

  final Animation<double> controller;
  final double xRelativeOffset;
  final double yOffset;
  final Animation<double> yPosition;
  final Color color;
  final Animation<double> appearOpacity;
  final Animation<double> dismissOpacity;

  // This function is called each time the controller "ticks" a new frame.
  // When it runs, all of the animation's values will have been
  // updated to reflect the controller's current value.
  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Container(
      padding: EdgeInsets.only(
        top: (MediaQuery.of(context).size.height - yOffset) -
            ((MediaQuery.of(context).size.height - yOffset)) * yPosition.value,
        left: MediaQuery.of(context).size.width -
            (xRelativeOffset * MediaQuery.of(context).size.width),
      ),
      alignment: Alignment.bottomLeft,
      child: Opacity(
        opacity: appearOpacity.value,
        child: Opacity(
            opacity: dismissOpacity.value,
            child: SizedBox(
                height: 50,
                width: 40,
                child: SvgPicture.asset(
                  'assets/icons/pin.svg',
                  color: color,
                ))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: _buildAnimation,
      animation: controller,
    );
  }
}
