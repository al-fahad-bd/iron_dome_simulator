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
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GameController());
  }

  String formatCost(int cost) {
    if (cost >= 1000000000) {
      return '\$${(cost / 1000000000).toStringAsFixed(1)}B';
    } else if (cost >= 1000000) {
      return '\$${(cost / 1000000).toStringAsFixed(1)}M';
    } else if (cost >= 1000) {
      return '\$${(cost / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$$cost';
    }
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

          return Stack(
            children: [
              // Game canvas
              GestureDetector(
                onTapDown: (details) {
                  if (!_gameStarted) {
                    setState(() {
                      _gameStarted = true;
                    });
                  } else {
                    controller.fireInterceptor(details.localPosition);
                  }
                },
                child: Stack(
                  children: [
                    GetBuilder<GameController>(
                      builder:
                          (ctrl) => CustomPaint(
                            painter: GamePainter(
                              missiles: ctrl.missiles,
                              explosions: ctrl.explosions,
                            ),
                            size: Size.infinite,
                          ),
                    ),
                    if (!_gameStarted)
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tap to Start',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Cost meter overlay
              Positioned(
                top: 20,
                left: 20,
                child: GetBuilder<GameController>(
                  builder:
                      (ctrl) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MISSILE COST',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCost(ctrl.totalCost.value),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${ctrl.totalCost.value ~/ GameController.costPerMissile} missiles fired',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ctrl.successfulInterceptions.value} successful hits',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 10,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${ctrl.groundHits.value} ground hits',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 10,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ],
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

    // Draw protected zone at the bottom (realistic homes/buildings/trees)
    final double groundY = size.height - 80;
    final double zoneHeight = 30;
    final double spacing = 32;
    double x = 8;
    final grassPaint = Paint()..color = Colors.green[700]!;
    // Draw grass patches
    for (double gx = 0; gx < size.width; gx += 10) {
      canvas.drawArc(
        Rect.fromLTWH(gx, groundY + zoneHeight - 4, 12, 8),
        pi,
        2 * pi,
        false,
        grassPaint,
      );
    }
    int treeCounter = 0;
    while (x < size.width - 32) {
      final yOffset = 6.0;
      // Draw a detailed house
      final houseBasePaint = Paint()..color = Colors.brown[600]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, groundY + 8 + yOffset, 18, 12),
          Radius.circular(3),
        ),
        houseBasePaint,
      );
      final roofPaint =
          Paint()
            ..shader = LinearGradient(
              colors: [Colors.red[700]!, Colors.red[300]!],
            ).createShader(Rect.fromLTWH(x, groundY + 2 + yOffset, 22, 8));
      final roofPath =
          Path()
            ..moveTo(x - 2, groundY + 8 + yOffset)
            ..lineTo(x + 9, groundY + yOffset)
            ..lineTo(x + 20, groundY + 8 + yOffset)
            ..close();
      canvas.drawPath(roofPath, roofPaint);
      // Chimney
      final chimneyPaint = Paint()..color = Colors.grey[700]!;
      canvas.drawRect(
        Rect.fromLTWH(x + 14, groundY + 2 + yOffset, 3, 6),
        chimneyPaint,
      );
      // Door
      final doorPaint = Paint()..color = Colors.brown[900]!;
      canvas.drawRect(
        Rect.fromLTWH(x + 7, groundY + 15 + yOffset, 4, 5),
        doorPaint,
      );
      // Windows
      final windowPaint = Paint()..color = Colors.blue[100]!;
      canvas.drawRect(
        Rect.fromLTWH(x + 3, groundY + 11 + yOffset, 3, 3),
        windowPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 12, groundY + 11 + yOffset, 3, 3),
        windowPaint,
      );
      x += spacing;
      // Draw a realistic building (taller)
      final buildingY = groundY + 8 + yOffset - 16;
      final buildingPaint =
          Paint()
            ..shader = LinearGradient(
              colors: [Colors.grey[400]!, Colors.grey[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(x, buildingY, 12, 28));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, buildingY, 12, 28),
          Radius.circular(2),
        ),
        buildingPaint,
      );
      // Building roof
      final bRoofPaint = Paint()..color = Colors.grey[800]!;
      canvas.drawRect(Rect.fromLTWH(x - 1, buildingY, 14, 3), bRoofPaint);
      // Building windows
      final bWindowPaint = Paint()..color = Colors.blue[50]!;
      for (int wy = 0; wy < 5; wy++) {
        for (int wx = 0; wx < 2; wx++) {
          canvas.drawRect(
            Rect.fromLTWH(x + 2 + wx * 5, buildingY + 4 + wy * 4, 3, 3),
            bWindowPaint,
          );
        }
      }
      x += spacing;
      // Draw a realistic tree only every other cycle
      if (treeCounter % 2 == 0) {
        final trunkPaint =
            Paint()
              ..shader = LinearGradient(
                colors: [Colors.brown[800]!, Colors.brown[400]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(
                Rect.fromLTWH(x + 6, groundY + 14 + yOffset, 3, 8),
              );
        canvas.drawRect(
          Rect.fromLTWH(x + 6, groundY + 14 + yOffset, 3, 8),
          trunkPaint,
        );
        // Foliage (layered)
        final foliagePaint1 = Paint()..color = Colors.green[800]!;
        final foliagePaint2 = Paint()..color = Colors.green[500]!;
        final foliagePaint3 = Paint()..color = Colors.green[300]!;
        canvas.drawCircle(
          Offset(x + 7.5, groundY + 14 + yOffset),
          8,
          foliagePaint1,
        );
        canvas.drawCircle(
          Offset(x + 7.5, groundY + 10 + yOffset),
          6,
          foliagePaint2,
        );
        canvas.drawCircle(
          Offset(x + 7.5, groundY + 7 + yOffset),
          4,
          foliagePaint3,
        );
        // Tree shadow
        final shadowPaint =
            Paint()..color = Colors.black.withValues(alpha: 0.2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + 8, groundY + 22 + yOffset),
            width: 12,
            height: 4,
          ),
          shadowPaint,
        );
        x += spacing;
      }
      treeCounter++;
    }

    // Draw missile launcher pad
    _drawLauncherPad(canvas, size);

    // Draw explosions first
    for (var explosion in explosions) {
      _drawExplosion(canvas, explosion, groundY);
    }

    // Draw missiles
    for (var missile in missiles) {
      _drawMissile(canvas, missile);
    }
  }

  void _drawLauncherPad(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 50;

    // Draw main platform base
    final platformPaint =
        Paint()
          ..color = Colors.grey[900]!
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 60, bottomY - 25, 120, 25),
      platformPaint,
    );

    // Draw platform border
    final borderPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 60, bottomY - 25, 120, 25),
      borderPaint,
    );

    // Draw central support structure
    final supportPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 15, bottomY - 45, 30, 20),
      supportPaint,
    );

    // Draw launcher arms
    final armPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    // Left launcher arm
    canvas.drawLine(
      Offset(centerX - 15, bottomY - 45),
      Offset(centerX - 35, bottomY - 55),
      armPaint,
    );

    // Right launcher arm
    canvas.drawLine(
      Offset(centerX + 15, bottomY - 45),
      Offset(centerX + 35, bottomY - 55),
      armPaint,
    );

    // Draw missile tubes
    final tubePaint =
        Paint()
          ..color = Colors.grey[850]!
          ..style = PaintingStyle.fill;

    // Left missile tube
    canvas.drawRect(
      Rect.fromLTWH(centerX - 40, bottomY - 60, 12, 20),
      tubePaint,
    );

    // Right missile tube
    canvas.drawRect(
      Rect.fromLTWH(centerX + 28, bottomY - 60, 12, 20),
      tubePaint,
    );

    // Draw tube borders
    final tubeBorderPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(centerX - 40, bottomY - 60, 12, 20),
      tubeBorderPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(centerX + 28, bottomY - 60, 12, 20),
      tubeBorderPaint,
    );

    // Draw central control unit
    final controlPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, bottomY - 50, 24, 15),
      controlPaint,
    );

    // Draw control unit border
    final controlBorderPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, bottomY - 50, 24, 15),
      controlBorderPaint,
    );

    // Draw targeting system
    final targetPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Central targeting reticle
    canvas.drawCircle(Offset(centerX, bottomY - 42), 8, targetPaint);

    // Targeting crosshairs
    canvas.drawLine(
      Offset(centerX, bottomY - 50),
      Offset(centerX, bottomY - 34),
      targetPaint,
    );
    canvas.drawLine(
      Offset(centerX - 8, bottomY - 42),
      Offset(centerX + 8, bottomY - 42),
      targetPaint,
    );

    // Draw status indicators
    final statusPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    // Left status light
    canvas.drawCircle(Offset(centerX - 25, bottomY - 35), 3, statusPaint);

    // Right status light
    canvas.drawCircle(Offset(centerX + 25, bottomY - 35), 3, statusPaint);

    // Draw platform panels
    final panelPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    // Left panel
    canvas.drawRect(
      Rect.fromLTWH(centerX - 50, bottomY - 20, 20, 10),
      panelPaint,
    );

    // Right panel
    canvas.drawRect(
      Rect.fromLTWH(centerX + 30, bottomY - 20, 20, 10),
      panelPaint,
    );
  }

  void _drawExplosion(Canvas canvas, Explosion explosion, double groundY) {
    final paint =
        Paint()
          ..color =
              explosion.isGround
                  ? Colors.red[900]!.withValues(alpha: explosion.opacity)
                  : Colors.yellow.withValues(alpha: explosion.opacity)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(explosion.position, explosion.radius, paint);
    final border =
        Paint()
          ..color =
              explosion.isGround
                  ? Colors.red[700]!.withValues(alpha: explosion.opacity)
                  : Colors.orange.withValues(alpha: explosion.opacity)
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
