import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get isFlutterTest {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

Route<T> createPageRoute<T>(Widget page) {
  if (isFlutterTest) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  } else {
    return MaterialPageRoute<T>(builder: (context) => page);
  }
}
