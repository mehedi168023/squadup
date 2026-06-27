import 'package:flutter/material.dart';

/// Typography. Display/headings use Baloo Da 2 (rounded bold, matches the
/// original logo-adjacent titles); body uses Google Sans.
class AppTextStyles {
  AppTextStyles._();

  static const String display = 'BalooDa2';
  static const String body = 'GoogleSans';

  static const TextStyle h1 = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 25,
    height: 1.1,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 19,
    height: 1.15,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 15.5,
  );

  static const TextStyle title = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 13.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    letterSpacing: 0.3,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.35,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 11.5,
    height: 1.35,
  );

  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 11.5,
  );

  /// Uppercase, letter-spaced section/stat captions ("ALL GAMES & MODES").
  static const TextStyle caption = TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 10.5,
    letterSpacing: 1.4,
  );
}
