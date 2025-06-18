import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../models/missile.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

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
    // Draw background
    final background =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, background);

    // Draw protected zone
    final protectedZone =
        Paint()
          ..color = Colors.green.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 580, size.width, 20), protectedZone);

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
    // Draw base platform
    final platformPaint =
        Paint()
          ..color =
              Colors.grey[900]! // Darker grey for better contrast
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(150, 560, 100, 30), // Moved up above green line
      platformPaint,
    );

    // Draw launcher structure
    final structurePaint =
        Paint()
          ..color =
              Colors.grey[800]! // Lighter grey for contrast
          ..style = PaintingStyle.fill;

    // Draw vertical support
    canvas.drawRect(
      Rect.fromLTWH(190, 540, 20, 20), // Moved up above platform
      structurePaint,
    );

    // Draw launcher arms
    final armPaint =
        Paint()
          ..color =
              Colors.grey[700]! // Even lighter grey
          ..style =
              PaintingStyle
                  .stroke // Changed to stroke for better visibility
          ..strokeWidth =
              6 // Thicker lines
          ..strokeCap = StrokeCap.round;

    // Left arm
    canvas.drawLine(
      const Offset(190, 540), // Adjusted position
      const Offset(170, 530), // Adjusted position
      armPaint,
    );

    // Right arm
    canvas.drawLine(
      const Offset(210, 540), // Adjusted position
      const Offset(230, 530), // Adjusted position
      armPaint,
    );

    // Draw launcher details
    final detailPaint =
        Paint()
          ..color =
              Colors.grey[600]! // Lighter grey for details
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3; // Thicker lines

    // Draw circular details
    canvas.drawCircle(
      const Offset(200, 545), // Adjusted position
      8, // Larger circle
      detailPaint,
    );

    // Draw targeting reticle
    final reticlePaint =
        Paint()
          ..color = Colors.red.withValues(alpha: 0.7) // More opaque red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2; // Thicker lines

    canvas.drawCircle(
      const Offset(200, 545), // Adjusted position
      12, // Larger reticle
      reticlePaint,
    );
    canvas.drawLine(
      const Offset(200, 533), // Adjusted position
      const Offset(200, 557), // Adjusted position
      reticlePaint,
    );
    canvas.drawLine(
      const Offset(188, 545), // Adjusted position
      const Offset(212, 545), // Adjusted position
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
