import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../models/missile.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GameController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'IRON DOME SIMULATION',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
            letterSpacing: 2.0,
            shadows: [
              Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.blue),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Update controller with screen dimensions
          controller.setScreenSize(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            onTapDown: (details) {
              controller.fireInterceptor(details.localPosition);
            },
            child: GetBuilder<GameController>(
              builder:
                  (ctrl) => CustomPaint(
                    painter: GamePainter(
                      missiles: ctrl.missiles,
                      explosions: ctrl.explosions,
                    ),
                    size: Size.infinite,
                  ),
            ),
          );
        },
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
    // Draw background
    final background =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, background);

    // Draw protected zone at the bottom
    final protectedZone =
        Paint()
          ..color = Colors.green.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 70, size.width, 20),
      protectedZone,
    );

    // Draw missile launcher pad
    _drawLauncherPad(canvas, size);

    // Draw explosions first
    for (var explosion in explosions) {
      _drawExplosion(canvas, explosion);
    }

    // Draw missiles
    for (var missile in missiles) {
      _drawMissile(canvas, missile);
    }
  }

  void _drawLauncherPad(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 50;
    
    // Draw base platform
    final platformPaint =
        Paint()
          ..color = Colors.grey[900]!
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 50, bottomY - 30, 100, 30),
      platformPaint,
    );

    // Draw launcher structure
    final structurePaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.fill;

    // Draw vertical support
    canvas.drawRect(
      Rect.fromLTWH(centerX - 10, bottomY - 50, 20, 20),
      structurePaint,
    );

    // Draw launcher arms
    final armPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;

    // Left arm
    canvas.drawLine(
      Offset(centerX - 10, bottomY - 50),
      Offset(centerX - 30, bottomY - 60),
      armPaint,
    );

    // Right arm
    canvas.drawLine(
      Offset(centerX + 10, bottomY - 50),
      Offset(centerX + 30, bottomY - 60),
      armPaint,
    );

    // Draw launcher details
    final detailPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    // Draw circular details
    canvas.drawCircle(
      Offset(centerX, bottomY - 45), 8,
      detailPaint,
    );

    // Draw targeting reticle
    final reticlePaint =
        Paint()
          ..color = Colors.red.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(centerX, bottomY - 45), 12,
      reticlePaint,
    );
    canvas.drawLine(
      Offset(centerX, bottomY - 57),
      Offset(centerX, bottomY - 33),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(centerX - 12, bottomY - 45),
      Offset(centerX + 12, bottomY - 45),
      reticlePaint,
    );
  }

  void _drawExplosion(Canvas canvas, Explosion explosion) {
    final paint =
        Paint()
          ..color = Colors.yellow.withValues(alpha: explosion.opacity)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(explosion.position, explosion.radius, paint);
    final border =
        Paint()
          ..color = Colors.orange.withValues(alpha: explosion.opacity)
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

