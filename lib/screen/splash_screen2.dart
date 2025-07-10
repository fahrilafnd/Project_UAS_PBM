import 'package:flutter/material.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen2>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<Alignment> _alignmentAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool showContent = false;

  @override
  void initState() {
    super.initState();

    // Controller utama untuk logo bergerak
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _alignmentAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.topLeft,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    // Controller untuk fade-in content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 300), () {
      _mainController.forward();
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          showContent = true;
        });
        _fadeController.forward(); // mulai animasi fade setelah logo selesai
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    return Align(
      alignment: _alignmentAnimation.value,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/splash_screen/logo_screen.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Opacity(
              opacity: _scaleAnimation.value < 1.2 ? 1.0 : 0.0,
              child: const Text(
                'PocketFarm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const SizedBox(height: 100),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/splash_screen/image_screen.png',
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.5,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memetakan Lahan, Penjadwalan\nKegiatan Pertanian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Solusi cerdas untuk petani dalam memetakan dan merencanakan kegiatan pertanian.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selanjutnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7AC943),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) => _buildLogo(),
            ),
            if (showContent) _buildContent(context),
          ],
        ),
      ),
    );
  }
}
