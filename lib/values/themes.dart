import 'package:datingapp/services/storageManager.dart';
import 'package:datingapp/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData = ThemeData();
  ThemeData getTheme() => _themeData;
  String themeMode = "";

  ThemeNotifier() {
    StorageManager.readData('themeMode').then((value) {
      print('value read from storage: ' + value.toString());
      var brightness = SchedulerBinding.instance.window.platformBrightness;
      String systemTheme;
      if (brightness == Brightness.dark) {
        systemTheme = 'dark';
      } else {
        systemTheme = 'light';
      }
      themeMode = value ?? systemTheme;
      if (themeMode == 'light') {
        _themeData = lightTheme;
      } else {
        print('setting dark theme');
        _themeData = darkTheme;
      }
      notifyListeners();
    });
  }

  void setDarkMode() async {
    _themeData = darkTheme;
    themeMode = "dark";
    StorageManager.saveData('themeMode', 'dark');
    notifyListeners();
  }

  void setLightMode() async {
    _themeData = lightTheme;
    themeMode = "light";
    StorageManager.saveData('themeMode', 'light');
    notifyListeners();
  }

  final lightTheme = ThemeData(
    brightness: Brightness.light,
    visualDensity: VisualDensity(vertical: 0.5, horizontal: 0.5),
    primaryColor: mainRed,
    primaryColorLight: mainRedLight,
    primaryColorDark: mainRedDark,
    hintColor: mainRed,
    scaffoldBackgroundColor: backgroundLightScheme,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: mainRed, hoverColor: mainRedDark),
    cardColor: cardColorLightScheme,
    dividerColor: mainTextLightScheme,
    shadowColor: Color(0xffbbbbbb),
    focusColor: mainRed,
    iconTheme: IconThemeData(
      color: darkIconColor,
    ),
    appBarTheme: AppBarTheme(
        color: Colors.white,
        iconTheme: IconThemeData(
          color: mainRed,
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: mainRed,
        )),
    textTheme: TextTheme(
      //
      headlineMedium: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: mainTextLightScheme,
      ),
      // Profile Name Small
      headlineLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: mainTextLightScheme,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: mainTextLightScheme,
      ),
    ),
    bottomAppBarTheme: BottomAppBarTheme(color: Colors.white),
  );

  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity(vertical: 0.5, horizontal: 0.5),
    primaryColor: mainTextLightScheme,
    primaryColorLight: mainRedUltraDark,
    primaryColorDark: backgroundDarkScheme,
    scaffoldBackgroundColor: backgroundDarkScheme,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: mainRed,
      hoverColor: mainRedDark,
    ),
    cardColor: cardColorDarkScheme,
    dividerColor: mainTextLightScheme,
    shadowColor: darkGray,
    focusColor: mainRed,
    iconTheme: IconThemeData(
      color: lightIconColor,
    ),
    appBarTheme: AppBarTheme(
        color: Colors.black,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: mainTextDarkScheme,
        )),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: mainTextDarkScheme,
      ),
      // Profile Name Small (Chats)
      headlineLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: mainTextDarkScheme,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: mainTextDarkScheme,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: mainRed),
    bottomAppBarTheme: BottomAppBarTheme(color: mainTextLightScheme),
  );
}

/*
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  visualDensity: VisualDensity(vertical: 0.5, horizontal: 0.5),
  primaryColor: mainRed,
  primaryColorBrightness: Brightness.light,
  primaryColorLight: mainRedLight,
  primaryColorDark: mainRedDark,
  accentColor: mainRed,
  accentColorBrightness: Brightness.light,
  scaffoldBackgroundColor: backgroundLightScheme,
  bottomAppBarColor: Colors.white,
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    foregroundColor: mainRed,
    hoverColor: mainRedDark
  ),
  buttonColor: mainRed,
  cardColor: cardColorLightScheme,
  dividerColor: mainTextLightScheme,
  shadowColor: Color(0xffbbbbbb),
  focusColor: mainRed,
  iconTheme: IconThemeData(
      color: darkIconColor,
  ),
  accentIconTheme: IconThemeData(
      color: lightIconColor,
  ),
  appBarTheme: AppBarTheme(
    color: mainRed,
    iconTheme: IconThemeData(
      color: appBarTitleColor,
    ),
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: appBarTitleColor,
    )
  ),
  textTheme: TextTheme(
    // Location Tracker On/Off
    headline1: GoogleFonts.roboto(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: mainTextLightScheme,
    ),
    headline2: GoogleFonts.roboto(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: explanationTextColor,
    ),
    //
    headlineMedium: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: mainTextLightScheme,
    ),
    // Profile Name Small
    headlineLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: mainTextLightScheme,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: mainTextLightScheme,
    ),
    // mainRed as Background
    bodyText2: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: textOnMainRedColor,
    ),

  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  visualDensity: VisualDensity(vertical: 0.5, horizontal: 0.5),
  primaryColor: mainTextLightScheme,
  primaryColorBrightness: Brightness.dark,
  primaryColorLight: mainRedUltraDark,
  primaryColorDark: backgroundDarkScheme,
  accentColor: mainRed,
  accentColorBrightness: Brightness.dark,
  scaffoldBackgroundColor: backgroundDarkScheme,
  bottomAppBarColor: mainTextLightScheme,
  buttonColor: mainRed,
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: mainRed,
      hoverColor: mainRedDark,
  ),
  cardColor: cardColorDarkScheme,
  dividerColor: mainTextLightScheme,
  shadowColor: darkGray,
  focusColor: mainRed,
  iconTheme: IconThemeData(
      color: lightIconColor,
  ),
  accentIconTheme: IconThemeData(
      color: darkIconColor,
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(
      color: appBarTitleColor,
    ),
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: mainTextDarkScheme,
    )
  ),
  textTheme: TextTheme(
    // Location Tracker On/Off
  headline1: GoogleFonts.roboto(
        fontSize: 100,
        fontWeight: FontWeight.bold,
        color: explanationTextColor,
    ),
    headline2: GoogleFonts.roboto(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: explanationTextColor,
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: mainTextDarkScheme,
    ),
    // Profile Name Small (Chats)
    headlineLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: mainTextDarkScheme,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: mainTextDarkScheme,
    ),
    // mainRed as Background
    bodyText2: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: textOnMainRedColor,
    ),
  ),
);*/
