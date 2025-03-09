import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String logoPath = "assets/icons/logo_300.png";
const String logoPathSVG = "assets/icons/logo.svg";
const String locationPinPathSVG = "assets/icons/pin.svg";
const String locationPinPath = "assets/icons/pin.png";
const String googleLogoPath = "assets/icons/google_logo_white.png";
const String appleLogoBlackPath = "assets/icons/apple_logo_black.png";
const String appleLogoWhitePath = "assets/icons/apple_logo_white.png";
const String defaultUserImagePath = "assets/images/default_profile_picture.png";

// ProfileImage is for now static
class default_user_profile_image extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(defaultUserImagePath, fit: BoxFit.cover);
  }
}

class logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(logoPath, fit: BoxFit.cover);
  }
}

class logo_custom extends StatelessWidget {
  logo_custom({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return new SvgPicture.asset(
      logoPathSVG,
      width: size,
      height: size,
      color: color,
    );
  }
}

class location_pin_custom extends StatelessWidget {
  location_pin_custom({required this.color, required this.size});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return new SvgPicture.asset(
      locationPinPathSVG,
      width: size,
      height: size,
      color: color,
    );
  }
}

class google_logo_custom extends StatelessWidget {
  google_logo_custom({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      googleLogoPath,
      height: size,
      width: size,
    );
  }
}

class apple_logo_custom extends StatelessWidget {
  apple_logo_custom({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      appleLogoWhitePath,
      height: size,
      width: size,
    );
  }
}
