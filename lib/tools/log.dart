import 'package:logger/logger.dart';

var log = Logger(
  printer: PrettyPrinter(
    //we dont need this
    printEmojis: false,
    methodCount: 0,
    colors: true
  ),
  filter: null
);