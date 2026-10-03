import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/routes.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _uiOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Fade in UI after a short delay (skip delay in tests to avoid timer collision)
    if (isFlutterTest) {
      _uiOpacity = 1.0;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _uiOpacity = 1.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF7E30), // Vibrant Orange
              Color(0xFFFFF5EE), // Soft Creamy Orange Glow
              Colors.white,      // Pure White at Bottom
            ],
            stops: [0.0, 0.6, 0.85],
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _uiOpacity,
            duration: const Duration(milliseconds: 800),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          children: [
                            const Spacer(),
                            
                            // Central Collage Image Box
                            Center(
                              child: SizedBox(
                                width: screenWidth * 0.85, // 85% of screen width
                                height: screenHeight * 0.58, // 58% of screen height
                                child: Image.asset(
                                  'assets/images/welcome.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            
                            const Spacer(flex: 2),

                            // Decorative orange divider line
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6D00),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title Texts
                            const Text(
                              'Everyday Essentials,',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Delivered Fast',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFFF6D00),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Next Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutCubic;

                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(tween);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 600),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(
                                    color: Colors.black87,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}
