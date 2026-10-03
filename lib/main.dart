import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/routes.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  if (!kIsWeb) {
    try {
      HttpOverrides.global = MyHttpOverrides();
    } catch (_) {}
  }
  runApp(const MyApp());
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrivKart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C38FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default fallback
        pageTransitionsTheme: isFlutterTest
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: NoTransitionsBuilder(),
                  TargetPlatform.iOS: NoTransitionsBuilder(),
                  TargetPlatform.macOS: NoTransitionsBuilder(),
                  TargetPlatform.windows: NoTransitionsBuilder(),
                  TargetPlatform.linux: NoTransitionsBuilder(),
                },
              )
            : null,
      ),
      home: const SplashScreen(),
    );
  }
}
