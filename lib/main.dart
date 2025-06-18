import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Iron Dome Simulation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

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
      Get.off(() => const IronDomeSimulation());
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

class Missile {
  Offset position;
  Offset velocity;
  bool isInterceptor;
  ui.Image? image;

  Missile({
    required this.position,
    required this.velocity,
    this.isInterceptor = false,
    this.image,
  });
}

class Explosion {
  Offset position;
  double radius;
  double maxRadius;
  double opacity;
  int lifetime;

  Explosion({
    required this.position,
    this.radius = 0,
    this.maxRadius = 30,
    this.opacity = 1.0,
    this.lifetime = 10, // 10 frames (0.5s)
  });
}

class GameController extends GetxController {
  final missiles = <Missile>[].obs;
  final explosions = <Explosion>[].obs;
  Timer? gameTimer;
  Timer? spawnTimer;
  final Random random = Random();

  // Image caches
  ui.Image? enemyMissileImage;
  ui.Image? interceptorImage;
  bool imagesLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      // Load enemy missile image (torpedo)
      final enemyImageProvider = AssetImage('assets/torpedo.png');
      final enemyImageStream = enemyImageProvider.resolve(ImageConfiguration());
      final enemyImageCompleter = Completer<ui.Image>();
      final enemyImageListener = ImageStreamListener(
        (ImageInfo info, bool _) => enemyImageCompleter.complete(info.image),
      );
      enemyImageStream.addListener(enemyImageListener);
      enemyMissileImage = await enemyImageCompleter.future;

      // Load interceptor image (Iron Dome missile)
      final interceptorImageProvider = AssetImage('assets/missile.png');
      final interceptorImageStream = interceptorImageProvider.resolve(
        ImageConfiguration(),
      );
      final interceptorImageCompleter = Completer<ui.Image>();
      final interceptorImageListener = ImageStreamListener(
        (ImageInfo info, bool _) =>
            interceptorImageCompleter.complete(info.image),
      );
      interceptorImageStream.addListener(interceptorImageListener);
      interceptorImage = await interceptorImageCompleter.future;

      imagesLoaded = true;
      startGame(); // Start the game after images are loaded
      update();
    } catch (e) {
      print('Error loading images: $e');
    }
  }

  void startGame() {
    if (!imagesLoaded) return;

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      updateGame();
    });
    spawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      spawnMissile();
    });
  }

  void spawnMissile() {
    if (!imagesLoaded) return;

    final x = random.nextDouble() * 400;
    final targetX = x + (random.nextDouble() * 100 - 50);
    missiles.add(
      Missile(
        position: Offset(x, 0),
        velocity: Offset((targetX - x) / 100, 2),
        image: enemyMissileImage,
      ),
    );
  }

  void fireInterceptor(Offset tapPosition) {
    if (!imagesLoaded) return;

    missiles.add(
      Missile(
        position: const Offset(200, 600),
        velocity: Offset((tapPosition.dx - 200) / 50, -4),
        isInterceptor: true,
        image: interceptorImage,
      ),
    );
  }

  void updateGame() {
    final toRemove = <int>{};
    final newExplosions = <Explosion>[];
    // Update positions
    for (var missile in missiles) {
      missile.position += missile.velocity;
    }
    // Detect collisions
    for (int i = 0; i < missiles.length; i++) {
      for (int j = i + 1; j < missiles.length; j++) {
        if (missiles[i].isInterceptor != missiles[j].isInterceptor &&
            (missiles[i].position - missiles[j].position).distance < 20) {
          toRemove.add(i);
          toRemove.add(j);
          // Add explosion at collision point
          final mid = (missiles[i].position + missiles[j].position) / 2;
          newExplosions.add(Explosion(position: mid));
        }
      }
    }
    // Remove collided missiles
    final sorted = toRemove.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in sorted) {
      if (idx < missiles.length) missiles.removeAt(idx);
    }
    // Remove out-of-bounds missiles
    missiles.removeWhere(
      (missile) =>
          missile.position.dy > 650 ||
          missile.position.dy < -50 ||
          missile.position.dx < -50 ||
          missile.position.dx > 450,
    );
    // Add new explosions
    explosions.addAll(newExplosions);
    // Update explosions
    for (var explosion in explosions) {
      explosion.radius += explosion.maxRadius / 10;
      explosion.opacity -= 1.0 / 10;
      explosion.lifetime--;
    }
    explosions.removeWhere((e) => e.lifetime <= 0 || e.opacity <= 0);
    update();
  }

  @override
  void onClose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    super.onClose();
  }
}

class IronDomeSimulation extends StatelessWidget {
  const IronDomeSimulation({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.put(GameController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iron Dome Simulation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        onTapDown: (details) {
          controller.fireInterceptor(details.localPosition);
        },
        child: Center(
          child: GetBuilder<GameController>(
            builder:
                (ctrl) => CustomPaint(
                  painter: GamePainter(
                    missiles: ctrl.missiles,
                    explosions: ctrl.explosions,
                  ),
                  size: const Size(400, 650),
                ),
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final List<Missile> missiles;
  final List<Explosion> explosions;

  GamePainter({required this.missiles, required this.explosions});

  @override
  void paint(Canvas canvas, Size size) {
    final protectedZone =
        Paint()
          ..color = Colors.green.withOpacity(0.3)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 580, size.width, 20), protectedZone);

    // Draw explosions first
    for (var explosion in explosions) {
      _drawExplosion(canvas, explosion);
    }

    // Draw missiles
    for (var missile in missiles) {
      _drawMissile(canvas, missile);
    }
  }

  void _drawExplosion(Canvas canvas, Explosion explosion) {
    final paint =
        Paint()
          ..color = Colors.yellow.withOpacity(explosion.opacity)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(explosion.position, explosion.radius, paint);
    final border =
        Paint()
          ..color = Colors.orange.withOpacity(explosion.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(explosion.position, explosion.radius, border);
  }

  void _drawMissile(Canvas canvas, Missile missile) {
    if (missile.image == null) return;

    final angle = missile.velocity.direction;
    canvas.save();
    canvas.translate(missile.position.dx, missile.position.dy);

    // Different rotation for enemy missiles vs interceptors
    if (missile.isInterceptor) {
      canvas.rotate(angle + pi / 2); // Interceptors point upward
    } else {
      canvas.rotate(angle - pi / 2); // Enemy missiles point downward
    }

    // Draw the missile image
    final imageSize =
        missile.isInterceptor
            ? 30.0
            : 40.0; // Different sizes for different missiles
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: imageSize,
      height: imageSize,
    );

    canvas.drawImageRect(
      missile.image!,
      Rect.fromLTWH(
        0,
        0,
        missile.image!.width.toDouble(),
        missile.image!.height.toDouble(),
      ),
      rect,
      Paint(),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
