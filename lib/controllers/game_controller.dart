import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import '../models/missile.dart';

class GameController extends GetxController {
  final missiles = <Missile>[].obs;
  final explosions = <Explosion>[].obs;
  final totalCost = 0.obs; // Track total cost in dollars
  final successfulInterceptions =
      0.obs; // Track successful missile interceptions
  final groundHits = 0.obs; // Track enemy missiles that hit the ground
  final gameOver = false.obs; // Track if game is over
  Timer? gameTimer;
  Timer? spawnTimer;
  final Random random = Random();

  // Screen dimensions
  double screenWidth = 400;
  double screenHeight = 650;

  // Cost per missile launch
  static const int costPerMissile = 50000; // $50K per missile
  static const double enemyMissileLength =
      30; // Height of the enemy missile image in pixels

  // Image caches
  ui.Image? enemyMissileImage;
  ui.Image? interceptorImage;
  bool imagesLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _loadImages();
  }

  void setScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
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
      debugPrint('Error loading images: $e');
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

    final x = random.nextDouble() * screenWidth;
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

    // Fire from center bottom of screen
    // final launcherX = screenWidth / 2;
    // final launcherY = screenHeight - 50;

    // Fire from launcher tube (centered between the two tubes for now)
    final tubeOffsets = [screenWidth / 2 - 34, screenWidth / 2 + 34];
    final launcherX = tubeOffsets[random.nextInt(2)];
    final launcherY = screenHeight - 60;

    missiles.add(
      Missile(
        position: Offset(launcherX, launcherY),
        velocity: Offset((tapPosition.dx - launcherX) / 50, -4),
        isInterceptor: true,
        image: interceptorImage,
      ),
    );

    // Add cost for missile launch
    totalCost.value += costPerMissile;
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
          newExplosions.add(Explosion(position: mid, isGround: false));

          // Increment successful interceptions counter
          successfulInterceptions.value++;
        }
      }
    }
    // Remove collided missiles
    final sorted = toRemove.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in sorted) {
      if (idx < missiles.length) missiles.removeAt(idx);
    }
    // Remove out-of-bounds missiles
    missiles.removeWhere((missile) {
      bool outOfBounds =
          missile.position.dy > screenHeight + 50 ||
          missile.position.dy < -50 ||
          missile.position.dx < -50 ||
          missile.position.dx > screenWidth + 50;
      bool hitProtectedZone =
          !missile.isInterceptor &&
          (missile.position.dy + enemyMissileLength / 2) >= screenHeight - 70;
      if (hitProtectedZone) {
        // Add explosion at the hit location
        explosions.add(Explosion(position: missile.position, isGround: true));
        groundHits.value++;
        if (groundHits.value >= 5 && !gameOver.value) {
          gameOver.value = true;
          gameTimer?.cancel();
          spawnTimer?.cancel();
        }
      }
      return outOfBounds || hitProtectedZone;
    });
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

  void resetGame() {
    missiles.clear();
    explosions.clear();
    totalCost.value = 0;
    successfulInterceptions.value = 0;
    groundHits.value = 0;
    gameOver.value = false;
    startGame();
    update();
  }

  @override
  void onClose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    super.onClose();
  }
}
