import 'package:flutter/material.dart';

const Color blueishlr = Color(0xFF4e5ae8);
const Color yellowclr = Color(0xFFFFB746);
const Color pinkclr = Color(0xFFff4667);
const Color white = Colors.white;
const primaryclr = blueishlr;
const Color darkgreyclr = Color(0xFF121212);
const darkHeaderclr = Color(0xFF424242);

class Themes {
  static final light =
      ThemeData(primaryColor: primaryclr, brightness: Brightness.light);

  static final dark =
      ThemeData(primaryColor: darkgreyclr, brightness: Brightness.dark);
}
