import 'package:flutter/material.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();

    // Mulai animasi setelah 300ms
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _animate = true;
      });
    });

    // Navigasi otomatis ke SplashScreen2
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/splash2');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7AC943),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          width: _animate ? 300 : 180,
          height: _animate ? 120 : 180,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _animate ? 50 : 80,
                height: _animate ? 50 : 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/splash_screen/logo_screen.png',
                  fit: BoxFit.contain,
                ),
              ),
              if (_animate) ...[
                const SizedBox(width: 20),
                const Text(
                  'PocketFarm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
