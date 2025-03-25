// lib/theme/text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  // Arabic text
  static const TextStyle arabicText = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 22.0,
    height: 1.5,
  );

  // English text
  static const TextStyle englishText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 1.4,
  );

  // Headers/Titles
  static const TextStyle titleText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );
}
