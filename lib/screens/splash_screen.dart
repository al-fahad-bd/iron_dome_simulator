import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'game_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ui.Image? _launcherImage;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Navigate to main game after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Get.off(() => const GameScreen());
    });
  }

  Future<void> _loadImage() async {
    try {
      final imageProvider = AssetImage('assets/missile_launcher.png');
      final imageStream = imageProvider.resolve(ImageConfiguration());
      final imageCompleter = Completer<ui.Image>();
      final imageListener = ImageStreamListener(
        (ImageInfo info, bool _) => imageCompleter.complete(info.image),
      );
      imageStream.addListener(imageListener);
      _launcherImage = await imageCompleter.future;
      setState(() {
        _imageLoaded = true;
      });
    } catch (e) {
      print('Error loading launcher image: $e');
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
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageLoaded)
                CustomPaint(
                  size: const Size(200, 200),
                  painter: LauncherPainter(image: _launcherImage!),
                ),
              const SizedBox(height: 20),
              const Text(
                'Iron Dome Simulation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Defend the Protected Zone',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LauncherPainter extends CustomPainter {
  final ui.Image image;

  LauncherPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
