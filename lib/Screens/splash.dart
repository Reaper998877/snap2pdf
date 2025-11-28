import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final bool navigate;
  const SplashScreen({super.key, required this.navigate});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Initialize animation controller
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      // Initialize scale animation
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      // Initialize fade animation
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward(); // Starts animation

    // Check navigation logic on initial load
    _checkNavigation();
  }

  // splash screen has:
  // an animation (controlled by _controller)
  // a navigate flag (true/false)
  // The problem:
  // ➤ “navigate” may change after the widget is built
  // Example:
  // App launches → navigate = false (because deep-link check is running)
  // Later → navigate becomes true after deep link finishes
  // In this scenario, the splash screen must:
  // ✔ detect that navigate changed from false → true
  // ✔ wait for the animation to finish
  // ✔ THEN navigate to Home screen
  // This code handles exactly that.

  // NEW: Detect if 'navigate' changed from false -> true
  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    // Detect property changes
    super.didUpdateWidget(oldWidget);
    // A StatefulWidget is rebuilt → didUpdateWidget is called.
    // Check if navigate changed from false to true.
    if (widget.navigate && !oldWidget.navigate) {
      // widget.navigate -> New value (after rebuild)
      // oldWidget.navigate -> Old value (before rebuild)
      _checkNavigation();
    }
  }

  void _checkNavigation() {
    if (!widget.navigate) return; // If navigate flag is still false → do nothing.

    // If animation is already done, navigate immediately
    if (_controller.isCompleted) {
      _navigateToHome();
    } else {
      // Otherwise, wait for it to finish
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) { // Check if animatin is complete
          _navigateToHome();
        }
      });
    }
  }

  void _navigateToHome() {
    // Ensure we only navigate once
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      size: 55,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Snap2PDF",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
