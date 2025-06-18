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
      debugPrint('Error loading launcher image: $e');
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
              const SizedBox(height: 30),
              const Text(
                'IRON DOME SIMULATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3.0,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 3),
                      blurRadius: 6,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'DEFEND THE PROTECTED ZONE',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.blue.withValues(alpha: 0.5),
                    ),
                  ],
                ),
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
