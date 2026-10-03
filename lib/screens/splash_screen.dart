import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.85;

  @override
  void initState() {
    super.initState();
    
    // Start animations shortly after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // Navigate to WelcomeScreen or HomeScreen after 3 seconds
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final savedPhone = prefs.getString('mobileno');

        if (!mounted) return;

        Widget targetScreen;
        if (token != null && token.isNotEmpty) {
          targetScreen = HomeScreen(phoneNumber: savedPhone ?? '7904488781');
        } else {
          targetScreen = const WelcomeScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05); // slight slide up
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
              var fadeAnimation = animation.drive(fadeTween);

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Off-white / Pure white background matching mockup
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeIn,
                child: SizedBox(
                  width: screenWidth * 0.7, // Centered responsive logo
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const Text(
              'TRIVKART',
              style: TextStyle(
                color: Colors.transparent,
                fontSize: 0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
